#!/usr/bin/env bash
# Usage: bash ${CLAUDE_PLUGIN_ROOT}/skills/wf/lib/set-data.sh <key> <value> [--append]
#
# Writes to .workflow/state.json under `data.<key>`. Only `data.*` is allowed;
# `control.*` keys are reserved for the state machine and cannot be set here.
#
# <value> is parsed as JSON when possible (numbers, booleans, arrays, objects,
# null), otherwise treated as a raw string.
#
# With --append: treat the existing value as an array and push <value> to it
# (creating the array if the key is absent).
#
# Automatically touches control.updated_at.
set -euo pipefail

KEY="${1:?Usage: set-data.sh <key> <value> [--append]}"
VALUE="${2?Usage: set-data.sh <key> <value> [--append]}"
FLAG="${3:-}"

STATE=".workflow/state.json"
if [[ ! -f "$STATE" ]]; then
  echo "ERROR: $STATE not found. Are you in the worktree?" >&2
  exit 1
fi

# Reject reserved control.* keys
case "$KEY" in
  control|control.*|.control*|status|current_step|steps|track|workflow_id|\
  interrupted|interrupt_reason|created_at|updated_at|error)
    echo "ERROR: '$KEY' is reserved for control.*; set-data.sh writes only to data.*" >&2
    exit 1
    ;;
esac

# Parse value as JSON; fallback to string
if echo "$VALUE" | jq -e . >/dev/null 2>&1; then
  VALUE_JSON="$VALUE"
else
  VALUE_JSON=$(jq -n --arg v "$VALUE" '$v')
fi

NOW=$(python3 -c "from datetime import datetime; print(datetime.now().isoformat())")

TMP="${STATE}.tmp.$$"
if [[ "$FLAG" == "--append" ]]; then
  jq --arg k "$KEY" --argjson v "$VALUE_JSON" --arg now "$NOW" '
    .data[$k] = ((.data[$k] // []) + [$v])
    | .control.updated_at = $now
  ' "$STATE" > "$TMP"
elif [[ -z "$FLAG" ]]; then
  jq --arg k "$KEY" --argjson v "$VALUE_JSON" --arg now "$NOW" '
    .data[$k] = $v
    | .control.updated_at = $now
  ' "$STATE" > "$TMP"
else
  echo "ERROR: unknown flag '$FLAG'. Only --append is supported." >&2
  exit 1
fi

mv "$TMP" "$STATE"
