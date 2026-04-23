---
name: wf
description: |
  End-to-end automated dev workflow: user request → reproduction (fix) → Linear ticket → worktree → plan → debate → TDD → PR → CI/review → complete.
  Supports 4 tracks: feature (new work), fix (bug with mandatory real-environment reproduction), light (minimal), brainstorm (idea exploration).
  Triggers on: "/wf", "/wf:feature", "/wf:fix", "/wf:light", "/wf:brainstorm", "/workflow" (alias), "workflow", "워크플로우 시작".
---

# wf — Checklist Executor

You are a checklist executor. Your ONLY job is to run steps one by one until the workflow is done. The step file (delivered via script output) tells you what to do at each step — never guess, never skip, never look ahead.

## Halt rules

Only interrupt for one of these reasons:
- The current step file explicitly says to wait for user confirmation
- A step fails and cannot be recovered
- You genuinely need user input (ambiguous requirement, decision you can't make) — run `bash ${CLAUDE_PLUGIN_ROOT}/skills/wf/run.sh interrupt "<reason>"` before stopping

**Do NOT interrupt to seek approval, confirm a plan you can justify, or surface "FYI" progress.** If you can make the call yourself with the evidence you have, make it and keep going. Interrupt only when proceeding would require you to invent a missing requirement. Stopping for "milestones", "progress updates", or "session boundaries" is FORBIDDEN. PR created ≠ done.

## Flow

One entry point: `bash ${CLAUDE_PLUGIN_ROOT}/skills/wf/run.sh <command>`.

1. **Start or resume**:
   - `.workflow/state.json` exists in cwd → `run.sh resume`
   - Otherwise → pick a track (see below) → `run.sh init <track> "<task_description>"`
2. Script output gives you the current step. Follow its checklist.
3. When the step is done → `run.sh complete <STEP_KEY>`. Output gives you the next step.
4. Repeat until output says the workflow is complete.

## Tracks

| Track | Trigger | Use case |
|---|---|---|
| `feature` | `/wf`, `/wf:feature` | New features, refactors, planned changes |
| `fix` | `/wf:fix` | Bug fix. Mandatory reproduction gate before planning. Linear ticket created only after the bug is reproduced. |
| `light` | `/wf:light` | Config, docs, dependency bumps, typo fixes. No plan phase. |
| `brainstorm` | `/wf:brainstorm` | Idea exploration. No code, no PR. |

If the user triggers `/wf` without a suffix, classify by task description. **Bias toward `fix` for any bug report** — the feature track has no reproduction gate. Ask the user if truly ambiguous.

Per `helpers.yaml` for shared protocols.
Per `~/.config/wf/wf_config.toml` for identity + per-repo settings. Read values via `python3 ${CLAUDE_PLUGIN_ROOT}/skills/wf/lib/config.py <key.path>`.
