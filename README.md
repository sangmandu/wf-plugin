# wf — Claude Code Plugin

End-to-end automated dev workflow plugin for Claude Code.

## Tracks

| Command | Track | Use case |
|---|---|---|
| `/wf <task>` | feature | New features, refactors, planned changes |
| `/fix <bug>` | fix | Bug fix with mandatory reproduction gate |
| `/light <task>` | light | Config, docs, dependency bumps, typo fixes |
| `/brainstorm <topic>` | brainstorm | Idea exploration, no code changes |

## Installation

```bash
claude plugin add ~/wf-plugin
```

## Configuration

Copy and edit the config template:

```bash
cp ~/wf-plugin/templates/config.example.toml ~/.claude/skills/wf/config/wf_config.toml
```

Or run `/setup` after installing the plugin.

## Hooks

Guard hooks are in `hooks/hooks.example.json`. To enable:

```bash
cp hooks/hooks.example.json hooks/hooks.json
```

## Local Smoke Test

```bash
claude plugin validate ~/wf-plugin
```
