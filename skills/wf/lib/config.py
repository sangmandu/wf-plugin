#!/usr/bin/env python3
"""Shared reader for ~/.config/wf/wf_config.toml.

Usage (CLI):
  config.py identity.user_id
  config.py repos.mally.setup_commands          # array → newline-separated
  config.py repos.mally.ci_checks --json        # raw JSON of the value
  config.py --has-repo mally                    # exit 0/1
  config.py --list-repo-keys mally              # one key per line
"""
import json
import os
import sys
import tomllib

CONFIG_PATH = os.path.expanduser("~/.config/wf/wf_config.toml")


def load():
    if not os.path.exists(CONFIG_PATH):
        sys.stderr.write(f"ERROR: {CONFIG_PATH} not found\n")
        sys.exit(2)
    with open(CONFIG_PATH, "rb") as f:
        return tomllib.load(f)


def dig(data, path):
    cur = data
    for part in path.split("."):
        if not isinstance(cur, dict) or part not in cur:
            return None
        cur = cur[part]
    return cur


def main():
    args = sys.argv[1:]
    if not args:
        sys.stderr.write(__doc__)
        return 2

    data = load()

    if args[0] == "--has-repo":
        return 0 if dig(data, f"repos.{args[1]}") is not None else 1

    if args[0] == "--list-repo-keys":
        repo = dig(data, f"repos.{args[1]}")
        if not isinstance(repo, dict):
            return 1
        print("\n".join(repo.keys()))
        return 0

    if args[0] == "--list-repos":
        repos = data.get("repos") or {}
        print("\n".join(repos.keys()))
        return 0

    key = args[0]
    as_json = "--json" in args[1:]
    val = dig(data, key)
    if val is None:
        return 1
    if as_json:
        print(json.dumps(val, ensure_ascii=False))
        return 0
    if isinstance(val, list):
        for item in val:
            print(item if not isinstance(item, (dict, list)) else json.dumps(item, ensure_ascii=False))
        return 0
    if isinstance(val, bool):
        print("true" if val else "false")
        return 0
    print(val)
    return 0


if __name__ == "__main__":
    sys.exit(main())
