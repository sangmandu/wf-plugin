# Step 090: COMPOUND_ANALYZE


## Pre-check

- [ ] Read `track` from state.json
- [ ] If track not in {`feature`, `fix`} → mark completed and skip
- [ ] Was anything non-trivial learned? (new pattern, gotcha, debugging insight, failed approach)
  - **No** → mark completed, log `"compound_skip_reason"` in state.json, skip

## Parallel Analysis

Launch **3 parallel sub-agents**:

- [ ] **Problem Analyzer**: Read spec.md, plan.md, git log/diff. Identify what was unexpectedly hard, failed attempts, broken assumptions. (max 200 words)

- [ ] **Pattern Extractor**: Read git diff main...HEAD, plan.md. Identify new patterns, reused patterns, anti-patterns avoided. (max 200 words)

- [ ] **Prevention Strategist**: Read workflow artifacts, CI logs, review comments. Identify preventive measures, missing lint rules/test patterns. (max 200 words)

Per `helpers#state_transition` — complete `COMPOUND_ANALYZE`
