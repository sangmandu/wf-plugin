#!/usr/bin/env bash
# Usage: bash ${CLAUDE_PLUGIN_ROOT}/skills/wf/lib/init-workflow.sh <track> <task_description>
#
# 1. Verifies environment (worktree + settings.json)
# 2. Runs track-specific preflight checks
# 3. Installs wf hooks into cwd .claude/settings.json
# 4. Generates .workflow/state.json (control/data namespaces) based on track
# 5. Outputs the first step file content
set -euo pipefail

TRACK="${1:?Usage: init-workflow.sh <track> <task_description>}"
TASK_DESC="${2:?Usage: init-workflow.sh <track> <task_description>}"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REGISTRY="$SKILL_DIR/step-registry.json"
TRACK_STEPS="$SKILL_DIR/track-steps.json"

# Normalize legacy track aliases for backwards compatibility
[[ "$TRACK" == "standard" ]] && TRACK="feature"
[[ "$TRACK" == "debug" ]] && TRACK="fix"

if [[ "$TRACK" != "feature" && "$TRACK" != "fix" && "$TRACK" != "light" && "$TRACK" != "brainstorm" ]]; then
  echo "ERROR: track must be feature, fix, light, or brainstorm" >&2
  exit 1
fi

# ── Capability check: can wf run here? ──
bash "$SKILL_DIR/lib/env-check.sh"

# ── Preflight check (deterministic, <1s) ──
PREFLIGHT_OUTPUT=$(bash "$SKILL_DIR/lib/preflight-check.sh" 2>&1) || {
  echo "$PREFLIGHT_OUTPUT"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Preflight failed. Resolve the issues above, then re-run /wf."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 1
}
[ -n "$PREFLIGHT_OUTPUT" ] && echo "$PREFLIGHT_OUTPUT"

# ── Install wf hooks into cwd's .claude/settings.json ──
bash "$SKILL_DIR/lib/install-hooks.sh" "$PWD" >/dev/null

# ── Build state.json via jq ──
mkdir -p .workflow
STATE=".workflow/state.json"

NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
WORKFLOW_ID="$(uuidgen | tr '[:upper:]' '[:lower:]')"

# Read step list for track from track-steps.json, build steps object.
# Mark the first step as 'running'; rest 'pending'.
# Add 'attempt: 0' for DEBATE_FOR_PLAN and DEBATE_TEST.
STEPS_JSON="$(
  jq --arg track "$TRACK" '
    .[$track]
    | . as $keys
    | reduce to_entries[] as $e (
        {};
        .[$e.value] = (
          { status: (if $e.key == 0 then "running" else "pending" end) }
          + (if ($e.value == "DEBATE_FOR_PLAN" or $e.value == "DEBATE_TEST") then {attempt: 0} else {} end)
        )
      )
  ' "$TRACK_STEPS"
)"

FIRST_KEY="$(jq -r --arg track "$TRACK" '.[$track][0]' "$TRACK_STEPS")"
TOTAL="$(jq --arg track "$TRACK" '.[$track] | length' "$TRACK_STEPS")"

jq -n \
  --arg workflow_id "$WORKFLOW_ID" \
  --arg track "$TRACK" \
  --arg first "$FIRST_KEY" \
  --arg now "$NOW" \
  --arg task_desc "$TASK_DESC" \
  --argjson steps "$STEPS_JSON" \
  '{
    control: {
      workflow_id: $workflow_id,
      track: $track,
      status: "running",
      current_step: $first,
      interrupted: false,
      interrupt_reason: "",
      steps: $steps,
      created_at: $now,
      updated_at: $now,
      error: null
    },
    data: {
      task_description: $task_desc,
      project_name: "",
      worktree_path: "",
      ticket_id: "",
      branch_name: "",
      pr_number: null,
      pr_url: "",
      ci_attempt: 0,
      ci_conclusions: [],
      review_verdict: "",
      speckit_feature_dir: "",
      debate_for_plan_count: 0,
      verdict_feedback: "",
      debate_test_count: 0,
      brainstorm_debate_count: 0,
      self_review_iteration: 0,
      self_review_findings: [],
      self_review_comments: [],
      review_iteration: 0,
      review_comments: []
    }
  }' > "$STATE"

# ── Emit first step ──
FIRST_FILENAME="$(jq -r --arg key "$FIRST_KEY" '.[$key]' "$REGISTRY")"
FIRST_FILEPATH="$SKILL_DIR/$FIRST_FILENAME"

echo ""
echo "[1/$TOTAL] $FIRST_KEY"
printf '━%.0s' $(seq 1 41); echo
echo "Follow the instructions below exactly."
printf '━%.0s' $(seq 1 41); echo
echo ""
cat "$FIRST_FILEPATH"
