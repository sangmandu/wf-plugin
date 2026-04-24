# Step 092: COMPLETE_MERGE


## Purpose

Merge the PR, update Linear, and mark the workflow as finished. This step sets `status = "completed"`.

## Pre-authorization

**This step is pre-authorized by the user's `/wf` invocation.** Execute `gh pr merge` and the Linear state change **without asking for confirmation**. Earlier steps (CI pass, review APPROVED) are the gate; by the time this step runs the user has already opted into the automated merge. Do not re-prompt — just run the commands.

## Merge Rules

After running `gh pr merge`, check the result. Only two outcomes allow proceeding to COMPLETE_REPORT:

| Outcome | Action |
|---------|--------|
| **Merged successfully** | Update Linear → Done. Proceed. |
| **Merge conflict** (`mergeable == "CONFLICTING"` / `mergeStateStatus == "DIRTY"`) | Do NOT proceed. Rewind to rebase loop: `bash <WF_DIR>/lib/rewind-step.sh CI_WAIT_REBASE CI_WAIT_REBASE CI_WAIT_POLL CI_WAIT_EVALUATE REVIEW_CHECK_VERDICT REVIEW_FETCH_COMMENTS REVIEW_REPLY REVIEW_APPLY_FIXES REVIEW_EXIT_APPROVED COMPLETE_MERGE` |
| **Branch protection blocks merge** (e.g. "requires peer approval", `mergeable == "MERGEABLE"` / `mergeStateStatus == "BLOCKED"`) and there are **no CHANGES_REQUESTED reviews** | Update Linear → Done. Proceed — peer will merge manually. |
| **CHANGES_REQUESTED review exists** | Do NOT proceed. Rewind to review loop: `bash <WF_DIR>/lib/rewind-step.sh REVIEW_CHECK_VERDICT REVIEW_CHECK_VERDICT REVIEW_FETCH_COMMENTS REVIEW_REPLY REVIEW_APPLY_FIXES REVIEW_EXIT_APPROVED` |
| **Any other failure** | Report the error to the user. Do not assume merged. |

The key distinction: "needs peer approval" (no one reviewed yet) is OK to proceed — the peer will approve and merge. "Changes requested" (someone reviewed and rejected) means the code needs fixes — must loop back.

### ⚠️ Never interpret `gh pr merge` error text

`gh pr merge` emits the generic string `"the base branch policy prohibits the merge"` for BOTH branch-protection-blocked PRs AND merge-conflicted PRs. Do NOT try to distinguish these cases from the error text alone. The only reliable signal is the `mergeable` / `mergeStateStatus` fields from `gh pr view`. Always query them before deciding which row of the table applies — even if the last check was minutes ago, because `master` may have advanced while you were polling CI or fetching reviews.

**NEVER use `--auto` flag.** Do not set auto-merge. If the PR can't be merged due to branch protection, just proceed to REPORT and let a human merge it.

## Checklist

- [ ] Merge the PR: `gh pr merge <pr-number> --squash`
- [ ] **If merge did NOT succeed**, always query mergeability first — do not branch on the error string:
  ```bash
  gh pr view <pr-number> --json mergeable,mergeStateStatus --jq '{mergeable, mergeStateStatus}'
  ```
- [ ] If `mergeable == "CONFLICTING"` (or `mergeStateStatus == "DIRTY"`) → **conflict, not branch protection**. Rewind to `CI_WAIT_REBASE` (see table above). Do NOT proceed to REPORT.
- [ ] If `mergeable == "MERGEABLE"` and the push was blocked, check for CHANGES_REQUESTED:
  ```bash
  REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
  gh api repos/$REPO/pulls/<pr-number>/reviews \
    --jq '[.[] | select(.state == "CHANGES_REQUESTED")] | length'
  ```
- [ ] If CHANGES_REQUESTED count > 0 → rewind to review loop (see table above)
- [ ] If 0 → proceed (peer will approve and merge manually)
- [ ] **Verify merge succeeded** (if merge command ran): `bash <WF_DIR>/scripts/check-merge-status.sh <pr-number>`
- [ ] Update Linear ticket to Done: `mcp__linear__save_issue` with state = "Done"

Per `helpers#state_transition` — complete `COMPLETE_MERGE`
