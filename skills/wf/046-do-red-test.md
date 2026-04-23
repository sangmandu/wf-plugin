# Step 046: DO_RED_TEST


## Purpose

Run all tests created in MAKE_UNIT_TEST and MAKE_E2E_TEST **before implementation**. Every test MUST fail (RED). If any test passes, the test is flawed — it doesn't actually verify the new behavior.

## Checklist

- [ ] Read `unit_test_files` and `e2e_test_files` from state.json
- [ ] Run all tests
- [ ] **Verify ALL tests fail (RED)**:
  - Every test must produce a FAIL result
  - Skipped does not count — open any env/credential gates and re-run
  - If any test PASSES → the test is wrong. Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/wf/lib/rewind-step.sh DEBATE_TEST DEBATE_TEST DO_RED_TEST` to go back and fix the tests.
- [ ] Record `red_baseline` in state.json (test names + failure reasons)

Per `helpers#state_transition` — save `red_baseline`
Per `helpers#state_transition` — complete `DO_RED_TEST`
