---
name: brainstorm
description: |
  Idea exploration workflow: sub-agent brainstorm → triangular debate → verdict → report.
  Uses /sss, /333, /rrr skills. No code changes, no PR.
  Triggers on: "/wf:brainstorm"
---

# wf:brainstorm — Idea Exploration Workflow

This is a shortcut for `/wf` with the `brainstorm` track pre-selected.

## Execution

1. Ask the user for the task description if not already provided
2. Initialize the workflow with the brainstorm track:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/wf/lib/init-workflow.sh brainstorm "<task_description>"
   ```
3. The script outputs the first step's instructions. Follow them.
4. On complete, run:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/wf/lib/complete-step.sh <STEP_KEY>
   ```
5. Follow the next step output. Repeat until workflow is done.

## Rules

Per `${CLAUDE_PLUGIN_ROOT}/skills/wf/SKILL.md` for interrupt conditions and step execution rules.
Per `${CLAUDE_PLUGIN_ROOT}/skills/wf/helpers.yaml` for shared protocols.
