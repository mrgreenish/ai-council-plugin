---
name: ai-council
description: Run the AI Council on any high-stakes question. Invokes 3 specialist models in parallel (GPT-5.4, Claude Opus 4.6, Gemini 3.1 Pro) and synthesizes the best final answer. Use for architecture decisions, code review, and ambiguous implementation choices.
---

Run the AI Council on the following request using the `ai-council` skill.

The request is: {{input}}

If code, files, or a diff are attached or selected, treat them as the primary context for the council.

Infer the mode automatically from the request:
- If the request involves reviewing code, a PR, or a diff → `code-review`
- If the request involves choosing a pattern, data model, or service boundary → `architecture`
- If the request involves picking between implementation options → `implementation-choice`
- If unclear, ask one short clarifying question before proceeding

Then follow the full `ai-council` skill workflow:
1. Normalize the request into a structured brief
2. Invoke all 3 council members in parallel
3. Judge outputs on correctness, completeness, groundedness, practicality, and simplicity
4. Run the escalation round if models materially disagree
5. Synthesize and present the final Council Verdict
