---
description: Contract-first implementation workflow with Spec → Plan → Build → Verify → Review gating. Refuses to write code until acceptance criteria are explicit.
argument-hint: <feature description> [--auto] [--fast]
---

# /cook — Contract-Gated Implementation Workflow

You are running the `/cook` workflow. The rules below override your default tendencies. **You may NOT write implementation code until Phase 1 (Spec) and Phase 2 (Plan) are complete and recorded as artifacts.**

The user's feature request: **$ARGUMENTS**

---

## Phase 0 · Pre-flight

```bash
mkdir -p .claude-artifacts
```

---

## Phase 1 · Spec (5 mandatory items — no skipping)

Write `.claude-artifacts/spec.md` containing **exactly** these 5 sections. If you cannot answer one with confidence, **STOP and ask the user** — do not invent.

### 1. Expected Output
The concrete artifact the user will see/use. Examples:
- "A new HTTP endpoint `POST /api/orders/:id/cancel` that returns 200 + the cancelled order on success."
- "A `<DateRangePicker>` React component used on the reports page."

If you can't describe what the user will touch, the request is too vague.

### 2. Acceptance Criteria
Input → output pairs that can be tested. Write as Gherkin-style or table. Example:

| Given | When | Then |
|-------|------|------|
| Order is `pending` | User cancels | Status becomes `cancelled`, refund job enqueued |
| Order is `shipped` | User cancels | 409 Conflict, `OrderNotCancellable` |

### 3. Scope Boundary (what is NOT in this round)
Explicit list of things the user might assume but you are NOT doing. Example:
- ❌ No partial refunds
- ❌ No customer email — that's a separate ticket
- ❌ No admin override flow

### 4. Non-negotiable Constraints
- Stack / framework / language version
- File locations + naming conventions (cite an existing file the new code should mirror)
- Backward compatibility requirements
- Performance / security constraints

### 5. Touchpoints
Every module / file / contract this change will touch. Use the codebase to verify each. Example:
- `src/services/orders.service.ts` — add `cancel()` method
- `src/api/orders.controller.ts` — add route
- `prisma/schema.prisma` — no change required (verified)
- `src/queues/refund.queue.ts` — new producer call

> **If any of the 5 sections is "I don't know" — go ask the user. Do not guess.**

---

## Phase 2 · Plan (required even with `--fast`)

Write `.claude-artifacts/plan.md`. Even `--fast` skips Research, not Plan.

Contents:
- **Ordered steps** to implement (numbered)
- **Test plan** — what tests prove each acceptance criterion
- **Rollout plan** — feature-flagged? migration order? deploy order?
- **Risk classification** — see Risk Gate below

### Risk Gate

A plan is **high-risk** if ANY of these are true:
- Touches auth / billing / payments / migrations / data deletion
- Adds or changes a public API contract
- Affects > 5 files or estimated > 200 lines
- Requires DB migration on a populated table
- Modifies a protected branch's deploy path

If `--auto` is set AND risk is `low` → proceed to Build.
If risk is `medium` or `high` → **STOP and request explicit user approval.** Print the plan. Wait.

Write `.claude-artifacts/risk-gate.json`:
```json
{
  "risk": "low|medium|high",
  "reasons": ["..."],
  "auto_stop_required": true|false,
  "human_approved": true|false
}
```

---

## Phase 3 · Build

Implement the plan. **Only the plan.** No scope creep.

For each acceptance criterion, write the test first if practical (TDD optional but encouraged).

After Build, write `.claude-artifacts/context-snippets.json`:
```json
{
  "task": "...",
  "acceptance_criteria": [...],
  "touchpoints": [...],
  "public_contracts": [...],
  "blast_radius": "...",
  "scout_summary": "..."
}
```

---

## Phase 4 · Verify (evidence required)

Run, in order:
1. Each acceptance criterion as a concrete test — capture pass/fail.
2. Full test suite — no regressions.
3. Lint + typecheck — clean.
4. If applicable: run the app and exercise the new path manually (the global `verify` skill).

Write `.claude-artifacts/verification.json` with the command, exit code, and before/after evidence for each.

**A claim of "tests pass" without `.claude-artifacts/verification.json` is not accepted.**

---

## Phase 5 · Review (adversarial)

Run the global `code-review` skill on the diff. Then write `.claude-artifacts/review-decision.json`:

```json
{
  "decision": "PASS | PASS_WITH_RISK | BLOCKED",
  "critical_count": 0,
  "regression_proof": "...",
  "unverified_claims": []
}
```

**Score-only approval is NOT permitted.** A 9.6/10 means nothing without:
- Zero unresolved critical issues
- Regression proof from Phase 4
- Acceptance criteria all green

Also write `.claude-artifacts/adversarial-validation.json`:
```json
{
  "claims_disproven": ["..."],
  "claims_unverified": ["..."],
  "regressions_reachable": ["..."]
}
```

---

## Phase 6 · Finalize Gate

Before committing, pushing, opening a PR, or deploying, the following **must exist** under `.claude-artifacts/`:

1. `spec.md`
2. `plan.md`
3. `risk-gate.json` — `auto_stop_required: false` OR `human_approved: true`
4. `context-snippets.json`
5. `verification.json` — all green
6. `review-decision.json` — decision ∈ `{PASS, PASS_WITH_RISK}`
7. `adversarial-validation.json`

Hard stages (`git push`, `pr`, deploy) check for these via hooks. Missing artifact → blocked.

If an artifact generation fails, retry **once**. If it fails again, **escalate to the user** — do not bypass.

---

## Flags

- `--auto` — auto-approve `low` risk plans. Does NOT skip Spec or Plan.
- `--fast` — skip the Research/Scout depth (still requires Spec and Plan and Verify).

## Anti-patterns this workflow blocks

- ❌ "Just implement X" → straight to Build without Spec
- ❌ Plan with no acceptance criteria
- ❌ Score-driven approval ("9/10, ship it")
- ❌ Build that creeps beyond the listed Touchpoints
- ❌ Verify that asserts "tests pass" without evidence file
- ❌ Reviewer is the same context that built it (always invoke `code-review` skill as a separate pass)
