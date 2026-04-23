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

`WF_DIR` = the parent directory of this file (i.e. the directory containing `run.sh`, `SKILL.md`, etc.). Derive it from the path this file was loaded from.

1. Ask the user for the task description if not already provided
2. Initialize the workflow with the brainstorm track:
   ```bash
   bash <WF_DIR>/run.sh init brainstorm "<task_description>"
   ```
3. The script outputs the first step's instructions. Follow them.
4. On complete, run:
   ```bash
   bash <WF_DIR>/run.sh complete <STEP_KEY>
   ```
5. Follow the next step output. Repeat until workflow is done.

## Rules

Per `<WF_DIR>/SKILL.md` for interrupt conditions and step execution rules.
Per `<WF_DIR>/helpers.yaml` for shared protocols.
