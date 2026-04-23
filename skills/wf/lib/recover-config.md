# Recovering wf_config.toml

Run this ONLY when `preflight-check.sh` fails with a missing/empty/malformed `${CLAUDE_PLUGIN_ROOT}/skills/wf/config/wf_config.toml` (or a missing `[identity]` section).

## Recovery order

1. **Check backups in the usual places first**:
   - `${CLAUDE_PLUGIN_ROOT}/skills/wf/config/wf_config.toml.bak`
   - `tmutil listlocalsnapshots /` / Time Machine
   - dotfiles repo, if the user keeps one

2. **Extract from Claude Code session transcripts.** Claude Code persists every `Read` tool result in `~/.claude/projects/-Users-*-*/*.jsonl`. If any past session has read `wf_config.toml`, its full content is still there.

   ```bash
   python3 - <<'PY'
   import json, glob
   for path in glob.glob(
       "/Users/$USER/.claude/projects/-Users-*/*.jsonl".replace("$USER", __import__("os").environ["USER"])
   ):
       try:
           with open(path) as f:
               for ln in f:
                   if "[identity]" in ln and "[cache]" in ln and "preflight_verified_at" in ln:
                       d = json.loads(ln)
                       def walk(x):
                           if isinstance(x, str) and "[identity]" in x and "[cache]" in x:
                               print(f"--- {path} ---")
                               print(x)
                           elif isinstance(x, dict):
                               for v in x.values(): walk(v)
                           elif isinstance(x, list):
                               for v in x: walk(v)
                       walk(d); break
       except Exception:
           pass
   PY
   ```

   Pick the most recent / most complete match, strip any `1\t`-style line-number prefixes from `Read` output, and write it back to `${CLAUDE_PLUGIN_ROOT}/skills/wf/config/wf_config.toml`.

3. If step 2 yields nothing, ask the user to reconstruct manually — **do not guess field values** (especially `identity.team_id` and `identity.user_id`, which are UUIDs the Linear API requires to be exact).
