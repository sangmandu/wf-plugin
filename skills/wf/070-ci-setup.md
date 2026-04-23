# Step 070: CI_SETUP

## Purpose

Ensure `[repos.<project>].ci_checks` in `wf_config.toml` is populated before `CI_WAIT_*` steps run. Discovery scans `.github/workflows/`, Jenkinsfile/other markers, and one recent PR's `statusCheckRollup` for external CI context strings. This is the structural guard that prevents `observe-ci.sh` from silently missing Jenkins / external CI checks.

## Behavior

`ci_checks` is populated at most once per repo:

| Current value                  | Action                                          |
| ------------------------------ | ----------------------------------------------- |
| missing / `[]`                 | run discovery, write result                     |
| `["__none__"]`                 | skip (already discovered, no CI)                |
| `["<name>", ...]` (any others) | skip (already known — re-run manually to reset) |

## Checklist

- [ ] ```bash
  bash <WF_DIR>/lib/discover-ci.sh
  ```
  - Exit 0 → done. Config is up to date.
  - Non-zero → step failure. Inspect stderr.
- [ ] Verify: `python3 <WF_DIR>/lib/config.py repos.$(jq -r .data.project_name .workflow/state.json).ci_checks`

Per `helpers#state_transition` — complete `CI_SETUP`
