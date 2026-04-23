---
name: feature
description: |
  Full workflow for new features, refactors, and large planned changes.
  For bug fixes, use `/wf:fix` instead — it runs a mandatory reproduction gate before planning.
  Triggers on: "/wf", "/wf:feature"
---

# wf:feature — Feature Workflow

This is the default `/wf` track. Use it for anything that is **not** a bug fix, **not** config/docs-only, and **not** pure ideation.

## When NOT to use this track

- **Bug fix** → use `/wf:fix`. It reproduces the bug in the real environment before writing code. Using the feature track for an unreproduced bug leads to code-analysis-only "fixes" that may miss the actual root cause.
- **Config/docs/dep bump** → use `/wf:light`. Skips the plan debate and TDD phases.
- **Idea exploration with no implementation** → use `/wf:brainstorm`.

## Execution

1. Ask the user for the task description if not already provided.
2. Initialize the workflow with the feature track:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/wf/lib/init-workflow.sh feature "<task_description>"
   ```
3. The script outputs the first step's instructions. Follow them.
4. On complete, run:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/wf/lib/complete-step.sh <STEP_KEY>
   ```
5. Follow the next step output. Repeat until the workflow is done.

## Rules

Per `${CLAUDE_PLUGIN_ROOT}/skills/wf/SKILL.md` for interrupt conditions and step execution rules.
Per `${CLAUDE_PLUGIN_ROOT}/skills/wf/helpers.yaml` for shared protocols.
