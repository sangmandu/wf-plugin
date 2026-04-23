#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────
# observe-reviews.sh — Deterministic review comment observer
#
# Fetches PR reviews + comments, compares against previous
# snapshot, and outputs a structured diff report.
#
# Detects: new reviews, new comments, MODIFIED comments
# (updated_at changed), and bot vs human commenters.
#
# Usage: bash observe-reviews.sh <PR_NUMBER>
#
# Snapshot storage: .workflow/observations/
# ─────────────────────────────────────────────────────────

PR="${1:?Usage: observe-reviews.sh <PR_NUMBER>}"

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null) || {
  echo "ERROR: Failed to detect repo. Run: gh auth login" >&2
  exit 1
}

mkdir -p .workflow/observations

SNAPSHOT_FILE=".workflow/observations/reviews-${PR}.json"
PREV_SNAPSHOT_FILE=".workflow/observations/reviews-${PR}-prev.json"

# ── Fetch current state ──

# Reviews (approve/request-changes/comment)
REVIEWS=$(gh api "repos/${REPO}/pulls/${PR}/reviews" \
  --jq '[.[] | {id, state, user_login: .user.login, user_type: .user.type, submitted_at, body}]' 2>/dev/null) || REVIEWS="[]"

# Review comments (inline on code)
REVIEW_COMMENTS=$(gh api "repos/${REPO}/pulls/${PR}/comments" \
  --jq '[.[] | {id, user_login: .user.login, user_type: .user.type, path, line, body, created_at, updated_at}]' 2>/dev/null) || REVIEW_COMMENTS="[]"

# Issue comments (general PR comments, including bot verdicts)
ISSUE_COMMENTS=$(gh api "repos/${REPO}/issues/${PR}/comments" \
  --jq '[.[] | {id, user_login: .user.login, user_type: .user.type, body, created_at, updated_at}]' 2>/dev/null) || ISSUE_COMMENTS="[]"

# Build current snapshot
CURRENT=$(jq -n \
  --argjson reviews "$REVIEWS" \
  --argjson review_comments "$REVIEW_COMMENTS" \
  --argjson issue_comments "$ISSUE_COMMENTS" \
  --arg fetched_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{fetched_at: $fetched_at, reviews: $reviews, review_comments: $review_comments, issue_comments: $issue_comments}')

# ── Compare with previous snapshot ──

if [ -f "$SNAPSHOT_FILE" ]; then
  cp "$SNAPSHOT_FILE" "$PREV_SNAPSHOT_FILE"
fi

echo "$CURRENT" > "$SNAPSHOT_FILE"

# ── Generate diff report ──

python3 -c "
import json, sys
from pathlib import Path

with open('$SNAPSHOT_FILE') as f:
    current = json.load(f)
prev_path = Path('$PREV_SNAPSHOT_FILE')

if prev_path.exists():
    with open(prev_path) as f:
        prev = json.load(f)
else:
    prev = {'reviews': [], 'review_comments': [], 'issue_comments': []}

# Detect bots
bots = set()
for src in [current['reviews'], current['review_comments'], current['issue_comments']]:
    for item in src:
        if item.get('user_type') == 'Bot':
            bots.add(item['user_login'])

# Index previous items by id
prev_review_ids = {r['id'] for r in prev.get('reviews', [])}
prev_rc_by_id = {r['id']: r for r in prev.get('review_comments', [])}
prev_ic_by_id = {r['id']: r for r in prev.get('issue_comments', [])}

# Diff: reviews
new_reviews = [r for r in current['reviews'] if r['id'] not in prev_review_ids]

# Diff: review comments (new + modified)
new_review_comments = []
modified_review_comments = []
for rc in current['review_comments']:
    if rc['id'] not in prev_rc_by_id:
        new_review_comments.append(rc)
    else:
        old = prev_rc_by_id[rc['id']]
        if rc.get('updated_at') != old.get('updated_at'):
            modified_review_comments.append({
                **rc,
                'previous_body': old.get('body', ''),
                'change_type': 'MODIFIED'
            })

# Diff: issue comments (new + modified)
new_issue_comments = []
modified_issue_comments = []
for ic in current['issue_comments']:
    if ic['id'] not in prev_ic_by_id:
        new_issue_comments.append(ic)
    else:
        old = prev_ic_by_id[ic['id']]
        if ic.get('updated_at') != old.get('updated_at'):
            modified_issue_comments.append({
                **ic,
                'previous_body': old.get('body', '')[:200] + '...' if len(old.get('body','')) > 200 else old.get('body',''),
                'change_type': 'MODIFIED'
            })

# Latest review verdict
latest_review = None
for r in reversed(current['reviews']):
    if r['state'] in ('APPROVED', 'CHANGES_REQUESTED'):
        latest_review = r
        break

has_changes = (new_reviews or new_review_comments or modified_review_comments
               or new_issue_comments or modified_issue_comments)

# Output markdown summary
lines = []
lines.append('## Review observation report')
lines.append(f'PR #{sys.argv[1] if len(sys.argv) > 1 else \"?\"}')
lines.append(f'Fetched at: {current[\"fetched_at\"]}')
if prev_path.exists():
    lines.append(f'Previous snapshot: {prev.get(\"fetched_at\", \"unknown\")}')
else:
    lines.append('Previous snapshot: none (first observation)')
lines.append('')

if bots:
    bot_list = ", ".join(sorted(bots))
    lines.append(f'Detected bots: {bot_list}')
    lines.append('')

if latest_review:
    lines.append(f'### Latest verdict: **{latest_review[\"state\"]}** by @{latest_review[\"user_login\"]}')
    lines.append('')

if not has_changes and prev_path.exists():
    lines.append('### No changes since last observation')
    lines.append('')
else:
    if new_reviews:
        lines.append(f'### New reviews ({len(new_reviews)})')
        for r in new_reviews:
            lines.append(f'- **{r[\"state\"]}** by @{r[\"user_login\"]} at {r[\"submitted_at\"]}')
        lines.append('')

    if new_review_comments:
        lines.append(f'### New inline comments ({len(new_review_comments)})')
        for rc in new_review_comments:
            lines.append(f'- @{rc[\"user_login\"]} on \`{rc[\"path\"]}:{rc.get(\"line\",\"?\")}\`')
            lines.append(f'  > {rc[\"body\"][:150]}')
        lines.append('')

    if modified_review_comments:
        lines.append(f'### ⚠️ MODIFIED inline comments ({len(modified_review_comments)})')
        lines.append('These comments were EDITED since last observation. You MUST re-read them.')
        for rc in modified_review_comments:
            lines.append(f'- @{rc[\"user_login\"]} on \`{rc[\"path\"]}:{rc.get(\"line\",\"?\")}\` (updated: {rc[\"updated_at\"]})')
            lines.append(f'  > {rc[\"body\"][:150]}')
        lines.append('')

    if new_issue_comments:
        lines.append(f'### New issue comments ({len(new_issue_comments)})')
        for ic in new_issue_comments:
            bot_tag = ' [BOT]' if ic['user_login'] in bots else ''
            lines.append(f'- @{ic[\"user_login\"]}{bot_tag} at {ic[\"created_at\"]}')
            lines.append(f'  > {ic[\"body\"][:200]}')
        lines.append('')

    if modified_issue_comments:
        lines.append(f'### ⚠️ MODIFIED issue comments ({len(modified_issue_comments)})')
        lines.append('These comments were EDITED since last observation. You MUST re-read them.')
        for ic in modified_issue_comments:
            bot_tag = ' [BOT]' if ic['user_login'] in bots else ''
            lines.append(f'- @{ic[\"user_login\"]}{bot_tag} (updated: {ic[\"updated_at\"]})')
            lines.append(f'  > {ic[\"body\"][:200]}')
        lines.append('')

# Summary counts
lines.append('### Summary')
lines.append(f'| Metric | Count |')
lines.append(f'|--------|-------|')
lines.append(f'| Total reviews | {len(current[\"reviews\"])} |')
lines.append(f'| Total inline comments | {len(current[\"review_comments\"])} |')
lines.append(f'| Total issue comments | {len(current[\"issue_comments\"])} |')
lines.append(f'| New (this observation) | {len(new_reviews) + len(new_review_comments) + len(new_issue_comments)} |')
lines.append(f'| Modified (this observation) | {len(modified_review_comments) + len(modified_issue_comments)} |')

print('\n'.join(lines))
" "$PR"
