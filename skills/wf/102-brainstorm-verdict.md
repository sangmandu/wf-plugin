# BRAINSTORM_VERDICT — Sub-Agent Verdict

## Objective

A sub-agent reviews the debate results and issues a verdict: **pass** or **revise**.

## Procedure

### 1. Read previous findings

Read `.workflow/brainstorm-explore.md` and `.workflow/brainstorm-debate.md`.

### 2. Launch verdict sub-agent

Launch a single Opus sub-agent with this prompt:

```
You are the verdict agent for a brainstorming session.

## Exploration results
{contents of brainstorm-explore.md}

## Debate results
{contents of brainstorm-debate.md}

## Your task
1. Synthesize the strongest arguments from all positions
2. Evaluate whether the debate has produced a clear, actionable conclusion
3. Issue a verdict:

- **pass**: The debate has converged on a clear direction with sufficient evidence.
  Output the chosen approach and key rationale.
- **revise**: The debate has unresolved contradictions, missing evidence, or the approaches need further refinement.
  Output specific feedback on what needs to be re-explored or re-debated.

You MUST pick one. There is no "block" option.
```

### 3. Handle verdict

Read `state.json` field `brainstorm_debate_count` (initialized to 0 by init-workflow).

- **pass** → Save verdict and chosen approach to `.workflow/brainstorm-verdict.md`. Proceed to next step.
- **revise** →
  1. Increment `brainstorm_debate_count` in `state.json`
  2. If `brainstorm_debate_count >= 3` → force pass with current best conclusion, save to `.workflow/brainstorm-verdict.md`, proceed
  3. Otherwise → save revision feedback to `.workflow/brainstorm-verdict-feedback.md`, then use `rewind-step.sh` to reset `BRAINSTORM_DEBATE` to `pending` and loop back

### Saving brainstorm_debate_count

```bash
CURRENT=$(bash ${CLAUDE_PLUGIN_ROOT}/skills/wf/lib/get-data.sh brainstorm_debate_count 2>/dev/null || echo 0)
bash ${CLAUDE_PLUGIN_ROOT}/skills/wf/lib/set-data.sh brainstorm_debate_count "$((CURRENT + 1))"
```

### Looping back on revise

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/wf/lib/rewind-step.sh BRAINSTORM_DEBATE
```

## Rules

- Verdict agent must be Opus model
- Maximum 3 debate rounds — after that, force pass
- Do NOT implement anything
