# Step 051: DO_GREEN_TEST


## Purpose

Run all tests after implementation. Tests should now PASS (GREEN).

## Checklist

- [ ] Read `unit_test_files` and `e2e_test_files` from state.json
- [ ] Run the project's validation commands per the project's CLAUDE.md. If no specific commands are found, run standard lint/test/build/typecheck commands appropriate for the project's tooling.
- [ ] If tests fail:
  - [ ] Analyze failure — is it implementation bug or test issue?
  - [ ] Fix implementation (preferred) or adjust test if test was wrong
  - [ ] Re-run (max 3 retries before asking user)
- [ ] All tests pass → record final score
- [ ] Compare with `red_baseline` from DO_RED_TEST — every previously failing test should now pass

**Every E2E test must actually execute and score pass/fail.** Skipped does not count as verified — open any env/credential gates and re-run. If the environment is unreachable, this step cannot be completed. Resolve the blocker before proceeding.
- [ ] **If UI-related E2E tests exist**, run visual verification:
  - [ ] Run E2E tests per the project's CLAUDE.md (starts preview server automatically)
  - [ ] For each screenshot in `test-results/screenshots/`:
    - Read the image file using the `Read` tool (Claude can see images)
    - Read the `// VISUAL CHECK:` comment from the test source to know what to verify
    - Judge whether the screenshot matches the expected behavior
    - If something looks wrong: fix the implementation and re-run
  - [ ] Record visual check results in state.json under `visual_checks`

Per `helpers#state_transition` — save `final_score`
Per `helpers#state_transition` — complete `DO_GREEN_TEST`
