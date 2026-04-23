# Step 040: MAKE_UNIT_TEST


## Purpose

Create a point reproduction test BEFORE implementation (TDD). This test SHOULD fail at this point — that's expected.

## Prerequisites

Before writing any test, follow this lookup chain in order:
1. Invoke the project's testing skill (`python-testing`, etc.) and read the project's CLAUDE.md testing section
2. Check memory files (`~/.claude/projects/*/memory/`) for e2e setup info, env vars, credentials
3. Check e2e-related skills (`e2e-test`, `mally-local-e2e-test`, `e2e-browser-test`) for infrastructure/conventions
4. Only after steps 1-3 — if required info is still missing, ask the user

**NEVER skip steps 1-3 and go straight to asking the user. NEVER fall back to simpler tests because setup seems unknown.**

## Point Reproduction Test

Tests the exact point where behavior changes. Proves WHERE the issue is.

- For bug fixes: triggers the exact reported symptom at the narrowest scope
- For features: verifies the new behavior at the component/function level
- Must use real dependencies (NO mocks — never use MagicMock, mock.patch, vi.fn, jest.fn, or any mocking library)

**For fix track — toggle verification is mandatory:**
1. Without fix → test FAILS (bug reproduced)
2. With fix → test PASSES
3. Fix removed → test FAILS again (proves causality)
4. Fix restored → test PASSES again

If step 3 still passes, the fix is not the real cause — investigate further.

## Sub-agent constraints

Launch a test-writing sub-agent with these rules:
- Follow the project's testing conventions (from CLAUDE.md and testing skills)
- Golden path first, edge cases second
- **Mocks are forbidden.** If unsure how to test without mocks, interrupt and ask the user.

## Checklist

- [ ] Read the approved plan
- [ ] Write the point reproduction test
- [ ] Record test file path in state.json

Per `helpers#test_tiers` — this is the **Unit** tier. If the SUT needs a mock to be tested, promote it to `MAKE_INTEGRATION_TEST` instead of introducing the mock here.
Per `helpers#state_transition` — save `unit_test_files` (list of created test files) and complete `MAKE_UNIT_TEST`.
