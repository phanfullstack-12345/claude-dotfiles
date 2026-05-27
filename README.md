# claude-dotfiles

Personal Claude Code global config — synced across all machines.
*Cấu hình global cá nhân cho Claude Code — đồng bộ trên tất cả các máy.*

## What's included / Thành phần bao gồm

| File | Purpose (English) | Mục đích (Tiếng Việt) |
|------|---------|---------|
| `CLAUDE.md` | Global skills & instructions (8800+ lines) | Kỹ năng & hướng dẫn global (Hơn 8800 dòng) |
| `SKILLS_INDEX.md` | Line-number index for fast section lookup | Chỉ mục số dòng để tra cứu nhanh các phần |
| `settings.json` | Hooks, permissions, allowed tools | Hooks, quyền, và các công cụ được phép |
| `commands/*.md` | Custom slash commands (`/audit`, `/check`, etc.) | Các lệnh slash tùy chỉnh (`/audit`, `/check`, v.v.) |
| `memory/MEMORY.md` | Persistent memory index | Chỉ mục bộ nhớ lưu trữ cố định |

***

## Setup on a new laptop (step by step) / Cài đặt trên laptop mới (từng bước)

### Step 1 — Install Claude Code (if not installed)
### *Bước 1 — Cài Claude Code (nếu chưa có)*

```bash
npm install -g @anthropic-ai/claude-code
```

Check if installed successfully / *Kiểm tra đã cài thành công*:
```bash
claude --version
```

***

### Step 2 — Login to GitHub CLI
### *Bước 2 — Đăng nhập GitHub CLI*

```bash
# Install gh if not installed (macOS)
# Cài gh nếu chưa có (macOS)
brew install gh

# Login / Đăng nhập
gh auth login
# → choose/chọn: GitHub.com → HTTPS → Login with a web browser
# → copy code, open browser/mở trình duyệt, paste into/dán vào github.com/login/device
```

***

### Step 3 — Clone the repo to your laptop
### *Bước 3 — Clone repo về laptop*

```bash
git clone https://github.com/phanfullstack-12345/claude-dotfiles.git ~/claude-dotfiles
```

***

### Step 4 — Run the installer
### *Bước 4 — Chạy installer*

```bash
cd ~/claude-dotfiles
chmod +x install.sh sync.sh
./install.sh
```

The output will look like this / *Output sẽ như thế này*:
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

***

### Step 5 — Verify everything works
### *Bước 5 — Verify mọi thứ hoạt động*

```bash
# Check if files were copied to the right place
# Kiểm tra các file đã được copy vào đúng chỗ chưa
ls ~/.claude/CLAUDE.md              # must exist / phải có
ls ~/.claude/SKILLS_INDEX.md        # must exist / phải có
ls ~/.claude/settings.json          # must exist / phải có
ls ~/.claude/commands/              # must have 4 files / phải có 4 files: audit.md, check.md, new-next.md, pr-prep.md

# Check CLAUDE.md size (must be ~8800+ lines)
# Kiểm tra dung lượng CLAUDE.md (phải ~8800+ dòng)
wc -l ~/.claude/CLAUDE.md
```

***

### Step 6 — Start Claude Code
### *Bước 6 — Khởi động Claude Code*

```bash
# Go to any project folder / Vào bất kỳ project folder nào
cd ~/your-project

# Start Claude Code / Khởi động Claude Code
claude
```

In Claude Code, try the custom commands / *Trong Claude Code, thử các custom commands*:
```text
/audit       ← custom command must work / custom command phải hoạt động
/check       ← custom command must work / custom command phải hoạt động
/new-next    ← custom command must work / custom command phải hoạt động
/pr-prep     ← custom command must work / custom command phải hoạt động
```

***

## Daily workflow — sync between 2 laptops / Quy trình hàng ngày — đồng bộ giữa 2 laptops

### When you just added skills/changed config, and want to sync to the other laptop:
### *Khi vừa thêm skills / đổi config, muốn sync sang laptop kia:*

**On the working laptop** (the one with new skills/config):
***Trên laptop đang làm việc*** *(laptop vừa thêm skills/config mới):*
```bash
cd ~/claude-dotfiles
./sync.sh "change description / mô tả thay đổi — vd: added testing skills"
```

**On the other laptop** to receive updates:
***Trên laptop kia*** *để nhận updates:*
```bash
cd ~/claude-dotfiles
git pull && ./install.sh
```

***

### When Claude Code auto-updates `~/.claude/CLAUDE.md` during a session:
### *Khi Claude Code tự cập nhật `~/.claude/CLAUDE.md` trong session:*

Claude Code edits the file directly during the session. After the session, run sync:
*Claude Code edit file trực tiếp trong session. Sau khi xong session, chạy sync:*

```bash
# Working laptop / Laptop đang làm việc
cd ~/claude-dotfiles && ./sync.sh "added new skills: XYZ"

# The other laptop pulls updates / Laptop kia lấy về
cd ~/claude-dotfiles && git pull && ./install.sh
```

***

## Quick reference / Bảng tra cứu nhanh

| Situation / Tình huống | Command |
|-----------|---------|
| Setup new laptop (first time)<br>*Setup laptop mới (lần đầu)* | `git clone ... && ./install.sh` |
| Just added skills, want to sync<br>*Vừa thêm skills, muốn sync* | `./sync.sh "notes / ghi chú"` |
| Other laptop pulls updates<br>*Laptop kia lấy updates* | `git pull && ./install.sh` |
| Fast skill lookup<br>*Xem skills nhanh* | `grep "Security" ~/.claude/SKILLS_INDEX.md` |
| Read a specific skill<br>*Đọc 1 skill cụ thể* | `# Read ~/.claude/CLAUDE.md offset:4908 limit:284` |

Sources

