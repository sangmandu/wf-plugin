# Step 044: DEBATE_TEST

Per `helpers#debate_protocol` — triangular debate (PRO / NEUTRAL / CON).

## Launch 3 agents in parallel

- [ ] **PRO Agent**:

  ```
  You are PRO in a triangular debate on these tests.
  Read the test files created in the MAKE_UNIT_TEST and MAKE_E2E_TEST steps.
  Defend them: verify tests capture planned behavior, coverage is sufficient,
  and patterns follow project conventions (Vitest, testing-library).
  Cite specifics.
  ```

- [ ] **NEUTRAL Agent**:

  ```
  You are NEUTRAL in a triangular debate on these tests.
  Read the test files created in the MAKE_UNIT_TEST and MAKE_E2E_TEST steps.
  Analyze objectively:
  1. Are the right things being tested? (behavior vs implementation details)
  2. Is coverage balanced — too many happy-path tests, too few edge cases?
  3. How do these tests compare to testing best practices for this domain?
  Present trade-offs clearly.
  ```

- [ ] **CON Agent**:
  ```
  You are CON in a triangular debate on these tests.
  Read the test files created in the MAKE_UNIT_TEST and MAKE_E2E_TEST steps.
  Attack aggressively:
  1. Tests too coupled to implementation details?
  2. Missing edge cases or untested scenarios?
  3. Any mocks present? Mocks are FORBIDDEN — flag every mock as a defect.
  4. Is the root cause a test problem or a PLAN problem?
  Back every criticism with evidence.
  ```

## Decision

- [ ] Review all 3 positions. Incorporate valid feedback into test files directly.
- [ ] Increment `debate_test_count`:
  ```bash
  CURRENT=$(bash <WF_DIR>/lib/get-data.sh debate_test_count 2>/dev/null || echo 0)
  bash <WF_DIR>/lib/set-data.sh debate_test_count "$((CURRENT + 1))"
  ```
- [ ] Always PASS and proceed to next step

Per `helpers#state_transition` — complete `DEBATE_TEST`
