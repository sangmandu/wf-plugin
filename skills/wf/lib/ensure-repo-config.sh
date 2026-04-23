#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────
# ensure-repo-config.sh — guarantee [repos.<project>] exists
# in ${CLAUDE_PLUGIN_ROOT}/skills/wf/config/wf_config.toml
#
# If the section exists, exits 0 silently (no-op).
# Otherwise, scans the repo for setup signals and prints a
# suggested TOML block to stdout — the agent then confirms
# with the user and appends it to wf_config.toml.
#
# Exit codes:
#   0   — section present, nothing to do
#   10  — section missing; stdout has suggested block + append target
#   1   — state/project_name missing, or unrecoverable
# ─────────────────────────────────────────────────────────

STATE=".workflow/state.json"
[[ -f "$STATE" ]] || { echo "ERROR: $STATE not found" >&2; exit 1; }

PROJECT="$(jq -r '.data.project_name // ""' "$STATE")"
[[ -n "$PROJECT" ]] || { echo "ERROR: data.project_name not set in state.json" >&2; exit 1; }

CONFIG="$HOME/.claude/skills/wf/config/wf_config.toml"
[[ -f "$CONFIG" ]] || { echo "ERROR: $CONFIG not found" >&2; exit 1; }

# Already registered → done
if python3 "$HOME/.claude/skills/wf/lib/config.py" --has-repo "$PROJECT" >/dev/null 2>&1; then
  exit 0
fi

# ── Scan repo root for setup signals ──
ROOT="$(git rev-parse --show-toplevel)"

commands=()
[[ -f "$ROOT/mise.toml" || -f "$ROOT/.mise.toml" ]] && commands+=("mise trust && mise install")
[[ -f "$ROOT/pyproject.toml" && -f "$ROOT/uv.lock" ]] && commands+=("uv sync")
if [[ -f "$ROOT/package.json" ]]; then
  if   [[ -f "$ROOT/pnpm-lock.yaml" ]]; then commands+=("pnpm install")
  elif [[ -f "$ROOT/yarn.lock"      ]]; then commands+=("yarn install")
  elif [[ -f "$ROOT/package-lock.json" ]]; then commands+=("npm install")
  fi
fi
if [[ -f "$ROOT/Makefile" ]] && grep -qE '^(bootstrap|setup):' "$ROOT/Makefile"; then
  commands+=("make bootstrap")
fi

copy_patterns=()
for f in .env.local .env.development .env.example; do
  [[ -f "$ROOT/$f" ]] && copy_patterns+=("$f")
done

# ── Emit suggestion ──
{
  echo "[ensure-repo-config] NO_REPO_SECTION"
  echo "Append the following block to: $CONFIG"
  echo "(confirm with user before writing; adjust detected commands if wrong.)"
  echo "---"
  echo "[repos.$PROJECT]"
  echo "setup_commands = ["
  for c in "${commands[@]-}"; do [[ -n "$c" ]] && echo "  \"$c\","; done
  echo "]"
  echo "worktree_copy_from_main = ["
  for p in "${copy_patterns[@]-}"; do [[ -n "$p" ]] && echo "  \"$p\","; done
  echo "]"
  echo "ci_checks = []"
  echo "---"
} >&1

exit 10
