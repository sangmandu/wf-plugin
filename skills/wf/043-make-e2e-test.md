# Step 043: MAKE_E2E_TEST

**MANDATORY.** This step MUST produce at least one real E2E test file recorded in `state.data.e2e_test_files`. Skipping — because infra seems hard, unit tests "cover most of it", or you judged it unnecessary — is FORBIDDEN. **Mock-based E2E is not E2E**: the test must exercise the real runtime (real server, real DB, real network); if you cannot, stop and ask the user.

## Purpose

Create a full-path E2E test BEFORE implementation (TDD). This test SHOULD fail at this point — that's expected.

## Prerequisites

Before writing any test, follow this lookup chain in order:
1. Invoke the project's testing skill (`python-testing`, etc.) and read the project's CLAUDE.md testing section
2. Check memory files (`~/.claude/projects/*/memory/`) for e2e setup info, env vars, credentials
3. Check e2e-related skills (`e2e-test`, `mally-local-e2e-test`, `e2e-browser-test`) for infrastructure/conventions
4. Read existing E2E test files in the project to learn infrastructure patterns (how servers are started, how DB is set up, how APIs are called)
5. Only after steps 1-4 — if required info is still missing, ask the user

**NEVER skip steps 1-4 and go straight to asking the user. NEVER fall back to simpler tests because setup seems unknown.**

## Full-Path E2E Test

Tests the complete path the user actually travels. Proves the WHOLE thing works.

- Exercises the real user-facing flow end-to-end (e.g., agent → client → API → DB → response → agent)
- Point reproduction passing does NOT mean the full path works — each layer can have its own issues
- Must hit real services, real DB, real runtime — not mocks

## Sub-agent constraints

Launch a test-writing sub-agent with these rules:
- Follow the project's testing conventions (from CLAUDE.md and testing skills)
- Golden path first, edge cases second
- **Mocks are forbidden.** If unsure how to test without mocks, interrupt and ask the user.

## Checklist

- [ ] Read the approved plan
- [ ] Read existing E2E tests for infrastructure patterns
- [ ] Write the full-path E2E test
- [ ] Record test file path in state.json

**E2E tests must actually execute and produce a pass/fail result.** Skipped is not a valid outcome — if a test is gated behind env flags or credentials, open the gate before running. If the environment cannot be brought up, this step cannot be completed. Resolve the blocker before proceeding.

Per `helpers#test_tiers` — this is the **E2E** tier. Distinguish FAILED (assertion broke) from BLOCKED (environment unavailable). Never mark BLOCKED as passed.
Per `helpers#state_transition` — save `e2e_test_files` (list of created test files) and complete `MAKE_E2E_TEST`.
