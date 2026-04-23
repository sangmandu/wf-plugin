# Step 080: REVIEW_CHECK_VERDICT


## Purpose

Check the latest review verdict to determine if we need to address comments.

## CRITICAL: Wait for the review workflow to finish first

The GitHub reviews API (`/pulls/N/reviews`) only returns reviews that have been
**submitted**. If the review bot's workflow is still running, the response is
empty and a naive "no reviews == approved" read sends the workflow into
`REVIEW_EXIT_APPROVED` while real feedback is still landing. Always gate on
the review workflow's run status first.

## Checklist

- [ ] **Block until the review workflow finishes.** Use the same branch as the PR:

  ```bash
  BR=$(gh pr view <pr-number> --json headRefName -q .headRefName)
  REVIEW_WF="${WF_REVIEW_WORKFLOW:-Claude Auto PR Code Review}"
  until STATUS=$(gh run list --branch "$BR" --workflow "$REVIEW_WF" \
        --limit 1 --json status -q '.[0].status') && \
        [ -n "$STATUS" ] && [ "$STATUS" != "in_progress" ] && [ "$STATUS" != "queued" ]; do
    sleep 30
  done
  ```

  - If `gh run list` returns empty (no run for this workflow), treat it as
    "no review configured" and proceed — the subsequent reviews check will
    correctly observe 0 reviews.
  - Override workflow name with `WF_REVIEW_WORKFLOW` env var when projects
    name their review workflow differently.

- [ ] Check the latest review verdict **only after the workflow is no longer running**:

  ```bash
  REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
  gh api repos/$REPO/pulls/<pr-number>/reviews \
    --jq '[.[] | select(.user.login == "claude[bot]")] | last | {id, state, body, submitted_at}'
  ```

- [ ] Record `review_verdict` (`"APPROVED"` or `"CHANGES_REQUESTED"`) in state.json for downstream steps.

- [ ] Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/wf/lib/complete-step.sh REVIEW_CHECK_VERDICT`. The next steps (FETCH/REPLY/APPLY) are no-ops on APPROVED and naturally flow to `REVIEW_EXIT_APPROVED`.
