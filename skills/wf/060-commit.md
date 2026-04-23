# Step 060: COMMIT

Per `helpers#git_rules`

## Checklist

### Record findings to Linear ticket

- [ ] If the workflow produced notable findings, experiment results, investigation logs, or decisions:
  - [ ] Update the Linear ticket description with the results using `mcp__linear__save_issue`
  - [ ] Include: benchmark data, comparison tables, investigation conclusions, architecture decisions
  - [ ] Attach relevant links (PR, external resources, documentation)
  - [ ] This ensures the ticket serves as the single source of truth, not just the PR body
- [ ] If no notable findings (simple code change) → skip this section

### Stage and commit

- [ ] Stage only relevant files — **NEVER `git add -A`**
- [ ] Commit:

  ```bash
  git commit -m "$(cat <<'EOF'
  type(scope): [TICKET-ID] Description

  Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
  EOF
  )"
  ```

- [ ] Do NOT push yet — PR updates the PR title/body first, then pushes. This ensures the review bot sees the correct PR description when CI triggers.

Per `helpers#state_transition` — complete `COMMIT`
