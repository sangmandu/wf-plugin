# Step 084: REVIEW_EXIT_APPROVED

## Purpose

Confirm APPROVED status and proceed.

## Checklist

- [ ] Verify one final time:
  ```bash
  REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
  gh api repos/$REPO/pulls/<pr-number>/reviews \
    --jq '[.[] | select(.user.login == "claude[bot]")] | last | {state}'
  ```
- [ ] `state == "APPROVED"` confirmed → run `bash ${CLAUDE_PLUGIN_ROOT}/skills/wf/lib/complete-step.sh REVIEW_EXIT_APPROVED`
- [ ] Save `review_verdict: "APPROVED"` in state.json
- [ ] NEVER proceed while CHANGES_REQUESTED remains. If max iterations reached, ask user.

Per `helpers#state_transition` — save `review_comments`, `review_iteration`, `review_verdict`
Per `helpers#state_transition` — complete `REVIEW_EXIT_APPROVED`
