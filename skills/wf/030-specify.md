# Step 030: SPECIFY

## Purpose

Produce a feature specification from the task description using speckit.

## Checklist

- [ ] Run `/speckit.specify <task_description from state.json>`
  - **IMPORTANT**: `/wf` has already created the worktree + branch. Do NOT run speckit's `create-new-feature.sh`. Write the spec files directly on the existing branch — if speckit creates its own branch, it will diverge from the PR branch.
- [ ] Wait for speckit (it may ask clarification questions).

Per `helpers#state_transition` — save `feature_dir` + top-level `speckit_feature_dir`
Per `helpers#state_transition` — complete `SPECIFY`
