---
description: Start a lightweight wf workflow
argument-hint: '<task>'
disable-model-invocation: true
allowed-tools: Bash
---

Run:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/wf/run.sh" init light "$ARGUMENTS"
```
