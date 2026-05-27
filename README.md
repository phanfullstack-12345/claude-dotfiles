# claude-dotfiles

Personal Claude Code global config — synced across all machines.

## What's included

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Global skills & instructions (8000+ lines) |
| `SKILLS_INDEX.md` | Line-number index for fast section lookup |
| `settings.json` | Hooks, permissions, allowed tools |
| `commands/*.md` | Custom slash commands (`/audit`, `/check`, `/new-next`, `/pr-prep`) |
| `memory/MEMORY.md` | Persistent memory index |

## First-time setup on a new laptop

```bash
# 1. Install Claude Code
npm install -g @anthropic-ai/claude-code

# 2. Clone this repo
git clone git@github.com:YOUR_USERNAME/claude-dotfiles.git ~/claude-dotfiles

# 3. Run the installer
cd ~/claude-dotfiles
chmod +x install.sh sync.sh
./install.sh

# 4. Restart Claude Code
```

## Daily workflow

**After making changes to Claude config on this machine:**
```bash
cd ~/claude-dotfiles
./sync.sh "added NestJS patterns"
```

**On the other laptop, to get latest:**
```bash
cd ~/claude-dotfiles
git pull && ./install.sh
```

## Keeping it up to date

When you add new skills or change settings via Claude Code, run `./sync.sh` before
switching laptops. That's it.
