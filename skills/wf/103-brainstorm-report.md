# BRAINSTORM_REPORT — Final Report

## Objective

Present the brainstorming results to the user using the `/rrr` (Research & Respond) style — step-by-step, interactive, easy to follow.

## Procedure

### 1. Read all findings

Read:
- `.workflow/brainstorm-explore.md` — initial exploration
- `.workflow/brainstorm-debate.md` — debate results
- `.workflow/brainstorm-verdict.md` — final verdict and chosen approach

### 2. Build a learning plan

Following the `/rrr` pattern, break down the final conclusion into digestible steps:

```
## Brainstorm complete. Here's what we found:

### The question
{what was being explored}

### The verdict
{chosen approach — one paragraph}

### Deep dive (step-by-step)
1. [Why this approach] — the problem it solves
2. [How it works] — core mechanics
3. [Trade-offs] — what we gain and what we give up
4. [What was rejected and why] — strongest counter-arguments and why they didn't win
5. [Next steps] — what to do with this conclusion

Ready? Say "1" to start, or ask me to adjust.
```

### 3. Step-by-step ping-pong

For each step:
1. Explain using the `/rrr` writing style: lead with "why", storytelling over listing, analogy → detail → concrete example
2. Connect to the user's codebase where relevant
3. End with a checkpoint — wait for user response before proceeding

### 4. Save final report

After all steps are covered, save the complete report to `.workflow/brainstorm-report.md`.

## Rules

- One step per message — never dump everything at once
- Wait for user signal before proceeding to next step
- Use the user's codebase as examples whenever possible
- **This is the final step of the brainstorm track.** The workflow ends here.
