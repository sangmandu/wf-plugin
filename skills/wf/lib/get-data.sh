#!/usr/bin/env bash
# Usage: bash ${CLAUDE_PLUGIN_ROOT}/skills/wf/lib/get-data.sh <key>
#
# Reads `data.<key>` from .workflow/state.json.
# - Strings/numbers/booleans are printed as raw values (no JSON quoting).
# - Arrays/objects are printed as compact JSON.
# - Missing key: exits 1 with empty stdout.
set -euo pipefail

KEY="${1:?Usage: get-data.sh <key>}"

STATE=".workflow/state.json"
if [[ ! -f "$STATE" ]]; then
  echo "ERROR: $STATE not found. Are you in the worktree?" >&2
  exit 1
fi

OUTPUT=$(jq -r --arg k "$KEY" '
  if (.data | type) == "object" and (.data | has($k)) then
    .data[$k]
    | if type == "string" then .
      elif type == "number" or type == "boolean" then tostring
      elif type == "null" then "null"
      else tojson
      end
  else empty end
' "$STATE")

if [[ -z "$OUTPUT" ]]; then
  # Key missing (or explicitly absent). Caller can distinguish null vs missing by
  # checking exit code + stdout ("null" vs empty).
  exit 1
fi

printf '%s\n' "$OUTPUT"
