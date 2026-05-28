#!/usr/bin/env bash
# sync.sh — pull current ~/.claude state back into this repo, then commit + push.
#
# Run this on the laptop where you made the changes; the other laptop pulls + runs ./install.sh.
#
# Usage:
#   ./sync.sh "commit message"
#   ./sync.sh --dry-run                # show diff, no commit
#   ./sync.sh --no-push "msg"          # commit but don't push
#
# Symmetric with install.sh — mirrors back: CLAUDE.md, SKILLS_INDEX.md, settings.json,
# commands/, skills/, agents/, hooks/.

set -euo pipefail

DRY_RUN=0
DO_PUSH=1
MSG=""
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --no-push) DO_PUSH=0 ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) MSG="$arg" ;;
  esac
done
MSG="${MSG:-sync claude config}"

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

copy_back() {
  # copy_back <src> <dest>
  local src="$1" dest="$2"
  [ ! -e "$src" ] && return 0
  if [ -e "$dest" ] && cmp -s "$src" "$dest"; then return 0; fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  echo "  → $(basename "$dest")"
}

copy_dir_back() {
  # copy_dir_back <src_dir> <dest_dir>
  local src="$1" dest="$2"
  [ ! -d "$src" ] && return 0
  mkdir -p "$dest"
  shopt -s nullglob
  for f in "$src"/*; do
    [ -d "$f" ] && continue
    copy_back "$f" "$dest/$(basename "$f")"
  done
  shopt -u nullglob
}

echo "Pulling ~/.claude → repo:"
copy_back     "$CLAUDE_DIR/CLAUDE.md"        "$DOTFILES_DIR/CLAUDE.md"
copy_back     "$CLAUDE_DIR/SKILLS_INDEX.md"  "$DOTFILES_DIR/SKILLS_INDEX.md"
copy_back     "$CLAUDE_DIR/settings.json"    "$DOTFILES_DIR/settings.json"
copy_dir_back "$CLAUDE_DIR/commands"         "$DOTFILES_DIR/commands"
copy_dir_back "$CLAUDE_DIR/skills"           "$DOTFILES_DIR/skills"
copy_dir_back "$CLAUDE_DIR/agents"           "$DOTFILES_DIR/agents"
copy_dir_back "$CLAUDE_DIR/hooks"            "$DOTFILES_DIR/hooks"

cd "$DOTFILES_DIR"
echo ""
echo "Repo status:"
git status --short

if [ "$DRY_RUN" -eq 1 ]; then
  echo ""
  echo "Diff (staged + unstaged):"
  git diff
  echo ""
  echo "Dry run — no commit, no push."
  exit 0
fi

if [ -z "$(git status --porcelain)" ]; then
  echo ""
  echo "(nothing to commit)"
  exit 0
fi

git add -A
git diff --cached --stat
git commit -m "$MSG"

if [ "$DO_PUSH" -eq 1 ]; then
  # Detect missing upstream and push with -u on first sync of a new branch.
  if git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
    git push
  else
    branch="$(git rev-parse --abbrev-ref HEAD)"
    echo "  (no upstream for '$branch' — pushing with -u origin $branch)"
    git push -u origin "$branch"
  fi
  echo ""
  echo "✓ Pushed. On the other laptop: git pull && ./install.sh"
else
  echo ""
  echo "✓ Committed (not pushed). Run 'git push' when ready."
fi
