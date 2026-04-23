#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────
# wf User Interrupt Detector (cwd-scoped)
#
# Registered as a UserPromptSubmit hook in the worktree's
# .claude/settings.json (installed by lib/install-hooks.sh).
#
# On every user prompt while a workflow is running:
#   1. Set control.interrupted=true (if not already)
#   2. Inject a neutral reminder — "keep pinging the user as
#      needed; when the topic is resolved and you are
#      returning to the main task, you must run run.sh resume"
# ─────────────────────────────────────────────────────────

WF_ROOT="$(cd "$(dirname "$0")" && pwd)"
INPUT="$(cat)"
CWD="$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)"
[ -z "$CWD" ] && CWD="$(pwd)"

STATE="$CWD/.workflow/state.json"
[ -f "$STATE" ] || exit 0

STATUS="$(jq -r '.control.status // ""' "$STATE" 2>/dev/null)" || exit 0
[ "$STATUS" = "running" ] || exit 0

CURRENT="$(jq -r '.control.current_step // ""' "$STATE" 2>/dev/null)" || exit 0
[ -z "$CURRENT" ] && exit 0

# Ensure interrupt flag is on (idempotent)
TMP="${STATE}.tmp.$$"
jq '.control.interrupted = true' "$STATE" > "$TMP" && mv "$TMP" "$STATE"

jq -n --arg step "$CURRENT" --arg wf_root "$WF_ROOT" '{
  hookSpecificOutput: {
    hookEventName: "UserPromptSubmit",
    additionalContext: "[wf] Workflow is paused at step \($step). If the user still needs a back-and-forth, keep the conversation going — the stop hook will allow it. Once the topic is resolved and you are returning to the main workflow task, you MUST run `bash \($wf_root)/run.sh resume` to reopen the workflow loop."
  }
}'
