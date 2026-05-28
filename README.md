# claude-dotfiles

Personal Claude Code global config — synced across all my machines.
*Cấu hình global cá nhân cho Claude Code — đồng bộ trên tất cả các máy.*

> **What's new (v2):** added `/fix` and `/cook` workflows (Scout → Diagnose → Plan → Verify → Review) inspired by [ClaudeKit](https://claudekit.cc) principles, plus a `PreToolUse` **artifact-gate** hook that blocks `git push` / `gh pr create` / deploy commands unless evidence artifacts under `.claude-artifacts/` are present and the review decision is PASS.
>
> *Có gì mới (v2): thêm workflow `/fix` và `/cook` (Scout → Diagnose → Plan → Verify → Review) lấy cảm hứng từ ClaudeKit, kèm hook `artifact-gate` chặn `git push` / `gh pr create` / deploy khi chưa có đủ bằng chứng (artifacts) và review decision PASS.*

---

## What's included / Thành phần bao gồm

| Path | Purpose (EN) | Mục đích (VI) |
|------|---------|---------|
| `CLAUDE.md` | Global standards & skill table (~8800 lines) | Chuẩn & bảng skill global |
| `SKILLS_INDEX.md` | Line-number index for fast lookup | Chỉ mục số dòng để tra cứu |
| `settings.json` | Hooks, permissions, allowed tools | Hooks, quyền, công cụ cho phép |
| `commands/*.md` | Slash commands — incl. `/fix`, `/cook`, `/scout`, `/audit`, `/check`, `/new-next`, `/pr-prep` | Slash commands tùy chỉnh |
| `skills/*.md` | Project-defined skills (`debug`, `refactor`, `deploy`, `test-gen`, etc.) | Skills tự định nghĩa |
| `agents/` | Agent stubs (optional) | Stubs cho agent (optional) |
| `hooks/artifact-gate.sh` | Blocks shipping commands without complete evidence | Chặn lệnh ship khi thiếu evidence |
| `memory/MEMORY.md` | Persistent memory index | Chỉ mục bộ nhớ |
| `install.sh` / `sync.sh` | Bidirectional sync repo ↔ `~/.claude` | Đồng bộ 2 chiều |

---

## The `/fix` and `/cook` workflows

### `/fix <symptom>` — investigate-first bug fix
Refuses to write code before completing **Scout** (read repo) and **Diagnose** (answer 6 questions: exact symptom, repro steps, expected vs actual, root cause file:line, *why now*, blast radius).
- High-risk fixes (auth / billing / migrations / >5 files / protected branch) **stop and wait for human approval** even in `--auto` mode.
- The **3-strike rule**: if 3 fix attempts fail verification, STOP — open a discussion with the user. Patching a 4th time is how a cough becomes pneumonia.

### `/cook <feature>` — contract-first implementation
Refuses to write code before completing **Spec** (5 mandatory sections: expected output, acceptance criteria, scope boundary, non-negotiable constraints, touchpoints) and **Plan**. Even `--fast` skips Research, **not** Plan.

### `/scout <area>` — read-only reconnaissance
Produces a scout report (`.claude-artifacts/scout.md`) without touching any file. Useful before opening `/fix` or `/cook` on an unfamiliar area.

### Artifacts produced
Every `/fix` and `/cook` run leaves evidence under the project's `.claude-artifacts/`:

```
.claude-artifacts/
├── scout.md                  ← /fix and /cook
├── diagnosis.md              ← /fix only
├── spec.md                   ← /cook only
├── plan.md                   ← both
├── risk-gate.json            ← both
├── context-snippets.json     ← /cook
├── verification.json         ← both
├── review-decision.json      ← /cook (and /fix when relevant)
└── adversarial-validation.json ← /cook
```

The **artifact-gate hook** reads the **critical 4** before allowing `git push`, `gh pr create`, `npm publish`, `vercel deploy`, etc.:

1. `plan.md` — non-empty
2. `spec.md` **or** `diagnosis.md` — at least one, non-empty
3. `verification.json` — parses as JSON
4. `review-decision.json` — parses, `decision` ∈ `{PASS, PASS_WITH_RISK}`

The other artifacts (`risk-gate.json`, `context-snippets.json`, `adversarial-validation.json`) are produced by `/cook` for traceability but are **not** enforced by the gate — extend `hooks/artifact-gate.sh` if you want them mandatory. Override the gate per-command with `CLAUDE_SKIP_ARTIFACT_GATE=1`.

Add `.claude-artifacts/` to your project's `.gitignore` — they're local evidence, not committed deliverables.

---

## Setup on a new laptop / Cài đặt trên laptop mới

### 1. Install Claude Code / Cài Claude Code
```bash
npm install -g @anthropic-ai/claude-code
claude --version
```

### 2. (Optional) Install ClaudeKit CLI / *(Tùy chọn)* Cài ClaudeKit CLI
```bash
npm install -g claudekit-cli   # provides the `ck` binary; the Engineer kit content requires a subscription at claudekit.cc
```

### 3. Authenticate GitHub / Xác thực GitHub
```bash
brew install gh   # macOS; or apt install gh on Ubuntu
gh auth login
```

### 4. Clone + install / Clone + cài
```bash
git clone https://github.com/phanfullstack-12345/claude-dotfiles.git ~/claude-dotfiles
cd ~/claude-dotfiles
chmod +x install.sh sync.sh hooks/*.sh
./install.sh --dry-run    # preview first
./install.sh              # apply (with timestamped backups under ~/.claude-backups)
```

### 5. Verify / Kiểm tra
```bash
ls ~/.claude/CLAUDE.md ~/.claude/settings.json ~/.claude/commands/ ~/.claude/skills/ ~/.claude/hooks/
wc -l ~/.claude/CLAUDE.md
```

### 6. Start Claude Code / Khởi động
```bash
cd ~/your-project
claude
```

Then try the new commands / *Sau đó thử các lệnh mới*:
```text
/scout src/services/auth
/fix "login fails with 401 on Safari only"
/cook "add /api/orders/:id/cancel endpoint"
```

---

## Daily sync between two laptops / Đồng bộ hàng ngày giữa 2 laptops

**On the laptop where you made changes** / *Trên laptop có thay đổi*:
```bash
cd ~/claude-dotfiles
./sync.sh --dry-run                    # preview what would be committed
./sync.sh "added /fix workflow"        # commit + push
```

**On the other laptop** / *Trên laptop kia*:
```bash
cd ~/claude-dotfiles
git pull && ./install.sh
```

---

## install.sh flags / Các flag của install.sh

| Flag | Effect |
|------|--------|
| *(no flags)* | Apply, with timestamped backups in `~/.claude-backups/<TS>/` |
| `--dry-run` | Preview every action, write nothing |
| `--no-backup` | Skip backups (faster; riskier) |
| `--force` | Skip the "existing CLAUDE.md differs" prompt |
| `-h`, `--help` | Show usage |

`install.sh` is **idempotent** — re-running with no upstream change is a no-op (each file is compared with `cmp` before copying).

---

## Quick reference / Bảng tra cứu nhanh

| Situation / Tình huống | Command |
|-----------|---------|
| New laptop setup / *Setup laptop mới* | `git clone … && ./install.sh` |
| Just changed config locally / *Vừa đổi config* | `./sync.sh "what changed"` |
| Pull on the other laptop / *Lấy về laptop kia* | `git pull && ./install.sh` |
| Preview install / *Xem trước install* | `./install.sh --dry-run` |
| Preview sync / *Xem trước sync* | `./sync.sh --dry-run` |
| Skip artifact-gate one time / *Bỏ qua gate 1 lần* | `CLAUDE_SKIP_ARTIFACT_GATE=1 git push …` |
| Restore a previous config / *Khôi phục config cũ* | `cp -r ~/.claude-backups/<TS>/* ~/.claude/` |
| Search skill table / *Tra cứu skills* | `grep -n "Security" ~/.claude/CLAUDE.md` |

---

## Philosophy / Triết lý

This repo embodies the lesson from production-grade Claude Code workflows:

> Prompt is just a hint. **Hooks are control.** Score-driven approval (`9/10, ship it`) is theater.
> Evidence-gated approval — `.claude-artifacts/` populated, `review-decision.json` is PASS — is real.
> 
> *Prompt chỉ là gợi ý. **Hook mới là kiểm soát.** Approval dựa vào score là diễn. Approval dựa vào artifact mới là thật.*

Inspired by [ClaudeKit Engineer](https://claudekit.cc) by mrgoonie. This repo reimplements the principles natively in plain markdown + bash so it works on any machine without a subscription.

<!-- push-test: verified 2025 -->
