#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────
# discover-ci.sh — populate [repos.<project>].ci_checks in
# ${CLAUDE_PLUGIN_ROOT}/skills/wf/config/wf_config.toml by inspecting the
# repo's CI config files and (optionally) a recent PR.
#
# Behavior:
#   - If ci_checks is already non-empty → exit 0, no-op.
#   - Else scan:
#       · .github/workflows/*.{yml,yaml} for `on: pull_request`
#         → collect `name:` fields (GitHub Actions display names)
#       · Jenkinsfile, .gitlab-ci.yml, .circleci/config.yml etc.
#         → mark as external CI (presence only; context strings
#           are harvested from a recent PR probe below)
#       · gh pr view <recent merged or open PR> --json
#         statusCheckRollup → external context names
#   - Merge, dedupe, write back.
#   - If nothing found → write ["__none__"].
# ─────────────────────────────────────────────────────────

STATE=".workflow/state.json"
[[ -f "$STATE" ]] || { echo "ERROR: $STATE not found" >&2; exit 1; }

PROJECT="$(jq -r '.data.project_name // ""' "$STATE")"
[[ -n "$PROJECT" ]] || { echo "ERROR: data.project_name not set" >&2; exit 1; }

CONFIG="$HOME/.claude/skills/wf/config/wf_config.toml"
CONFIG_PY="$HOME/.claude/skills/wf/lib/config.py"

# Check if already populated.
existing="$(python3 "$CONFIG_PY" "repos.$PROJECT.ci_checks" --json 2>/dev/null || echo '[]')"
if [ "$existing" != "[]" ] && [ "$existing" != "null" ]; then
  echo "[discover-ci] ci_checks already set for $PROJECT → skip"
  exit 0
fi

ROOT="$(git rev-parse --show-toplevel)"
declare -a CHECKS=()

# ── 1. Probe a recent PR's statusCheckRollup (PRIMARY SOURCE) ──
# This is the authoritative source because it reports exactly the names
# observe-ci.sh will see at runtime (job names for CheckRuns, context strings
# for external StatusContexts like Jenkins). YAML `name:` fields do NOT match
# because rollups expose job-level slugs, not workflow display names.
if command -v gh >/dev/null 2>&1; then
  sample_pr="$(gh pr list --state all --limit 1 --json number --jq '.[0].number' 2>/dev/null || true)"
  if [ -n "${sample_pr:-}" ]; then
    while IFS= read -r ctx; do
      [ -n "$ctx" ] && CHECKS+=("$ctx")
    done < <(gh pr view "$sample_pr" --json statusCheckRollup --jq \
      '.statusCheckRollup[] | (.context // .name) // empty' 2>/dev/null || true)
  fi
fi

# ── 2. YAML fallback (only if rollup probe yielded nothing) ──
# Workflow `name:` fields are used here as a best-effort floor for repos with
# no prior PRs. Observer may not match perfectly until first PR registers real
# names; CI_SETUP can be re-run then.
if [ ${#CHECKS[@]} -eq 0 ] && [ -d "$ROOT/.github/workflows" ]; then
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    if ! grep -qE '^\s*pull_request\s*:' "$f" 2>/dev/null \
       && ! grep -qE '^on:\s*pull_request' "$f" 2>/dev/null; then
      continue
    fi
    name="$(awk '/^name:/ { sub(/^name:[[:space:]]*/, ""); gsub(/^["'\''"]|["'\''"]$/, ""); print; exit }' "$f")"
    [ -n "$name" ] && CHECKS+=("$name")
  done < <(find "$ROOT/.github/workflows" -maxdepth 1 -type f \( -name '*.yml' -o -name '*.yaml' \))
fi

# ── 3. External CI presence detection (for logging only) ──
external=""
{ [ -f "$ROOT/Jenkinsfile" ] || [ -f "$ROOT/ops/Jenkinsfile" ]; } && external="$external jenkins"
[ -f "$ROOT/.gitlab-ci.yml" ] && external="$external gitlab"
[ -f "$ROOT/.circleci/config.yml" ] && external="$external circleci"
[ -f "$ROOT/.buildkite/pipeline.yml" ] && external="$external buildkite"

# ── 4. Dedupe, filter empty ──
if [ ${#CHECKS[@]} -eq 0 ]; then
  FINAL='["__none__"]'
  echo "[discover-ci] no CI detected → writing sentinel __none__"
else
  FINAL="$(printf '%s\n' "${CHECKS[@]}" | awk 'NF' | sort -u | jq -R . | jq -s -c .)"
  echo "[discover-ci] discovered ${#CHECKS[@]} raw entries → $FINAL"
fi

[ -n "$external" ] && echo "[discover-ci] external CI markers:$external"

# ── 5. Rewrite ci_checks line in-place ──
export WFC_PROJECT="$PROJECT"
export WFC_VALUE="$FINAL"
python3 - "$CONFIG" <<'PY'
# Line-based editor: finds the target [repos.<project>] section and
# replaces its `ci_checks = ...` line, or injects one after the header.
# Safe against inline arrays containing `[`.
import os, re, sys

path = sys.argv[1]
project = os.environ["WFC_PROJECT"]
value   = os.environ["WFC_VALUE"]

target_header = f"[repos.{project}]"
section_re = re.compile(r"^\s*\[[^\]]+\]\s*$")
ci_line_re = re.compile(r"^\s*ci_checks\s*=")

with open(path) as f:
    lines = f.readlines()

in_section = False
header_idx = -1
ci_idx = -1
section_end_idx = len(lines)  # exclusive

for i, ln in enumerate(lines):
    stripped = ln.strip()
    if stripped == target_header:
        in_section = True
        header_idx = i
        continue
    if in_section:
        if section_re.match(ln) and stripped != target_header:
            section_end_idx = i
            break
        if ci_line_re.match(ln):
            ci_idx = i

if header_idx < 0:
    sys.stderr.write(f"ERROR: [repos.{project}] section not found\n")
    sys.exit(1)

new_line = f"ci_checks = {value}\n"
if ci_idx >= 0:
    lines[ci_idx] = new_line
else:
    lines.insert(header_idx + 1, new_line)

with open(path, "w") as f:
    f.writelines(lines)
print(f"[discover-ci] wrote ci_checks to [repos.{project}]")
PY
