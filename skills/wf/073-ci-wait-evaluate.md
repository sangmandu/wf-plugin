# Step 072: CI_WAIT_EVALUATE


## Purpose

Evaluate CI results and handle failures.

## Checklist

- [ ] **All 3 checks passed** → run `bash <WF_DIR>/lib/complete-step.sh CI_WAIT_EVALUATE`
- [ ] **CI failed** (build/test/lint/typecheck — NOT the review check):
  - [ ] Show failure details: `gh run view <run-id> --log-failed`
  - [ ] Analyze root cause
  - [ ] Fix implementation
  - [ ] Re-run validation per the project's CLAUDE.md. If no specific commands found, run standard lint/test/build/typecheck commands appropriate for the project's tooling.
  - [ ] Stage + commit + push (follow `helpers#git_rules`)
  - [ ] Increment `ci_attempt` in state.json (max 3 before asking user)
  - [ ] Append to `ci_conclusions[]` in state.json
  - [ ] `bash <WF_DIR>/lib/rewind-step.sh CI_WAIT_REBASE CI_WAIT_REBASE CI_WAIT_POLL CI_WAIT_EVALUATE`

## IMPORTANT

- This step does NOT evaluate review verdicts
- Review verdict evaluation happens in the next step
- Do NOT ask about merge from this step — always proceed to the next step

Per `helpers#state_transition` — append to `ci_conclusions[]`
Per `helpers#state_transition` — complete `CI_WAIT_EVALUATE`
