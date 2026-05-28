#!/usr/bin/env bash
# install.sh — sync claude-dotfiles to ~/.claude on any machine.
#
# Usage:
#   ./install.sh                 # apply, with timestamped backup of replaced files
#   ./install.sh --dry-run       # preview, no changes
#   ./install.sh --no-backup     # apply without making backups (faster, riskier)
#   ./install.sh --force         # overwrite without prompting (still backs up unless --no-backup)
#
# Idempotent: re-running with no upstream changes is a no-op.

set -euo pipefail

# ── Flags ─────────────────────────────────────────────────────────────────────
DRY_RUN=0
DO_BACKUP=1
FORCE=0
for arg in "$@"; do
  case "$arg" in
    --dry-run)   DRY_RUN=1 ;;
    --no-backup) DO_BACKUP=0 ;;
    --force)     FORCE=1 ;;
    -h|--help)
      sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "Unknown flag: $arg"; exit 2 ;;
  esac
done

# ── Paths ─────────────────────────────────────────────────────────────────────
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
USERNAME="$(whoami)"
MEMORY_DIR="$CLAUDE_DIR/projects/-Users-${USERNAME}/memory"
BACKUP_ROOT="$HOME/.claude-backups"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$BACKUP_ROOT/$TS"

# ── Helpers ───────────────────────────────────────────────────────────────────
say()   { printf '%s\n' "$*"; }
note()  { printf '  → %s\n' "$*"; }
warn()  { printf '  ! %s\n' "$*" >&2; }

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '    [dry-run] %s\n' "$*"
  else
    eval "$@"
  fi
}

backup_if_exists() {
  local target="$1"
  [ "$DO_BACKUP" -eq 0 ] && return 0
  [ ! -e "$target" ]    && return 0
  local rel="${target#$CLAUDE_DIR/}"
  local dest="$BACKUP_DIR/$rel"
  run "mkdir -p \"$(dirname "$dest")\""
  run "cp -a \"$target\" \"$dest\""
}

sync_file() {
  # sync_file <src> <dest>
  local src="$1" dest="$2"
  [ ! -e "$src" ] && { warn "source missing: $src"; return 0; }
  if [ -e "$dest" ] && cmp -s "$src" "$dest"; then
    return 0   # idempotent — already in sync
  fi
  backup_if_exists "$dest"
  run "mkdir -p \"$(dirname "$dest")\""
  run "cp \"$src\" \"$dest\""
  note "synced $(basename "$src")"
}

sync_dir() {
  # sync_dir <src_dir> <dest_dir> — mirror top-level files (additive; does not delete)
  local src="$1" dest="$2"
  [ ! -d "$src" ] && { warn "source dir missing: $src"; return 0; }
  run "mkdir -p \"$dest\""
  shopt -s nullglob
  for f in "$src"/*; do
    [ -d "$f" ] && continue
    sync_file "$f" "$dest/$(basename "$f")"
  done
  shopt -u nullglob
}

# ── Pre-flight ────────────────────────────────────────────────────────────────
say "claude-dotfiles installer"
say "  repo:   $DOTFILES_DIR"
say "  target: $CLAUDE_DIR"
[ "$DRY_RUN"   -eq 1 ] && say "  mode:   DRY RUN (no changes)"
[ "$DO_BACKUP" -eq 1 ] && say "  backup: $BACKUP_DIR (created lazily)"
say ""

# Refuse to silently clobber a divergent CLAUDE.md unless --force or --dry-run.
# Skip the prompt entirely under non-interactive stdin (CI, piped, no tty) — otherwise
# `read -r` returns 1 under `set -e` and aborts the install before any file is copied.
if [ -d "$CLAUDE_DIR" ] && [ -f "$CLAUDE_DIR/CLAUDE.md" ] && [ "$FORCE" -eq 0 ] && [ "$DRY_RUN" -eq 0 ]; then
  if ! cmp -s "$DOTFILES_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"; then
    say "Existing CLAUDE.md differs from repo. Backups will land in: $BACKUP_DIR"
    if [ -t 0 ]; then
      say "Press Enter to continue, or Ctrl+C to abort (use --force to skip this prompt)."
      read -r _ || true
    else
      say "Non-interactive stdin detected — proceeding without prompt (existing files will be backed up)."
    fi
  fi
fi

run "mkdir -p \"$CLAUDE_DIR\""

# ── Core files ────────────────────────────────────────────────────────────────
say "Core files:"
sync_file "$DOTFILES_DIR/CLAUDE.md"        "$CLAUDE_DIR/CLAUDE.md"
sync_file "$DOTFILES_DIR/SKILLS_INDEX.md"  "$CLAUDE_DIR/SKILLS_INDEX.md"
sync_file "$DOTFILES_DIR/settings.json"    "$CLAUDE_DIR/settings.json"

# ── Slash commands ────────────────────────────────────────────────────────────
say ""
say "Slash commands:"
sync_dir "$DOTFILES_DIR/commands" "$CLAUDE_DIR/commands"

# ── Skills ────────────────────────────────────────────────────────────────────
if [ -d "$DOTFILES_DIR/skills" ]; then
  say ""
  say "Skills:"
  sync_dir "$DOTFILES_DIR/skills" "$CLAUDE_DIR/skills"
fi

# ── Agents ────────────────────────────────────────────────────────────────────
if [ -d "$DOTFILES_DIR/agents" ] && [ -n "$(ls -A "$DOTFILES_DIR/agents" 2>/dev/null || true)" ]; then
  say ""
  say "Agents:"
  sync_dir "$DOTFILES_DIR/agents" "$CLAUDE_DIR/agents"
fi

# ── Hook scripts ──────────────────────────────────────────────────────────────
if [ -d "$DOTFILES_DIR/hooks" ]; then
  say ""
  say "Hook scripts:"
  run "mkdir -p \"$CLAUDE_DIR/hooks\""
  shopt -s nullglob
  for h in "$DOTFILES_DIR/hooks"/*.sh; do
    sync_file "$h" "$CLAUDE_DIR/hooks/$(basename "$h")"
    [ "$DRY_RUN" -eq 0 ] && chmod +x "$CLAUDE_DIR/hooks/$(basename "$h")"
  done
  shopt -u nullglob
fi

# ── Memory index ──────────────────────────────────────────────────────────────
say ""
say "Memory index:"
run "mkdir -p \"$MEMORY_DIR\""
if [ -f "$DOTFILES_DIR/memory/MEMORY.md" ]; then
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '    [dry-run] write %s with rewritten SKILLS_INDEX path\n' "$MEMORY_DIR/MEMORY.md"
  else
    backup_if_exists "$MEMORY_DIR/MEMORY.md"
    sed "s|../../../SKILLS_INDEX.md|$CLAUDE_DIR/SKILLS_INDEX.md|g" \
        "$DOTFILES_DIR/memory/MEMORY.md" > "$MEMORY_DIR/MEMORY.md"
    note "wrote MEMORY.md"
  fi
fi

# ── Done ──────────────────────────────────────────────────────────────────────
say ""
if [ "$DRY_RUN" -eq 1 ]; then
  say "Dry run complete. No files changed."
else
  say "✓ Install complete."
  [ "$DO_BACKUP" -eq 1 ] && [ -d "$BACKUP_DIR" ] && say "  Backups kept at: $BACKUP_DIR"
  say ""
  say "Restart Claude Code for changes to take effect."
fi
