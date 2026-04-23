# Step 053: SELF_REVIEW_VERDICT


## Purpose

Evaluate self-review findings and decide whether to fix or proceed. Acts as the quality gate between implementation and commit.

## Checklist

### Load findings

- [ ] Read `self_review_findings` from state.json (saved in SELF_REVIEW step)

### Evaluate findings

- [ ] Count `must_fix` findings
- [ ] Display summary:

```
Self-Review Results
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
must_fix:  N items
suggested: N items
follow_up: N items
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

- [ ] For each finding, briefly show: file, line, severity, description

### Decision

```
IF must_fix > 0:
    → Loop back (see below)
ELSE:
    → Proceed (see below)
```

### Loop back (if must_fix > 0)

- [ ] Increment `self_review_iteration` in state.json (starts at 0)
- [ ] Save `must_fix` findings to `self_review_comments` in state.json:
  ```json
  [
    {
      "file": "path/to/file.ts",
      "line": 42,
      "action": "fix",
      "description": "description from finding"
    }
  ]
  ```
- [ ] Clear `self_review_findings` from state.json (will be regenerated)
- [ ] `bash ${CLAUDE_PLUGIN_ROOT}/skills/wf/lib/rewind-step.sh IMPLEMENT IMPLEMENT DO_GREEN_TEST SELF_REVIEW SELF_REVIEW_VERDICT`

### Proceed (if must_fix == 0)

- [ ] If `suggested` or `follow_up` findings exist, log them but do not block

Per `helpers#state_transition` — complete `SELF_REVIEW_VERDICT`
