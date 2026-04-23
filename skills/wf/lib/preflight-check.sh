#!/usr/bin/env bash
set -euo pipefail

WF_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

ERRORS=()
FIXES=()
AUTO_FIXED=()

# ── 1. Global config ──
CONFIG="$HOME/.config/wf/wf_config.toml"
if [ ! -f "$CONFIG" ]; then
  ERRORS+=("wf config not found: $CONFIG")
  FIXES+=("Create $CONFIG with [identity] section (user_id, team_id UUIDs from Linear). If lost, see $WF_ROOT/lib/recover-config.md")
elif ! grep -q '^\[identity\]' "$CONFIG" 2>/dev/null; then
  ERRORS+=("wf config missing [identity] section")
  FIXES+=("Add [identity] section with user_id and team_id to $CONFIG (recovery: $WF_ROOT/lib/recover-config.md)")
fi

# ── 2. Required tools ──
check_tool() {
  local name="$1" install_hint="$2"
  if ! command -v "$name" >/dev/null 2>&1; then
    ERRORS+=("$name not found")
    FIXES+=("$install_hint")
  fi
}

check_tool "jq"   "brew install jq"
check_tool "gh"   "brew install gh && gh auth login"
check_tool "uv"   "brew install uv"

# gh auth check (only if gh exists)
if command -v gh >/dev/null 2>&1; then
  if ! gh auth status >/dev/null 2>&1; then
    ERRORS+=("gh not authenticated")
    FIXES+=("Run: gh auth login")
  fi
fi

# ── 3. Git exclude auto-fix ──
ensure_git_exclude() {
  local pattern="$1"
  local git_dir exclude_file
  git_dir="$(git rev-parse --git-dir 2>/dev/null)" || return 0
  exclude_file="$git_dir/info/exclude"
  if [ -f "$exclude_file" ]; then
    if ! grep -qxF "$pattern" "$exclude_file" 2>/dev/null; then
      if ! git check-ignore "$pattern/dummy" >/dev/null 2>&1; then
        echo "$pattern" >> "$exclude_file"
        AUTO_FIXED+=("Added '$pattern' to .git/info/exclude")
      fi
    fi
  fi
}

# speckit (specify) dependencies:
#   .specify/ — speckit tool installation (scripts, memory, config)
#   specs/    — speckit output artifacts (spec.md, plan.md, tasks.md)
ensure_git_exclude ".specify/"
ensure_git_exclude "specs/"

# wf workflow state (not meant for version control)
ensure_git_exclude ".workflow/"

# ── 4. Stale worktree cleanup ──
if [ -f "$WF_ROOT/lib/cleanup-stale-worktrees.sh" ]; then
  bash "$WF_ROOT/lib/cleanup-stale-worktrees.sh" >/dev/null 2>&1 || true
fi

# ── Output ──
if [ ${#AUTO_FIXED[@]} -gt 0 ]; then
  echo "[preflight] Auto-fixed:"
  for fix in "${AUTO_FIXED[@]}"; do
    echo "  ✓ $fix"
  done
fi

if [ ${#ERRORS[@]} -gt 0 ]; then
  echo ""
  echo "[preflight] FAILED — resolve these before continuing:"
  for i in "${!ERRORS[@]}"; do
    echo "  ✗ ${ERRORS[$i]}"
    echo "    → ${FIXES[$i]}"
  done
  exit 1
fi

exit 0
