# Reference: vibe-cleanup-guide
# Load this file when working on tasks matching this domain.

## 🤖 AI Vibe Code Developer

### Mindset
- AI is a **senior pair programmer** — brief it like one: give context, constraints, and the "why".
- You own the output — never ship AI-generated code you don't fully understand.
- Iterate fast: small → working → review → expand. Don't ask for 500 lines in one shot.
- AI excels at: boilerplate, patterns, refactoring, test generation, documentation. You own: architecture, business logic decisions, security review.
- **Vibe coding**: stay in flow — let AI handle syntax/ceremony, you handle intent and review.

### Effective Prompting for Code
- Always give: **what** (goal), **where** (file/function), **constraints** (framework, style, must not break X).
- Bad: "add auth". Good: "add JWT auth to `src/api/users.ts` using `@nestjs/passport`, follow existing service patterns, don't change the DB schema".
- Include error messages verbatim — AI can't guess what the error says.
- Reference existing patterns: "follow the pattern in `users.service.ts`".
- Specify output format: "edit only the file, no explanations, no new dependencies".
- For complex tasks: ask for a **plan first**, approve it, then execute step by step.

### AI-Assisted Development Phases

#### Planning
```
"I'm building X. My constraints are Y. What are the main architectural risks?
Give me a 5-step implementation plan, starting with the riskiest part."
```
- Use AI to stress-test your approach before writing code.
- Ask for alternatives: "what's wrong with my current plan?" or "what would you do differently?"

#### Implementation
- One feature/fix per conversation — don't let context drift.
- Commit working code before starting the next feature — gives you a restore point.
- If AI goes in wrong direction: stop, `/clear`, re-brief with corrected constraints.
- Use `@filename` references to give AI exact context — don't describe the code, show it.

#### Review & Verification
- After every AI edit: read the diff yourself before running it.
- Ask AI to review its own output: "what edge cases does this miss?" or "what could go wrong here?"
- Run tests after every change — never assume AI edits are regression-free.
- Security-sensitive code: always run `/security-review` before merging.

#### Debugging with AI
- Paste the full error + stack trace + relevant code — not paraphrases.
- Give reproduction steps: "this fails when I call `POST /users` with `{email: null}`".
- Share what you already tried — prevents AI suggesting things you've ruled out.
- If AI fix doesn't work: say exactly what happened, don't re-ask the same question.

### Multi-Agent Patterns
- Spawn subagents for **independent** research (Explore agent) — keeps main context clean.
- Use Plan mode for complex multi-step tasks — get alignment before execution.
- Background agents for long-running tasks (CI checks, test runs) — don't block main thread.
- Worktree isolation for risky changes — changes in isolated branch, main checkout untouched.

### Knowing When NOT to Use AI
- **Security-critical code**: crypto implementations, auth flows — write manually, AI-assist only for review.
- **Performance-critical hot paths**: AI often writes correct but not optimal code — profile and verify.
- **When you don't understand the domain**: learn first, then let AI help implement.
- **Ambiguous requirements**: clarify with humans before asking AI to build it.

### AI Code Quality Checklist
- [ ] Do I understand every line of the generated code?
- [ ] Are there no hardcoded secrets, test data, or debug logs?
- [ ] Does it handle errors properly (not just happy path)?
- [ ] Are edge cases covered (null, empty, large input, concurrent access)?
- [ ] Does it follow the existing project patterns?
- [ ] Have tests been added or updated?
- [ ] Has `/security-review` been run on auth/data-handling changes?

---

## 🧹 Vibe Coding Cleanup Specialist

### The Role & The Controversy

**Vibe coding** = using AI to generate large amounts of code rapidly, prioritizing speed and working output over code quality, security, maintainability, or understanding. The result ships — but leaves a technical landmine.

The **Vibe Coding Cleanup Specialist** (also called AI Code Auditor, LLM Output Engineer, or AI Tech Debt Remediator) is an emerging role focused on taking AI-generated codebases and bringing them to production-grade standards.

**Why it's controversial:**
- Some engineers see it as glorifying bad practice — "just write it right the first time"
- Others argue AI-generated code is no worse than rushed junior code, which has always needed review
- Companies love the cost narrative: fast AI generation + cheap cleanup vs. slow careful engineering
- Senior engineers resent being cleanup crews for AI output they consider fundamentally broken
- Startups counter: shipping fast and cleaning up later is how every successful startup worked
- There's genuine debate about whether cleanup specialists enable or discourage responsible AI use

**The reality:** The role exists, the demand is real, and understanding how to do it well is valuable regardless of where you stand on the controversy.

---

### Recognising Vibe-Coded Code

Before cleaning, identify it. Vibe-coded code has consistent fingerprints:

#### Structural Tells
```
✦ Massive functions (200+ lines) that do 5 different things
✦ Deeply nested callbacks or conditionals (6+ levels)
✦ Inconsistent naming: camelCase + snake_case + PascalCase in the same file
✦ Duplicated logic copied rather than extracted
✦ Files that are too long (1000+ lines) — AI doesn't split naturally
✦ No separation of concerns: HTTP handling + business logic + DB access in one function
✦ Comments describing what the code does (AI wrote them), not why
✦ Generated boilerplate left in: TODO comments, placeholder strings, "example.com" URLs
✦ Imports of packages that aren't actually used anywhere
✦ Both old and new patterns side by side (AI continued from both directions)
```

#### Logic & Safety Tells
```
✦ Missing authentication checks on routes — AI assumed auth was "elsewhere"
✦ No input validation: req.body.email used directly in a query
✦ Error handling is console.log then continue — no propagation
✦ Hardcoded secrets, localhost URLs, or test credentials
✦ Race conditions: shared state mutated inside async loops
✦ N+1 queries: DB call inside a loop with no batching
✦ No pagination on endpoints that return potentially unbounded data
✦ SQL queries built with string concatenation (injection risk)
✦ Promise rejections swallowed: .catch(() => {}) with empty handler
✦ Memory leaks: event listeners or timers never cleaned up
```

#### Dependency Tells
```
✦ package.json with 50+ dependencies for a simple CRUD app
✦ Multiple libraries doing the same job (axios + fetch + got all imported)
✦ Packages that don't exist on npm (hallucinated imports)
✦ Outdated packages — AI training data has a cutoff, so it recommends old versions
✦ Dev dependencies in production dependencies or vice versa
✦ No lockfile, or lockfile not committed
```

---

### Cleanup Methodology — The 5-Phase Process

#### Phase 1: Triage (Don't Touch Yet)
```bash
# Get a full picture before changing anything
git log --oneline -20           # understand commit history
wc -l **/*.ts                   # find largest files
find . -name "*.ts" | xargs grep -l "console.log" | wc -l  # log hygiene
grep -r "TODO\|FIXME\|HACK\|XXX" src/ --include="*.ts"      # debt markers
grep -r "any" src/ --include="*.ts" | wc -l                  # TypeScript holes

# Check what's actually broken
pnpm test 2>&1 | tail -30       # test status
pnpm lint 2>&1 | head -50       # lint violations
npx tsc --noEmit 2>&1 | wc -l  # type errors

# Security quick scan
npx audit 2>&1
gitleaks detect --source .
grep -r "password\|secret\|api_key\|token" src/ --include="*.ts" -i | grep -v "test\|spec\|mock"
```

**Produce a triage report before writing a single line:**
```markdown
## Triage Report — [Project Name] — [Date]

### Scale
- Files: X | Lines: X | Test coverage: X%

### Critical (Fix before any deployment)
- [ ] Hardcoded API key in src/config.ts:12
- [ ] SQL injection in src/routes/users.ts:45
- [ ] No auth check on DELETE /api/users/:id

### High (Fix this sprint)
- [ ] 0 tests on payment processing logic
- [ ] N+1 query in OrderService.getAll() — 50 DB calls per request
- [ ] Uncaught promise rejections in 12 files

### Medium (Fix next sprint)
- [ ] 847 TypeScript `any` casts
- [ ] No error handling on 3rd party API calls
- [ ] Duplicated user validation logic in 4 places

### Low (Ongoing)
- [ ] Inconsistent naming conventions
- [ ] Unused imports in 23 files
- [ ] No JSDoc on public APIs

### Estimated cleanup effort: X sprints
```

#### Phase 2: Safety Net First (Tests Before Refactoring)
```
Rule: Never refactor code that has no tests.
      Write characterization tests first to capture current behavior,
      then refactor with confidence.
```

```ts
// Characterization test — document what code DOES (not what it SHOULD do)
// Write these before you understand the code fully
describe("OrderService.calculateTotal (characterization)", () => {
  it("returns 0 for empty cart", async () => {
    const result = await orderService.calculateTotal([]);
    expect(result).toBe(0);  // capture current behavior
  });

  it("applies discount code before tax (discovered behavior)", async () => {
    // found by running the code — may or may not be the intended order
    const result = await orderService.calculateTotal([item], "SAVE10");
    expect(result).toBe(90.00);  // snapshot the current output
  });
});
```

**Characterization test goal:** If you run the tests before cleanup and after cleanup, they should all still pass. If one fails, your refactor changed behavior — investigate.

#### Phase 3: Security Cleanup (Highest Priority)

```ts
// Pattern: find and fix injection vulnerabilities

// ❌ Vibe-coded — SQL injection
async function getUser(email: string) {
  return db.query(`SELECT * FROM users WHERE email = '${email}'`);
}

// ✅ Fixed — parameterized query
async function getUser(email: string) {
  return db.query("SELECT * FROM users WHERE email = $1", [email]);
}

// ❌ Vibe-coded — missing auth
app.delete("/api/users/:id", async (req, res) => {
  await db.user.delete({ where: { id: req.params.id } });
  res.json({ deleted: true });
});

// ✅ Fixed — auth + authorization + ownership check
app.delete("/api/users/:id", authenticate, async (req, res) => {
  if (req.user.id !== req.params.id && req.user.role !== "admin") {
    return res.status(403).json({ error: "Forbidden" });
  }
  await db.user.delete({ where: { id: req.params.id } });
  res.status(204).send();
});

// ❌ Vibe-coded — hardcoded secrets
const stripe = new Stripe("sk_live_abc123real_key_here");

// ✅ Fixed — environment variable with validation
if (!process.env.STRIPE_SECRET_KEY) throw new Error("STRIPE_SECRET_KEY is required");
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);
```

**Security cleanup checklist:**
```
□ All secrets moved to environment variables + .env.example created
□ All SQL / NoSQL queries parameterized
□ Input validation added at every API boundary (Zod/yup)
□ Auth middleware applied to every protected route
□ Authorization (not just authentication) checked on each operation
□ File upload endpoints validate type, size, and store outside webroot
□ Error responses scrubbed of stack traces / internal info
□ Dependencies audited: npm audit --audit-level=high
□ Secrets scan run: gitleaks detect --source .
□ If secrets were committed: rotate them immediately + rewrite git history
```

#### Phase 4: Structural Cleanup (Refactoring)

**Extract and organize — follow the Strangler Fig pattern for large refactors:**

```ts
// ❌ Vibe-coded — 200-line function doing everything
export async function handleCheckout(req, res) {
  // validate cart (40 lines)
  // check inventory (30 lines)
  // apply discounts (25 lines)
  // calculate tax (20 lines)
  // charge card (30 lines)
  // create order (25 lines)
  // send confirmation email (20 lines)
  // update inventory (15 lines)
}

// ✅ Cleaned — each concern is its own function/service
export async function handleCheckout(req: Request, res: Response) {
  const cart = CartValidator.parse(req.body);           // throws on invalid
  await InventoryService.reserve(cart.items);
  const pricing = PricingEngine.calculate(cart);
  const payment = await PaymentService.charge(pricing.total, cart.paymentMethod);
  const order = await OrderService.create({ cart, pricing, payment });
  await NotificationService.sendOrderConfirmation(order);
  res.status(201).json(order);
}
```

**Deduplication — find and consolidate:**
```bash
# Find duplicated validation logic
grep -r "isValidEmail\|validateEmail\|email.*regex" src/ --include="*.ts" -l

# Find copy-pasted blocks (jscpd)
npx jscpd src/ --min-lines 10 --reporters console
```

```ts
// ❌ Vibe-coded — same validation in 4 places
// users.ts:     if (!email.includes("@")) throw new Error("invalid email")
// auth.ts:      if (!email.match(/.*@.*/)) return false
// profile.ts:   email.split("@").length === 2  // bad regex
// signup.ts:    z.string().email()              // correct but not shared

// ✅ Cleaned — one shared validator
// src/lib/validators.ts
export const emailSchema = z.string().email("Invalid email address");
export const validateEmail = (email: string) => emailSchema.parse(email);
// imported everywhere else
```

**Fix N+1 queries:**
```ts
// ❌ Vibe-coded — 1 query per post (N+1)
async function getPosts() {
  const posts = await db.post.findMany();
  for (const post of posts) {
    post.author = await db.user.findUnique({ where: { id: post.authorId } });
    post.tags = await db.tag.findMany({ where: { postId: post.id } });
  }
  return posts;
}

// ✅ Fixed — one query with eager loading
async function getPosts() {
  return db.post.findMany({
    include: { author: true, tags: true },
  });
}
```

**Add proper error handling:**
```ts
// ❌ Vibe-coded — silent failures
async function sendWelcomeEmail(userId: string) {
  try {
    await emailService.send(userId);
  } catch (e) {
    console.log("email failed");  // swallowed — no retry, no alert
  }
}

// ✅ Fixed — explicit handling with retry + alerting
async function sendWelcomeEmail(userId: string) {
  try {
    await withRetry(() => emailService.send(userId), { attempts: 3, delay: 1000 });
  } catch (err) {
    logger.error({ userId, err }, "Welcome email failed after 3 attempts");
    await alerting.notify("email-failures", { userId, err });
    // don't rethrow — non-critical; user still created successfully
  }
}
```

#### Phase 5: Hardening (Production-Readiness)

```ts
// Add rate limiting (probably missing)
import rateLimit from "express-rate-limit";
app.use("/api/", rateLimit({ windowMs: 15 * 60 * 1000, max: 100 }));
app.use("/api/auth/", rateLimit({ windowMs: 15 * 60 * 1000, max: 10 }));

// Add request validation middleware (probably missing)
app.use(express.json({ limit: "10kb" }));  // prevent large payload attacks

// Add security headers (probably missing)
import helmet from "helmet";
app.use(helmet());

// Add health check (definitely missing)
app.get("/health", async (req, res) => {
  const db = await checkDatabaseConnection();
  res.json({ status: db ? "ok" : "degraded", timestamp: new Date().toISOString() });
});

// Add graceful shutdown (missing)
process.on("SIGTERM", async () => {
  server.close(async () => {
    await db.$disconnect();
    process.exit(0);
  });
});
```

---

### Common Vibe-Code Anti-Patterns & Fixes

| Anti-Pattern | Why It Happens | Fix |
|---|---|---|
| `any` everywhere in TypeScript | AI avoids type errors by casting | Replace with real types; use `unknown` + type guards |
| `console.log` as error handling | AI demos use print debugging | Replace with structured logger (pino/winston) |
| No `.env.example` | AI doesn't think about onboarding | Create `.env.example` with all required vars documented |
| Missing `await` on async calls | AI misses async chains under pressure | `tsc --noEmit` + `@typescript-eslint/no-floating-promises` |
| Returning sensitive data in API responses | AI returns full model objects | Use DTOs / response transformers; strip password, tokens |
| Pagination missing | AI writes simple `findAll()` | Add cursor or offset pagination on all list endpoints |
| No DB transactions | AI treats multi-step ops as atomic | Wrap related mutations in `db.$transaction()` |
| Magic numbers/strings | AI hardcodes values | Extract to named constants or config |
| Circular dependencies | AI imports freely | Run `madge --circular src/` and fix |
| Missing `Content-Type` validation | AI assumes well-formed requests | Validate `req.is("application/json")` |

---

### Tooling for Vibe Code Cleanup

#### Code Analysis
```bash
# TypeScript — find all the any's and errors
npx tsc --noEmit 2>&1 | grep "error TS" | wc -l
npx ts-prune              # find unused exports

# ESLint — vibe-code specific rules
# Add to .eslintrc:
# "@typescript-eslint/no-explicit-any": "error"
# "@typescript-eslint/no-floating-promises": "error"
# "no-console": ["warn", { "allow": ["error"] }]
# "no-unused-vars": "error"

# Complexity analysis
npx complexity-report src/ --max-cyclomatic 10

# Dead code detection
npx knip                  # finds unused files, deps, exports

# Duplicate code detection
npx jscpd src/ --min-lines 8

# Circular dependency detection
npx madge --circular src/ --extensions ts
```

#### Security Scanning
```bash
gitleaks detect --source . --exit-code 1       # secrets in code
semgrep --config=p/owasp-top-ten src/          # OWASP issues
npx audit --audit-level=high                   # CVE dependencies
snyk test                                       # advanced CVE + license scan
```

#### Dependency Cleanup
```bash
# Find unused dependencies
npx depcheck

# Find packages with known issues
npm audit --json | jq '.vulnerabilities | keys[]'

# Check if imported package actually exists
# (catches hallucinated packages from AI)
cat package.json | jq '.dependencies | keys[]' | xargs -I {} sh -c 'node -e "require(\"{}\")" 2>&1 | grep -q "Cannot find" && echo "MISSING: {}"'

# Find duplicate packages (different versions of same lib)
npm ls --json | npx npm-duplicate-packages
```

---

### The Cleanup Specialist's Conversation with the AI

When using AI (Claude Code) to help clean up AI-generated code:

```
Effective prompts for cleanup work:

"Review src/api/users.ts for security vulnerabilities. Focus on:
auth checks, input validation, SQL injection, and data exposure.
For each issue: show the vulnerable code, explain the risk, show the fix."

"This function is 200 lines long and does too much. Extract it into
separate functions. Keep the same external behavior — don't change logic,
just organize. Add types for all parameters and return values."

"Find all places in src/ where we're swallowing errors (empty catch blocks
or console.log only). List each location with the file:line and suggest
proper error handling for each case."

"Audit package.json for: unused dependencies, duplicated functionality,
packages that should be devDependencies, and packages with high CVEs.
Show me what to remove and why."

"Write characterization tests for OrderService.calculateTotal() before
I refactor it. Tests should capture current behavior exactly, including
edge cases you can infer from the code."
```

---

### Prioritisation Framework

When the cleanup backlog is overwhelming, use this priority matrix:

```
IMPACT vs EFFORT matrix:

High Impact, Low Effort (DO FIRST):
  → Fix SQL injection / auth holes
  → Move hardcoded secrets to env vars
  → Add request validation (Zod) to top-traffic endpoints
  → Fix N+1 queries on slow endpoints

High Impact, High Effort (PLAN & SCHEDULE):
  → Add test coverage to critical business logic
  → Refactor monolithic services into domain modules
  → Implement proper error handling throughout
  → TypeScript strict mode + remove all `any`

Low Impact, Low Effort (FILL TIME):
  → Fix naming inconsistencies
  → Remove unused imports
  → Add JSDoc to public functions
  → Consolidate duplicate validation

Low Impact, High Effort (DEFER OR DROP):
  → Rewrite working code in a "better" pattern
  → Change ORM when current one works
  → Perfect test coverage on non-critical code
  → Architectural purism over shipping velocity
```

---

### Communicating with Stakeholders

The cleanup specialist often has to justify time spent not shipping features:

```markdown
## How to frame cleanup work in business terms:

SECURITY issues → "This is a data breach waiting to happen.
  If exploited: [specific consequence]. Cost to fix now: X hours.
  Cost after breach: legal fees + compliance + reputation + customer loss."

PERFORMANCE issues → "The /orders endpoint makes 50 DB queries per request.
  At 100 concurrent users, our DB is receiving 5,000 queries/second.
  Fix: 4 hours. Payoff: can handle 10× traffic without scaling DB."

TEST COVERAGE → "We have 0 tests on payment logic. Every deploy is a gamble.
  Adding tests: 2 days. Prevented incidents: we've had 3 payment bugs in 2 months
  costing X hours of incident response each."

TECH DEBT generally → "We're paying 20% interest on every feature — it takes
  longer to add new things because the codebase fights us. This cleanup
  removes that interest charge."

What NOT to say:
  ❌ "The code is messy and it bothers me"
  ❌ "This isn't how you're supposed to do it"
  ❌ "The AI wrote bad code"  (blame-y, doesn't drive action)
  ✅ Always connect to business outcome: risk, cost, speed, reliability
```

---

### Cleanup Metrics — Proving Progress

Track these to show value over time:

```bash
# Baseline these before starting, track weekly
echo "TypeScript errors:  $(npx tsc --noEmit 2>&1 | grep -c 'error TS')"
echo "ESLint violations:  $(pnpm lint 2>&1 | grep -c 'error\|warning')"
echo "Test coverage:      $(pnpm test --coverage 2>&1 | grep 'All files' | awk '{print $10}')"
echo "any casts:          $(grep -r ': any' src/ --include='*.ts' | wc -l)"
echo "Console.logs:       $(grep -r 'console.log' src/ --include='*.ts' | wc -l)"
echo "TODO/FIXME:         $(grep -r 'TODO\|FIXME' src/ --include='*.ts' | wc -l)"
echo "Unused deps:        $(npx depcheck 2>&1 | grep -c 'Unused')"
echo "Audit issues:       $(npm audit --json 2>&1 | jq '.metadata.vulnerabilities.high + .metadata.vulnerabilities.critical')"
```

**Weekly report format:**
```
Week of 2024-01-22 — Cleanup Progress

Metric              | Baseline | This Week | Change
--------------------|----------|-----------|--------
TypeScript errors   |   847    |    612    |  -235 ✅
Test coverage       |    4%    |    23%    |  +19% ✅
Critical CVEs       |     6    |      1    |   -5  ✅
console.logs        |   203    |    156    |  -47  ✅
any casts           |   1,203  |  1,198    |   -5  ➡️ (slow)
ESLint violations   |   2,841  |  1,102    | -1739 ✅
```

---

### When to Rewrite vs. Clean Up

The hardest decision in this role:

```
Rewrite signals (consider starting fresh):
  ✦ Core logic is fundamentally wrong (not just messy)
  ✦ Security model is baked into architecture (can't patch routes)
  ✦ No tests AND no one understands the code AND frequent bugs
  ✦ Cleanup effort > rewrite effort (run the numbers)
  ✦ Blocking all new feature development

Clean up signals (incrementally improve):
  ✦ Code works, just messy
  ✦ Users depend on current behavior (even undocumented quirks)
  ✦ Team understands the domain, just not the code
  ✦ Rewrite risk > cleanup risk
  ✦ Can ship cleanup in incremental PRs

Middle path (strangler fig):
  ✦ Build new modules alongside old ones
  ✦ Route new traffic to new code
  ✦ Migrate old data/logic gradually
  ✦ Delete old code when new covers everything
  ✦ Each incremental step is independently deployable
```

---

