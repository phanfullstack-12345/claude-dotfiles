# claude-dotfiles

Personal Claude Code global config — synced across all machines.

## What's included

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Global skills & instructions (8800+ lines) |
| `SKILLS_INDEX.md` | Line-number index for fast section lookup |
| `settings.json` | Hooks, permissions, allowed tools |
| `commands/*.md` | Custom slash commands (`/audit`, `/check`, `/new-next`, `/pr-prep`) |
| `memory/MEMORY.md` | Persistent memory index |

---

## Setup on a new laptop (step by step)

### Bước 1 — Cài Claude Code (nếu chưa có)

```bash
npm install -g @anthropic-ai/claude-code
```

Kiểm tra đã cài thành công:
```bash
claude --version
```

---

### Bước 2 — Đăng nhập GitHub CLI

```bash
# Cài gh nếu chưa có (macOS)
brew install gh

# Đăng nhập
gh auth login
# → chọn: GitHub.com → HTTPS → Login with a web browser
# → copy code, mở browser, paste vào github.com/login/device
```

---

### Bước 3 — Clone repo về laptop

```bash
git clone https://github.com/phanfullstack-12345/claude-dotfiles.git ~/claude-dotfiles
```

---

### Bước 4 — Chạy installer

```bash
cd ~/claude-dotfiles
chmod +x install.sh sync.sh
./install.sh
```

Output sẽ như thế này:
```
Installing claude-dotfiles from: /Users/<you>/claude-dotfiles
Target: /Users/<you>/.claude

→ Copying CLAUDE.md...
→ Copying SKILLS_INDEX.md...
→ Copying settings.json...
→ Copying commands/...
→ Setting up memory index...

✓ Done! All claude config synced to /Users/<you>/.claude
```

---

### Bước 5 — Verify mọi thứ hoạt động

```bash
# Kiểm tra các file đã được copy vào đúng chỗ chưa
ls ~/.claude/CLAUDE.md              # phải có
ls ~/.claude/SKILLS_INDEX.md        # phải có
ls ~/.claude/settings.json          # phải có
ls ~/.claude/commands/              # phải có 4 files: audit.md, check.md, new-next.md, pr-prep.md

# Kiểm tra dung lượng CLAUDE.md (phải ~8800+ dòng)
wc -l ~/.claude/CLAUDE.md
```

---

### Bước 6 — Khởi động Claude Code

```bash
# Vào bất kỳ project folder nào
cd ~/your-project

# Khởi động Claude Code
claude
```

Trong Claude Code, thử các custom commands:
```
/audit       ← custom command phải hoạt động
/check       ← custom command phải hoạt động
/new-next    ← custom command phải hoạt động
/pr-prep     ← custom command phải hoạt động
```

---

## Daily workflow — sync giữa 2 laptops

### Khi vừa thêm skills / đổi config, muốn sync sang laptop kia:

**Trên laptop đang làm việc** (laptop vừa thêm skills/config mới):
```bash
cd ~/claude-dotfiles
./sync.sh "mô tả thay đổi — vd: added testing skills"
```

**Trên laptop kia** để nhận updates:
```bash
cd ~/claude-dotfiles
git pull && ./install.sh
```

---

### Khi Claude Code tự cập nhật `~/.claude/CLAUDE.md` trong session:

Claude Code edit file trực tiếp trong session. Sau khi xong session, chạy sync:

```bash
# Laptop đang làm việc
cd ~/claude-dotfiles && ./sync.sh "added new skills: XYZ"

# Laptop kia lấy về
cd ~/claude-dotfiles && git pull && ./install.sh
```

---

## Quick reference

| Tình huống | Command |
|-----------|---------|
| Setup laptop mới (lần đầu) | `git clone ... && ./install.sh` |
| Vừa thêm skills, muốn sync | `./sync.sh "ghi chú"` |
| Laptop kia lấy updates | `git pull && ./install.sh` |
| Xem skills nhanh | `grep "Security" ~/.claude/SKILLS_INDEX.md` |
| Đọc 1 skill cụ thể | `# Read ~/.claude/CLAUDE.md offset:4908 limit:284` |
