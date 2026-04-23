#!/usr/bin/env bash
# cleanup-stale-worktrees.sh
#
# Auto-remove worktrees under .claude/worktrees/*/ whose .workflow/state.json
# has not been touched in more than THRESHOLD_SECONDS (default 7 days).
#
# Deterministic cleanup — invoked by wf step 000 (CLEANUP). No LLM judgment
# required: mtime > threshold → remove. Active worktrees are left alone.
#
# Usage:
#   bash ${CLAUDE_PLUGIN_ROOT}/skills/wf/cleanup-stale-worktrees.sh [threshold_seconds]
#
# Output:
#   [cleanup] removed <branch> (idle <N>d)   # per stale worktree removed
#   [cleanup] kept <branch> (idle <N>d)      # per active worktree
#   [cleanup] done: removed=<X> kept=<Y>     # summary

set -euo pipefail

THRESHOLD_SECONDS="${1:-604800}"  # default 7 days
NOW=$(date +%s)
REMOVED=0
KEPT=0

# Must run from repo root (where .claude/worktrees/ lives). If not found, exit
# silently — there's nothing to clean up.
if [ ! -d ".claude/worktrees" ]; then
  echo "[cleanup] no .claude/worktrees/ directory — nothing to do"
  exit 0
fi

for state in .claude/worktrees/*/.workflow/state.json; do
  [ -f "$state" ] || continue
  wt_dir=$(dirname "$(dirname "$state")")
  branch=$(basename "$wt_dir")

  # macOS stat syntax; fall back to GNU stat for Linux.
  if mtime=$(stat -f %m "$state" 2>/dev/null); then
    :
  else
    mtime=$(stat -c %Y "$state")
  fi

  age=$(( NOW - mtime ))
  age_days=$(( age / 86400 ))

  if [ "$age" -gt "$THRESHOLD_SECONDS" ]; then
    echo "[cleanup] removed $branch (idle ${age_days}d)"
    git worktree remove --force "$wt_dir" 2>/dev/null || rm -rf "$wt_dir"
    REMOVED=$(( REMOVED + 1 ))
  else
    echo "[cleanup] kept $branch (idle ${age_days}d)"
    KEPT=$(( KEPT + 1 ))
  fi
done

# Prune any dangling worktree administrative records (safe no-op if none).
git worktree prune 2>/dev/null || true

echo "[cleanup] done: removed=${REMOVED} kept=${KEPT}"
