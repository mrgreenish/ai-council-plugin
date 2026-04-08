#!/usr/bin/env python3

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SKILL_PATH = ROOT / "skills" / "ai-council" / "SKILL.md"


def main() -> int:
    text = SKILL_PATH.read_text()
    failures: list[str] = []

    match = re.search(
        r"\*\*Partial council \(2 of 3 models\):\*\*\s*```(?P<block>.*?)```",
        text,
        re.DOTALL,
    )
    if not match:
        print("Partial council template verification failed:")
        print("- could not find the partial council template block in SKILL.md")
        return 1

    block = match.group("block")

    if "### Peer review insights" in block:
        failures.append(
            "partial council template still includes a `### Peer review insights` section"
        )

    if "(peer: X)" in block:
        failures.append(
            "partial council template still includes peer-score placeholders"
        )

    if failures:
        print("Partial council template verification failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("Partial council template verification passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
