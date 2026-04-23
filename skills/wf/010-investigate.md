# Step 010: INVESTIGATE

## Purpose

Form hypotheses about the root cause of the reported bug **from code reading alone**. This step does NOT reproduce the bug yet — that happens in the next step (`VERIFY`). It exists because attempting reproduction without a hypothesis is blind and because narrowing down the suspect code path lets you target diagnostic logs effectively in the next step.

## Rules

- **This step is read-only.** No code changes, no diagnostic logs yet. Save log placements for the next step.
- **Do NOT** create a Linear ticket, plan document, or test file here. The workflow creates the ticket only after the bug is reproduced.
- **Separate observed facts from interpretation.** Facts go in `Observed evidence` below; your conclusions go in `Hypotheses` and must start with "Hypothesis: ...".
- **If the reporter gave you an error message, screenshot, or log**, treat those as the only facts you currently have. Anything beyond them is hypothesis.

## Procedure

1. **Collect the report**. From the conversation, extract:
   - The exact symptom (error message, screenshot contents, unexpected behavior description).
   - When it happens (always, intermittently, after a specific action).
   - The environment it was observed in.
   - Anything the user said about reproduction steps they already tried.

2. **Trace the code**. Search the codebase for the error string, the feature name, or the affected component. Follow the flow end-to-end: where does input enter, where does it leave, where are the state transitions? Prefer focused searches over broad explores; you are looking for a hypothesis, not a full map.

3. **Form 1–3 hypotheses**. Each hypothesis must name:
   - The suspect code location (file:line or function).
   - The trigger condition (what has to be true for the bug to fire).
   - The expected observable signal if that hypothesis is correct (which log line, which HTTP status, which error message).

4. **Write `.workflow/reproduction.md`** (create the file) with this structure:
   ```markdown
   # Reproduction notes

   ## Reported symptom
   - <exact error / screenshot text / behavior description from the user>
   - Environment: <where it was observed>
   - Frequency: <always / intermittent / once>

   ## Observed evidence
   - <any log lines, stack traces, network responses the user shared>
   - <git history of suspect area if relevant>

   ## Hypotheses
   1. **Hypothesis**: <one sentence>
      - Suspect location: <file:line or function>
      - Trigger condition: <what must be true>
      - Expected signal: <what you expect to see when the bug fires>
   2. ...
   3. ...

   ## Verification plan (drafted for the next step)
   - Diagnostic log placements: <file:line → what to log>
   - How to trigger: <command, UI action, script>
   - Pass criterion: <what observable evidence counts as "bug reproduced">
   ```

## INTERRUPT

Present the hypotheses and the verification plan to the user. **Wait for the user to confirm direction before proceeding.** The user may:
- Approve the plan → run `complete-step.sh INVESTIGATE`.
- Redirect to a different hypothesis → update `reproduction.md` and re-present.
- Provide additional information (new logs, different environment) → incorporate into `Observed evidence` and re-run this step's logic.

Do NOT run `complete-step.sh` until the user confirms the hypotheses.

Per `helpers#state_transition` — complete `INVESTIGATE`
