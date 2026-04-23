# Step 071: CI_WAIT_POLL


## Purpose

Poll CI status using a deterministic script that handles the entire polling loop internally. The agent calls it once and gets back a terminal result.

## Checklist

- [ ] Run the CI polling loop (blocks until terminal state):
  ```bash
  bash <WF_DIR>/scripts/wait-for-ci.sh <pr-number>
  ```
  This script internally polls every 30s for up to 15 minutes. It returns only when CI reaches a terminal state. **Do NOT manage the loop yourself.**

- [ ] Branch on `next_action` from the JSON output:

  | `next_action` | What to do |
  |---|---|
  | `FETCH_LOGS_AND_FIX` | Proceed — CI failures detected. Do NOT fix here; the next step (CI_WAIT_EVALUATE) handles fixes. |
  | `DONE` | All checks passed. Proceed to next step. |
  | `ALERT_USER` | Read `remediation` field and present it to the user. Halt and wait for user guidance. |

- [ ] Do NOT interpret check-run names or statuses yourself. The script already did that.
- [ ] Do NOT use `gh pr checks` or `gh run watch` — these have known hang bugs.
- [ ] Do NOT call `observe-ci.sh` directly or implement your own polling loop.

Per `helpers#state_transition` — complete `CI_WAIT_POLL`
