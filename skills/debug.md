---
name: debug
description: "Use when debugging errors, investigating failures, diagnosing unexpected behavior, or investigating why something isn't working as expected"
---

# Debug Skill

## Methodology

Follow the scientific method: reproduce → isolate → hypothesize → test → explain.

### Step 1: Reproduce consistently
```bash
# Get exact error output
pnpm dev 2>&1 | tee /tmp/debug.log
# Or for tests:
pnpm test --verbose 2>&1 | grep -A 20 "FAIL\|Error"
```

### Step 2: Read the full error
- Read the complete stack trace — the root cause is usually the last frame before node_modules
- Check the line number referenced; read that file and surrounding context
- Note: what was the code trying to do at that point?

### Step 3: Check recent changes
```bash
git diff HEAD~1 -- .          # what changed in the last commit?
git log --oneline -10         # recent commit history
git stash && pnpm dev         # does it work without my changes?
```

### Step 4: Isolate the failure
- Narrow to the smallest failing case (comment out code, binary search)
- Check: does it fail in isolation or only in combination with something else?
- Check: does it fail in all environments or just one?

### Step 5: Inspect state at failure point
```bash
# Node.js — add debug logging temporarily
console.error('[DEBUG]', { variableName, anotherVar })

# Or use debugger
node --inspect-brk dist/index.js
# Then open chrome://inspect in Chrome
```

### Step 6: Fix and verify
- Change ONE thing at a time
- After fix: re-run the original failing scenario
- Check for regressions: run full test suite

### Common Patterns

**TypeScript errors:**
```bash
npx tsc --noEmit 2>&1 | head -30     # type errors
```

**Module not found:**
```bash
ls node_modules/<package>             # is it installed?
cat package.json | grep <package>     # is it in dependencies?
```

**Port already in use:**
```bash
lsof -i :3000                        # find what's using it
kill -9 <PID>
```

**Environment variable missing:**
```bash
cat .env.example                     # what vars are needed?
printenv | grep VAR_NAME             # is it set?
```

**Database connection failed:**
```bash
# Check connection string format
# Check DB is running: docker ps | grep postgres
# Check credentials match .env
```

## Output Format
After debugging: report (1) root cause, (2) fix applied, (3) how to prevent recurrence.
