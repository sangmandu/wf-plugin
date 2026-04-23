# Step 001: SETUP

Prepare the worktree for work: ensure the per-repo config exists, run its setup commands, and record worktree identifiers. PR creation happens later in the PR step.

## Ensure project_name is set

- [ ] ```bash
  PROJECT_NAME="$(basename "$(git rev-parse --path-format=absolute --git-common-dir | xargs dirname)")"
  bash <WF_DIR>/lib/set-data.sh project_name "$PROJECT_NAME"
  ```

## Ensure repo config exists

- [ ] Run `bash <WF_DIR>/lib/ensure-repo-config.sh`
  - Exit 0 → config already exists, continue.
  - Exit 10 (NO_REPO_SECTION) → stdout contains a suggested `[repos.<project>]` TOML block. Show it to the user, confirm or adjust, then append the block to `~/.config/wf/wf_config.toml`. Re-run the script to verify exit 0.
  - Any other non-zero → step failure.

## Run repo-specific setup

- [ ] Run `bash <WF_DIR>/lib/run-repo-setup.sh`
  - Exit 0 → done.
  - Any non-zero → a configured command failed; treat as step failure.

## Ensure speckit is initialized

- [ ] Check if `.specify/` directory exists in the repo root (NOT the worktree — check the main repo via `git rev-parse --path-format=absolute --git-common-dir | xargs dirname`).
  - If `.specify/` exists in the main repo → copy it to the worktree root if not already present: `cp -R <main_repo>/.specify .specify`
  - If `.specify/` does NOT exist anywhere:
    1. Ensure `specify` CLI is installed globally:
       ```bash
       command -v specify >/dev/null 2>&1 || uv tool install specify-cli --from "git+https://github.com/github/spec-kit.git"
       ```
    2. Initialize speckit in the worktree:
       ```bash
       specify init --here
       ```
    This creates `.specify/` with templates, scripts, and config. The `--here` flag initializes in the current directory.
- [ ] Verify `.specify/` exists after the above step. If initialization failed, treat as a non-blocking warning (speckit is optional — the SPECIFY step can fallback to manual spec writing).

## Record worktree identifiers

- [ ] Persist into `.workflow/state.json` via `lib/set-data.sh`:
  ```bash
  bash <WF_DIR>/lib/set-data.sh worktree_path "$PWD"
  bash <WF_DIR>/lib/set-data.sh branch_name "$(git branch --show-current)"
  ```

Per `helpers#state_transition` — complete `SETUP`
