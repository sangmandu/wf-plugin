#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────
# wait-for-ci.sh — deterministic CI polling loop
#
# Wraps observe-ci.sh in a sleep-and-retry loop so the LLM
# never needs to manage the loop itself. Returns only when
# CI reaches a terminal state (DONE, FETCH_LOGS_AND_FIX,
# ALERT_USER) or the timeout expires.
#
# Usage: bash wait-for-ci.sh <PR_NUMBER> [MAX_MINUTES]
#
# Defaults: poll every 30s, timeout after 15 minutes.
# Output: the final observe-ci.sh JSON (terminal state).
# ─────────────────────────────────────────────────────────

PR="${1:?Usage: wait-for-ci.sh <PR_NUMBER> [MAX_MINUTES]}"
MAX_MINUTES="${2:-15}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OBSERVER="$SCRIPT_DIR/observe-ci.sh"

POLL_INTERVAL=30
MAX_SECONDS=$((MAX_MINUTES * 60))
ELAPSED=0

while true; do
  RESULT="$(bash "$OBSERVER" "$PR")"
  ACTION="$(echo "$RESULT" | jq -r '.next_action // "ALERT_USER"')"

  case "$ACTION" in
    DONE|FETCH_LOGS_AND_FIX|ALERT_USER)
      echo "$RESULT"
      exit 0
      ;;
    WAIT)
      if [ "$ELAPSED" -ge "$MAX_SECONDS" ]; then
        cat <<EOF
{
  "platform": "ci_checks",
  "status": "timeout",
  "next_action": "ALERT_USER",
  "remediation": "CI polling timed out after ${MAX_MINUTES} minutes. Last status: $(echo "$RESULT" | jq -r '.status'). Check manually: gh pr checks ${PR}",
  "last_result": $RESULT
}
EOF
        exit 0
      fi
      >&2 echo "[wait-for-ci] ${ELAPSED}s/${MAX_SECONDS}s — CI pending, sleeping ${POLL_INTERVAL}s..."
      sleep "$POLL_INTERVAL"
      ELAPSED=$((ELAPSED + POLL_INTERVAL))
      ;;
    *)
      echo "$RESULT"
      exit 0
      ;;
  esac
done
