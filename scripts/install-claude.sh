#!/usr/bin/env bash
# AI Council — Claude installer
# Copies the council skill and agent files into Claude user directories.
# Run from the ai-council-plugin root: bash scripts/install-claude.sh
#
# Note: The /ai-council slash command is a Cursor-only feature.
# Claude Code users invoke the council via the ai-council skill directly.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

CLAUDE_SKILLS_DIR="${HOME}/.claude/skills"
CLAUDE_AGENTS_DIR="${HOME}/.claude/agents"

FORCE=false
if [[ "${1:-}" == "--force" ]]; then
  FORCE=true
fi

echo "AI Council — Claude installer"
echo "Plugin source: $PLUGIN_DIR"
echo ""

# Create target directories if they do not exist
mkdir -p "$CLAUDE_SKILLS_DIR/ai-council"
mkdir -p "$CLAUDE_AGENTS_DIR"

# Helper: copy with overwrite protection
safe_copy() {
  local src="$1"
  local dst="$2"

  if [ -f "$dst" ] && [ "$FORCE" = false ]; then
    echo "  WARNING: $dst already exists."
    printf "  Overwrite? [y/N] "
    read -r confirm
    if [ "${confirm:-N}" != "y" ] && [ "${confirm:-N}" != "Y" ]; then
      echo "  Skipped: $dst"
      return
    fi
  fi

  cp "$src" "$dst"
  echo "  Installed: $dst"
}

# Install skill
echo "Installing skill..."
safe_copy "$PLUGIN_DIR/skills/ai-council/SKILL.md" "$CLAUDE_SKILLS_DIR/ai-council/SKILL.md"

# Install agents
echo "Installing agents..."
safe_copy "$PLUGIN_DIR/agents/council-gpt-54.md"       "$CLAUDE_AGENTS_DIR/council-gpt-54.md"
safe_copy "$PLUGIN_DIR/agents/council-opus-46.md"      "$CLAUDE_AGENTS_DIR/council-opus-46.md"
safe_copy "$PLUGIN_DIR/agents/council-gemini-31-pro.md" "$CLAUDE_AGENTS_DIR/council-gemini-31-pro.md"

echo ""
echo "Done. The AI Council is now available in Claude."
echo ""
echo "Usage (Claude Code):"
echo "  Ask Claude to use the ai-council skill for high-stakes questions."
echo "  Or invoke a council member directly:"
echo "    /council-gpt-54, /council-opus-46, /council-gemini-31-pro"
echo ""
echo "Note: The /ai-council command is Cursor-only and is NOT installed by this script."
echo ""
echo "To uninstall:"
echo "  rm -rf ~/.claude/skills/ai-council"
echo "  rm ~/.claude/agents/council-gpt-54.md"
echo "  rm ~/.claude/agents/council-opus-46.md"
echo "  rm ~/.claude/agents/council-gemini-31-pro.md"
echo ""
echo "To force-overwrite an existing install without prompts:"
echo "  bash scripts/install-claude.sh --force"
