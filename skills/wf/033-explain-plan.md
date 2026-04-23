# Step 033: EXPLAIN_PLAN

## Purpose

Walk the user through the plan **one concept at a time** so they fully understand the reasoning before any code is written. The user has NOT read the codebase — they only know what you tell them. Bridge that information asymmetry.

## Procedure

### Phase 1: Make an Explanation Outline

Before explaining anything, create a numbered outline. Present it first:

```
Explanation Plan
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
I'll explain this plan in N steps:

1. <topic> — <one-line summary>
2. <topic> — <one-line summary>
...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Outline guidelines:
- **Start from background** — domain concepts, system architecture, terminology the user needs. Never assume the user knows how the affected system works.
- Then move to the **problem** (what the user experiences today)
- Each step answers ONE question: "what is X?" or "why does X cause Y?"
- Order by causal chain: background → cause → why → effect → solution → why
- Typically 3–6 steps.

### Phase 2: Step-by-Step Explanation

For each step in the outline:

1. **Explain the concept** — per `helpers#explanation_style` (PTIA pattern). Include the causal link: not just "X happens" but "X happens **because** Y, which means Z."
2. **Wait for user OK** — do not proceed until the user confirms.
3. **User restates in their own words?** — validate precisely. If correct, confirm. If partially wrong, point to exactly which part diverges and why.
4. **User follow-up?** — answer fully before moving on.

### Phase 3: Transition

Once the last step is acknowledged, ask:

```
Explanation complete. Ready to proceed to test-writing — go ahead?
```

**Wait for user confirmation.** Only then complete the step.

## Rules

- **Never explain multiple concepts in one message.** One step = one message.
- **Every claim needs a "why".** "We chose X" is incomplete. "We chose X because Y, and Z was rejected because W" is complete.
- **Show what you saw.** Reference file:line when relevant.
- **No jargon without definition.** Define technical terms in the same sentence you use them.
- **Adapt granularity.** Brief "OK" = right pace. Clarifying questions = too fast, break the step down.

## Checklist

- [ ] Outline presented
- [ ] Each step delivered one at a time
- [ ] Each step acknowledged by user before proceeding
- [ ] Final confirmation received

Per `helpers#state_transition` — complete `EXPLAIN_PLAN`
