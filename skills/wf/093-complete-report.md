# Step 093: COMPLETE_REPORT


## Purpose

Present a comprehensive summary using the PTIA explanation style. This is the FINAL step of every workflow — tell the story so the user understands what happened without reading the code.

## Checklist

- [ ] Display the status banner:

```
Workflow Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Track:        {track}
 PR:           {pr_url}
 Linear:       {ticket_url}
 CI:           ✅ passed
 Review:       {review_status}
 Iterations:   {review_iteration} review cycle(s)
 Debates:      plan({debate_for_plan_count}) test({debate_test_count})
 Test score:   {baseline_score} → {final_score}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

- [ ] Write each section below using `helpers#explanation_style` (PTIA):

### 1. Problem — What Was Broken

Start with the user-visible breakage. Not the technical root cause — what the user or system experienced.
- "When X happened, Y broke" — not "Module Z had a missing field"
- Show the timeline: what triggered it → what went wrong → what the user saw

### 2. Solution — What Changed and Why

For each modified file, tell the causal story:
- **Problem-first**: why this file needed to change
- **Timeline**: the sequence of what happens now (before → after)
- **Inline example**: show a real value, real input/output, or real code snippet
- **Anchor**: one-word mapping to something familiar if the concept is new

### 3. Test Coverage

List test files with pass counts. For each test, explain **what bug it catches if removed** — not just "tests X works."

### 4. Review Handling

For each review comment: FIXED (what changed) or SKIPPED (reason).
If no review comments: "No review comments received."

### 5. Side Effects

Explicitly state what is NOT affected. Connect to user concerns — "existing X flow is untouched because Y."

### 6. Compound Insights — feature track only

If COMPOUND ran: key patterns, where saved, improvement suggestions.
If skipped: omit this section entirely.

### 7. Next Steps

What the user can do now. What remains (if anything). Poppy-side changes, staging verification, etc.

Per `helpers#state_transition` — complete `COMPLETE_REPORT` + set `status = "completed"`
