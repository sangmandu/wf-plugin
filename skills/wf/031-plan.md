# Step 031: PLAN

Single planning step for both `feature` and `fix` tracks. Branch on track, produce `.workflow/plan.md`. Downstream `DEBATE_FOR_PLAN` + `EXPLAIN_PLAN` validate the plan — do NOT wait for user approval here.

## Track branching

Read `.workflow/state.json` → `data.track`.

### If `track == "fix"` — repair plan from reproduction

Inputs:
- `.workflow/reproduction.md` — hypotheses, confirmed hypothesis, causal chain
- `.workflow/reproduction-artifact.*` — observed evidence
- Code trace from `INVESTIGATE`

**Root cause classification** (required before writing the plan):
- Key question: "Is the symptom location the same as the cause location?"
  - YES → fix in current layer.
  - NO / UNCERTAIN → identify the actual cause layer before designing the fix.
- Categories:
  - **Code-level mistake** — typo, missing condition, wrong variable. Fix in place.
  - **Same-layer structural flaw** — architecture makes this bug class inevitable. Consider refactor.
  - **System boundary problem** — different layer (API schema, server response, type contract) is not providing what this layer needs. Fix at the boundary.
- **Boundary signal checklist** — 2+ of these → classify as boundary problem:
  - `@ts-expect-error` / `@ts-ignore` on external data
  - `as any` on API responses
  - `enabled: false` / conditional disabling based on missing data
  - `// TODO` / `// HACK` / `// FIXME` near the bug area
  - Fallback chains of 3+ levels
- When boundary problem: confirm upstream contract, surface "symptom in layer X, cause in layer Y", ask user whether to fix at boundary (fundamental) or workaround in current layer (tactical).
- `git fetch origin main` — if the bug is already fixed upstream, cancel the workflow early.

Write `.workflow/plan.md`:

```markdown
# Fix plan for <ticket-id>

## Observed symptom
<1-sentence restatement from reproduction.md>

## Root cause
<2-4 sentences. Trigger → causal chain → symptom. Every step supported by artifact or code trace.>

## Proposed change
### <file path>
- Current behavior: <1-2 sentences>
- Proposed behavior: <1-2 sentences>
- Why this fixes the root cause: <1 sentence>

## Out of scope
<related issues noticed but not addressed here>

## Regression risks
<what could break + how MAKE_UNIT_TEST / MAKE_E2E_TEST will guard each>

## Rollback
<1-2 sentences on how to revert if the fix is wrong>
```

Fix-track rules:
- Smallest change that makes the reproduction stop failing. No surrounding refactor.
- Every proposed change traceable to root cause — if you can't write the 1-sentence "why", remove it.
- Describe behavior, not code. No pseudocode/diffs — that's `IMPLEMENT`.
- No new features. Note in `Out of scope` and move on.
- Diagnostic logs: explain conceptually how the final fix replaces the need for them.

### If `track == "feature"` — design plan from spec

- Launch an Agent with `model: "opus"` and `subagent_type: "Plan"`.
- Pass: task description, spec output, and these criteria:
  - **Layer selection** — frontend / server / library? Choose where the problem originates, not where symptoms appear.
  - **Cost-effectiveness** — simplest approach; avoid unnecessary complexity (new routes, new state, new API calls).
  - **Blast radius** — fewer files changed = less risk.
- If revise iteration (`debate_for_plan_count > 0`), also pass the Verdict agent's feedback so the Plan sub-agent addresses the specific concerns raised.
- Main agent receives the plan output — does NOT modify or synthesize it.

## Checklist

- [ ] Determine track and branch accordingly.
- [ ] `.workflow/plan.md` written.
- [ ] Do NOT wait for user approval — `DEBATE_FOR_PLAN` + `EXPLAIN_PLAN` validate next.

Per `helpers#state_transition` — complete `PLAN`
