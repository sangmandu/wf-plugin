# Step 091: COMPOUND_STORE


## Purpose

Store findings as memory files with confidence scoring.

## Checklist

- [ ] Synthesize findings from all 3 agents
- [ ] For each finding, search existing memory files in the project's memory directory at `~/.claude/projects/<project-path-slug>/memory/` (derive the slug from the absolute project path, replacing `/` with `-`):

  **Existing pattern found** → update the memory file:
  - Increment `confidence` (cap at 1.0)
  - Append new evidence (PR url, date)
  - If confidence >= 0.8 AND 3+ observations → suggest skill promotion in the final step

  **New pattern** → create memory file:
  - Type: `feedback` or `project`
  - `confidence: 0.3`, `observations: 1`
  - Include: Problem, Root Cause, Solution, Prevention sections
  - Update `MEMORY.md` index

  **Nothing meaningful** → skip storage

## Verify

- [ ] Memory files have valid frontmatter and are indexed in MEMORY.md
- [ ] No duplicate memories created (same pattern = update, not create)

Per `helpers#state_transition` — complete `COMPOUND_STORE`
