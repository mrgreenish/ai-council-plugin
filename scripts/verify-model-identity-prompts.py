#!/usr/bin/env python3

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
AGENT_FILES = [
    ROOT / "agents" / "council-gpt-54.md",
    ROOT / "agents" / "council-opus-46.md",
    ROOT / "agents" / "council-gemini-31-pro.md",
]
RUNTIME_ID_PHRASE = "actual runtime model identity"
UNKNOWN_PHRASE = "If you cannot determine it reliably, write `UNKNOWN`"
SLOT_GUARD_PHRASE = "Do not report your assigned council slot"


def main() -> int:
    failures: list[str] = []

    for path in AGENT_FILES:
        text = path.read_text()

        if re.search(
            r"## Model Identity\s*\n(GPT-5\.4|Claude Opus 4\.6|Gemini 3\.1 Pro)\b",
            text,
        ):
            failures.append(
                f"{path.name}: hardcodes a specific model name in the `## Model Identity` template"
            )

        if "always write exactly" in text:
            failures.append(
                f"{path.name}: still tells the agent to always write an assigned identity"
            )

        if RUNTIME_ID_PHRASE not in text:
            failures.append(
                f"{path.name}: missing instruction to report the actual runtime model identity"
            )

        if UNKNOWN_PHRASE not in text:
            failures.append(
                f"{path.name}: missing `UNKNOWN` fallback for uncertain runtime identity"
            )

        if SLOT_GUARD_PHRASE not in text:
            failures.append(
                f"{path.name}: missing guard against reporting the assigned council slot"
            )

    if failures:
        print("Model identity prompt verification failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("Model identity prompt verification passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
