# Step 011: VERIFY

## Purpose

Observe the reported bug happening **in a real runtime environment**, not a unit-test mock. This is the gate that decides whether work continues. If you cannot produce an observed reproduction here, the fix track does not proceed to planning or implementation.

## Hard rules — none of these are negotiable

### What counts as a reproduction

A reproduction is an **artifact captured from running code** that shows the reported symptom. Acceptable artifacts include:

- A log file or console output from the real application (dev server, binary, background service) showing the exact error.
- A network trace (curl, HTTP client, browser devtools) showing the real request/response pair that produced the bug.
- A screenshot of the running application displaying the reported symptom.
- A standalone script that imports the real library/module (no mocks, no spies, no stubs) and observes the symptom end-to-end.

The artifact MUST be saved under `.workflow/reproduction-artifact.*` (pick an extension that matches the format: `.log`, `.txt`, `.json`, `.png`, `.har`, etc.). Multiple artifacts are fine.

### What does NOT count as a reproduction

- A unit test that mocks the suspect module and asserts the hypothesis. Mocking the very thing you are investigating is circular — you are verifying your assumption about the module, not the module itself.
- A test that spies on a function and simulates the call sequence you believe happens. Same problem.
- A reasoned argument from reading the code. "This branch must fire" is a hypothesis, not an observation.
- A passing or failing CI build without a captured artifact that shows the symptom.

If you find yourself writing `vi.fn`, `jest.fn`, `spyOn`, `stub`, `MagicMock`, `sinon`, or similar mock helpers to "reproduce" the bug, stop. That is not reproduction.

### Required order of reproduction methods

Prefer the method that needs the least user intervention. Try them in order; only escalate to the next tier after the current tier genuinely fails.

1. **Standalone script with real dependencies**. Write a small script that imports the real production modules and exercises the code path directly. If the module depends on browser or runtime globals, polyfill the minimum set rather than falling back to mocks. Example: spin up a real local HTTP server, point the real client at it, capture the real request/response.
2. **Headless end-to-end harness**. If the bug is UI-driven, use the project's existing end-to-end test runner in headless mode with an added scenario that triggers the bug. This is still code-driven — no manual clicks.
3. **Dev server + automated trigger**. Start the project's dev server in the background, then drive the scenario with an HTTP client, CLI call, or scripted input. Capture the server logs and the client response.
4. **Diagnostic logs + dev server + automated trigger**. Add temporary diagnostic log statements at the file:line locations identified in `INVESTIGATE`, start the dev server, trigger the scenario, and grep the log output. Log statements must be obviously temporary (e.g., prefixed with the ticket identifier) so they can be removed cleanly before commit.
5. **User-in-the-loop**. Only if every earlier tier is genuinely infeasible — e.g., the bug only happens on the user's specific hardware, OS permissions, or hosted environment you cannot access. In that case: prepare the diagnostic logs yourself, ask the user to start the app and perform the trigger steps, and request they paste the captured output back to you. Do not invoke this tier because it is easier; invoke it because it is the only option.

Document in `reproduction.md` under `Verification attempts` which tier was tried and why earlier tiers were insufficient.

## Procedure

1. **Write the reproduction target**. Pick the lowest-numbered tier that can actually run the suspect code path. Create the script, harness update, or diagnostic log additions inside the current worktree. These changes are temporary — they will be removed before commit unless they represent a genuine regression test.

2. **Add diagnostic logs** to every file:line location you hypothesized about in `INVESTIGATE`. Each log line should include:
   - A unique prefix (e.g., the branch name or a short tag) so you can grep for just your logs.
   - The relevant state (status codes, variable values, call counts).
   - A clear indication of which branch was taken.

3. **Run the reproduction**. Execute the script, start the dev server, or run the headless harness. Capture stdout, stderr, and any log files. Save all output verbatim to `.workflow/reproduction-artifact.log` (or appropriate extension). Do not summarize. Do not trim. The raw artifact is evidence.

4. **Compare the observation against the hypothesis**. Open `reproduction.md` and append under `Verification attempts`:
   - Which tier you tried.
   - The exact command(s) run.
   - What was observed (the relevant excerpt from the artifact, plus a pointer to the full file).
   - Whether it matches the hypothesized symptom.

5. **Decide**:
   - **Matches**: bug reproduced. Mark verification passed in `reproduction.md`, proceed to `REPORT`.
   - **Does not match** (different symptom): the hypothesis was wrong. Update `Hypotheses` in `reproduction.md` with what you learned, then return to `INVESTIGATE` (run `rewind-step.sh INVESTIGATE INVESTIGATE VERIFY`). Keep the diagnostic logs in place — the next investigation round will use them.
   - **Nothing observed at all** (the trigger ran, no error, no relevant log lines): either the hypothesis is wrong, or the scenario did not actually exercise the suspect path, or the environment is not the one where the bug manifests. Treat as "does not match" and go back to `INVESTIGATE`.

6. **No attempt cap**. Keep iterating until the bug is reproduced or you hit a genuine dead end (the bug requires an environment you cannot access). There is no "max 3 tries" — but each return to `INVESTIGATE` must produce a *new* hypothesis, not a rerun of the same one.

## INTERRUPT

INTERRUPT and ask the user for help when, and only when, one of these is true:

- **Environment inaccessible**: the bug requires access to a runtime you cannot reach (user's specific machine, production data, hosted service you lack credentials for). Ask the user to run the prepared diagnostic steps and paste the output.
- **Scenario ambiguous**: the report does not give enough information to trigger the symptom and you have exhausted reasonable guesses. Ask for concrete steps.
- **All hypotheses exhausted**: you have tried and ruled out every hypothesis from `INVESTIGATE` and have no new lead. Ask the user for any additional clues, logs, or environment details they can share.

Do NOT INTERRUPT because reproducing feels hard or slow. Reproducing a real bug is the work.

## Diagnostic log cleanup

Diagnostic logs added during this step are temporary instrumentation, not product code. They will be removed in the commit that lands the fix. Keep them in place for now — `PLAN` and `IMPLEMENT` will reference them, and they are only removed before `COMMIT`. Do not commit them to the repository at the end of this step.

Per `helpers#state_transition` — complete `VERIFY` only after a matching observation has been captured.
