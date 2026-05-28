---
name: refactor
description: "Use when refactoring, restructuring, or improving code quality without changing external behavior — includes extracting functions, renaming, splitting files, removing duplication, or improving types"
---

# Refactor Skill

## Before Refactoring

```bash
# Confirm tests pass before touching anything
pnpm test
pnpm lint && tsc --noEmit

# Understand what you're about to change
git diff HEAD~1 -- .           # what changed recently?
wc -l src/**/*.ts              # find largest files
```

- Read the file(s) fully before making changes — never assume structure.
- Confirm the scope: are you refactoring one function, one file, or a module?
- Check if there are characterization tests. If not, write them first.
- Never refactor and fix bugs in the same commit — separate concerns.

## Refactoring Patterns

### Extract Function / Method
```ts
// ❌ Before — one function doing too much
async function handleCheckout(req, res) {
  // 50 lines of validation
  // 30 lines of pricing
  // 40 lines of payment
  // 20 lines of notification
}

// ✅ After — each concern isolated
async function handleCheckout(req, res) {
  const cart = validateCart(req.body);
  const pricing = calculatePricing(cart);
  const payment = await chargeCard(pricing, cart.paymentToken);
  await sendConfirmation(payment);
  res.status(201).json(payment);
}
```

### Remove Duplication
```bash
# Find duplicated blocks
npx jscpd src/ --min-lines 8 --reporters console

# Find duplicated validation logic
grep -r "isValidEmail\|validateEmail" src/ --include="*.ts" -l
```

```ts
// Extract to shared utility and import from one place
// src/lib/validators.ts
export const emailSchema = z.string().email();
```

### Improve TypeScript Types
```bash
# Find all any casts
grep -r ": any" src/ --include="*.ts" | wc -l

# Find implicit any
npx tsc --noEmit --strict 2>&1 | grep "implicitly has an 'any' type"
```

```ts
// ❌ Before
function process(data: any) { return data.value; }

// ✅ After
interface ProcessInput { value: string; }
function process(data: ProcessInput): string { return data.value; }
```

### Split Large Files
- Split when a file exceeds ~200 lines or contains multiple unrelated concerns.
- One class/module = one file.
- Move related types into a co-located `types.ts`.

### Simplify Conditionals
```ts
// ❌ Before — nested if/else
if (user) {
  if (user.role === "admin") {
    if (resource.ownerId === user.id || user.permissions.includes("delete")) {
      return true;
    }
  }
}
return false;

// ✅ After — early returns + guard clauses
if (!user) return false;
if (user.role === "admin") return true;
return resource.ownerId === user.id || user.permissions.includes("delete");
```

## Safety Rules

- Run tests after **every** change — not at the end.
- Change ONE thing at a time — don't rename + restructure + move in one commit.
- Use `git add -p` to stage refactors in logical atomic chunks.
- If a test breaks during refactor, stop and investigate — don't push through.
- Do not change behavior. If you find a bug, fix it in a separate commit.

## After Refactoring

```bash
# Verify nothing broke
pnpm test
pnpm lint && tsc --noEmit

# Check bundle/output is equivalent
git diff HEAD -- dist/   # if applicable
```

## Output Format
Report: (1) what was refactored and why, (2) pattern applied, (3) test result confirming no regressions.
