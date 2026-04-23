# Step 052: SELF_REVIEW


## Purpose

Review your own implementation before committing, using the same review agents as pr-review. Catches logic bugs, convention violations, and security/performance issues before they reach PR review.

## MANDATORY

**NEVER skip this step.** Even if the diff is small, trivial, config-only, or doc-only — you MUST run all 3 review agents. Do not make your own judgment about whether changes "need" review.

## Checklist

### Get the diff

- [ ] Generate the diff of all changes against origin/main:
  ```bash
  git diff origin/main
  ```
- [ ] Get the list of changed files:
  ```bash
  git diff origin/main --name-only
  ```

### Determine SECURITY_SENSITIVE

- [ ] If ANY changed file is under `.github/` or `.claude/`, set `SECURITY_SENSITIVE=true`, otherwise `false`

### Exclude codegen files

- [ ] Skip any auto-generated files (e.g. files in codegen output directories defined in the project's CLAUDE.md or build config). Do not review generated code.

### Launch 3 review sub-agents in parallel

Review changes against the project's code conventions (CODE_CONVENTIONS.md or equivalent). If no conventions file exists, review against general best practices. In each sub-agent prompt, replace `gh pr diff {{PR_NUMBER}}` with `git diff origin/main`.

**Delegate to 3 parallel sub-agents** using the `Agent` tool with `subagent_type: "superpowers:code-reviewer"`. Each sub-agent receives the full diff and reviews from its assigned perspective:

- [ ] **Sub-Agent A: Logic & Bugs** — Review for logic errors, bugs, and incorrect behavior
- [ ] **Sub-Agent B: Patterns & Conventions** — Review against project code conventions
- [ ] **Sub-Agent C: Security & Performance** — Review for security issues and performance problems

All 3 sub-agents MUST run in parallel via a single message with 3 Agent tool calls.

### Collect and filter findings

- [ ] Gather JSON arrays from all 3 agents
- [ ] Apply confidence threshold: **70+** only. Discard all findings below 70.
- [ ] If any agent returns invalid JSON, include as a fallback finding with severity `follow_up`

### Categorize into tiers

| Tier | Label         | Meaning                                         |
| ---- | ------------- | ----------------------------------------------- |
| 1    | **must_fix**  | Bugs, security issues, breaking changes         |
| 2    | **suggested** | Convention violations, performance improvements |
| 3    | **follow_up** | Separate cleanup recommended                    |

### Save findings

Per `helpers#state_transition` — save `self_review_findings` (the full filtered findings array) to state.json

Per `helpers#state_transition` — complete `SELF_REVIEW`
