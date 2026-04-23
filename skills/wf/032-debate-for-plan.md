# Step 032: DEBATE_FOR_PLAN

Per `helpers#debate_protocol` — triangular debate (PRO / NEUTRAL / CON).

## Launch 3 agents in parallel

- [ ] **PRO Agent**:

  ```
  You are PRO in a triangular debate on this implementation plan.
  Read the plan from speckit output.
  Defend it: find supporting evidence, codebase precedents, and patterns that validate the approach.
  Acknowledge minor weaknesses but argue the plan is fundamentally sound.
  Cite specifics — no vague claims.
  ```

- [ ] **NEUTRAL Agent**:

  ```
  You are NEUTRAL in a triangular debate on this implementation plan.
  Read the plan from speckit output.
  Analyze objectively:
  1. Compare against alternative approaches — what trade-offs does each have?
  2. What does real-world practice show for this kind of change?
  3. Is the scope right — too much or too little?
  Present trade-offs without hedging. Pick what the evidence supports.
  ```

- [ ] **CON Agent**:
  ```
  You are CON in a triangular debate on this implementation plan.
  Read the plan from speckit output.
  Attack it aggressively:
  1. Is this the wrong layer? (UI fix when root cause is server/library?)
  2. Is this over-engineered? (too many files, unnecessary complexity?)
  3. Is there a fundamentally better approach?
  Propose a concrete alternative. Back every criticism with evidence.
  ```

## Verdict

- [ ] Launch a **Verdict agent** (Opus) with all 3 debate outputs. The Verdict agent's prompt:

  ```
  You are the VERDICT agent. You received 3 debate positions (PRO, NEUTRAL, CON) on an implementation plan.

  Your job:
  1. Synthesize the strongest arguments from all 3 positions.
  2. Incorporate valid feedback into the plan — write the improved version.
  3. Judge the plan quality and issue a verdict:

     - **pass** — The plan is sound. Minor suggestions were incorporated. Proceed to implementation.
     - **revise** — The plan has significant flaws identified by the debate. List the specific concerns
       that MUST be addressed. The Plan sub-agent will rewrite the plan using your feedback.

  Return a JSON object: { "verdict": "pass|revise", "summary": "...", "feedback": "..." }
  - summary: 1-2 sentence synthesis of the debate
  - feedback: (revise/block only) specific concerns to address
  ```

- [ ] Increment `debate_for_plan_count`:
  ```bash
  CURRENT=$(bash <WF_DIR>/lib/get-data.sh debate_for_plan_count 2>/dev/null || echo 0)
  bash <WF_DIR>/lib/set-data.sh debate_for_plan_count "$((CURRENT + 1))"
  ```
- [ ] **Verdict routing**:
  - `pass` → proceed to next step
  - `revise` → check `debate_for_plan_count`:
    - If `< 3` → save feedback to state.json `verdict_feedback` field → `bash <WF_DIR>/lib/rewind-step.sh PLAN PLAN DEBATE_FOR_PLAN`
    - If `>= 3` → escalate to user: "Plan failed to converge after 3 revision rounds. Here are the unresolved concerns: [feedback]"

Per `helpers#state_transition` — complete `DEBATE_FOR_PLAN`
