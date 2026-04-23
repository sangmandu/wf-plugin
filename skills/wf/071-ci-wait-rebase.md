# Step 070: CI_WAIT_REBASE


## Purpose

Rebase onto latest main before CI runs to avoid stale-branch issues.

## Checklist

- [ ] Rebase onto latest main:
  ```bash
  git fetch origin main
  git rebase origin/main
  git push --force-with-lease
  ```
- [ ] Verify no merge conflicts:

  ```bash
  gh pr view <pr-number> --json mergeable,mergeStateStatus --jq '{mergeable, mergeStateStatus}'
  ```

  - If `mergeable: "CONFLICTING"` → resolve conflicts, rebase again, force-push
  - **"no checks reported" + CONFLICTING = conflict is blocking CI**, not "CI passed"

Per `helpers#state_transition` — complete `CI_WAIT_REBASE`
