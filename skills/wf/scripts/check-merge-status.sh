#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────
# check-merge-status.sh — Verify PR merge state
#
# Usage:
#   bash ${CLAUDE_PLUGIN_ROOT}/skills/wf/scripts/check-merge-status.sh <pr-number>
#
# Outputs JSON with state and mergedAt fields.
# Exit 0 = merged, Exit 1 = not merged or error.
# ─────────────────────────────────────────────────────────

PR="${1:?Usage: check-merge-status.sh <pr-number>}"

RESULT="$(gh pr view "$PR" --json state,mergedAt,url 2>&1)" || {
  echo "{\"error\": \"Failed to query PR $PR\"}" >&2
  exit 1
}

STATE="$(echo "$RESULT" | jq -r '.state')"
MERGED_AT="$(echo "$RESULT" | jq -r '.mergedAt // ""')"
URL="$(echo "$RESULT" | jq -r '.url')"

echo "$RESULT" | jq '.'

if [ "$STATE" = "MERGED" ] && [ -n "$MERGED_AT" ] && [ "$MERGED_AT" != "null" ]; then
  echo "✓ PR $PR is MERGED (at $MERGED_AT)"
  exit 0
else
  echo "✗ PR $PR is NOT merged (state: $STATE)"
  exit 1
fi
