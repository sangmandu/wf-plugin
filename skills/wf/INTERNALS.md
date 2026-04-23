# wf Internals

This document is for humans who want to modify the wf skill.
For agent-facing execution rules, see `SKILL.md` and `helpers.yaml`.

## Architecture

```
Agent message loop (runtime)
  ↓ reads
SKILL.md (role: "you are a checklist executor")
  ↓ delegates to
init-workflow.sh / complete-step.sh / resume-workflow.sh
  ↓ manage
.workflow/state.json (single source of truth)
  ↓ outputs
Step .md files (one at a time, via stdout → agent context)
```

The agent IS the runtime. There is no orchestrator process.
Shell scripts handle state mutation + step file delivery only. No decisions.

## Hooks

Two hooks in `~/.claude/settings.json` enforce workflow discipline:

### Stop hook (`stop-guard.sh`)
- Fires when the agent tries to end its turn
- If `.workflow/state.json` exists with `status: "running"`:
  - Current step in `INTERRUPT_STEPS` array → allow (exit 0)
  - `interrupted: true` → allow + reset flag
  - `interrupted: true` → allow + reset flag (set by `scripts/agent-interrupt.sh`)
  - Otherwise → block with reason message
- No workflow active → silent exit 0

### UserPromptSubmit hook (`user-interrupt.sh`)
- Fires when user sends a message
- If workflow is running → sets `interrupted: true` in state.json
- Injects `additionalContext` telling agent to respond to user first
- No workflow active → silent exit 0

The two hooks cooperate: UserPromptSubmit sets the flag, Stop reads + resets it.

## Preflight

`lib/preflight-check.sh` runs at the start of `init-workflow.sh`, before state.json creation.
Deterministic shell checks — no LLM involvement in the normal case.

Checks: tools (jq, gh, uv), global config identity, git exclude entries.
Auto-fixes: adds `.specify/`, `specs/`, `.workflow/` to .git/info/exclude if missing.

The old step-based preflight (001-004) has been removed.

## CI/Review Observer Scripts

### `scripts/observe-ci.sh <PR>`
- Auto-detects CI platform from filesystem (`.github/workflows/` → github-actions)
- Queries GitHub API for check-run statuses
- Outputs JSON with `next_action`: `WAIT`, `FETCH_LOGS_AND_FIX`, `DONE`, `ALERT_USER`
- Handles edge cases: draft PR, rebase conflict, no CI configured, checks not registered yet
- Step 051 branches on `next_action` without interpreting raw API data

### `scripts/observe-reviews.sh <PR>`
- Fetches reviews, review comments, issue comments via GitHub API
- Saves snapshots to `.workflow/observations/reviews-<PR>.json`
- Diffs against previous snapshot to detect:
  - New reviews/comments
  - **Modified comments** (same id, changed `updated_at`) ← key feature
  - Bot vs human commenters (auto-detected from `user.type`)
- Outputs markdown report that the agent reads directly
- Step 061 acts on the report without calling `gh api` itself

### Adding a new CI platform
1. Add detection in `observe-ci.sh`'s `detect_ci_platform()` function
2. Add a platform-specific branch below the github-actions block
3. Output the same JSON schema — the step files don't change

## State Machine

```
init-workflow.sh
  → creates state.json with steps[*].status = "pending"
  → marks first step "running"
  → outputs first step file

complete-step.sh <KEY>
  → marks KEY "completed"
  → finds next "pending" step → marks it "running"
  → outputs its step file
  → if no pending steps → "ALL STEPS COMPLETED"

resume-workflow.sh
  → finds current "running" step
  → outputs its step file
```

Dict insertion order = execution order. No separate DAG definition.

## Step Files

Each step is a markdown checklist in the skill directory.
`step-registry.json` maps step keys to filenames.
`track-steps.json` defines which steps each track includes.

Step files are **never read directly by the agent** — only delivered via script stdout.

### Adding a step
1. Create `NNN-step-name.md` with checklist
2. Add `"STEP_KEY": "NNN-step-name.md"` to `step-registry.json`
3. Add `"STEP_KEY"` to the appropriate track(s) in `track-steps.json` at the desired position

### Halt-allowed steps
Steps that genuinely need user input must be added to the `INTERRUPT_STEPS` array in `stop-guard.sh`.
Without this, the Stop hook will block the agent from pausing at that step.

## File Layout

```
${CLAUDE_PLUGIN_ROOT}/skills/wf/
├── SKILL.md              ← Agent reads this (execution rules)
├── INTERNALS.md          ← You're reading this (modification guide)
├── helpers.yaml            ← Agent reads this (shared protocols)
├── stop-guard.sh         ← Stop hook (interrupt prevention, path-pinned in settings.json)
├── user-interrupt.sh     ← UserPromptSubmit hook (interrupt flag, path-pinned)
├── step-registry.json    ← Step key → filename mapping
├── track-steps.json      ← Track → step key list
├── lib/                  ← Internal scripts (called by skill framework)
│   ├── init-workflow.sh          ← Creates state.json + first step
│   ├── complete-step.sh          ← State transition + next step delivery
│   ├── resume-workflow.sh        ← Resumes from current running step
│   ├── rewind-step.sh            ← Reset steps to pending (for loops)
│   ├── get-data.sh               ← Read data.<key> from state.json
│   ├── set-data.sh               ← Write data.<key> to state.json
│   ├── env-check.sh              ← Capability check (worktree + settings.json + deps)
│   ├── install-hooks.sh          ← Runtime wf hook injection
│   ├── preflight-check.sh        ← Setup readiness check (<1s)
│   └── cleanup-stale-worktrees.sh
├── scripts/              ← Step utilities (called from step .md via bash)
│   ├── observe-ci.sh             ← Deterministic CI status observer
│   ├── observe-reviews.sh        ← Deterministic review diff observer
│   ├── agent-interrupt.sh             ← Agent-initiated interrupt (sets interrupted flag)
│   └── check-merge-status.sh     ← Verify PR merge state via gh API
├── internal/             ← Internals docs (for humans modifying the skill)
└── 0*.md, 09*.md         ← Step files (never read directly)
```
