#!/usr/bin/env bash
# Install wf hooks into the current cwd's .claude/settings.json.
# Idempotent: safe to call multiple times; skips if marker already present.
#
# Usage: bash ${CLAUDE_PLUGIN_ROOT}/skills/wf/install-hooks.sh [worktree_path]
#   worktree_path defaults to $PWD
#
# The skill owns its own hook definitions; no external template file.
set -euo pipefail

ROOT="${1:-$PWD}"
SETTINGS="$ROOT/.claude/settings.json"

# Marker for idempotency and future removal. Kept in command string itself
# since Claude settings schema doesn't allow arbitrary metadata fields.
INTERRUPT_CMD="bash ${CLAUDE_PLUGIN_ROOT}/skills/wf/user-interrupt.sh"
STOP_CMD="bash ${CLAUDE_PLUGIN_ROOT}/skills/wf/stop-guard.sh"

if [ ! -f "$SETTINGS" ]; then
  echo "error: $SETTINGS not found — cannot install wf hooks." >&2
  echo "       Creating it mid-session would not register hooks for the" >&2
  echo "       current Claude session (file watcher only tracks files that" >&2
  echo "       existed at session start)." >&2
  echo "hint:  create .claude/settings.json in the main repo, commit it," >&2
  echo "       then restart this session (exit and 'cc' again)." >&2
  exit 1
fi

tmp="$(mktemp "${SETTINGS}.tmp.XXXXXX")"
jq \
  --arg interrupt "$INTERRUPT_CMD" \
  --arg stop "$STOP_CMD" \
  '
  def ensure_event($event; $cmd; $timeout):
    .hooks //= {}
    | .hooks[$event] //= []
    | if any(.hooks[$event][]?.hooks[]?; (.command // "") == $cmd) then
        .  # already installed
      else
        .hooks[$event] += [{
          "hooks": [{
            "type": "command",
            "command": $cmd,
            "timeout": $timeout
          }]
        }]
      end;

  ensure_event("UserPromptSubmit"; $interrupt; 3)
  | ensure_event("Stop"; $stop; 5)
  ' "$SETTINGS" > "$tmp"

mv "$tmp" "$SETTINGS"

echo "wf hooks installed into $SETTINGS"
