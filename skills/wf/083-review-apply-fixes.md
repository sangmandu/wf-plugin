# Step 083: REVIEW_APPLY_FIXES


## Purpose

Apply code fixes after all replies are posted, then trigger re-review.

## Checklist — code changes needed

- [ ] Increment `review_iteration` in state.json (max 3 before asking user)
- [ ] Scope changes to ONLY items with `action: "fix"` in `review_comments`
- [ ] `bash ${CLAUDE_PLUGIN_ROOT}/skills/wf/lib/rewind-step.sh IMPLEMENT IMPLEMENT DO_GREEN_TEST COMMIT PR CI_WAIT_REBASE CI_WAIT_POLL CI_WAIT_EVALUATE`
  - Do NOT reset SELF_REVIEW or SELF_REVIEW_VERDICT — PR review feedback is already a higher-fidelity review, so self-review is redundant on review fix iterations

## Checklist — no code changes needed (all SKIP)

- [ ] Push empty commit to trigger re-review:
  ```bash
  git commit --allow-empty -m "chore: trigger re-review after comment replies"
  git push
  ```
- [ ] Or re-run the review workflow:
  ```bash
  gh run list --workflow=review --branch=<branch> --limit=1 --json databaseId --jq '.[0].databaseId'
  gh run rerun <run-id>
  ```
- [ ] `bash ${CLAUDE_PLUGIN_ROOT}/skills/wf/lib/rewind-step.sh CI_WAIT_REBASE CI_WAIT_REBASE CI_WAIT_POLL CI_WAIT_EVALUATE`

Per `helpers#state_transition` — complete `REVIEW_APPLY_FIXES`
