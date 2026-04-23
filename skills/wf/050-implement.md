# Step 050: IMPLEMENT


## Entry Guard: Fix Mode

- [ ] Check `self_review_iteration` and `review_iteration` in state.json
- [ ] If `self_review_iteration > 0`:
  - [ ] Read `self_review_comments` from state.json
  - [ ] Scope changes to ONLY items with `action: "fix"`
  - [ ] Do NOT re-run `/speckit.implement` or re-implement the full feature
  - [ ] For each fix item: read the comment, locate the code, apply the minimal change
  - [ ] Skip to step completion after all fix items are addressed
- [ ] If `review_iteration > 0`:
  - [ ] Read `review_comments` from state.json
  - [ ] Scope changes to ONLY items with `action: "fix"`
  - [ ] Do NOT re-run `/speckit.implement` or re-implement the full feature
  - [ ] For each fix item: read the comment, locate the code, apply the minimal change
  - [ ] Skip to step completion after all fix items are addressed

## Checklist (first-pass only — when both `self_review_iteration == 0` and `review_iteration == 0`)

- [ ] `/speckit.implement`
- [ ] Already-completed `[x]` tasks skipped (resume-safe)

Per `helpers#state_transition` — save `tasks_total`, `tasks_done`
Per `helpers#state_transition` — complete `IMPLEMENT`
