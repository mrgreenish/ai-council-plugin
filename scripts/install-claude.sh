#!/usr/bin/env bash
# AI Council — Claude installer
# Copies the council skill and agent files into Claude user directories.
# Run from the ai-council-plugin root: bash scripts/install-claude.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

CLAUDE_SKILLS_DIR="${HOME}/.claude/skills"
CLAUDE_AGENTS_DIR="${HOME}/.claude/agents"

echo "AI Council — Claude installer"
echo "Plugin source: $PLUGIN_DIR"
echo ""

# Create target directories if they do not exist
mkdir -p "$CLAUDE_SKILLS_DIR/ai-council"
mkdir -p "$CLAUDE_AGENTS_DIR"

# Install skill
echo "Installing skill..."
cp "$PLUGIN_DIR/skills/ai-council/SKILL.md" "$CLAUDE_SKILLS_DIR/ai-council/SKILL.md"
echo "  $CLAUDE_SKILLS_DIR/ai-council/SKILL.md"

# Install agents
echo "Installing agents..."
cp "$PLUGIN_DIR/agents/council-gpt-54.md" "$CLAUDE_AGENTS_DIR/council-gpt-54.md"
echo "  $CLAUDE_AGENTS_DIR/council-gpt-54.md"

cp "$PLUGIN_DIR/agents/council-opus-46.md" "$CLAUDE_AGENTS_DIR/council-opus-46.md"
echo "  $CLAUDE_AGENTS_DIR/council-opus-46.md"

cp "$PLUGIN_DIR/agents/council-gemini-31-pro.md" "$CLAUDE_AGENTS_DIR/council-gemini-31-pro.md"
echo "  $CLAUDE_AGENTS_DIR/council-gemini-31-pro.md"

echo ""
echo "Done. The AI Council is now available in Claude."
echo ""
echo "To use it, ask Claude to use the ai-council skill, or invoke a council member directly:"
echo "  /council-gpt-54, /council-opus-46, /council-gemini-31-pro"
echo ""
echo "To uninstall:"
echo "  rm -rf ~/.claude/skills/ai-council"
echo "  rm ~/.claude/agents/council-gpt-54.md"
echo "  rm ~/.claude/agents/council-opus-46.md"
echo "  rm ~/.claude/agents/council-gemini-31-pro.md"
