# claude-dotfiles

Personal Claude Code global config — synced across all my machines.
*Cấu hình global cá nhân cho Claude Code — đồng bộ trên tất cả các máy.*

> **What's new (v2):** added `/fix` and `/cook` workflows (Scout → Diagnose → Plan → Apply → Verify → Review) inspired by [ClaudeKit](https://claudekit.cc) principles, plus a `PreToolUse` **artifact-gate** hook that blocks `git push` / `gh pr create` / deploy commands unless evidence artifacts under `.claude-artifacts/` are present and the review decision is PASS.
>
> *Có gì mới (v2): thêm workflow `/fix` và `/cook` (Scout → Diagnose → Plan → Apply → Verify → Review) lấy cảm hứng từ ClaudeKit, kèm hook `artifact-gate` chặn `git push` / `gh pr create` / deploy khi chưa có đủ bằng chứng (artifacts) và review decision PASS.*

---

## What's included / Thành phần bao gồm

| Path | Purpose (EN) | Mục đích (VI) |
|------|---------|---------|
| `CLAUDE.md` | Global standards & skill table (~8800 lines) | Chuẩn & bảng skill global |
| `SKILLS_INDEX.md` | Line-number index for fast lookup | Chỉ mục số dòng để tra cứu |
| `settings.json` | Hooks, permissions, allowed tools | Hooks, quyền, công cụ cho phép |
| `commands/*.md` | Slash commands — incl. `/fix`, `/cook`, `/scout` | Slash commands tùy chỉnh |
| `skills/*.md` | Project-defined skills (`debug`, `refactor`, `deploy`, `test-gen`, etc.) | Skills tự định nghĩa |
| `agents/` | Agent stubs (optional) | Stubs cho agent (optional) |
| `hooks/artifact-gate.sh` | Blocks shipping commands without complete evidence | Chặn lệnh ship khi thiếu evidence |
| `memory/MEMORY.md` | Persistent memory index | Chỉ mục bộ nhớ |
| `install.sh` / `sync.sh` | Bidirectional sync repo ↔ `~/.claude` | Đồng bộ 2 chiều |

---

## Setup on a new laptop / Cài đặt trên laptop mới

### 1. Install Claude Code / Cài Claude Code
```bash
npm install -g @anthropic-ai/claude-code
claude --version
```

### 2. Authenticate GitHub / Xác thực GitHub
```bash
brew install gh   # macOS; or: apt install gh (Ubuntu)
gh auth login
gh auth setup-git
gh config set git_protocol https --host github.com
```

### 3. Clone + install / Clone + cài
```bash
git clone https://github.com/phanfullstack-12345/claude-dotfiles.git ~/claude-dotfiles
cd ~/claude-dotfiles
chmod +x install.sh sync.sh hooks/*.sh
./install.sh --dry-run    # preview first / xem trước
./install.sh              # apply (backs up old files to ~/.claude-backups/)
```

### 4. Verify / Kiểm tra
```bash
ls ~/.claude/commands/    # should show fix.md cook.md scout.md
ls ~/.claude/hooks/       # should show artifact-gate.sh
ls ~/.claude/skills/      # should show debug.md refactor.md …
```

### 5. Start using / Bắt đầu dùng
```bash
cd ~/your-project
claude
```

---

## How to use / Cách sử dụng

### Step 0 — Start Claude Code in your project

```bash
cd ~/my-project
claude
```

---

### `/scout <area>` — Khảo sát code (không sửa gì)

**Dùng khi:** mới vào project lạ, muốn hiểu cấu trúc trước khi làm gì.

```
/scout src/services/auth
/scout src/api/orders
/scout .
```

**Claude sẽ làm:**
1. Đọc toàn bộ khu vực được chỉ định
2. Tạo báo cáo tại `.claude-artifacts/scout.md` gồm:
   - Project profile (stack, entry points, config)
   - Target area map (files, dependencies)
   - Recent activity (git log)
   - Convention survey (patterns, naming)
   - Unknowns & questions

**Ví dụ thực tế:**
```
# Tình huống: mới join team, chưa biết code auth hoạt động thế nào
/scout src/middleware/auth

# Sau khi đọc report → mới bắt đầu /fix hoặc /cook
```

---

### `/fix "<symptom>"` — Sửa bug

**Dùng khi:** có bug, có lỗi, có thứ gì đó không chạy đúng.

```
/fix "login fails with 401 on Safari only"
/fix "checkout page crashes when cart is empty"
/fix "API /api/orders returns 500 intermittently"
/fix "image upload hangs after 2MB"
```

**Flags (tùy chọn):**
```
/fix "bug description" --auto       # ít hỏi xác nhận hơn
/fix "bug description" --no-stop    # tắt 3-strike rule (tiếp tục dù fail nhiều lần)
```

**Claude đi qua 6 bước — bạn approve ở bước 3:**

```
Phase 1 — Scout      Đọc các file liên quan
Phase 2 — Diagnose   Trả lời 6 câu hỏi:
                       1. Exact symptom (triệu chứng chính xác)
                       2. Repro steps (cách tái hiện)
                       3. Expected vs actual (mong đợi vs thực tế)
                       4. Root cause: file:line (nguyên nhân gốc)
                       5. Why now? (tại sao bây giờ mới xảy ra)
                       6. Blast radius (phạm vi ảnh hưởng)
Phase 3 — Plan       ← BẠN APPROVE trước khi sửa
Phase 4 — Apply      Sửa code
Phase 5 — Verify     Chạy test, xác nhận fix hoạt động
Phase 6 — Review     Tổng kết
```

**3-strike rule:** Nếu sửa 3 lần vẫn fail → Claude **dừng lại hỏi bạn**, không tự mò thêm.

**High-risk auto-stop:** Auth / billing / migrations / >5 files / protected branch → Claude **luôn hỏi xác nhận** dù đang ở `--auto` mode.

**Artifacts được tạo ra:**
```
.claude-artifacts/
├── scout.md         ← kết quả khảo sát
├── diagnosis.md     ← phân tích 6 câu hỏi
├── plan.md          ← kế hoạch đã approve
└── verification.json ← kết quả test
```

**Ví dụ thực tế:**
```
# Bug: user đăng nhập bằng Google OAuth bị lỗi redirect
/fix "Google OAuth redirects to /undefined instead of /dashboard"

# Bug: API bị chậm
/fix "GET /api/products takes 8 seconds, timeout on mobile"

# Bug: UI bị vỡ layout
/fix "product card overlaps on screens smaller than 375px"
```

---

### `/cook "<feature>"` — Làm tính năng mới

**Dùng khi:** muốn thêm feature, build endpoint mới, tạo component, refactor lớn.

```
/cook "add /api/orders/:id/cancel endpoint"
/cook "add dark mode toggle to settings page"
/cook "add CSV export to the reports page"
/cook "refactor UserService to use dependency injection"
```

**Flags (tùy chọn):**
```
/cook "feature" --auto     # ít hỏi xác nhận hơn
/cook "feature" --fast     # bỏ qua research, giữ nguyên Plan
```

**Claude đi qua 5 bước — bạn approve ở bước 2:**

```
Phase 1 — Spec     Định nghĩa rõ 5 mục:
                     1. Expected output (output mong đợi là gì)
                     2. Acceptance criteria (điều kiện nghiệm thu)
                     3. Scope boundary (làm gì, KHÔNG làm gì)
                     4. Non-negotiable constraints (ràng buộc bắt buộc)
                     5. Touchpoints (files/services bị ảnh hưởng)
Phase 2 — Plan     ← BẠN APPROVE trước khi code
Phase 3 — Build    Viết code
Phase 4 — Verify   Chạy test, kiểm tra hoạt động
Phase 5 — Review   Review toàn bộ diff + adversarial check
```

**Artifacts được tạo ra:**
```
.claude-artifacts/
├── spec.md                     ← đặc tả 5 mục
├── plan.md                     ← kế hoạch đã approve
├── risk-gate.json              ← đánh giá rủi ro
├── context-snippets.json       ← code patterns tham khảo
├── verification.json           ← kết quả test
├── review-decision.json        ← PASS / PASS_WITH_RISK / FAIL
└── adversarial-validation.json ← kiểm tra góc khuất
```

**Ví dụ thực tế:**
```
# Thêm API endpoint mới
/cook "add POST /api/products/:id/duplicate endpoint that clones a product"

# Thêm tính năng UI
/cook "add infinite scroll to the product listing page"

# Thêm auth
/cook "add rate limiting (10 req/min) to all /api/auth/* routes"

# Refactor
/cook "extract payment logic from OrderController into PaymentService"
```

---

## 🛡️ Artifact Gate — bảo vệ tự động

Hook chạy **trước mọi lệnh** `git push`, `gh pr create`, `npm publish`, `pnpm publish`, `vercel deploy`, `fly deploy`, `kubectl apply *prod`.

**Khi bạn chạy `/fix` hoặc `/cook` xong rồi push — hook tự kiểm tra:**

```bash
git push origin main
# ✅ artifact-gate: all artifacts present, ship approved.
```

**Khi push mà chưa làm workflow — hook chặn lại:**

```bash
git push origin main
# ❌ ARTIFACT GATE BLOCKED: shipping command refused.
#    Missing: plan.md, verification.json, review-decision.json
#    Complete the /fix or /cook workflow, OR set CLAUDE_SKIP_ARTIFACT_GATE=1
```

**Bypass cho lệnh push thông thường** (không liên quan đến /fix hay /cook):

```bash
CLAUDE_SKIP_ARTIFACT_GATE=1 git push origin main
```

**Lưu ý:** Thêm vào `.gitignore` của mỗi project:
```
.claude-artifacts/
```

---

## 📋 Workflow thực tế từ A→Z

### Scenario 1: Sửa bug được report

```bash
cd ~/my-project
claude

# Bước 1: khảo sát khu vực liên quan (tuỳ chọn nhưng nên làm)
/scout src/api/auth

# Bước 2: bắt đầu fix
/fix "users get logged out randomly after 10 minutes"

# Claude sẽ:
# → Scout files liên quan
# → Diagnose: tìm ra session TTL config sai ở src/config/session.ts:23
# → Đưa ra Plan → bạn gõ "y" để approve
# → Sửa code
# → Chạy test để verify
# → Tạo artifacts

# Bước 3: push (hook tự kiểm tra artifacts)
git add -A
git commit -m "fix: correct session TTL from 10min to 24h"
git push    # ← hook chạy, thấy artifacts đủ → allow
```

### Scenario 2: Build feature mới

```bash
cd ~/my-project
claude

/cook "add email notification when order status changes to 'shipped'"

# Claude sẽ:
# → Spec: định nghĩa 5 mục, bạn review và confirm
# → Plan: kế hoạch implement, bạn approve
# → Build: viết NotificationService, OrderObserver, email template
# → Verify: chạy unit test + integration test
# → Review: kiểm tra toàn bộ diff

# Push sau khi xong
git add -A
git commit -m "feat: email notification on order shipped"
git push    # ← hook thấy review-decision.json = PASS → allow
```

### Scenario 3: Push code bình thường (không dùng /fix /cook)

```bash
# Sửa typo trong README, đổi màu button, update config nhỏ
git add README.md
git commit -m "docs: fix typo"
CLAUDE_SKIP_ARTIFACT_GATE=1 git push   # bypass hook vì không cần workflow
```

---

## 🔄 Sync giữa 2 laptops / Daily sync

**Laptop A — sau khi thay đổi config:**
```bash
cd ~/claude-dotfiles
./sync.sh --dry-run              # preview trước
./sync.sh "add new skill"        # commit + push lên GitHub
```

**Laptop B — lấy config mới về:**
```bash
cd ~/claude-dotfiles
git pull && ./install.sh
```

---

## ⌨️ Các lệnh Claude Code hay dùng

| Lệnh | Tác dụng |
|---|---|
| `/clear` | Xóa context, bắt đầu task mới |
| `/compact` | Tóm tắt conversation dài (tiết kiệm token) |
| `/cost` | Xem đã dùng bao nhiêu token |
| `/model` | Đổi model (sonnet / opus / haiku) |
| `/memory` | Xem / sửa CLAUDE.md instructions |
| `/diff` | Xem pending file changes |
| `/doctor` | Kiểm tra sức khoẻ Claude Code |

---

## install.sh flags / Các flag của install.sh

| Flag | Effect |
|------|--------|
| *(no flags)* | Apply, with timestamped backups in `~/.claude-backups/<TS>/` |
| `--dry-run` | Preview every action, write nothing |
| `--no-backup` | Skip backups (faster; riskier) |
| `--force` | Skip the "existing CLAUDE.md differs" prompt |
| `-h`, `--help` | Show usage |

`install.sh` is **idempotent** — re-running with no upstream change is a no-op.

---

## Quick reference / Bảng tra cứu nhanh

| Tình huống | Lệnh |
|---|---|
| Setup laptop mới | `git clone … && ./install.sh` |
| Vừa đổi config trên laptop này | `./sync.sh "mô tả"` |
| Lấy config mới về laptop kia | `git pull && ./install.sh` |
| Khảo sát code trước khi làm | `/scout src/services/auth` |
| Sửa bug | `/fix "mô tả bug"` |
| Làm feature mới | `/cook "mô tả feature"` |
| Push code thông thường (bypass gate) | `CLAUDE_SKIP_ARTIFACT_GATE=1 git push` |
| Xem trước install | `./install.sh --dry-run` |
| Xem trước sync | `./sync.sh --dry-run` |
| Khôi phục config cũ | `cp -r ~/.claude-backups/<TS>/* ~/.claude/` |

---

## The `/fix` and `/cook` workflows — Technical details

### `/fix <symptom>` — investigate-first bug fix
Refuses to write code before completing **Scout** (read repo) and **Diagnose** (answer 6 questions: exact symptom, repro steps, expected vs actual, root cause file:line, *why now*, blast radius).
- High-risk fixes (auth / billing / migrations / >5 files / protected branch) **stop and wait for human approval** even in `--auto` mode.
- The **3-strike rule**: if 3 fix attempts fail verification, STOP — open a discussion with the user.

### `/cook <feature>` — contract-first implementation
Refuses to write code before completing **Spec** (5 mandatory sections: expected output, acceptance criteria, scope boundary, non-negotiable constraints, touchpoints) and **Plan**. Even `--fast` skips Research, **not** Plan.

### Artifact gate — critical 4 files checked before shipping

1. `plan.md` — non-empty
2. `spec.md` **or** `diagnosis.md` — at least one, non-empty
3. `verification.json` — valid JSON
4. `review-decision.json` — `decision` ∈ `{PASS, PASS_WITH_RISK}`

---

## Philosophy / Triết lý

> Prompt is just a hint. **Hooks are control.** Score-driven approval (`9/10, ship it`) is theater.
> Evidence-gated approval — `.claude-artifacts/` populated, `review-decision.json` is PASS — is real.
>
> *Prompt chỉ là gợi ý. **Hook mới là kiểm soát.** Approval dựa vào score là diễn. Approval dựa vào artifact mới là thật.*

Inspired by [ClaudeKit Engineer](https://claudekit.cc) by mrgoonie. This repo reimplements the principles natively in plain markdown + bash — no subscription required.
