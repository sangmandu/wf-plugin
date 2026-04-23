# wf-plugin

## Versioning (Semver)

| Segment | When | Examples |
|---|---|---|
| **X.0.0** (major) | Breaking changes: step structure, state.json schema, track add/remove, incompatible with running workflows | step-registry reorganization, new required state fields |
| **X.Y.0** (minor) | New features, backward-compatible | speckit auto-install, new command, new helper script |
| **X.Y.Z** (patch) | Bug fixes, config/path fixes, interrupt step adjustments | f-string fix, interrupt list change, doc typo |

Update version in both files:
- `.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json`

## Config Location

User config lives at `~/.config/wf/wf_config.toml` (outside plugin cache, writable).

## Sub-Agent Rules

When dispatching sub-agents, MUST invoke the `/subagent` skill first and follow its protocol.

## Path Rules

- Shell scripts: use `WF_ROOT="$(cd "$(dirname "$0")/.." && pwd)"` for self-locating
- Step md files: use `<WF_DIR>` placeholder — the model derives the actual path from where SKILL.md was loaded
- Never use `$CLAUDE_PLUGIN_ROOT` in runtime code (only available in command files, not in bash calls)
- Never hardcode `~/.claude/skills/wf/` or `$HOME/.claude/skills/wf/`
