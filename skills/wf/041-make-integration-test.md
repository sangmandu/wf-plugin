# Step 041: MAKE_INTEGRATION_TEST

**MANDATORY.** This step MUST produce at least one real integration test file recorded in `state.data.integration_test_files`. Skipping — because setup seems hard, unit tests "cover most of it", or you judged it unnecessary — is FORBIDDEN. **Mocking the collaborating systems defeats the point**: the test must exercise real module boundaries (real DB/queue/client, not stubs); if you cannot, stop and ask the user.

## Purpose

Create an integration test BEFORE implementation (TDD). Sits between the narrow unit test (040) and the full-path E2E (042). This test SHOULD fail at this point — that's expected.

## Prerequisites

Before writing any test, follow this lookup chain in order:
1. Invoke the project's testing skill (`python-testing`, etc.) and read the project's CLAUDE.md testing section.
2. Check memory files (`~/.claude/projects/*/memory/`) for integration setup patterns, env vars, credentials.
3. Check integration-related skills and read **existing integration tests in the project** to learn its conventions (how stores are wired, how fixtures are built, what the minimal "real" surface is).
4. Only after steps 1–3 — if required info is still missing, ask the user.

**NEVER skip steps 1–3 and go straight to asking the user. NEVER fall back to simpler tests because setup seems unknown.**

## Integration Test

Exercises multiple real modules wired together, with only the outermost system boundary stubbed (e.g., real state store + real reducers + minimal persistence stub; or real HTTP handler + real service layer + in-memory DB). Proves the modules *compose* correctly — something unit tests cannot prove and E2E tests cannot isolate.

- Uses real code for every module inside the system under test
- Stubs only at hard external boundaries (network, filesystem, third-party SaaS) when the E2E layer will cover them instead
- **Mocks are forbidden.** A minimal stub at a boundary is not a mock of internal behavior.

## Sub-agent constraints

Launch a test-writing sub-agent with these rules:
- Follow the project's integration test conventions (from CLAUDE.md and existing tests).
- Golden path first, edge cases second.
- **No mocks of internal modules.** If unsure how to wire real modules, interrupt and ask the user.

## Checklist

- [ ] Read the approved plan.
- [ ] Read existing integration tests for wiring patterns.
- [ ] Write the integration test.
- [ ] Record test file path(s) in state.json.

Per `helpers#test_tiers` — this is the **Integration** tier. Stub only at external boundaries; never stub internal modules of the package under test.
Per `helpers#state_transition` — save `integration_test_files` (list of created test files) and complete `MAKE_INTEGRATION_TEST`.
