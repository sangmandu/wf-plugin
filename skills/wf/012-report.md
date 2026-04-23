# Step 012: REPORT

## Purpose

Present the reproduction to the user and get explicit confirmation that "this is the bug we are fixing" before the workflow creates a Linear ticket and formalizes the fix. This is the last chance to course-correct before ceremony begins.

## Procedure

Present the following sections in order. Do not skip any.

### 1. Hypothesis that was confirmed

State the single hypothesis from `reproduction.md` that the verification matched. Include the suspect location, the trigger condition, and the expected signal.

### 2. Reproduction artifact

Show the relevant excerpt from `.workflow/reproduction-artifact.*` (or list the files if multiple). Include:
- The exact command(s) that were run.
- The key log lines, response body, or screenshot description that proves the symptom.
- The path to the full artifact so the user can inspect everything.

### 3. Causal chain

Explain the bug end-to-end in 3–6 sentences, from trigger to observable symptom. Do not skip steps — each transition should be supported by the reproduction artifact or by the code trace from `INVESTIGATE`. This is what proves you understand the bug, not just that you observed it.

### 4. Scope assessment

State:
- **Where the fix will land**: the file(s) you believe need to change, at what level (client/server/shared/config).
- **Out of scope**: closely related issues you noticed during investigation but will not fix in this pass. Call them out so the user can decide whether to expand scope.
- **Any prerequisites**: upstream fixes, migrations, or coordination work needed before the fix is safe to ship.

### 5. Ticket proposal

Propose:
- A ticket title in the project's conventional format.
- A one-line summary.
- Priority if it is obvious from the artifact (user-blocking vs. annoyance).

Do NOT create the ticket yet — that happens in the next step. This section is just a proposal for the user to review.

## INTERRUPT

Ask the user explicitly: **"Is this the bug you wanted fixed?"**

- **Yes** → run `complete-step.sh REPORT`. The workflow proceeds to `LINEAR_TICKET` and then `RENAME_BRANCH`.
- **No, different symptom** → update `reproduction.md` and return to `INVESTIGATE`.
- **Yes, but also fix X** → note X in `reproduction.md` under "Additional scope", and ask the user whether to expand the ticket or leave X for a separate ticket. Do NOT silently expand scope.
- **Pause** → leave the step running; the user can resume later.

Do NOT run `complete-step.sh` until the user confirms. This is a mandatory gate.

Per `helpers#state_transition` — complete `REPORT`
