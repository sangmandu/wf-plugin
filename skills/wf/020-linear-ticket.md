# Step 020: LINEAR_TICKET

Per `helpers#load_config` — read `~/.config/wf/wf_config.toml`

## Prerequisites

- [ ] Follow the **hook-injected Linear Guide** (`~/.claude/guides/linear.md`, auto-injected as `📌 Linear Guide` system-reminder). This is the single source of truth for all Linear ticket rules.

## Checklist

- [ ] **Existing ticket**: If the user explicitly mentioned a ticket ID → use it and skip creation.
- [ ] **Creation policy**:
  - `feature` / `fix` tracks → always create a new ticket.
  - `light` track → evaluate the change nature from `task_description`:
    - **Skip creation** (no ticket) for:
      - skill / prompt / docs / md-only edits under `.claude/`, `~/.claude/`, `docs/`, `README*`
      - config-only edits (e.g. `.toml`, `.json`, `.yml`) with no runtime code touched
      - typo / comment-only fixes
    - **Create** for everything else (any code under `apps/`, `libs/`, `src/`, shell scripts, CI pipelines, etc.)
    - **Ambiguous** (mix of docs + code, unclear scope) → ask the user once: "Create a Linear ticket for this? (y/n)"
  - When skipping, mark this step complete with `[skip] light track — no ticket for {reason}` and proceed.
- [ ] Draft ticket content from `task_description` (spec.md/plan.md not yet available at this stage)
- [ ] Determine 3 mandatory labels (Cost, Activity Type, Core Layer) — UUIDs per hook Linear Guide
- [ ] `mcp__linear__save_issue` — follow all rules from the hook Linear Guide (title, description template, assignee, team, project, milestone, labels)

Per `helpers#state_transition` — save `ticket_id` + top-level
Per `helpers#state_transition` — complete `LINEAR_TICKET`
