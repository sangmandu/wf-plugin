---
description: Start the default wf feature workflow
argument-hint: '<task>'
disable-model-invocation: true
allowed-tools: Bash
---

Run:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/wf/run.sh" init feature "$ARGUMENTS"
```
