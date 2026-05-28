---
name: git-flow
description: "Use when managing branches, writing commit messages, resolving merge conflicts, rebasing, tagging releases, or performing any git workflow operations"
---

# Git-Flow Skill

## Branch Naming

```
feat/short-description         # new feature
fix/short-description          # bug fix
chore/short-description        # maintenance, deps, config
refactor/short-description     # code improvement, no behavior change
docs/short-description         # documentation only
hotfix/short-description       # urgent production fix
```

## Commit Messages

Follow Conventional Commits:

```
<type>(<scope>): <short summary>

[optional body — WHY, not what]

[optional footer — BREAKING CHANGE, Fixes #123]
```

Types: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `perf`, `ci`

```bash
# Good commits
git commit -m "feat(auth): add magic link login"
git commit -m "fix(cart): correct total when multiple discounts applied"
git commit -m "chore: upgrade Next.js to 14.2"

# With body for non-obvious changes
git commit -m "$(cat <<'EOF'
refactor(payments): extract ChargeService from CheckoutController

The controller was handling payment logic directly, making it
untestable and hard to reuse. ChargeService is now independently
injectable and tested.

Fixes #234
EOF
)"
```

## Feature Branch Workflow

```bash
# Start a feature
git checkout main && git pull origin main
git checkout -b feat/user-profile-photos

# Work...
git add src/features/profile/
git commit -m "feat(profile): add photo upload endpoint"

# Keep up-to-date with main (prefer rebase over merge)
git fetch origin
git rebase origin/main

# Push and open PR
git push -u origin feat/user-profile-photos
gh pr create --base main
```

## Interactive Rebase (Clean Up Before PR)

```bash
# Squash fixup commits before opening PR
git rebase -i main

# In the editor:
# pick abc1234 feat: add photo upload
# squash def5678 fix typo
# squash ghi9012 address review comments
# fixup jkl3456 remove debug log
```

## Merge Conflict Resolution

```bash
# See what's conflicting
git status
git diff --diff-filter=U           # show only conflict files

# Open each conflicted file, resolve, then:
git add <resolved-file>
git rebase --continue              # if rebasing
git merge --continue               # if merging

# Abort and start over if needed
git rebase --abort
git merge --abort
```

## Stashing

```bash
git stash                          # save WIP
git stash push -m "half-done login form"
git stash list
git stash pop                      # restore latest
git stash apply stash@{1}         # restore specific
git stash drop stash@{0}          # delete stash
```

## Tagging Releases

```bash
# Semantic version tag
git tag -a v1.2.0 -m "Release v1.2.0 — cursor pagination, profile photos"
git push origin v1.2.0

# List tags
git tag -l "v1.*"

# Delete a tag (local + remote)
git tag -d v1.2.0
git push origin --delete v1.2.0
```

## Common Recovery Operations

```bash
# Undo last commit (keep changes staged)
git reset --soft HEAD~1

# Undo last commit (keep changes unstaged)
git reset HEAD~1

# Discard changes to a specific file
git checkout -- path/to/file

# Recover a deleted branch
git reflog | grep "branch-name"
git checkout -b branch-name <sha>

# Find which commit introduced a bug
git bisect start
git bisect bad HEAD
git bisect good v1.0.0
# git bisect good/bad until found
git bisect reset
```

## Useful Aliases

```bash
# Add to ~/.gitconfig
git config --global alias.lg "log --oneline --graph --decorate --all"
git config --global alias.st "status -sb"
git config --global alias.co "checkout"
git config --global alias.unstage "reset HEAD --"
git config --global alias.last "log -1 HEAD --stat"
```

## Safety Rules

- Never `git push --force` on shared branches (`main`, `staging`) — use `--force-with-lease` on personal branches only.
- Never `git reset --hard` without confirming there's nothing unreachable you need.
- Always `git stash` or commit before switching branches with uncommitted work.
- Run tests before pushing — don't rely on CI to catch obvious breaks.

## Output Format
Report: (1) branch/commits affected, (2) operation performed, (3) current branch state.
