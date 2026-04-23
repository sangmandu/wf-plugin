#!/usr/bin/env bash
# Usage: bash ${CLAUDE_PLUGIN_ROOT}/skills/wf/lib/rewind-step.sh <TARGET_STEP>
#
# Resets TARGET and all steps after it to pending, then jumps to TARGET.
# Uses track-steps.json to determine step order.
set -euo pipefail

TARGET="${1:?Usage: rewind-step.sh <TARGET_STEP>}"

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REGISTRY="$SKILL_DIR/step-registry.json"
TRACK_STEPS="$SKILL_DIR/track-steps.json"
STATE=".workflow/state.json"

if [[ ! -f "$STATE" ]]; then
  echo "ERROR: $STATE not found. Are you in the worktree?" >&2
  exit 1
fi

python3 -c "
import json, os, sys
from datetime import datetime

target = '$TARGET'
skill_dir = '$SKILL_DIR'

with open('$STATE') as f:
    state = json.load(f)

with open('$REGISTRY') as f:
    registry = json.load(f)

with open('$TRACK_STEPS') as f:
    track_steps = json.load(f)

ctrl = state['control']
track = ctrl.get('track', 'feature')
ordered_steps = track_steps.get(track, [])

if target not in ctrl['steps']:
    print(f'ERROR: {target} not in control.steps', file=sys.stderr)
    sys.exit(1)

if target not in ordered_steps:
    print(f'ERROR: {target} not in track {track} step list', file=sys.stderr)
    sys.exit(1)

target_idx = ordered_steps.index(target)
for step_key in ordered_steps[target_idx:]:
    if step_key in ctrl['steps']:
        ctrl['steps'][step_key]['status'] = 'pending'

ctrl['steps'][target]['status'] = 'running'
ctrl['current_step'] = target
ctrl['updated_at'] = datetime.now().isoformat()

with open('$STATE', 'w') as f:
    json.dump(state, f, indent=2)

filename = registry.get(target)
if not filename:
    print(f'ERROR: {target} not in step-registry.json', file=sys.stderr)
    sys.exit(1)

filepath = os.path.join(skill_dir, filename)
step_keys = list(ctrl['steps'].keys())
total = len(step_keys)
completed_count = sum(1 for v in ctrl['steps'].values() if v['status'] == 'completed')
current_num = completed_count + 1

print(f'[{current_num}/{total}] {target} (loop back)')
print('━' * 41)
print('Next step exists. Follow the instructions below exactly.')
print('━' * 41)
print()
with open(filepath) as sf:
    print(sf.read())
"
