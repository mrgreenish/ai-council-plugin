---
name: ai-council
description: Runs 3 specialist AI subagents in parallel (GPT-5.4, Claude Opus 4.6, Gemini 3.1 Pro) for high-stakes decisions, then synthesizes the best final answer. Use when asked for "best possible answer", architecture decisions, code review, or ambiguous implementation choices.
---

# AI Council

Invoke 3 specialist subagents in parallel, collect their structured outputs, judge them, and synthesize one final answer that is better than any single model could produce alone.

> This skill is the **canonical workflow source** for the AI Council. The `/ai-council` command delegates directly to this skill. All orchestration logic lives here — do not duplicate it in the command file or elsewhere.

## When to use this skill

Use the council only for high-value prompts where quality matters more than speed:

- Architecture decisions (choosing patterns, data models, service boundaries)
- Code review (finding bugs, regressions, missing tests, design issues)
- Ambiguous implementation choices where multiple valid paths exist
- Any request phrased as "best possible answer", "review this carefully", or "what is the right approach"

Do NOT use for: simple lookups, quick fixes, formatting, or anything that does not benefit from multi-perspective analysis.

## Step 1 — Normalize the prompt into a brief

Before invoking the council, reframe the user's request into this brief:

```
TASK: [one sentence — what needs to be decided or reviewed]
CONTEXT: [relevant codebase facts, constraints, existing patterns]
DELIVERABLE: [what a good answer looks like — code, recommendation, review findings]
RUBRIC: [what makes one answer better than another for this specific task]
MODE: [architecture | code-review | implementation-choice]
```

Share this brief with all 3 council members so they are answering the same question.

## Step 2 — Invoke 3 council members in parallel

Send the brief to all 3 subagents simultaneously in a single message:

- `/council-gpt-54` — adversarial analyst: edge cases, failure modes, strongest objections
- `/council-opus-46` — production quality advocate: correctness, clarity, maintainability
- `/council-gemini-31-pro` — breadth analyst: alternatives, hidden assumptions, cross-cutting concerns

Each subagent returns the same schema:
- `## Answer`
- `## Assumptions`
- `## Risks`
- `## Counterargument`
- `## Confidence`

## Step 3 — Judge the outputs

Score each response on these 5 dimensions (1-5 each):

| Dimension | What to evaluate |
|---|---|
| Correctness | Is the answer technically accurate? |
| Completeness | Does it address the full scope of the task? |
| Groundedness | Is it based on actual codebase context, not generic advice? |
| Practicality | Can this be implemented by the team without heroics? |
| Simplicity | Is it the simplest solution that fully satisfies the requirements? |

Note which model scored highest on each dimension.

## Step 4 — Escalation check (disagreement round)

Before synthesizing, check: **do the 3 models materially disagree on a core point?**

A material disagreement is when:
- Two or more models recommend fundamentally different approaches (not just different wording)
- One model flags a CRITICAL or HIGH risk that the others did not mention
- The confidence scores differ by 3 or more points on the same question

If material disagreement exists:
1. Identify the exact point of disagreement in one sentence
2. Send only that disagreement back to the 2 conflicting models as a focused follow-up: "Model A says X, Model B says Y — which is correct and why?"
3. Use the follow-up responses to resolve the conflict before synthesizing
4. This second round is one exchange only — do not loop

If no material disagreement: skip directly to synthesis.

## Step 5 — Synthesize the final answer

The final answer must synthesize, not average. Rules:

- **Adopt consensus**: where all 3 models agree, state it as established fact
- **Preserve minority warnings**: if one model flags a CRITICAL or HIGH risk that others missed, include it even if it is the minority view — label it "Minority risk flagged by [model]"
- **Resolve conflicts explicitly**: if models disagreed and the second round resolved it, state which view won and why
- **Call out unresolved uncertainty**: if the council genuinely cannot resolve something, say so explicitly rather than picking arbitrarily
- **Lead with the answer**: put the recommendation or finding first, justification second

## Final output format

```
## Council Verdict

### Recommendation
[The concrete answer — what to do or what was found]

### Consensus points
[What all 3 models agreed on]

### Key risks
[All CRITICAL and HIGH risks from any model, labeled with source]

### Minority flags
[Any important finding that only 1 model raised but is worth preserving]

### Unresolved uncertainty
[Anything the council could not resolve — only include if genuinely unresolved]

### Models consulted
- GPT-5.4 (adversarial analyst) — confidence: X/10
- Claude Opus 4.6 (production quality) — confidence: X/10
- Gemini 3.1 Pro (breadth analyst) — confidence: X/10
```

## Quality guardrails

- Every council member must use "ASSUMING:" for assumptions and "UNKNOWN:" for gaps — do not let them hide uncertainty in confident-sounding prose
- For code-review mode: bugs and regressions must come before style findings in the final output
- For architecture mode: the final answer must include trade-offs and a brief "why not the alternatives" section
- Keep each council member's output focused — if a response is longer than ~400 words, ask for a shorter version before judging
- No nested councils: this skill is orchestrated by the parent session only

## Example invocation

User: "Review this PR — is the approach correct and what could go wrong?"

1. Normalize into a brief with MODE: code-review
2. Send brief to all 3 council members in parallel
3. Collect structured outputs
4. Check for material disagreements (escalate if needed)
5. Synthesize final Council Verdict
6. Present verdict to user
