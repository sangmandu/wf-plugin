---
description: Start a wf fix workflow
argument-hint: '<bug or task>'
disable-model-invocation: true
allowed-tools: Bash
---

Run:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/wf/run.sh" init fix "$ARGUMENTS"
```
