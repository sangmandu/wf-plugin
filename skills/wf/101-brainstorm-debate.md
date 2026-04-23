# BRAINSTORM_DEBATE — Triangular Debate

## Objective

Run a `/333` triangular debate on the consolidated approaches from the explore step.

## Procedure

### 1. Read previous findings

Read `.workflow/brainstorm-explore.md` for the consolidated approaches.

### 2. Launch triangular debate (3 agents in parallel)

Follow the `/333` (Triangular Debate) pattern exactly:

| Agent | Role | Goal |
|-------|------|------|
| **PRO** (찬성) | Defend the top recommended approach | Find evidence that supports it |
| **NEUTRAL** (중립) | Analyze objectively | Compare all approaches, present trade-offs, cite real-world practice |
| **CON** (반대) | Attack the top approach | Find fundamental flaws, champion an alternative |

All agents MUST:
- Search for real evidence (papers, frameworks, production examples)
- Cite specific sources
- Make concrete arguments, not vague claims
- Be aggressive in their assigned role

### 3. Synthesize debate

Present results as a table:

```
| Issue | PRO | CON | NEUTRAL | Strongest argument |
|-------|-----|-----|---------|-------------------|
| ...   | ... | ... | ...     | ...               |
```

Save debate results to `.workflow/brainstorm-debate.md`.

## Rules

- Agents must do web research — arguments without evidence are opinions
- Do NOT make a final decision here — that's for the verdict step
- Do NOT implement anything
