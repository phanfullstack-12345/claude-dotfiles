Run a security audit of the current project.

Steps:
1. Check for secrets accidentally committed: scan for patterns like API keys, tokens, passwords in recent commits and staged files
2. Run dependency audit:
   - Node: `pnpm audit --audit-level=high` or `npm audit`
   - Python: `pip-audit` or `uv pip audit`
   - PHP: `composer audit`
3. Check for outdated packages with known CVEs
4. Review the diff for OWASP Top 10 issues: SQL injection, XSS, SSRF, insecure deserialization, broken auth
5. Check that `.env` files are in `.gitignore`
6. Report findings grouped by severity: Critical → High → Medium
7. For each finding: what it is, where it is (file:line), and how to fix it
