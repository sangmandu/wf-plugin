#!/usr/bin/env bash
# Usage: bash ${CLAUDE_PLUGIN_ROOT}/skills/wf/lib/resume-workflow.sh
#
# Finds the current running or first pending step and outputs its file content.
# Used when resuming a workflow from a previous session.
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REGISTRY="$SKILL_DIR/step-registry.json"
STATE=".workflow/state.json"

if [[ ! -f "$STATE" ]]; then
  echo "ERROR: $STATE not found. Are you in the worktree?" >&2
  exit 1
fi

python3 -c "
import json, os, sys
from datetime import datetime

skill_dir = '$SKILL_DIR'

with open('$STATE') as f:
    state = json.load(f)

with open('$REGISTRY') as f:
    registry = json.load(f)

ctrl = state['control']

# Clear interrupt flag on resume
ctrl['interrupted'] = False
ctrl['interrupt_reason'] = ''
with open('$STATE', 'w') as f:
    json.dump(state, f, indent=2)

# Find current step: first 'running', then first 'pending'
current_step = None
for key, val in ctrl['steps'].items():
    if val['status'] == 'running':
        current_step = key
        break

if not current_step:
    for key, val in ctrl['steps'].items():
        if val['status'] == 'pending':
            current_step = key
            ctrl['steps'][key]['status'] = 'running'
            ctrl['current_step'] = key
            ctrl['updated_at'] = datetime.now().isoformat()
            with open('$STATE', 'w') as f:
                json.dump(state, f, indent=2)
            break

if not current_step:
    print('ALL STEPS COMPLETED — workflow done.')
    sys.exit(0)

filename = registry.get(current_step)
if not filename:
    print(f'ERROR: {current_step} not found in step-registry.json', file=sys.stderr)
    sys.exit(1)

filepath = os.path.join(skill_dir, filename)
if not os.path.exists(filepath):
    print(f'ERROR: {filepath} not found', file=sys.stderr)
    sys.exit(1)

step_keys = list(ctrl['steps'].keys())
total = len(step_keys)
completed_count = sum(1 for v in ctrl['steps'].values() if v['status'] == 'completed')
current_num = completed_count + 1

print(f'[{current_num}/{total}] {current_step}')
print('\u2501' * 41)
print('Resuming workflow. Follow the instructions below exactly.')
print('\u2501' * 41)
print()
import subprocess
subprocess.run(
    ['python3', os.path.join(skill_dir, 'lib', 'render-step.py'), filepath],
    check=True,
)
"
