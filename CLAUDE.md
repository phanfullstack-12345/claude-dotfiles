# ~/.claude/CLAUDE.md — Global Claude Code Instructions

Personal global config. Applies to every project.
Project-level `CLAUDE.md` files override specific sections.

---

## 🧠 General Behavior

- Read relevant files before making changes — never assume contents.
- Prefer editing existing files over creating new ones.
- After every task, give a short summary: what changed and why.
- Ask for clarification when requirements are ambiguous — don't guess.
- Never delete files, folders, or records without explicit confirmation.
- Outline multi-step plans before executing — wait for approval on destructive ops.
- Keep responses focused — don't over-explain unless asked.

---

## 🛠️ Stack Preferences (Quick Reference)

Apply these preferences unless the project-level `CLAUDE.md` overrides them.

### JavaScript / TypeScript
- **Package manager**: `pnpm` preferred; lock file always committed
- **TypeScript**: `strict: true` always; `noUncheckedIndexedAccess: true`
- **Linting/Format**: ESLint + Prettier; run `pnpm lint && tsc --noEmit` before done
- **No `any`**: use `unknown` + type guards; `as const` for literals; no `enum` → use `as const` object + union type

### React / Next.js
- **New projects**: Vite (SPA) or Next.js 14+ App Router (full-stack/SSR)
- **Bootstrap Next.js**: `pnpm create next-app@latest --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"`
- **Components**: functional + arrow functions only; co-locate styles/tests/types; split at ~200 lines
- **State**: `useState`/`useReducer` (local) → TanStack Query (server) → Zustand (global client)
- **Next.js**: Server Components by default; `"use client"` only for interactivity/browser APIs/event listeners
- **Images**: always `next/image` with explicit `width`/`height`; **Fonts**: `next/font`
- **Routes**: `loading.tsx` + `error.tsx` + `not-found.tsx` per route segment

### Python
- **Version**: 3.12+; **Package manager**: `uv` preferred (`uv init`, `uv add`, `uv run`)
- **Format/Lint**: `ruff format` + `ruff check`; **Types**: `mypy --strict` or `pyright`
- **FastAPI**: async by default; Pydantic v2 for all models; `Depends()` for DI; always set `response_model`
- **Tests**: pytest + pytest-asyncio; `httpx.AsyncClient` + ASGITransport for FastAPI integration tests
- **No bare `except`**: always catch specific exceptions; use `pathlib.Path` over `os.path`

### NestJS
- **TypeScript strict**, pnpm; `ValidationPipe` global (`whitelist: true`, `forbidNonWhitelisted: true`, `transform: true`)
- **Structure**: one module per domain; thin controllers → services for logic; DTOs for all request/response
- **DB**: TypeORM with `synchronize: false` in production; migrations always; `@InjectRepository` pattern
- **Auth**: `@nestjs/passport` + JWT; store only `userId`/`roles` in JWT payload
- **Config**: `@nestjs/config` `ConfigService` for all env vars — never `process.env` inline

### PHP / Laravel
- **PHP 8.2+**; PSR-12 + PHP CS Fixer; PHPStan level 8+
- Fat models, thin controllers; Form Requests for all validation; never `env()` outside config files
- Events + Listeners for side effects; Jobs + Queues for async/slow operations

### Java / Spring Boot
- **Java 21**; constructor injection only — never `@Autowired` on fields; DTOs always
- Validation: `@Valid` + Bean Validation on DTOs; `@ControllerAdvice` for global exception handling

### Databases
- **PostgreSQL 16+**: preferred; UUID PKs with `gen_random_uuid()`; PgBouncer in prod; migrations always
- **MongoDB**: replica sets always; schema validation at collection level; no raw `$where`
- **General**: parameterized queries always — never interpolate user input; `EXPLAIN ANALYZE` before shipping complex queries

### Testing
- **Pyramid**: Unit (60%) → Integration (30%) → E2E (10%)
- **JS/TS**: Vitest; **Python**: pytest; **E2E**: Playwright; **Mocking**: MSW for API mocking
- Coverage ≥ 80% on business logic; test behaviour, not implementation (no testing internals)
- FIRST principles: Fast, Isolated, Repeatable, Self-validating, Timely

### DevOps / Cloud
- **IaC**: Terraform with remote state (S3+DynamoDB / GCS); `terraform plan -out=tfplan` before apply
- **K8s**: always set `resources.requests/limits`; liveness + readiness probes; never `latest` image tag
- **CI/CD**: build once → promote artifact; pipeline order: lint → test → build → security scan → deploy
- **Secrets**: never in code or git; use Vault/Secrets Manager; OIDC federation over long-lived keys
- **Docker**: multi-stage builds; pin base image versions; non-root user; `.dockerignore` always

### AI / LLM
- `max_tokens` always explicitly set; structured output over free text parsing
- LangSmith: `LANGCHAIN_TRACING_V2=true` in all environments; tag runs with project/env/version
- LangGraph: typed state (`TypedDict`/Pydantic); explicit `END` conditions; checkpoint in prod (`PostgresSaver`)
- Never roll your own crypto; PII scrubbing before sending to third-party LLM APIs

---

## ⚠️ Off-Limits (Always Require Human Confirmation)

Claude must **never** do the following without explicit confirmation:

- Delete files, folders, or database records
- Run `DROP`, `TRUNCATE`, or `DELETE` without `WHERE` clause
- Modify CI/CD pipeline configs or deployment workflows
- Push to `main`, `staging`, or any protected branch
- Change environment variables in staging or production
- Publish packages, create releases, or tag versions
- Expose, log, or commit secrets of any kind
- Apply Kubernetes manifests to production cluster
- Run Ansible playbooks against production inventory
- Accept ToS, grant OAuth permissions, or click "Deploy to production"
- Modify IAM policies, firewall rules, or security groups

---

## 🔧 Skill Usage — Always Proactive

Always invoke the relevant skill before responding to development tasks. Do NOT skip skills to save time.

| Task context | Skill / Command to invoke |
|---|---|
| Bug report / failing behaviour / "X is broken" | `/fix` — Scout → Diagnose → Plan → Apply → Verify, with 6-question diagnosis + 3-strike stop |
| New feature / "implement X" / "build Y" | `/cook` — Spec (5 items) → Plan → Build → Verify → Review, with artifact-gate |
| "Look at X" / "where does Y live" / area survey | `/scout` — read-only reconnaissance |
| Running or starting the app | `run` |
| Verifying a fix / confirming a feature works | `verify` |
| Reviewing code changes or diffs | `code-review` |
| Reviewing a pull request | `review` |
| Security audit of pending changes | `security-review` |
| Any `.pptx` file involved | `pptx` |
| Any `.xlsx` / `.csv` / `.tsv` file involved | `xlsx` |
| Any `.docx` / Word document involved | `docx` |
| Any `.pdf` file involved | `pdf` |
| Code imports `anthropic` / Anthropic SDK | `claude-api` |
| Configuring hooks, permissions, settings.json | `update-config` |

### Reference skill files (read on demand)

When a task needs deep reference for a specific domain, read the relevant skill file:

| Domain | Skill file |
|---|---|
| React + Next.js deep patterns | `skills/react-nextjs-guide.md` |
| Python + FastAPI deep patterns | `skills/python-guide.md` |
| NestJS deep patterns | `skills/nestjs-guide.md` |
| Testing deep patterns | `skills/testing-guide.md` |
| Security engineering | `skills/security-guide.md` |
| Design / UX | `skills/design-ux-guide.md` |
| DevOps / SRE / CI-CD | `skills/devops-guide.md` |
| Software architecture patterns | `skills/architecture-guide.md` |
| AI/ML / LLM engineering | `skills/ai-ml-guide.md` |
| Senior fullstack patterns | `skills/fullstack-guide.md` |
| HTML + CSS + JS/TS | `skills/html-css-js-guide.md` |
| Databases deep patterns | `skills/databases-guide.md` |
| Cloud architecture | `skills/cloud-guide.md` |
| Cybersecurity / pen testing | `skills/cybersecurity-guide.md` |
| Data engineering | `skills/data-engineering-guide.md` |
| Linux / terminal | `skills/linux-guide.md` |
| Vibe coding cleanup | `skills/vibe-cleanup-guide.md` |
| Canvas / D3.js / game dev | `skills/canvas-d3-guide.md` |

### Evidence over score

**Never** approve work based on a self-assigned score ("9/10, ship it"). Approval requires:
- Acceptance criteria all green (from `/cook` spec) OR reproduction steps fail pre-fix and pass post-fix (from `/fix` diagnosis)
- `.claude-artifacts/verification.json` exists with green commands logged
- `.claude-artifacts/review-decision.json` decision ∈ `{PASS, PASS_WITH_RISK}`
- Zero unresolved **critical** issues from `code-review`

The PreToolUse artifact-gate hook enforces this for `git push`, `gh pr create`, `npm publish`, and `vercel deploy`. To bypass for a one-off command, set `CLAUDE_SKIP_ARTIFACT_GATE=1` and tell the user why.

**Rule:** If the task matches a skill trigger, invoke the skill FIRST — then proceed.

### ⚠️ MANDATORY for Every Development / Coding Task

After completing **any** code change (editing files, fixing bugs, adding features, updating styles, refactoring), ALWAYS run these two skills in order — no exceptions:

1. **`verify`** — Run the app and visually/functionally confirm the change works as intended.
2. **`code-review`** — Review the diff for correctness bugs before calling the task done.

**Do NOT** skip either skill to save time. If the app cannot be started, explicitly tell the user what blocked verification and ask them to confirm manually.

Full mandatory checklist for every coding session:
- [ ] Relevant skills from the table above identified and invoked at start
- [ ] Code changes made
- [ ] `verify` invoked — app running and change confirmed visually
- [ ] `code-review` invoked — diff reviewed for bugs
- [ ] Short summary given: what changed and why

---

## 📝 Project-Level Overrides

Each project's own `CLAUDE.md` (in the repo root) can override any section above.
Global rules apply when no project-level override exists.
Conflicts: project-level always wins.
