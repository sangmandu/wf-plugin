#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────
# wf — single entry point
#
# Hides internal layout (lib/, scripts/) from SKILL.md.
# Dispatches to the appropriate script based on subcommand.
# ─────────────────────────────────────────────────────────

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$(git rev-parse --show-toplevel)"
CMD="${1:-}"
shift || true

case "$CMD" in
  init)
    exec bash "$SKILL_DIR/lib/init-workflow.sh" "$@"
    ;;
  resume)
    exec bash "$SKILL_DIR/lib/resume-workflow.sh" "$@"
    ;;
  complete)
    exec bash "$SKILL_DIR/lib/complete-step.sh" "$@"
    ;;
  interrupt)
    exec bash "$SKILL_DIR/scripts/agent-interrupt.sh" "$@"
    ;;
  *)
    cat >&2 <<EOF
Usage: wf/run.sh <command> [args]

Commands:
  init <track> "<description>"   Start a new workflow
  resume                         Resume the current workflow
  complete <STEP_KEY>            Mark step done and get the next one
  interrupt "<reason>"           Signal that the agent needs user input
EOF
    exit 2
    ;;
esac
