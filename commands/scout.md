---
description: Read-only codebase reconnaissance. Produces a scout report without writing or proposing changes.
argument-hint: <area or symptom to investigate>
---

# /scout — Read-only Codebase Reconnaissance

You are running the `/scout` workflow. **Read-only.** Do not edit files. Do not propose changes. Your only job is to produce evidence.

Target: **$ARGUMENTS**

---

## Output

Write `.claude-artifacts/scout.md` containing:

### 1. Project profile
- Language(s), framework(s), package manager
- Entry points (main, index, app bootstrap)
- Build / test / lint commands actually in use (from `package.json` scripts, `Makefile`, etc.)

### 2. Target area map
- Primary file(s) where the target symptom/feature lives
- Direct callers / consumers (via `grep -r` / `rg` for imports/usages)
- Tests covering this area (or "none" if absent)

### 3. Recent activity
- `git log -20 --oneline -- <target files>` output
- Any commit message that sounds related to the symptom

### 4. Convention survey
- Quote 1-3 examples of how the codebase solves analogous problems today
- Note any inconsistencies (legacy patterns, parallel implementations)

### 5. Unknowns
- Explicitly list questions you cannot answer from the code alone
- These become questions for the user

---

## Rules
- ❌ No file edits
- ❌ No "I would suggest..." — that's `/cook` or `/fix`, not Scout
- ✅ Cite file:line for every claim
- ✅ "I don't know" is a valid finding — say it
