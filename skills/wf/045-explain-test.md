# Step 045: EXPLAIN_TEST

## Purpose

Walk the user through the test strategy **one scenario at a time** so they fully understand what's being verified and why. The user has NOT read the test code — they only know what you tell them.

## Procedure

### Phase 1: Make an Explanation Outline

```
Explanation Plan
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
I'll explain the test plan in N steps:

1. <topic> — <one-line summary>
2. <topic> — <one-line summary>
...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Outline guidelines:
- Start from **what we need to verify** (connect back to the spec/plan)
- Each step answers ONE question: "what scenario are we testing?" or "why does this test matter?"
- Order by importance: critical paths first, edge cases after
- For each scenario, explain the causal chain: "if X breaks, users would experience Y, so we test Z"
- Typically 3–6 steps.

### Phase 2: Step-by-Step Explanation

For each step:

1. **Explain the test concept** — per `helpers#explanation_style` (PTIA pattern). What scenario, why it matters, what bug this catches if missing. Concrete Given/When/Then.
2. **Wait for user OK**.
3. **User restates?** — validate precisely.
4. **User follow-up?** — answer fully before moving on.

Also state the real-dependency policy once: what services are used for real (testcontainers / local / staging), and confirm **no mocks**.

### Phase 3: Transition

```
Explanation complete. Ready to proceed to implementation — go ahead?
```

**Wait for user confirmation.**

## Rules

- **One scenario per message.** No dumping.
- **Every test needs a "why it matters".** "We test X because if it breaks, Y happens to the user."
- **Connect tests to the plan.** Each test traces back to a spec item or plan decision.
- **Show what you saw.** Reference specific code paths being tested.
- **Adapt granularity.** Brief OK = right pace. Questions = too fast.

## Checklist

- [ ] Outline presented
- [ ] Each scenario explained one at a time
- [ ] Each step acknowledged by user
- [ ] Final confirmation received

Per `helpers#state_transition` — complete `EXPLAIN_TEST`
