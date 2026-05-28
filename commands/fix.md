---
description: Investigate-first bug-fix workflow with Scout → Diagnose → Plan → Apply → Verify gating. Refuses to write code until evidence is gathered.
argument-hint: <bug description or symptom> [--auto] [--no-stop]
---

# /fix — Evidence-Gated Bug-Fix Workflow

You are running the `/fix` workflow. The rules below override your default tendencies. **Do not skip phases. Do not propose a fix before Scout + Diagnose complete.**

The user's bug report / symptom: **$ARGUMENTS**

---

## Phase 0 · Pre-flight (mandatory)

Before anything else, create the artifact directory:

```bash
mkdir -p .claude-artifacts
```

All evidence you collect goes here. **No artifact = no progress.**

---

## Phase 1 · Scout (no fixes yet — collect facts)

Read the repo. Do not hypothesise yet. Collect:

1. **Project type / language / framework** — read `package.json` / `pyproject.toml` / `go.mod` / etc.
2. **Symptom file + caller graph** — the file where the bug manifests and its direct callers/dependents (use `grep -r` / `rg` for imports/usages).
3. **Related tests** — find any test file covering the symptom area. If none exist, note that explicitly.
4. **Recent commits touching this area** — `git log -20 --oneline -- <symptom file>` and adjacent files.
5. **Convention/pattern survey** — how does the rest of the codebase solve similar problems? Quote 1-2 examples.

Write findings to `.claude-artifacts/scout.md` as a structured report. **If you cannot answer any of the 5 above, say so explicitly — do NOT invent.**

---

## Phase 2 · Diagnose (form a single hypothesis with evidence)

Answer these **6 questions** with file:line citations. Write to `.claude-artifacts/diagnosis.md`:

| # | Question | Required form |
|---|----------|---------------|
| 1 | **Exact symptom** | Precise, observable. No "it's broken." |
| 2 | **Reproduction steps** | Deterministic. Numbered. Include input data. |
| 3 | **Expected vs actual** | Two parallel statements. |
| 4 | **Root cause + file:line** | Specific. Cite the line. No "somewhere in auth." |
| 5 | **Why now** | What changed (commit / env / dependency / data shape) that made this surface today? |
| 6 | **Blast radius** | Every caller, route, job, or consumer affected by the fix. |

> **The "why now" question is non-negotiable.** If you can't answer it, you don't understand the system yet — go back to Scout.

---

## Phase 3 · Plan (smallest reversible change that fixes root cause)

Write `.claude-artifacts/plan.md` containing:

- **Files to change** — exact paths
- **Test additions** — what new tests prove the fix
- **Migration / rollback notes** — if any
- **Risk level** — `low` / `medium` / `high` (see Risk Gate below)

### Risk Gate

A fix is **high-risk** if ANY of these are true:
- Touches auth, billing, payment, migrations, or data deletion
- Changes a public API contract or DB schema
- Modifies > 5 files or > 100 lines
- Blast radius includes a protected branch deploy

If `--auto` is set AND risk is `low` → proceed.
If risk is `medium` or `high` → **STOP and request explicit user approval** before applying. Print the plan and wait. Do not bypass this even with `--auto`.

---

## Phase 4 · Apply

Make the change. **Only what the plan says.** No drive-by refactors. No "while I'm here" cleanups.

---

## Phase 5 · Verify (evidence required)

Run, in order:
1. The exact reproduction steps from Diagnose Q2 — confirm the bug is gone.
2. The full test suite (`pnpm test` / `pytest` / etc.) — confirm no regression.
3. Linter + typechecker — confirm clean.
4. Any test you added — confirm it passes (and confirm it FAILS on the pre-fix code if you can).

Write `.claude-artifacts/verification.json` with `{command, exit_code, before, after}` for each.

---

## Phase 6 · The 3-Strike Rule

If the same bug class fails verification **3 times in a row**:

🛑 **STOP. Do not patch again.**

The architecture is suspicious. Open a discussion with the user. State:
- What you tried
- Why each attempt failed
- What architectural assumption you now doubt

Patching a 4th time without re-thinking is how "fixing a cough" becomes "pneumonia."

---

## Outputs at the end

A successful `/fix` session leaves behind:

```
.claude-artifacts/
├── scout.md
├── diagnosis.md
├── plan.md
└── verification.json
```

These are read by the artifact-gate hooks before any `git push` / deploy / ship.

---

## Flags

- `--auto` — auto-approve `low` risk plans. Default behavior. Does NOT skip Scout/Diagnose/Plan.
- `--no-stop` — disables the 3-strike rule. Use only when explicitly debugging the workflow itself.
- `--fast` — skip the full test suite in Verify (still run reproduction + linter). Reserved for trivial typo fixes.

## Anti-patterns this workflow blocks

- ❌ Reading 2 files, declaring root cause, editing
- ❌ "Test passed, done" without running the reproduction
- ❌ Patching the visible symptom while leaving root cause
- ❌ Compound fixes that touch unrelated code
- ❌ "It should work now" — no, run it
