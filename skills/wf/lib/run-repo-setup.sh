#!/usr/bin/env bash
set -euo pipefail

WF_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# ─────────────────────────────────────────────────────────
# run-repo-setup.sh — execute per-repo setup commands
#
# Reads data.project_name from .workflow/state.json, looks up
# [repos.<project>] in wf_config.toml,
# runs each entry in setup_commands and then copies any
# worktree_copy_from_main files from the main repo.
#
# Exit codes:
#   0   — commands ran successfully (or section exists with empty arrays)
#   10  — repo section missing (agent should run ensure-repo-config.sh,
#         ping-pong user, append the block, then re-run)
#   1   — any other failure (missing state/config, command failed)
# ─────────────────────────────────────────────────────────

STATE=".workflow/state.json"
[[ -f "$STATE" ]] || { echo "ERROR: $STATE not found" >&2; exit 1; }

PROJECT="$(jq -r '.data.project_name // ""' "$STATE")"
[[ -n "$PROJECT" ]] || { echo "ERROR: data.project_name not set in state.json" >&2; exit 1; }

CONFIG_PY="$WF_ROOT/lib/config.py"

if ! python3 "$CONFIG_PY" --has-repo "$PROJECT" >/dev/null 2>&1; then
  echo "[run-repo-setup] No [repos.$PROJECT] section — run ensure-repo-config.sh first." >&2
  exit 10
fi

COMMANDS=()
while IFS= read -r line; do [[ -n "$line" ]] && COMMANDS+=("$line"); done < <(python3 "$CONFIG_PY" "repos.$PROJECT.setup_commands" 2>/dev/null || true)

COPY_PATTERNS=()
while IFS= read -r line; do [[ -n "$line" ]] && COPY_PATTERNS+=("$line"); done < <(python3 "$CONFIG_PY" "repos.$PROJECT.worktree_copy_from_main" 2>/dev/null || true)

# ── Run setup_commands ──
if (( ${#COMMANDS[@]-0} == 0 )); then
  echo "[run-repo-setup] No commands configured — skipping."
else
  for cmd in "${COMMANDS[@]}"; do
    echo "[run-repo-setup] \$ $cmd"
    bash -c "$cmd" || { echo "[run-repo-setup] FAILED: $cmd" >&2; exit 1; }
  done
fi

# ── Copy gitignored files from the main repo ──
if (( ${#COPY_PATTERNS[@]-0} > 0 )); then
  MAIN_REPO="$(git rev-parse --path-format=absolute --git-common-dir | xargs dirname)"
  for pat in "${COPY_PATTERNS[@]}"; do
    while IFS= read -r src; do
      rel="${src#$MAIN_REPO/}"
      dest="$PWD/$rel"
      mkdir -p "$(dirname "$dest")"
      cp "$src" "$dest"
      echo "[run-repo-setup] copied $rel"
    done < <(find "$MAIN_REPO" -name "$pat" -not -path "*/node_modules/*" -not -path "*/.claude/worktrees/*" 2>/dev/null)
  done
fi

echo "[run-repo-setup] done."
