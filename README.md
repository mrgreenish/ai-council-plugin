# AI Council Plugin

A multi-model review council for high-stakes decisions. Three specialist AI models run in parallel, each with a different analytical role, and the parent session synthesizes the best final answer.

## What it does

Instead of asking one model a hard question, the council asks three simultaneously:

```
Your question
     │
     ▼
AI Council Skill (normalizes prompt into a brief)
     │
     ├──► council-gpt-54         (GPT-5.4 — adversarial analyst)
     ├──► council-opus-46        (Claude Opus 4.6 — production quality)
     └──► council-gemini-31-pro  (Gemini 3.1 Pro — breadth & alternatives)
                │
                ▼
     Parent session (judge + synthesis)
                │
                ▼
     Council Verdict (best final answer)
```

## Council members

| Agent | Model | Role |
|---|---|---|
| `council-gpt-54` | `gpt-5.4` | Adversarial analyst — edge cases, failure modes, strongest objections |
| `council-opus-46` | `claude-opus-4-6` | Production quality advocate — correctness, clarity, maintainability |
| `council-gemini-31-pro` | `gemini-3.1-pro` | Breadth analyst — alternatives, hidden assumptions, cross-cutting concerns |

All three return the same structured schema so the judge can compare them directly:

```
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

### Cursor — Option A: copy into a project (recommended, works immediately)

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

### Cursor — Option B: install as a global user plugin

Install the council once and use it across all your projects without copying files per repo.

**Step 1: clone the repo**

```bash
git clone https://github.com/filipvanharreveld/ai-council-plugin.git ~/cursor-plugins/ai-council
```

**Step 2: open Cursor settings**

Go to `Cursor → Settings → Plugins` (or open the command palette and search for `Plugins`).

**Step 3: add the plugin**

Click `Add plugin from local path` and select the folder you cloned:

```
~/cursor-plugins/ai-council
```

Cursor reads the `.cursor-plugin/plugin.json` manifest and auto-discovers the `agents/`, `skills/`, and `commands/` folders.

**Step 4: reload Cursor**

Restart or reload the window. The council is now available globally in all projects.

**To update:**

```bash
cd ~/cursor-plugins/ai-council
git pull
```

Then reload Cursor.

**To uninstall:**

Remove the plugin from `Cursor → Settings → Plugins`, then delete the cloned folder.

---

After installing via either option, the following are available:
- `/ai-council [your question]` — main command entrypoint
- `@ai-council` — attach the skill as context
- `/council-gpt-54`, `/council-opus-46`, `/council-gemini-31-pro` — individual council members

### Claude (install script)

Run the installer to copy the council files into your Claude user directories:

```bash
bash scripts/install-claude.sh
```

This installs:
- `skills/ai-council/SKILL.md` → `~/.claude/skills/ai-council/SKILL.md`
- `agents/council-gpt-54.md` → `~/.claude/agents/council-gpt-54.md`
- `agents/council-opus-46.md` → `~/.claude/agents/council-opus-46.md`
- `agents/council-gemini-31-pro.md` → `~/.claude/agents/council-gemini-31-pro.md`

> **Note:** The `/ai-council` slash command is a Cursor-only feature. Claude Code does not support command files in the same way. After installing, invoke the council by asking Claude to use the `ai-council` skill, or invoke a council member directly: `/council-gpt-54`, `/council-opus-46`, `/council-gemini-31-pro`.

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

1. **Test a single council member** — invoke one member with a simple question:
   ```
   /council-gpt-54 What is 2+2? (test only)
   ```
   Check the response header or model attribution to confirm it is running on GPT-5.4 and not a fallback model.

2. **Repeat for the other two members** — run the same check for `council-opus-46` (expect Claude Opus 4.6) and `council-gemini-31-pro` (expect Gemini 3.1 Pro).

3. **Confirm all 3 are distinct models** — if all three responses come from the same model, you are running on a fallback. Check that your plan supports Max Mode (required for GPT-5.4 and Claude Opus 4.6).

4. **Run a full council** — try a real question with `/ai-council` (Cursor) or by asking the AI to use the `ai-council` skill (Claude). Confirm the verdict includes responses from all 3 perspectives.

> **Model availability:** `gpt-5.4` and `claude-opus-4-6` require **Max Mode** on request-based Cursor plans. `gemini-3.1-pro` is available on standard plans. If a model is unavailable, Cursor falls back silently — use the verification steps above to detect this.

## Usage

### Recommended: `/ai-council` command

```
/ai-council should we add a caching layer between the API and the frontend?
/ai-council review this diff for bugs and missing tests
/ai-council what is the best approach for this implementation?
```

The command passes your request and any attached context to the `ai-council` skill, which handles the full workflow: mode inference, scope check, parallel council invocation, judging, escalation, and synthesis.

### Architecture examples

```
/ai-council Should we use a monorepo or separate repos for this service split?
/ai-council Where should this business logic live — in the API layer or the frontend?
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

1. **Preflight** — The skill infers the mode (`architecture`, `code-review`, or `implementation-choice`) from your request. If the request is ambiguous, it asks one short clarifying question. If the attached context is too large or covers too many independent concerns to review groundedly, it asks you to narrow the scope before proceeding.
2. **Normalize** — Your question is rewritten into a structured brief (task, constraints, deliverable, rubric, mode). Attached code or diffs are included as primary context.
3. **Parallel run** — All 3 council members are launched as parallel subagents simultaneously; their agent IDs are preserved for the escalation round.
4. **Failure check** — If a model fails or returns malformed output, the council continues with the remaining responses (minimum 2 to produce a verdict). A partial council is clearly labeled in the verdict.
5. **Judge** — The parent session scores each output on correctness, completeness, groundedness, practicality, and simplicity; scores appear in the final verdict.
6. **Escalation check** — If models materially disagree (different recommendations, contradictory correctness claims, or an unaddressed CRITICAL/HIGH risk), each conflicting agent is *resumed* with a focused follow-up question in one parallel round. If the disagreement round does not converge, the conflict is surfaced explicitly under "Unresolved uncertainty".
7. **Synthesis** — The final Council Verdict adopts consensus, preserves minority risks, and calls out unresolved uncertainty.

## Final output format

**Full council (all 3 models responded):**

```
## Council Verdict

### Recommendation
### Consensus points
### Key risks
### Minority flags
### Judge scores
| Dimension    | GPT-5.4 | Opus 4.6 | Gemini 3.1 Pro |
|---|---|---|---|
| Correctness  | X | X | X |
| Completeness | X | X | X |
| Groundedness | X | X | X |
| Practicality | X | X | X |
| Simplicity   | X | X | X |
### Unresolved uncertainty
### Models consulted (with confidence scores)
```

**Partial council (one model unavailable):**

When a model fails to respond, the verdict is labeled at the top and the judge table uses `—` for the missing model's column:

```
## Council Verdict

> Partial council: [Missing model] did not respond. Verdict is based on 2 of 3 perspectives.

### Recommendation
### Consensus points  (what both responding models agreed on)
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
### Unresolved uncertainty
### Models consulted
```

## Model availability notes

- `gpt-5.4` and `claude-opus-4-6` require **Max Mode** on request-based Cursor plans
- `gemini-3.1-pro` is available on standard plans
- If a model is unavailable on your plan, Cursor falls back to a compatible model — use the verification steps above to confirm you are not running 3 copies of the same fallback model
- The parent session (judge + synthesis) uses whatever model your active chat is running

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
│   └── install-claude.sh    # Claude install script
└── README.md
```
