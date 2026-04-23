#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────
# observe-ci.sh — deterministic CI status observer
#
# Drives itself from [repos.<project>].ci_checks in
# wf_config.toml (populated by CI_SETUP).
# Queries both GitHub check-runs AND commit statuses so external CI
# (Jenkins, CircleCI, etc.) are covered.
#
# Usage: bash observe-ci.sh <PR_NUMBER>
# ─────────────────────────────────────────────────────────

PR="${1:?Usage: observe-ci.sh <PR_NUMBER>}"

WF_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STATE=".workflow/state.json"
if [ ! -f "$STATE" ]; then
  echo '{"status":"error","next_action":"ALERT_USER","remediation":"Missing .workflow/state.json"}'
  exit 0
fi

PROJECT="$(jq -r '.data.project_name // ""' "$STATE")"
CONFIG_PY="$WF_ROOT/lib/config.py"

CI_CHECKS_JSON="$(python3 "$CONFIG_PY" "repos.$PROJECT.ci_checks" --json 2>/dev/null || echo '[]')"

# ── Sentinel: no CI expected ──
if echo "$CI_CHECKS_JSON" | jq -e '. == ["__none__"]' >/dev/null 2>&1; then
  cat <<'EOF'
{
  "platform": "none",
  "status": "skipped",
  "passed": 0, "failed": 0, "pending": 0,
  "missing_reason": "ci_checks=__none__",
  "failed_jobs": [],
  "next_action": "DONE",
  "remediation": null
}
EOF
  exit 0
fi

# ── Sentinel: not discovered yet ──
if echo "$CI_CHECKS_JSON" | jq -e '. == [] or . == null' >/dev/null 2>&1; then
  cat <<'EOF'
{
  "platform": "unknown",
  "status": "error",
  "passed": 0, "failed": 0, "pending": 0,
  "missing_reason": "ci_checks_not_discovered",
  "failed_jobs": [],
  "next_action": "ALERT_USER",
  "remediation": "ci_checks is empty — run bash ${CLAUDE_PLUGIN_ROOT}/skills/wf/lib/discover-ci.sh (CI_SETUP step) before polling."
}
EOF
  exit 0
fi

# ── Gather PR state ──
REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)"
if [ -z "$REPO" ]; then
  echo '{"status":"error","next_action":"ALERT_USER","remediation":"Failed to detect repo via gh."}'
  exit 0
fi

PR_STATE="$(gh pr view "$PR" --json isDraft,mergeable,mergeStateStatus,headRefOid 2>/dev/null || true)"
if [ -z "$PR_STATE" ]; then
  echo '{"status":"error","next_action":"ALERT_USER","remediation":"Failed to fetch PR state."}'
  exit 0
fi

IS_DRAFT="$(echo "$PR_STATE" | jq -r '.isDraft')"
MERGEABLE="$(echo "$PR_STATE" | jq -r '.mergeable')"
MERGE_STATUS="$(echo "$PR_STATE" | jq -r '.mergeStateStatus')"
SHA="$(echo "$PR_STATE" | jq -r '.headRefOid')"

# ── Fetch both check-runs and commit statuses ──
# Use PR's statusCheckRollup which natively merges both sources.
ROLLUP="$(gh pr view "$PR" --json statusCheckRollup 2>/dev/null \
  | jq '.statusCheckRollup')"
if [ -z "$ROLLUP" ] || [ "$ROLLUP" = "null" ]; then
  ROLLUP='[]'
fi

# Normalize each entry to {name, state, url}.
#   CheckRun  → name,  status, conclusion, detailsUrl
#   StatusCtx → context, state, targetUrl
ENTRIES="$(echo "$ROLLUP" | jq '
  [ .[] | (
    if .__typename == "CheckRun" then
      {
        name: .name,
        state: (
          if .status != "COMPLETED" then "pending"
          elif (.conclusion | ascii_downcase) == "success" then "passed"
          elif (.conclusion | ascii_downcase) == "neutral" or (.conclusion | ascii_downcase) == "skipped" then "skipped"
          else "failed"
          end
        ),
        url: .detailsUrl
      }
    else
      {
        name: (.context // .name // ""),
        state: (
          if (.state // "") == "" then "pending"
          elif (.state | ascii_downcase) == "success" then "passed"
          elif (.state | ascii_downcase) == "pending" then "pending"
          else "failed"
          end
        ),
        url: (.targetUrl // .detailsUrl // "")
      }
    end
  ) ]
')"

# ── Match against ci_checks ──
# Each expected check is matched by exact name. If missing from rollup → missing.
REPORT="$(echo "$ENTRIES" | jq --argjson expected "$CI_CHECKS_JSON" '
  . as $entries
  | reduce $expected[] as $name (
      {passed: [], failed: [], pending: [], missing: [], skipped: []};
      . as $acc |
      ($entries | map(select(.name == $name))) as $matches |
      if ($matches | length) == 0 then
        $acc | .missing += [{name: $name}]
      else
        ($matches[0]) as $m |
        if $m.state == "passed" then $acc | .passed += [$m]
        elif $m.state == "failed" then $acc | .failed += [$m]
        elif $m.state == "pending" then $acc | .pending += [$m]
        else $acc | .skipped += [$m]
        end
      end
    )
')"

PASSED="$(echo "$REPORT" | jq '.passed | length')"
FAILED_COUNT="$(echo "$REPORT" | jq '.failed | length')"
PENDING="$(echo "$REPORT" | jq '.pending | length')"
MISSING="$(echo "$REPORT" | jq '.missing | length')"
SKIPPED="$(echo "$REPORT" | jq '.skipped | length')"
TOTAL="$(echo "$CI_CHECKS_JSON" | jq 'length')"

FAILED_JOBS="$(echo "$REPORT" | jq '.failed + .missing')"

# ── Determine status + next_action ──
if [ "$IS_DRAFT" = "true" ] && [ $((PASSED+FAILED_COUNT+PENDING+SKIPPED)) -eq 0 ]; then
  STATUS="missing"
  ACTION="ALERT_USER"
  REMEDIATION="PR is in draft — CI won't run until marked ready for review."
elif [ "$MISSING" -gt 0 ] && [ "$PENDING" -eq 0 ] && [ "$FAILED_COUNT" -eq 0 ]; then
  # Expected checks didn't report yet.
  STATUS="missing"
  ACTION="WAIT"
  REMEDIATION="$MISSING expected check(s) haven't registered yet. Wait and re-poll."
elif [ "$PENDING" -gt 0 ] || [ "$MISSING" -gt 0 ]; then
  STATUS="pending"
  ACTION="WAIT"
  REMEDIATION="$PENDING running, $MISSING missing. Wait and re-poll."
elif [ "$FAILED_COUNT" -gt 0 ]; then
  STATUS="some_failed"
  ACTION="FETCH_LOGS_AND_FIX"
  REMEDIATION="$FAILED_COUNT check(s) failed. Inspect via: gh pr checks $PR"
else
  STATUS="all_passed"
  ACTION="DONE"
  REMEDIATION="null"
fi

if [ "$MERGEABLE" = "CONFLICTING" ] && [ "$ACTION" != "FETCH_LOGS_AND_FIX" ]; then
  ACTION="ALERT_USER"
  REMEDIATION="PR has merge conflicts. Run: git fetch origin && git rebase origin/main"
fi

# ── Emit ──
cat <<EOF
{
  "platform": "ci_checks",
  "status": "$STATUS",
  "passed": $PASSED,
  "failed": $FAILED_COUNT,
  "pending": $PENDING,
  "missing": $MISSING,
  "skipped": $SKIPPED,
  "total": $TOTAL,
  "expected": $CI_CHECKS_JSON,
  "is_draft": $IS_DRAFT,
  "mergeable": "$MERGEABLE",
  "merge_state": "$MERGE_STATUS",
  "failed_jobs": $FAILED_JOBS,
  "next_action": "$ACTION",
  "remediation": $([ "$REMEDIATION" = "null" ] && echo "null" || echo "\"$REMEDIATION\"")
}
EOF
