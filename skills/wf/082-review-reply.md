# Step 082: REVIEW_REPLY


## Purpose

Reply to ALL review comments BEFORE any code changes or commits.

## CRITICAL: Order matters

Reply first → commit/push after. Push triggers the review bot's re-review. If you push without replies, the bot won't see your SKIP justifications.

## Checklist

- [ ] For **FIX** comments: reply with what will be changed
- [ ] For **SKIP** comments: reply with technical justification and evidence
- [ ] Post replies:
  ```bash
  REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
  gh api repos/$REPO/pulls/<pr-number>/comments/<comment-id>/replies \
    -f body="<reason>"
  ```
- [ ] **Verify all replies are posted** before proceeding

Per `helpers#state_transition` — complete `REVIEW_REPLY`
