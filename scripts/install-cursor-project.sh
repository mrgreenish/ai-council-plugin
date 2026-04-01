#!/usr/bin/env bash
# AI Council — project-local Cursor install (for this repo)
# Symlinks canonical agents/, skills/, and commands/ into .cursor/ so the
# plugin works in this workspace without duplicating files. Run from repo root:
#   bash scripts/install-cursor-project.sh
#
# After running, reload Cursor. Same effect as README "Option A" copy, but
# edits stay single-sourced at the repo paths.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$ROOT"

mkdir -p .cursor/agents .cursor/skills/ai-council .cursor/commands

ln -sf ../../agents/council-gpt-54.md .cursor/agents/council-gpt-54.md
ln -sf ../../agents/council-opus-46.md .cursor/agents/council-opus-46.md
ln -sf ../../agents/council-gemini-31-pro.md .cursor/agents/council-gemini-31-pro.md
ln -sf ../../../skills/ai-council/SKILL.md .cursor/skills/ai-council/SKILL.md
ln -sf ../../commands/ai-council.md .cursor/commands/ai-council.md

echo "Linked AI Council into .cursor/ (project-local). Reload Cursor to pick it up."
