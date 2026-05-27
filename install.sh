#!/usr/bin/env bash
# install.sh — sync claude-dotfiles to ~/.claude on any machine
# Usage: ./install.sh
# Run this on a new laptop after cloning the repo.

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
USERNAME=$(whoami)
MEMORY_DIR="$CLAUDE_DIR/projects/-Users-${USERNAME}/memory"

echo "Installing claude-dotfiles from: $DOTFILES_DIR"
echo "Target: $CLAUDE_DIR"
echo ""

# ── Core files ────────────────────────────────────────────────────────────────
echo "→ Copying CLAUDE.md..."
cp "$DOTFILES_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"

echo "→ Copying SKILLS_INDEX.md..."
cp "$DOTFILES_DIR/SKILLS_INDEX.md" "$CLAUDE_DIR/SKILLS_INDEX.md"

echo "→ Copying settings.json..."
cp "$DOTFILES_DIR/settings.json" "$CLAUDE_DIR/settings.json"

# ── Custom slash commands ──────────────────────────────────────────────────────
echo "→ Copying commands/..."
mkdir -p "$CLAUDE_DIR/commands"
cp "$DOTFILES_DIR/commands/"*.md "$CLAUDE_DIR/commands/"

# ── Memory index ──────────────────────────────────────────────────────────────
echo "→ Setting up memory index..."
mkdir -p "$MEMORY_DIR"

# Update MEMORY.md path to point to the correct SKILLS_INDEX.md for this machine
sed "s|../../../SKILLS_INDEX.md|$CLAUDE_DIR/SKILLS_INDEX.md|g" \
    "$DOTFILES_DIR/memory/MEMORY.md" > "$MEMORY_DIR/MEMORY.md"

echo ""
echo "✓ Done! All claude config synced to $CLAUDE_DIR"
echo ""
echo "Note: If your username differs from the original machine,"
echo "      memory is installed at: $MEMORY_DIR"
echo ""
echo "Restart Claude Code for changes to take effect."
