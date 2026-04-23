#!/usr/bin/env python3
"""Render a step file for delivery to the agent.

Emits:
  1. The step file body as-is.
  2. "Always-applied helpers" block (every `always.*` section in helpers.yaml).
  3. "Step-specific helpers" block — every `on_demand.<key>` whose key appears
     in the step body via the `helpers#<key>` reference pattern.

Usage: render-step.py <step-filepath>
"""
import os
import re
import sys

try:
    import yaml
except ImportError:
    sys.stderr.write(
        "ERROR: PyYAML is required. Install with `pip install pyyaml` or "
        "`brew install libyaml && pip install pyyaml`.\n"
    )
    sys.exit(1)


SKILL_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HELPERS_PATH = os.path.join(SKILL_DIR, "helpers.yaml")
ANCHOR_RE = re.compile(r"helpers#([a-z][a-z0-9_]*)")


def main() -> int:
    if len(sys.argv) != 2:
        sys.stderr.write("Usage: render-step.py <step-filepath>\n")
        return 2

    step_path = sys.argv[1]
    if not os.path.exists(step_path):
        sys.stderr.write(f"ERROR: step file not found: {step_path}\n")
        return 1
    if not os.path.exists(HELPERS_PATH):
        sys.stderr.write(f"ERROR: helpers.yaml not found at {HELPERS_PATH}\n")
        return 1

    with open(step_path) as f:
        body = f.read()
    with open(HELPERS_PATH) as f:
        helpers = yaml.safe_load(f) or {}

    always = helpers.get("always") or {}
    on_demand = helpers.get("on_demand") or {}

    print(body, end="" if body.endswith("\n") else "\n")

    if always:
        print()
        print("━━━ Always-applied helpers ━━━")
        for name, section in always.items():
            print()
            print(section["body"].rstrip())

    referenced = []
    seen = set()
    for match in ANCHOR_RE.finditer(body):
        key = match.group(1)
        if key in seen:
            continue
        seen.add(key)
        referenced.append(key)

    if referenced:
        print()
        print("━━━ Step-specific helpers ━━━")
        for key in referenced:
            if key in always:
                continue  # already emitted in the always block
            section = on_demand.get(key)
            if section is None:
                sys.stderr.write(f"WARNING: unknown helper key: helpers#{key}\n")
                continue
            print()
            print(section["body"].rstrip())

    return 0


if __name__ == "__main__":
    sys.exit(main())
