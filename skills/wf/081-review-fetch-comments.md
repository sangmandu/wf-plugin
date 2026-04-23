# Step 081: REVIEW_FETCH_COMMENTS


## Purpose

Fetch ALL review data using the deterministic observer script. The script handles snapshot diffing, detects MODIFIED comments, and identifies bots automatically.

## Checklist

- [ ] Run the review observer:
  ```bash
  bash <WF_DIR>/scripts/observe-reviews.sh <pr-number>
  ```

- [ ] Read the markdown report output. Pay special attention to:
  - **⚠️ MODIFIED comments** — these were EDITED since last observation. Re-read the full body even if you think you've already addressed them.
  - **New inline comments** — code-level feedback on specific files/lines.
  - **New issue comments** — especially from `[BOT]` users (review bot verdicts).
  - **Latest verdict** — `APPROVED` or `CHANGES_REQUESTED`.

- [ ] If "No changes since last observation" and this is NOT the first run → check if `review_iteration` in state.json has been incremented. If the reviewer may have edited existing comments without creating new ones, re-run the script (it compares `updated_at` timestamps).

## Classify each comment

- [ ] **MUST FIX** — bug, security, logic error, test gap
- [ ] **SHOULD FIX** — code quality, naming, style → fix if straightforward
- [ ] **SKIP** — nitpick, preference, disagree → skip with reason
- [ ] Record in state.json `review_comments[]`

## Impact check (before applying any FIX)

For each FIX item, verify the proposed change won't break other call sites:

- [ ] **Find all callers**: grep for every place the affected function/code path is invoked
- [ ] **Check each caller's context**: the same function may be called with different expectations (e.g. strict vs lenient mode, build-time vs runtime, CI vs local)
- [ ] **If the fix changes error handling or control flow** (e.g. warn→error, skip→exit, return→throw): confirm the new behavior is correct for ALL callers, not just the one the reviewer pointed at
- [ ] If any caller would break → adjust the fix to be context-aware (e.g. respect a flag, check the caller's mode) or SKIP with justification

Per `helpers#state_transition` — complete `REVIEW_FETCH_COMMENTS`
