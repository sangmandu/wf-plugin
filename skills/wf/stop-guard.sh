#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────
# wf Stop Guard (cwd-scoped)
#
# Registered as a Stop hook in the worktree's
# .claude/settings.json (installed by lib/install-hooks.sh).
#
# Prevents the agent from interrupting mid-workflow unless
# control.interrupted=true. The interrupt stays open across
# turns until `run.sh resume` clears it.
#
# Also auto-enters interrupt mode when the current step is
# one of INTERRUPT_STEPS — steps that inherently need user
# input (reproduction review, plan confirm, merge, etc.).
# ─────────────────────────────────────────────────────────

WF_ROOT="$(cd "$(dirname "$0")" && pwd)"

INTERRUPT_STEPS=(
  INVESTIGATE
  VERIFY
  REPORT
  DEBATE_FOR_PLAN
  EXPLAIN_PLAN
  EXPLAIN_TEST
  BRAINSTORM_EXPLORE
  BRAINSTORM_REPORT
  COMPLETE_MERGE
)

INPUT="$(cat)"
CWD="$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)"
[ -z "$CWD" ] && CWD="$(pwd)"

STATE="$CWD/.workflow/state.json"
[ -f "$STATE" ] || exit 0

STATUS="$(jq -r '.control.status // ""' "$STATE" 2>/dev/null)" || exit 0
[ "$STATUS" = "running" ] || exit 0

CURRENT="$(jq -r '.control.current_step // ""' "$STATE" 2>/dev/null)" || exit 0
[ -z "$CURRENT" ] && exit 0

# Interrupt active → allow stop (flag is cleared only by resume)
INTERRUPTED="$(jq -r '.control.interrupted // false' "$STATE" 2>/dev/null)" || INTERRUPTED="false"
if [ "$INTERRUPTED" = "true" ]; then
  exit 0
fi

# Interrupt-steps → auto-enter interrupt mode so user replies are treated as answers
for step in "${INTERRUPT_STEPS[@]}"; do
  if [ "$CURRENT" = "$step" ]; then
    TMP="${STATE}.tmp.$$"
    jq --arg step "$CURRENT" '.control.interrupted = true | .control.interrupt_reason = "step: " + $step' "$STATE" > "$TMP" && mv "$TMP" "$STATE"
    exit 0
  fi
done

# Block the stop
TOTAL="$(jq -r '.control.steps | length' "$STATE" 2>/dev/null)" || TOTAL="?"
COMPLETED="$(jq -r '[.control.steps[] | select(.status=="completed")] | length' "$STATE" 2>/dev/null)" || COMPLETED="?"
POSITION=$((COMPLETED + 1))

cat <<EOF
{
  "decision": "block",
  "reason": "[wf guard] Workflow is still running — step [$POSITION/$TOTAL] $CURRENT.\nChoose one of the following:\n  1. Step is complete → bash $WF_ROOT/run.sh complete $CURRENT\n  2. Continue working → proceed with the workflow instructions\n  3. Need user input → bash $WF_ROOT/run.sh interrupt \"<reason>\""
}
EOF
