Prepare the current branch for a pull request.

Steps:
1. Run /check — abort and report if lint/types/tests fail
2. Show `git diff main...HEAD --stat` to summarize what changed
3. Check for any leftover TODOs, console.logs, debug code, or hardcoded secrets in the diff
4. Suggest a concise PR title (under 70 chars) based on the changes
5. Draft a PR description with: Summary (3 bullets max), Test plan (checklist), and any breaking changes
6. Ask if you should create the PR with `gh pr create`
