# BRAINSTORM_EXPLORE — Idea Exploration via Sub-Agents

## Objective

Use sub-agents to brainstorm the user's idea from multiple independent angles, following the `/sss` pattern combined with `superpowers:brainstorming`.

## Procedure

### 1. Clarify the topic

Ask the user (via `AskUserQuestion`):
- What idea or topic do you want to brainstorm?
- Any constraints or context we should know?

**INTERRUPT here — wait for user response before proceeding.**

### 2. Launch 3 sub-agents in parallel

Follow the `/sss` (Sub-Agent Review) pattern. Launch 3 independent agents, each applying the `superpowers:brainstorming` methodology from its own unique angle.

Prompt template for each agent:

```
You are one of 3 independent brainstorming agents exploring the same idea.
Other agents are exploring this too — your job is to find approaches THEY would miss.

## The idea
{user's idea/topic}

## Context
{relevant background from the conversation and codebase}

## Your task
Apply the superpowers:brainstorming methodology:
1. Explore the project context (check files, docs, recent commits if relevant)
2. Identify purpose, constraints, success criteria
3. Propose 2-3 approaches with trade-offs and your recommendation
4. Go deep on whatever angle stands out to you

Be specific. Cite real code, patterns, or references where possible.
Do not try to be comprehensive — go deep on your unique angle.
```

### 3. Synthesize

After all 3 agents complete, present a synthesis:

```
## Multi-perspective brainstorm (3 agents)

### Consensus (all agreed)
- ...

### Divergence (disagreed on)
- ...

### Unique insights (only 1 agent found)
- ...

### Consolidated approaches
1. [Approach name] — description, trade-offs
2. [Approach name] — description, trade-offs
3. [Approach name] — description, trade-offs
```

Save synthesis to `.workflow/brainstorm-explore.md`.

## Rules

- All 3 agents must run in parallel (no shared context)
- Do NOT pick a winner yet — that's for the debate step
- Do NOT implement anything
