#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────
# agent-interrupt.sh — Agent-initiated interrupt
#
# Purpose: Pause the workflow when you judge that user intervention has
#          become necessary. Not for casual questions.
#
# Sets control.interrupted=true so stop-guard allows the stop. The pause
# stays open across multiple turns until `run.sh resume` is called.
#
# Usage:
#   bash ${CLAUDE_PLUGIN_ROOT}/skills/wf/scripts/agent-interrupt.sh "<short label>"
#
# The reason must be a SHORT LABEL (≤40 chars, single line). Good:
#   "plan review"  "test design"  "ci log triage"
# Bad:
#   "I need the user to review the plan and..."  (too long — put detail
#   in the agent's actual response to the user, not the flag)
#
# Limit: 100 chars, single line.
# ─────────────────────────────────────────────────────────

WF_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REASON="${1:-agent needs input}"

if [[ "$REASON" == *$'\n'* ]]; then
  echo "ERROR: interrupt_reason must be single-line (got multi-line)" >&2
  exit 1
fi
if (( ${#REASON} > 100 )); then
  echo "ERROR: interrupt_reason too long (${#REASON} chars, max 100). Use a short label like \"plan review\"." >&2
  exit 1
fi

find_state_file() {
  local candidates=("./.workflow/state.json")
  local git_root
  if git_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    candidates+=("$git_root/.workflow/state.json")
  fi
  for c in "${candidates[@]}"; do
    if [ -f "$c" ]; then
      echo "$c"
      return 0
    fi
  done
  return 1
}

STATE_FILE="$(find_state_file)" || { echo "No active workflow found" >&2; exit 1; }

TMP="${STATE_FILE}.tmp.$$"
jq --arg reason "$REASON" '.control.interrupted = true | .control.interrupt_reason = $reason' "$STATE_FILE" > "$TMP" && mv "$TMP" "$STATE_FILE"

cat <<'EOF'
Interrupt flag set. Workflow paused.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
INTERRUPT REPORT — present ALL 4 sections to the user below
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The user has NOT been watching the session and does NOT know your
context. Bridge the information asymmetry. No file-dump + "proceed?".

1. Context  ← apply `helpers#explanation_style` (PTIA) in full
   Walk the user from "nothing observed" to "ready to decide" using
   all 4 PTIA steps in order:
     · Problem-First Entry — the impossibility / conflict that forced
       the pause. NOT "I was at step X". Lead with what broke.
     · Timeline Walkthrough — how the state reached this point
       (first → then → so). Numbered steps or ASCII flow.
     · Inline Data Example — real paths, values, CI output, error
       text. Never describe data abstractly when you can show it.
     · One-Word Anchor — map any new concept to something the user
       already knows (1 word/phrase, no extra explanation).

2. Options
   - Concrete choices with tradeoffs. Do NOT ask open-ended questions.
   - For each option: what it means, what it costs, what it unlocks.

3. Recommendation + reasoning
   - Which option you lean toward and why.
   - What evidence / prior step output supports it.

4. Ask
   - One line: "Pick A or B" / "Tell me value of X" / "Confirm Y".

The interrupt stays active across turns. Keep conversing with the user
as needed. When the topic is resolved and you are returning to the
workflow, run `bash $WF_ROOT/run.sh resume`.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

# Append the explanation_style (PTIA) helper body so the agent has the
# full pattern visible inline — not just the "apply it here" pointer.
export WF_ROOT
python3 - <<'PY'
import os, sys
try:
    import yaml
except ImportError:
    sys.exit(0)
path = os.path.join(os.environ.get("WF_ROOT", ""), "helpers.yaml")
if not os.path.exists(path):
    sys.exit(0)
with open(path) as f:
    data = yaml.safe_load(f) or {}
section = (data.get("on_demand") or {}).get("explanation_style")
if not section:
    sys.exit(0)
print()
print("━━━ Helper: explanation_style (PTIA) ━━━")
print()
print(section["body"].rstrip())
PY

echo "Reason: $REASON"
