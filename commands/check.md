Run the full quality check suite for the current project: lint, type-check, and tests.

1. Detect the project type from package.json / pyproject.toml / pom.xml / composer.json
2. For Node/TS projects: run `pnpm lint && tsc --noEmit && pnpm test` (or npm/yarn equivalents)
3. For Python projects: run `ruff check . && mypy . && pytest`
4. For PHP/Laravel: run `./vendor/bin/phpstan analyse && php artisan test`
5. For Java/Maven: run `mvn verify`
6. Report: ✅ passed / ❌ failed with the specific error output
7. If any check fails, diagnose the root cause and offer to fix it
