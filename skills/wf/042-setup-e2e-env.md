# Step 042: SETUP_E2E_ENV

**MANDATORY.** This step ensures a real E2E environment is running before you write any E2E test. Without a live environment, you cannot write a real E2E test — and mock-based tests are not E2E.

## Purpose

Prepare a real runtime environment so the next step (MAKE_E2E_TEST) can write tests that hit actual services. This step is the gate: if you cannot bring up the environment, MAKE_E2E_TEST cannot proceed.

## Lookup chain

Before attempting to start anything, follow this order:
1. Read the project's CLAUDE.md for serve/dev commands and E2E setup instructions
2. Check memory files (`~/.claude/projects/*/memory/`) for E2E env vars, credentials, ports
3. Check e2e-related skills (`poppy-local-e2e-test`, `mally-local-e2e-test`, etc.)
4. Read existing E2E test files to learn what environment they expect (env vars, base URLs, servers)
5. Only after steps 1-4 — if required info is still missing, ask the user

## Checklist

- [ ] Identify what real environment the E2E tests need (dev server, staging API, credentials, etc.)
- [ ] Check if required env vars and credentials are available (e.g. `POPPY_E2E=1`, JWT tokens, API keys)
- [ ] Start the required servers/services (e.g. `pnpm nx serve poppy`, staging backend)
- [ ] Verify the environment is reachable (e.g. health check, curl, or a simple request)
- [ ] Record in state.json: `e2e_env` object with `{ status, services, env_vars, base_url }`

## What counts as a ready environment

- A real app server is running and responding (local dev or staging)
- Real network requests can reach real backends (no mocked transport)
- Required credentials/env vars are set
- You have verified connectivity with at least one real request

## BLOCKED — when you cannot bring up the environment

If the environment cannot be started (missing credentials, server won't start, staging is down), do NOT:
- Proceed to MAKE_E2E_TEST and write mock-based tests instead
- Skip this step
- Claim the environment is "not needed"

Instead:
- Record `e2e_env.status = "BLOCKED"` with the reason in state.json

**A blocked environment means MAKE_E2E_TEST cannot produce real E2E tests. This is by design — fake E2E is worse than no E2E.**

Per `helpers#state_transition` — save `e2e_env` and complete `SETUP_E2E_ENV`
