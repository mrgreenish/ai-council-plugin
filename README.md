# AI Council Plugin

A multi-model review council for high-stakes decisions. Three specialist AI models run in parallel, each with a different analytical role. They peer-review each other's outputs anonymously, and the parent session synthesizes the best final answer.

## What it does

Instead of asking one model a hard question, the council asks three simultaneously, then has them review each other:

```
Your question
     |
     v
AI Council Skill (normalizes prompt into a brief)
     |
     |--- council-gpt-54         (GPT-5.4 -- adversarial analyst)
     |--- council-opus-46        (Claude Opus 4.6 -- production quality)
     '--- council-gemini-31-pro  (Gemini 3.1 Pro -- breadth & alternatives)
                |
                v
     Peer Review (each model anonymously scores the other two)
                |
                v
     Parent session (judge + synthesis, informed by peer scores)
                |
                v
     Council Verdict (best final answer)
```

## Council members

| Agent | Model | Role |
|---|---|---|
| `council-gpt-54` | `gpt-5.4` | Adversarial analyst -- edge cases, failure modes, strongest objections |
| `council-opus-46` | `claude-opus-4-6` | Production quality advocate -- correctness, clarity, maintainability |
| `council-gemini-31-pro` | `gemini-3.1-pro` | Breadth analyst -- alternatives, hidden assumptions, cross-cutting concerns |

All three return the same structured schema so the judge can compare them directly:

```
## Model Identity
[(self-reported runtime model identity, or `UNKNOWN` if uncertain)]
## Answer
## Assumptions   (prefixed with "ASSUMING:")
## Risks         (ordered by severity: CRITICAL / HIGH / MEDIUM / LOW)
## Counterargument
## Confidence    (1-10 score with justification)
```

## When to use it

| Use it for | Skip it for |
|---|---|
| Architecture decisions | Simple lookups |
| Code review | Quick bug fixes |
| Ambiguous implementation choices | Formatting changes |
| "Best possible answer" requests | Anything obvious |

## Installation

### Cursor -- Option A: copy into a project (recommended, works immediately)

Copy the council files directly into your project's `.cursor/` directory. This is the fastest way to get started and requires no plugin setup.

```bash
# From the root of your project, run:
git clone https://github.com/filipvanharreveld/ai-council-plugin.git /tmp/ai-council-plugin

mkdir -p .cursor/agents .cursor/skills/ai-council .cursor/commands

cp /tmp/ai-council-plugin/agents/council-gpt-54.md .cursor/agents/
cp /tmp/ai-council-plugin/agents/council-opus-46.md .cursor/agents/
cp /tmp/ai-council-plugin/agents/council-gemini-31-pro.md .cursor/agents/
cp /tmp/ai-council-plugin/skills/ai-council/SKILL.md .cursor/skills/ai-council/
cp /tmp/ai-council-plugin/commands/ai-council.md .cursor/commands/

rm -rf /tmp/ai-council-plugin
```

After copying, restart or reload your Cursor window. The council is immediately available in that project.

> **Working inside the ai-council-plugin repo?** Run `bash scripts/install-cursor-project.sh` instead. It symlinks the canonical files into `.cursor/` so changes stay single-sourced and you don't need to re-copy after every edit.

To update later, re-run the copy commands with the latest version of the repo.

To uninstall, delete the copied files:

```bash
rm .cursor/agents/council-gpt-54.md
rm .cursor/agents/council-opus-46.md
rm .cursor/agents/council-gemini-31-pro.md
rm -rf .cursor/skills/ai-council
rm .cursor/commands/ai-council.md
```

---

### Cursor -- Option B: install as a global user plugin

Install the council once and use it across all your projects without copying files per repo.

**Step 1: clone the repo**

```bash
git clone https://github.com/filipvanharreveld/ai-council-plugin.git ~/cursor-plugins/ai-council
```

**Step 2: open Cursor settings**

Go to `Cursor > Settings > Plugins` (or open the command palette and search for `Plugins`).

**Step 3: add the plugin**

Click `Add plugin from local path` and select the folder you cloned:

```
~/cursor-plugins/ai-council
```

Cursor reads the `.cursor-plugin/plugin.json` manifest and loads the agents, skills, and commands listed in it.

**Step 4: reload Cursor**

Restart or reload the window. The council is now available globally in all projects.

**To update:**

```bash
cd ~/cursor-plugins/ai-council
git pull
```

Then reload Cursor.

**To uninstall:**

Remove the plugin from `Cursor > Settings > Plugins`, then delete the cloned folder.

---

After installing via either option, the following are available:
- `/ai-council [your question]` -- main command entrypoint
- `@ai-council` -- attach the skill as context
- `/council-gpt-54`, `/council-opus-46`, `/council-gemini-31-pro` -- individual council members

### Claude (install script)

Run the installer to copy the council files into your Claude user directories:

```bash
bash scripts/install-claude.sh
```

This installs:
- `skills/ai-council/SKILL.md` -> `~/.claude/skills/ai-council/SKILL.md`
- `agents/council-gpt-54.md` -> `~/.claude/agents/council-gpt-54.md`
- `agents/council-opus-46.md` -> `~/.claude/agents/council-opus-46.md`
- `agents/council-gemini-31-pro.md` -> `~/.claude/agents/council-gemini-31-pro.md`

> **Note:** After installing, invoke the council with `/ai-council` — the skill is slash-invocable in Claude Code. To use an individual council member directly, ask Claude in natural language, for example: "Use the council-gpt-54 agent to review this code."

To uninstall, remove those files manually:

```bash
rm -rf ~/.claude/skills/ai-council
rm ~/.claude/agents/council-gpt-54.md
rm ~/.claude/agents/council-opus-46.md
rm ~/.claude/agents/council-gemini-31-pro.md
```

To update, re-run the install script after pulling the latest version of this repo.

## Verifying your installation

After installing via any method, confirm the council is working before using it on a real task:

1. **Test a single council member** -- invoke one member with a simple question:
   - **Cursor:** `/council-gpt-54 What is 2+2? (test only)`
   - **Claude Code:** `Use the council-gpt-54 agent: What is 2+2? (test only)`

   Check the response to confirm it is running on GPT-5.4 and not a fallback model. The response will include a `## Model Identity` section that reports the model's self-reported runtime identity, or `UNKNOWN` if it cannot determine that reliably.

2. **Repeat for the other two members** -- run the same check for `council-opus-46` (expect Claude Opus 4.6) and `council-gemini-31-pro` (expect Gemini 3.1 Pro).

3. **Confirm all 3 are distinct models** -- if all three responses come from the same model, you are running on a fallback. Check that your plan supports Max Mode (required for GPT-5.4 and Claude Opus 4.6).

4. **Run a full council** -- try a real question with `/ai-council`. Confirm the verdict includes responses from all 3 perspectives.

> **Automatic verification:** The council workflow now checks model identities automatically. If two or more agents report the same model, or if multiple agents report `UNKNOWN`, you will see a warning in the output. This does not replace the manual check above for initial setup, but it catches likely fallback issues during normal use.

## Usage

### Recommended: `/ai-council` command

```
/ai-council should we add a caching layer between the API and the frontend?
/ai-council review this diff for bugs and missing tests
/ai-council what is the best approach for this implementation?
```

The command passes your request and any attached context to the `ai-council` skill, which handles the full workflow: mode inference, context checks, parallel council invocation, judging, disagreement handling, and synthesis. If the request is project-specific but no relevant code, diff, or architecture context is attached, the skill asks for that context before running the council.

### Architecture examples

```
/ai-council Should we use a monorepo or separate repos for this service split?
/ai-council Where should this business logic live -- in the API layer or the frontend?
/ai-council What are the trade-offs between event-driven and request-response for this feature?
```

### Code review examples

```
/ai-council Review the selected code for bugs, missing edge cases, and test gaps.
/ai-council Is this change safe to merge? Focus on regressions and security.
/ai-council Does this implementation follow the patterns already established in this codebase?
```

### Implementation choice examples

```
/ai-council Should we use server-side rendering or client-side fetching for this page?
/ai-council Is a new API endpoint the right abstraction here, or should this live in the client?
/ai-council Between these two approaches, which is simpler and more maintainable long-term?
```

### Individual council members

Invoke one perspective directly when you want a specific lens:

```
/council-gpt-54 What are the worst failure modes if we ship this as-is?
/council-opus-46 Is this code maintainable for the team six months from now?
/council-gemini-31-pro What alternatives did we not consider for this architecture?
```

## How it works step by step

1. **Preflight** -- The skill infers the mode (`architecture`, `code-review`, or `implementation-choice`) from your request. If the request is ambiguous, it asks one short clarifying question. If the request is project-specific but missing relevant code/diff/architecture context, it asks for that first. If the attached context is too large or covers too many independent concerns to review groundedly, it asks you to narrow the scope before proceeding.
2. **Normalize** -- Your question is rewritten into a structured brief (task, constraints, deliverable, rubric, mode). A separate internal `peer_review_setting` is resolved to `yes` or `no` before any subagent call. Attached code or diffs are included as primary context.
3. **Parallel run** -- All 3 council members are launched as parallel subagents simultaneously. The skill stores the first-round outputs, identities, and agent IDs needed for peer review.
4. **Model verification** -- Each agent reports its self-reported runtime model identity; if duplicates are detected, or if multiple agents report `UNKNOWN`, a warning is surfaced.
5. **Failure check** -- If a model fails or returns malformed output, the council continues with the remaining responses (minimum 2 to produce a verdict). A partial council is clearly labeled in the verdict.
6. **Peer review** -- If all 3 first-round responses are available and peer review is enabled, each model reviews the other two under pseudonymous labels, scores them on 5 dimensions, identifies blind spots, and signals whether another response is better than its own.
7. **Judge** -- The parent session scores each output on correctness, completeness, groundedness, practicality, simplicity; peer scores are shown alongside parent scores in the final verdict when available.
8. **Disagreement round** -- If models materially disagree (different recommendations, contradictory correctness claims, or an unaddressed CRITICAL/HIGH risk), only the conflicting models are asked a fresh follow-up question in one parallel round. If that round does not converge, the conflict is surfaced explicitly together with what missing information would resolve it.
9. **Synthesis** -- The final Council Verdict leads with a direct recommendation, explains why, gives next steps, preserves minority risks, incorporates peer review insights, and calls out unresolved uncertainty.

## Final output format

**Full council (all 3 models responded):**

```
## Council Verdict

### Recommendation
### Why
### Next steps
### Why not the alternatives  (architecture mode only)
### Key risks
### Minority flags
### Peer review insights (omitted if peer review did not run)
### Judge scores
| Dimension    | GPT-5.4        | Opus 4.6       | Gemini 3.1 Pro |
|---|---|---|---|
| Correctness  | X (peer: X)    | X (peer: X)    | X (peer: X)    |
| Completeness | X (peer: X)    | X (peer: X)    | X (peer: X)    |
| Groundedness | X (peer: X)    | X (peer: X)    | X (peer: X)    |
| Practicality | X (peer: X)    | X (peer: X)    | X (peer: X)    |
| Simplicity   | X (peer: X)    | X (peer: X)    | X (peer: X)    |
### Judge notes  (only when scoring materially affects the verdict)
### Unresolved uncertainty
### Models consulted (with confidence scores)
```

## Example council verdict

> The following is a condensed example showing what a real council verdict looks like. Details are abbreviated for brevity.

**User question:** `/ai-council Should we add a Redis caching layer between the API and the database?`

**Mode:** architecture | **Peer review:** yes

**What each model said (summarized):**

- **GPT-5.4** recommended adding Redis but flagged cache invalidation as a CRITICAL risk, warning that stale data in the user permissions cache could cause authorization bugs. Confidence: 6/10.
- **Opus 4.6** recommended Redis with a TTL-based strategy, emphasizing it fits the existing infrastructure patterns and is straightforward to operate. Flagged the lack of a cache monitoring story as a HIGH risk. Confidence: 8/10.
- **Gemini 3.1 Pro** recommended considering HTTP-level caching (CDN or reverse proxy) as an alternative before committing to Redis, noting that Redis adds operational complexity that may not be justified by current traffic. Confidence: 7/10.

**Peer review highlights:**

- Both GPT-5.4 and Gemini 3.1 Pro marked Opus 4.6's response as "BETTER THAN MINE" for practicality
- GPT-5.4 identified a blind spot in Gemini's response: the CDN alternative does not help with authenticated/personalized endpoints
- Gemini flagged that GPT-5.4's invalidation concerns, while valid, assumed a write-heavy workload that may not match the actual use case

**Council verdict:**

```
## Council Verdict

### Recommendation
Add Redis caching for the read-heavy public endpoints (product catalog, search results).
Defer caching for authenticated endpoints until the invalidation strategy is validated
with the team. Start with a 60-second TTL and add cache-hit/miss metrics from day one.

### Why
- Public endpoints are read-heavy enough to benefit from caching immediately
- TTL-based expiration fits the current team and infrastructure better than event-driven invalidation
- The strongest correctness concern applies to auth/personalized data, not to the initial public-endpoint rollout

### Next steps
- Roll out Redis only for product catalog and search results first
- Ship hit/miss metrics and stale-data alerting in the first release
- Keep authenticated and personalized endpoints uncached until invalidation semantics are reviewed with the team

### Why not the alternatives
- HTTP/CDN caching is simpler, but it only covers public cacheable traffic and does not solve the authenticated-path use case that motivated the request
- Event-driven invalidation adds operational complexity before there is evidence that a simple TTL rollout is insufficient

### Key risks
- CRITICAL (GPT-5.4): Cache invalidation for user permissions could cause stale
  authorization decisions. Mitigated by excluding auth endpoints from initial rollout.
- HIGH (Opus 4.6): No cache monitoring story -- stale data failures will be invisible
  without hit/miss metrics and alerting.

### Minority flags
- Gemini 3.1 Pro raised HTTP-level caching as a simpler alternative. This is valid for
  public endpoints but does not apply to authenticated routes. Worth revisiting if Redis
  operational burden becomes a concern.

### Peer review insights
- Opus 4.6's response was rated strongest on practicality by both peers
- GPT-5.4's cache invalidation concern was validated by peers but scoped: it matters most
  for auth/personalized data, less for public read endpoints
- Gemini's CDN alternative was noted as a valid fallback but not a replacement for the
  primary use case

### Judge scores
| Dimension    | GPT-5.4      | Opus 4.6     | Gemini 3.1 Pro |
|---|---|---|---|
| Correctness  | 4 (peer: 4)  | 5 (peer: 4.5)| 4 (peer: 3.5) |
| Completeness | 3 (peer: 3.5)| 4 (peer: 4.5)| 4 (peer: 4)   |
| Groundedness | 4 (peer: 4)  | 5 (peer: 4.5)| 3 (peer: 3)   |
| Practicality | 3 (peer: 3)  | 5 (peer: 5)  | 4 (peer: 3.5) |
| Simplicity   | 3 (peer: 3.5)| 4 (peer: 4)  | 4 (peer: 4)   |

### Judge notes
- Opus 4.6 led on practicality and groundedness, which made it the backbone of the final recommendation
- GPT-5.4's CRITICAL invalidation warning materially changed the scope of the rollout, even though it did not change the recommendation to cache public endpoints

### Models consulted
- GPT-5.4 (adversarial analyst) -- confidence: 6/10
- Claude Opus 4.6 (production quality) -- confidence: 8/10
- Gemini 3.1 Pro (breadth analyst) -- confidence: 7/10
```

**Partial council (one model unavailable):**

When a model fails to respond, the verdict is labeled at the top, peer review is skipped, and the judge table uses `—` for the missing model's column:

```
## Council Verdict

> Partial council: [Missing model] did not respond. Verdict is based on 2 of 3 perspectives.

### Recommendation
### Why
### Next steps
### Why not the alternatives  (architecture mode only)
### Key risks
### Minority flags
### Judge scores
| Dimension    | [Model A] | [Model B] | [Missing model] |
|---|---|---|---|
| Correctness  | X | X | — |
| Completeness | X | X | — |
| Groundedness | X | X | — |
| Practicality | X | X | — |
| Simplicity   | X | X | — |
### Judge notes
### Unresolved uncertainty
### Models consulted
```

## Model availability notes

- `gpt-5.4` and `claude-opus-4-6` require **Max Mode** on request-based Cursor plans
- `gemini-3.1-pro` is available on standard plans
- If a model is unavailable on your plan, Cursor falls back to a compatible model -- the council now checks for this automatically via self-reported model identity and warns you in the output
- The parent session (judge + synthesis) uses whatever model your active chat is running
- For best results, use a strong model (Opus or GPT-5.4 class) as your parent session when running the full council

## File layout

```
ai-council-plugin/
├── .cursor-plugin/
│   └── plugin.json          # Cursor plugin manifest
├── agents/
│   ├── council-gpt-54.md    # GPT-5.4 adversarial analyst
│   ├── council-opus-46.md   # Claude Opus 4.6 production quality
│   └── council-gemini-31-pro.md  # Gemini 3.1 Pro breadth analyst
├── skills/
│   └── ai-council/
│       └── SKILL.md         # Canonical orchestration workflow
├── commands/
│   └── ai-council.md        # Thin /ai-council command entrypoint
├── scripts/
│   ├── install-claude.sh           # Claude install script
│   └── install-cursor-project.sh  # Cursor project-local symlink helper
└── README.md
```

## Design philosophy and trade-offs

This plugin is markdown-first -- no runtime dependencies, no build step. The orchestration logic lives entirely in human-readable markdown files. This is a deliberate choice with real trade-offs:

**Strengths of the markdown-first approach:**
- Works immediately in any Cursor or Claude Code project without build complexity
- No dependency management, no version conflicts, no build pipeline
- Every part of the system is human-readable and editable
- Portable across Cursor and Claude Code with minimal adaptation

**Limitations:**
- No programmatic validation of agent responses -- the parent session must handle malformed output by following the failure-handling instructions in the workflow
- No retry logic beyond what the host platform provides
- Schema compliance depends on the models following instructions, which they occasionally do not
- The orchestration quality depends on the parent session's model -- a weaker parent model may not follow the multi-step workflow as precisely (the peer review stage mitigates this by providing structured scoring signal the parent can lean on)
- If the host platform changes how subagents or skills are loaded, the plugin could break without any code to debug

These are acceptable trade-offs for a plugin that prioritizes accessibility and simplicity. If you need stronger guarantees, consider wrapping the council in a code-based orchestrator that calls the same agents programmatically.
