---
name: create-pr
description: "Use when creating, preparing, or reviewing a pull request — includes writing PR descriptions, choosing reviewers, checking CI status, or ensuring a branch is ready to merge"
---

# Create PR Skill

## Before Opening the PR

```bash
# Confirm you're on the right branch
git branch --show-current
git status                    # must be clean

# Confirm tests and lint pass
pnpm test
pnpm lint && tsc --noEmit

# Check what will be in the PR
git log main..HEAD --oneline  # commits since branching
git diff main...HEAD          # full diff
```

- Squash/rebase fixup commits before opening (`git rebase -i main`).
- Every PR should have a single clear purpose — split if scope is too wide.
- Link the PR to the relevant issue or ticket.

## PR Description Template

```markdown
## Summary
- What changed and why (not how — the diff shows how)
- One bullet per logical change

## Test Plan
- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Manually tested: describe steps taken

## Screenshots (if UI change)
Before | After

## Notes / Breaking Changes
- List any breaking API changes, migrations required, env vars added
```

## Size Guidelines

| PR size | Lines changed | Rule |
|---|---|---|
| Ideal | < 400 | Easy to review in one sitting |
| Acceptable | 400–800 | Add extra description |
| Split required | > 800 | Break into stacked PRs |

## Checklist Before Marking Ready

```bash
# Rebase on latest main to avoid merge conflicts
git fetch origin
git rebase origin/main

# Final checks
pnpm test
pnpm lint && tsc --noEmit
```

- [ ] Title follows convention: `feat:`, `fix:`, `chore:`, `refactor:`, `docs:`
- [ ] Description filled out — not just "fixes bug"
- [ ] Linked to issue/ticket
- [ ] Reviewers assigned
- [ ] Labels added if required
- [ ] Draft → Ready when all checks pass

## Creating with GitHub CLI

```bash
# Create PR (opens editor for description)
gh pr create --base main --head $(git branch --show-current)

# With inline title and body
gh pr create \
  --title "feat: add pagination to /api/posts" \
  --body "$(cat <<'EOF'
## Summary
- Added cursor-based pagination to GET /api/posts
- Default page size: 20; max: 100

## Test Plan
- [x] Unit tests for PaginationService
- [x] Integration test: GET /api/posts?cursor=abc&limit=20
- [x] Manually tested with Postman
EOF
)"

# Convert draft to ready
gh pr ready

# Check CI status
gh pr checks
gh run watch
```

## Output Format
Report: (1) PR URL, (2) commits included, (3) CI status, (4) any blockers for merge.
