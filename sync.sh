#!/usr/bin/env bash
# sync.sh — pull latest from ~/.claude back into this repo, then push
# Run this on the machine where you made changes, before switching to the other laptop.
# Usage: ./sync.sh "what changed"

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
MSG="${1:-sync claude config}"

echo "→ Pulling latest from ~/.claude into repo..."
cp "$CLAUDE_DIR/CLAUDE.md"      "$DOTFILES_DIR/CLAUDE.md"
cp "$CLAUDE_DIR/SKILLS_INDEX.md" "$DOTFILES_DIR/SKILLS_INDEX.md"
cp "$CLAUDE_DIR/settings.json"  "$DOTFILES_DIR/settings.json"
cp "$CLAUDE_DIR/commands/"*.md  "$DOTFILES_DIR/commands/"

echo "→ Committing and pushing..."
cd "$DOTFILES_DIR"
git add -A
git diff --cached --stat
git commit -m "$MSG" || echo "(nothing to commit)"
git push

echo ""
echo "✓ Pushed. On your other laptop run: git pull && ./install.sh"
