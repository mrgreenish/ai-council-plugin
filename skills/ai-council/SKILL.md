---
name: ai-council
description: Runs 3 specialist AI subagents in parallel (GPT-5.4, Claude Opus 4.6, Gemini 3.1 Pro) for high-stakes decisions, then synthesizes the best final answer. Use when asked for "best possible answer", architecture decisions, code review, or ambiguous implementation choices.
---

# AI Council

Invoke 3 specialist subagents in parallel, collect their structured outputs, run peer review, judge them, and synthesize one final answer that is better than any single model could produce alone.

> This skill is the **canonical workflow source** for the AI Council. The `/ai-council` command delegates directly to this skill. All orchestration logic lives here — do not duplicate it in the command file or elsewhere.

## When to use this skill

Use the council only for high-value prompts where quality matters more than speed:

- Architecture decisions (choosing patterns, data models, service boundaries)
- Code review (finding bugs, regressions, missing tests, design issues)
- Ambiguous implementation choices where multiple valid paths exist
- Any request phrased as "best possible answer", "review this carefully", or "what is the right approach"

Do NOT use for: simple lookups, quick fixes, formatting, or anything that does not benefit from multi-perspective analysis.

## Preflight — before invoking the council

Run these checks before Step 1. Stop and act on the first one that applies.

**1. Infer mode from the request:**
- Request involves reviewing code, a PR, or a diff → `code-review`
- Request involves choosing a pattern, data model, or service boundary → `architecture`
- Request involves picking between implementation options → `implementation-choice`
- If unclear, ask **one short clarifying question** and wait for the answer before proceeding.

**2. Identify primary context:**
If code, files, or a diff are attached or selected, treat them as the primary context for the council brief. Include the most relevant excerpts directly in the brief rather than referring to them abstractly.

**3. Scope guard — stop if context is too large or diffuse:**
If the attached or selected context is too large to review groundedly in one pass (e.g. an entire large codebase, an unfocused multi-topic diff, or a request that spans several independent concerns), do **not** start the council. Instead, ask the user to narrow the scope:

> "This context is too large or covers too many independent concerns for a focused council review. Could you narrow it to a specific file, function, or decision? For example: [suggest a concrete scoping option based on what was attached]."

Wait for the user's narrowed input before proceeding.

## Step 1 — Normalize the prompt into a brief

Reframe the user's request into this brief:

```
TASK: [one sentence — what needs to be decided or reviewed]
CONTEXT: [relevant codebase facts, constraints, existing patterns; include key excerpts if code is attached]
DELIVERABLE: [what a good answer looks like — code, recommendation, review findings]
RUBRIC: [what makes one answer better than another for this specific task]
MODE: [architecture | code-review | implementation-choice]
PEER_REVIEW: [yes | no | auto]
```

**PEER_REVIEW field:** Set automatically based on MODE:
- `architecture` or `code-review` → defaults to `yes` (high-stakes, peer review adds significant value)
- `implementation-choice` → defaults to `no` (lower stakes, skip peer review for speed)
- The user can override by explicitly requesting peer review or asking to skip it

Share this brief with all council members so they are answering the same question.

## Step 2 — Invoke council members in parallel

**Invocation mechanism:** Launch all 3 as parallel `Task` tool calls in a single message. Use `subagent_type` set to the agent name, pass the brief as the `prompt`, and set `readonly: true`.

```
Task(subagent_type="council-gpt-54",       prompt=<brief>, readonly=true)
Task(subagent_type="council-opus-46",      prompt=<brief>, readonly=true)
Task(subagent_type="council-gemini-31-pro", prompt=<brief>, readonly=true)
```

**Preserve agent IDs:** Each `Task` call returns an agent ID. Store all 3 IDs — they are required for peer review (Step 3) and the escalation round (Step 5).

Council member roles:
- `council-gpt-54` — adversarial analyst: edge cases, failure modes, strongest objections
- `council-opus-46` — production quality advocate: correctness, clarity, maintainability
- `council-gemini-31-pro` — breadth analyst: alternatives, hidden assumptions, cross-cutting concerns

Each subagent returns the same schema:
- `## Model Identity`
- `## Answer`
- `## Assumptions`
- `## Risks`
- `## Counterargument`
- `## Confidence`

**Output length:** Council members should be concise. If a response is excessively long, synthesize their key points directly during judging rather than requesting a shorter version — do not add a round-trip just for brevity.

## Step 2a — Model identity verification

After collecting responses, extract the `## Model Identity` field from each response.

**Check for duplicates:**
- If 2 or more agents report the same model identity, this means fallback occurred. Warn the user: "⚠️ WARNING: [agent-name] and [agent-name] both report running as [model]. This likely means Max Mode is not enabled. The council verdict may reflect a single model's perspective rather than true multi-model analysis."
- If a model reports "UNKNOWN", note it but proceed.
- If all 3 report distinct models, proceed normally.

This check is informational only — it does not abort the workflow. The user decides whether to continue or fix their model configuration.

## Step 2b — Handle failures before judging

After collecting responses, check for failures before proceeding:

- **One model failed or returned malformed output:** Continue with the 2 valid responses as a **partial council**. Note the missing model under "Models consulted" in the final verdict. Follow the partial-council rules in Step 5 and the Final output format.
- **Malformed output (missing schema sections):** Attempt to extract usable content from the valid parts. If the response is too broken to use, treat it as a failure and proceed with the remaining models.
- **Only 1 model responded:** Do not synthesize a "council verdict". Answer directly using that single response and inform the user that the council could not run with fewer than 2 perspectives.
- **All 3 models failed:** Abort the council workflow and answer the user's question directly without council framing.

## Step 3 — Peer review round

> **Skip this step** if `PEER_REVIEW` is `no` in the brief, or if fewer than 2 models responded in Step 2.

Each model anonymously reviews the responses from the other two models. This catches blind spots that a single judge would miss and provides structured cross-validation.

### 3a — Anonymize responses

Strip model names and any self-identifying information from each response. Assign anonymous labels:
- The response from `council-gpt-54` → one of "Response A", "Response B", or "Response C"
- The response from `council-opus-46` → one of the remaining labels
- The response from `council-gemini-31-pro` → the last remaining label

Track the mapping internally (e.g., A=GPT-5.4, B=Opus 4.6, C=Gemini 3.1 Pro) but do not share it with the reviewers. Remove the `## Model Identity` section from each anonymized response.

### 3b — Send peer review requests in parallel

Each model reviews only the responses that are NOT its own. Launch all 3 as parallel `Task` calls using `resume` to preserve first-round context:

```
Task(subagent_type="council-gpt-54",
     prompt=<peer_review_brief with Response B + Response C>,
     resume=<agent_id_from_step2>)

Task(subagent_type="council-opus-46",
     prompt=<peer_review_brief with Response A + Response C>,
     resume=<agent_id_from_step2>)

Task(subagent_type="council-gemini-31-pro",
     prompt=<peer_review_brief with Response A + Response B>,
     resume=<agent_id_from_step2>)
```

> **Why `resume` matters:** The model retains context of the original brief and its own first-round analysis. It can evaluate the other responses with full problem context without needing the brief repeated.

### 3c — Peer review brief template

Send each reviewer the following prompt (substituting the appropriate anonymized responses):

```
PEER REVIEW ROUND

You previously answered this council question. Now review the other two
responses below. You do NOT know which model wrote which response.

For each response, score it on these dimensions (1-5):
- Correctness: Is it technically accurate?
- Completeness: Does it address the full scope?
- Groundedness: Based on real context, not generic advice?
- Practicality: Can this be implemented without heroics?
- Simplicity: Simplest solution that fully satisfies requirements?

Then state:
- STRONGEST POINT: The single best insight in this response
- BLIND SPOT: The most important thing this response missed or underweighted
- BETTER THAN MINE: Yes or No — is this response overall better than your own?

## Response A
[anonymized content]

## Response B
[anonymized content]

Respond using this exact format:

## Review of Response A
| Dimension | Score |
|---|---|
| Correctness | X |
| Completeness | X |
| Groundedness | X |
| Practicality | X |
| Simplicity | X |
STRONGEST POINT: ...
BLIND SPOT: ...
BETTER THAN MINE: Yes/No

## Review of Response B
[same format]
```

### 3d — Handle peer review edge cases

- **Only 2 models responded in Step 2:** Each reviews the other's single response. Adjust the brief to present "Response A" only and drop one review section from the format.
- **A peer review response is malformed:** Extract usable scores if possible. If the review is too broken, proceed without that reviewer's scores — note it in the verdict.
- **A reviewer did not return:** The response still has one peer review from the other reviewer. Proceed with available scores.

## Step 4 — Judge the outputs

Score each response on these 5 dimensions (1–5 each):

| Dimension | What to evaluate |
|---|---|
| Correctness | Is the answer technically accurate? |
| Completeness | Does it address the full scope of the task? |
| Groundedness | Is it based on actual codebase context, not generic advice? |
| Practicality | Can this be implemented by the team without heroics? |
| Simplicity | Is it the simplest solution that fully satisfies the requirements? |

**Incorporating peer scores (when peer review ran):**
- For each response, average the two peer reviewer scores on each dimension to produce a peer average
- Present both parent scores and peer averages in the final verdict table (format: `4 (peer: 3.5)`)
- If the parent score and peer average differ by 2 or more on any dimension, the parent must explain the discrepancy in the verdict (e.g., "Parent scored Correctness 2 points higher than peers because...")
- The "BETTER THAN MINE" signals are strong evidence: if both peer reviewers say a response is better than theirs, weight that response heavily in synthesis

**When peer review did not run:** Score using parent assessment only, as before.

Note which model scored highest on each dimension. Include the scoring grid in the final verdict under `### Judge scores`.

## Step 5 — Escalation check (disagreement round)

Before synthesizing, check: **do the models materially disagree on a core point?**

A material disagreement requires at least one of:
- Two or more models recommend **fundamentally different approaches** (not just different wording)
- One model flags a **CRITICAL or HIGH risk** that the others did not mention
- Models reach **contradictory correctness conclusions** about the same claim

> Confidence scores differing by 3 or more points alone is **not** sufficient to trigger escalation. Confidence is subjective and model-calibrated differently. Only escalate when there is a concrete recommendation mismatch, correctness contradiction, or unaddressed CRITICAL/HIGH risk.

**If material disagreement exists:**

1. Identify the exact point of disagreement in one sentence.
2. Resume **each materially conflicting model** using its agent ID from Step 2 — send a single parallel disagreement round:

   ```
   Task(subagent_type="council-gpt-54",       prompt=<disagreement>, resume=<agent_id_gpt>)
   Task(subagent_type="council-opus-46",      prompt=<disagreement>, resume=<agent_id_opus>)
   Task(subagent_type="council-gemini-31-pro", prompt=<disagreement>, resume=<agent_id_gemini>)
   ```

   Only resume the models that are party to the conflict. If only two models disagree, resume only those two. If all three diverge, resume all three.

   The follow-up prompt should be: "Model A says [X], Model B says [Y] — which is correct and why? Be concise."

3. Use the follow-up responses to resolve the conflict before synthesizing.
4. This second round is **one exchange only** — do not loop.
5. If the disagreement round does not converge on a shared position, do **not** silently pick a winner. Surface the conflict explicitly under `### Unresolved uncertainty` in the final verdict.

**If no material disagreement:** skip directly to synthesis.

> **Why resume matters:** Subagents are stateless by default. Without `resume`, a follow-up invocation starts fresh with no memory of the first-round analysis or the original brief. Always use `resume` for escalation follow-ups.

## Step 6 — Synthesize the final answer

The final answer must synthesize, not average. Rules:

- **Adopt consensus**: where all responding models agree, state it as established fact
- **Preserve minority warnings**: if one model flags a CRITICAL or HIGH risk that others missed, include it even if it is the minority view — label it "Minority risk flagged by [model]"
- **Resolve conflicts explicitly**: if models disagreed and the second round resolved it, state which view won and why
- **Call out unresolved uncertainty**: if the council genuinely cannot resolve something, say so explicitly rather than picking arbitrarily
- **Lead with the answer**: put the recommendation or finding first, justification second
- **Use peer review signals**: if peer reviewers identified blind spots, incorporate those findings into the synthesis even if the parent judge did not flag them independently

**Partial council (2 of 3 models responded):**
- Use the same synthesis rules above, but scope all consensus/agreement language to "both responding models" rather than "all 3".
- The judge scores table uses only the 2 responding models' columns; mark the missing model's column as `—`.
- Add a visible note at the top of the verdict: `> Partial council: [Model name] did not respond. Verdict is based on 2 of 3 perspectives.`

## Final output format

**Full council (3 models):**

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

### Peer review insights
[Key blind spots and strongest points surfaced during peer review — omit this section if peer review did not run]

### Judge scores
| Dimension    | GPT-5.4 | Opus 4.6 | Gemini 3.1 Pro |
|---|---|---|---|
| Correctness  | X (peer: X) | X (peer: X) | X (peer: X) |
| Completeness | X (peer: X) | X (peer: X) | X (peer: X) |
| Groundedness | X (peer: X) | X (peer: X) | X (peer: X) |
| Practicality | X (peer: X) | X (peer: X) | X (peer: X) |
| Simplicity   | X (peer: X) | X (peer: X) | X (peer: X) |

(peer scores omitted if peer review did not run)

### Unresolved uncertainty
[Anything the council could not resolve — only include if genuinely unresolved]

### Models consulted
- GPT-5.4 (adversarial analyst) — confidence: X/10
- Claude Opus 4.6 (production quality) — confidence: X/10
- Gemini 3.1 Pro (breadth analyst) — confidence: X/10
[Note any model that failed to respond or reported unexpected identity]
```

**Partial council (2 of 3 models):**

```
## Council Verdict

> Partial council: [Missing model name] did not respond. Verdict is based on 2 of 3 perspectives.

### Recommendation
[The concrete answer — what to do or what was found]

### Consensus points
[What both responding models agreed on]

### Key risks
[All CRITICAL and HIGH risks from any responding model, labeled with source]

### Minority flags
[Any important finding that only 1 of the 2 responding models raised]

### Judge scores
| Dimension    | [Model A] | [Model B] | [Missing model] |
|---|---|---|---|
| Correctness  | X | X | — |
| Completeness | X | X | — |
| Groundedness | X | X | — |
| Practicality | X | X | — |
| Simplicity   | X | X | — |

### Unresolved uncertainty
[Anything the council could not resolve — only include if genuinely unresolved]

### Models consulted
- [Model A name] ([role]) — confidence: X/10
- [Model B name] ([role]) — confidence: X/10
- [Missing model name] — did not respond
```

## Quality guardrails

- Every council member must use "ASSUMING:" for assumptions and "UNKNOWN:" for gaps — do not let them hide uncertainty in confident-sounding prose
- For code-review mode: bugs and regressions must come before style findings in the final output
- For architecture mode: the final answer must include trade-offs and a brief "why not the alternatives" section
- No nested councils: this skill is orchestrated by the parent session only

## Example invocation

User: "Review this PR — is the approach correct and what could go wrong?"

1. Preflight: infer `code-review` mode; check that the diff is focused enough to review in one pass
2. Normalize into a brief with MODE: code-review, PEER_REVIEW: yes
3. Launch 3 parallel Task calls (council-gpt-54, council-opus-46, council-gemini-31-pro), store agent IDs
4. Verify model identities — warn if duplicates detected (Step 2a)
5. Check for failures (Step 2b); if partial council, apply partial-council rules
6. Peer review — each model anonymously scores the other two (Step 3)
7. Judge outputs with both parent and peer scores (Step 4)
8. Check for material disagreements — if found, resume conflicting agents with disagreement (Step 5)
9. Synthesize final Council Verdict using the appropriate full or partial template (Step 6)
10. Present verdict to user
