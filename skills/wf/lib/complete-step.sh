#!/usr/bin/env bash
# Usage: bash ${CLAUDE_PLUGIN_ROOT}/skills/wf/lib/complete-step.sh <STEP_KEY>
#
# 1. Marks the given step as completed in .workflow/state.json (control.steps)
# 2. Finds the next pending step
# 3. Outputs the next step file content so it lands in the agent's context
set -euo pipefail

STEP="${1:?Usage: complete-step.sh <STEP_KEY>}"
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

step = '$STEP'
skill_dir = '$SKILL_DIR'
registry_path = '$REGISTRY'

with open('$STATE') as f:
    state = json.load(f)

with open(registry_path) as f:
    registry = json.load(f)

ctrl = state['control']

if step not in ctrl['steps']:
    print(f'ERROR: step {step} not found in control.steps', file=sys.stderr)
    sys.exit(1)

ctrl['steps'][step]['status'] = 'completed'
ctrl['updated_at'] = datetime.now().isoformat()
ctrl['interrupted'] = False
ctrl['interrupt_reason'] = ''

next_step = None
for key, val in ctrl['steps'].items():
    if val['status'] == 'pending':
        next_step = key
        break

if next_step:
    ctrl['steps'][next_step]['status'] = 'running'
    ctrl['current_step'] = next_step
else:
    ctrl['status'] = 'completed'
    ctrl['current_step'] = ''

with open('$STATE', 'w') as f:
    json.dump(state, f, indent=2)

if next_step is None:
    print()
    print('=' * 60)
    print('ALL STEPS COMPLETED — workflow done.')
    print('=' * 60)
else:
    filename = registry.get(next_step)
    if not filename:
        print(f'ERROR: {next_step} not found in step-registry.json', file=sys.stderr)
        sys.exit(1)

    filepath = os.path.join(skill_dir, filename)
    if not os.path.exists(filepath):
        print(f'ERROR: {filepath} not found', file=sys.stderr)
        sys.exit(1)

    step_keys = list(ctrl['steps'].keys())
    total = len(step_keys)
    completed_count = sum(1 for v in ctrl['steps'].values() if v['status'] == 'completed')
    current_num = completed_count + 1

    print()
    print(f'[{current_num}/{total}] {next_step}')
    print('\u2501' * 41)
    print('Next step exists. Follow the instructions below exactly.')
    print('\u2501' * 41)
    print()
    import subprocess
    subprocess.run(
        ['python3', os.path.join(skill_dir, 'lib', 'render-step.py'), filepath],
        check=True,
    )
"
