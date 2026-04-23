---
name: fix
description: |
  Bug-fix workflow with a mandatory real-environment reproduction gate.
  Unlike the feature track, fix starts with reproducing the reported symptom against the real runtime (NO mocks) before any ticket is created, any plan is written, or any code is changed.
  Triggers on: "/wf:fix"
---

# wf:fix — Bug Fix Workflow

This is a shortcut for `/wf` with the `fix` track pre-selected.

## What makes fix different from feature

| Phase              | feature track                        | fix track                                                          |
| ------------------ | ------------------------------------ | ------------------------------------------------------------------ |
| Ticket creation    | Before setup                         | After reproduction is confirmed                                    |
| Reproduction gate  | None                                 | `INVESTIGATE` → `VERIFY` → `REPORT`  |
| Planning           | SDD `SPECIFY` + `PLAN`               | Single `PLAN` (fix-branch) derived from the reproduction artifact         |
| Mock-based tests   | Allowed                              | **Forbidden** as reproduction evidence                             |
| Branch naming      | Named from the ticket up front       | Temporary placeholder until `RENAME_BRANCH` after ticket creation  |

The reproduction gate is non-negotiable. Code-analysis hypotheses are not reproductions. Mock-based tests that simulate the suspected library behavior are not reproductions. The evidence must come from running the real product code against a real runtime (real HTTP server, real library import, real dev server, etc.).

## Execution

1. Ask the user for the bug report if it is not already in the conversation. Capture the exact error message, screenshot, or behavior description verbatim.
2. Initialize the workflow with the fix track:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/wf/lib/init-workflow.sh fix "<task_description>"
   ```
3. The script outputs the first step's instructions. Follow them.
4. On complete, run:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/wf/lib/complete-step.sh <STEP_KEY>
   ```
5. Follow the next step output. Repeat until the workflow is done.

## When to reroute to feature

If the reported "bug" turns out on investigation to be a missing feature or a spec question ("this should also support X"), stop the fix workflow and restart with `/wf:feature`. Do not try to shoehorn new-feature work through the fix track.

## Rules

Per `${CLAUDE_PLUGIN_ROOT}/skills/wf/SKILL.md` for interrupt conditions and step execution rules.
Per `${CLAUDE_PLUGIN_ROOT}/skills/wf/helpers.yaml` for shared protocols.
