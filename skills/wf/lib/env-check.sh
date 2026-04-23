#!/usr/bin/env bash
# Verify the environment can host a wf workflow.
# Checks:
#   1. cwd is inside a cc-managed worktree (.claude/worktrees/*)
#   2. .claude/settings.json exists (needed for runtime hook injection)
#
# Exits non-zero with a message if any check fails.
set -euo pipefail

ROOT="$PWD"

for bin in jq python3 git; do
  command -v "$bin" >/dev/null 2>&1 || {
    echo "error: '$bin' is required but not found in PATH." >&2
    exit 1
  }
done

python3 -c 'import yaml' 2>/dev/null || {
  echo "error: PyYAML is required (render-step.py reads helpers.yaml)." >&2
  echo "hint:  pip install pyyaml" >&2
  exit 1
}

case "$ROOT" in
  */.claude/worktrees/*) ;;
  *)
    cat >&2 <<EOF
error: wf must run inside a cc-managed worktree.
       current cwd: $ROOT
hint:  exit this session and run 'cc' from the main repo to create one.
EOF
    exit 1
    ;;
esac

if [[ ! -f "$ROOT/.claude/settings.json" ]]; then
  cat >&2 <<EOF
error: $ROOT/.claude/settings.json not found.
reason: wf installs hooks into this file at runtime. The Claude Code file
        watcher only tracks files that existed at session start, so creating
        settings.json now would not activate hooks for this session.
hint:  1. In the main repo, create .claude/settings.json with at minimum {}.
       2. Commit it so worktrees inherit it on creation.
       3. Exit this session and run 'cc' again from the main repo.
EOF
  exit 1
fi
