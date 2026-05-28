# Reference: docs-guide
# Load this file when working on tasks matching this domain.

## 📄 Documentation Skills — Senior Engineer & Technical Writer

### Documentation Philosophy
- Documentation is a product — it needs design, iteration, and maintenance.
- Write for the reader, not yourself — they have less context, different goals.
- **Docs as code**: documentation lives in the repo, reviewed in PRs, versioned with code.
- The best documentation is the code itself — clear naming, typed interfaces, error messages.
- Supplemental docs explain **why** (decisions, constraints, trade-offs) — not just what the code does.
- Stale documentation is worse than no documentation — it misleads.

### Documentation Types

| Type | Purpose | Audience | Lives in |
|---|---|---|---|
| **README** | Project overview, quick start | New contributors | Repo root |
| **API reference** | Every endpoint/function documented | Developers integrating | Auto-generated or `docs/api/` |
| **Architecture Decision Record (ADR)** | Why decisions were made | Future engineers | `docs/adr/` |
| **Runbook** | How to operate the system | On-call engineers | `docs/runbooks/` |
| **Tutorial** | Learning-oriented, step-by-step | New users | `docs/tutorials/` |
| **How-to guide** | Goal-oriented, task-specific | Practitioners | `docs/how-to/` |
| **Explanation** | Conceptual understanding | Learners | `docs/concepts/` |
| **Changelog** | What changed between versions | Users upgrading | `CHANGELOG.md` |

### README Best Practices

#### README Structure
```markdown
# Project Name

One-line description of what this does and who it's for.

## Features
- Feature 1 — why it matters
- Feature 2

## Quick Start
```bash
git clone https://github.com/org/repo
cd repo
pnpm install
cp .env.example .env.local   # fill in your values
pnpm dev
```
Open http://localhost:3000 — you should see X.

## Requirements
- Node.js 20+
- PostgreSQL 16+
- Redis 7+

## Configuration
| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DATABASE_URL` | ✅ | — | PostgreSQL connection string |
| `REDIS_URL` | ✅ | — | Redis connection string |
| `JWT_SECRET` | ✅ | — | Min 32 chars, random string |
| `PORT` | ❌ | 3000 | HTTP server port |

## Development
```bash
pnpm dev          # start dev server with hot reload
pnpm test         # run unit + integration tests
pnpm test:e2e     # run Playwright end-to-end tests
pnpm lint         # lint + type check
pnpm db:migrate   # run pending migrations
pnpm db:seed      # seed development data
```

## Architecture
Brief overview + link to detailed docs.
See [Architecture Overview](docs/architecture.md).

## Contributing
See [CONTRIBUTING.md](CONTRIBUTING.md).

## License
MIT
```

#### README Anti-Patterns
```
❌ No installation instructions ("just run it")
❌ Outdated screenshots that no longer match the UI
❌ "TODO: add docs" sections that never get filled
❌ Listing every dependency and their versions
❌ Documenting internal implementation (belongs in code comments)
❌ Wall of text with no code examples
❌ No "quick start" — forcing reader to read everything before trying anything
```

### API Documentation

#### OpenAPI / Swagger
```yaml
# openapi.yaml — spec-first approach
openapi: "3.1.0"
info:
  title: User Service API
  version: "1.0.0"
  description: |
    Manages user accounts, authentication, and authorization.

    **Authentication**: All endpoints except `/auth/login` require a Bearer token.

    **Rate limiting**: 100 requests per 15 minutes per user. Headers:
    `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

paths:
  /users/{id}:
    get:
      summary: Get user by ID
      operationId: getUserById
      tags: [Users]
      security: [{ bearerAuth: [] }]
      parameters:
        - name: id
          in: path
          required: true
          schema: { type: string, format: uuid }
          example: "550e8400-e29b-41d4-a716-446655440000"
      responses:
        "200":
          description: User found
          content:
            application/json:
              schema: { $ref: "#/components/schemas/User" }
              example:
                id: "550e8400-e29b-41d4-a716-446655440000"
                email: "alice@example.com"
                name: "Alice Smith"
                role: "editor"
                createdAt: "2024-01-15T10:30:00Z"
        "404":
          description: User not found
          content:
            application/json:
              schema: { $ref: "#/components/schemas/Error" }
        "401": { $ref: "#/components/responses/Unauthorized" }

components:
  schemas:
    User:
      type: object
      required: [id, email, name, role, createdAt]
      properties:
        id:        { type: string, format: uuid }
        email:     { type: string, format: email }
        name:      { type: string, example: "Alice Smith" }
        role:      { type: string, enum: [admin, editor, viewer] }
        createdAt: { type: string, format: date-time }
      additionalProperties: false

    Error:
      type: object
      required: [code, message]
      properties:
        code:    { type: string, example: "NOT_FOUND" }
        message: { type: string, example: "User 123 not found" }
        context: { type: object }
```

#### JSDoc / TSDoc
```ts
/**
 * Calculates the discount amount for an order.
 *
 * @param amount - The order total in cents (must be positive)
 * @param code - Discount code (STANDARD = 10%, PREMIUM = 20%)
 * @returns The discount amount in cents, or 0 if below threshold
 * @throws {ValueError} If amount is negative
 *
 * @example
 * ```ts
 * calculateDiscount(15000, "STANDARD") // returns 1500 (10% of $150)
 * calculateDiscount(8000, "STANDARD")  // returns 0 (below $100 threshold)
 * ```
 */
export function calculateDiscount(amount: number, code: DiscountCode): number {
  if (amount < 0) throw new ValueError("Amount must be positive");
  if (amount < DISCOUNT_THRESHOLD) return 0;
  return Math.round(amount * DISCOUNT_RATES[code]);
}
```

#### Python Docstrings (Google style)
```python
def calculate_discount(amount: float, code: str) -> float:
    """Calculate discount amount for an order.

    Args:
        amount: Order total in dollars. Must be positive.
        code: Discount code. "STANDARD" = 10%, "PREMIUM" = 20%.

    Returns:
        Discount amount in dollars, or 0 if below $100 threshold.

    Raises:
        ValueError: If amount is negative.

    Example:
        >>> calculate_discount(150, "STANDARD")
        15.0
        >>> calculate_discount(80, "STANDARD")
        0.0
    """
```

### Architecture Decision Records (ADR)

#### ADR Template
```markdown
# ADR-001: Use PostgreSQL as Primary Database

## Status
Accepted | Proposed | Deprecated | Superseded by ADR-XXX

## Date
2024-01-15

## Context
We need a primary database for storing user accounts, orders, and product data.
The team has mixed experience with relational and document databases.
Expected load: 10k DAU, 100 writes/sec, 1000 reads/sec initially.

## Decision
We will use PostgreSQL 16 as our primary database.

## Rationale
- ACID compliance required for financial transactions (orders, payments)
- Team has strong PostgreSQL expertise — lower operational risk
- JSONB support covers semi-structured product attributes without a separate NoSQL DB
- Managed options available on AWS (RDS), GCP (Cloud SQL), and Supabase
- pgvector extension available if we add vector search for recommendations

## Alternatives Considered
| Option | Pros | Cons |
|--------|------|------|
| MySQL 8 | Wide familiarity, MariaDB option | Weaker JSON support, no extensions |
| MongoDB | Flexible schema, easy horizontal scale | Eventual consistency risks for payments |
| CockroachDB | Global distribution, auto-sharding | Complexity overkill at current scale |

## Consequences
- All engineers need basic PostgreSQL knowledge (not a concern — it's universal)
- Horizontal write scaling requires read replicas + app-level routing (acceptable)
- If we grow to 10M+ users, may revisit sharding strategy (ADR-002 if needed)
- ORM: Prisma (TypeScript) or SQLAlchemy (Python) — both support Postgres well
```

### Runbooks

#### Runbook Template
```markdown
# Runbook: High Database Connection Count

## Overview
Alert fires when active PostgreSQL connections exceed 80% of `max_connections`.

## Impact
- Severity: P2 (new connections failing; existing requests may slow down)
- Affected: All users making API requests requiring DB access

## Diagnosis

### Step 1: Check current connection count
```sql
SELECT count(*), state
FROM pg_stat_activity
GROUP BY state;
```
Expected: `idle` < 80, `active` < 20. If `idle` is high → connection leak.

### Step 2: Find top connection consumers
```sql
SELECT application_name, count(*)
FROM pg_stat_activity
GROUP BY application_name
ORDER BY count DESC;
```

### Step 3: Check for long-running queries
```sql
SELECT pid, now() - pg_stat_activity.query_start AS duration, query, state
FROM pg_stat_activity
WHERE state != 'idle' AND now() - pg_stat_activity.query_start > interval '5 minutes';
```

## Mitigation

### Option A: Kill idle connections (immediate relief)
```sql
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE state = 'idle' AND state_change < now() - interval '10 minutes';
```

### Option B: Restart the affected app instance
```bash
kubectl rollout restart deployment/api-deployment -n production
```

### Option C: Scale up PgBouncer pool size (if load is legitimate)
Edit `k8s/pgbouncer-config.yaml`: increase `default_pool_size` from 20 to 40.
Apply: `kubectl apply -f k8s/pgbouncer-config.yaml`

## Prevention
- Ensure all DB connections use connection pooling (PgBouncer)
- Monitor `pg_stat_activity` in Grafana dashboard (link)
- Set `idle_in_transaction_session_timeout = 30s` in PostgreSQL config

## Escalation
If none of the above resolves within 15 minutes, page the database team.
Slack: #db-oncall | PagerDuty: Database Escalation policy
```

### Changelog Writing (Keep a Changelog Format)
```markdown
# Changelog

All notable changes to this project will be documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
Versioning: [Semantic Versioning](https://semver.org/)

## [Unreleased]

## [2.4.0] — 2024-02-01

### Added
- User profile photos with automatic resizing and WebP conversion
- Bulk export to CSV for reports (up to 10,000 records)
- Rate limiting on `/auth` endpoints (10 requests / 15 min)

### Changed
- Password minimum length increased from 8 to 12 characters
- API tokens now expire after 90 days (previously no expiry)

### Fixed
- Cart total incorrect when applying multiple discount codes (#892)
- Checkout form submits twice on slow connections (#901)

### Security
- Updated `jsonwebtoken` to 9.0.2 (CVE-2022-23541)
- Removed MD5 from password reset token generation

## [2.3.1] — 2024-01-20

### Fixed
- Admin panel inaccessible for users with special characters in email (#885)

## [2.3.0] — 2024-01-15
...

[Unreleased]: https://github.com/org/repo/compare/v2.4.0...HEAD
[2.4.0]: https://github.com/org/repo/compare/v2.3.1...v2.4.0
```

### Code Comments — When and How

#### When to Comment
```ts
// ✅ WHY — non-obvious reason or constraint
// Use a 1-second delay here because the payment gateway has an eventual-consistency
// window after capture; charging immediately causes duplicate transaction errors.
await sleep(1000);
await chargeCard(token, amount);

// ✅ Workaround for a specific bug
// Safari 16.x crashes on `crypto.subtle` in service workers (WebKit bug #245734).
// Fall back to the polyfill when SubtleCrypto is unavailable.
const subtle = crypto.subtle ?? await import("./subtle-polyfill");

// ✅ Warning about a subtle invariant
// IMPORTANT: This array must remain sorted by priority DESC.
// The scheduler picks the first item and assumes it has the highest priority.
const jobs = [...pendingJobs].sort((a, b) => b.priority - a.priority);

// ❌ Describing WHAT the code does (obvious from reading it)
// Increment the counter
counter++;

// ❌ Restating the function name
// Gets the user by ID
async function getUserById(id: string) { ... }

// ❌ Tracking history ("added for feature X") — belongs in git log
// Added 2024-01-15 to fix the race condition in checkout
```

#### Comment Quality Standards
```
Comments should survive:
  - Renaming the function they mention
  - Moving the code to another file
  - The original author leaving the team

Good comment tests:
  1. Does removing this comment make the code harder to understand?
  2. Would a new engineer with 3 years experience be confused without it?
  3. Is this still true? (stale comments are dangerous)
```

### Technical Writing Style Guide

#### Clarity Rules
```
1. One idea per sentence — split long compound sentences
   ❌ "The API returns a paginated list of users which can be filtered by role and sorted
       by name or creation date and the default page size is 20."
   ✅ "The API returns a paginated list of users. Default page size: 20.
       Filter by `role`. Sort by `name` or `createdAt` (default: `createdAt DESC`)."

2. Active voice — subject performs the action
   ❌ "The request is validated by the server."
   ✅ "The server validates the request."

3. Present tense — describes current behavior
   ❌ "This function will return null if the user is not found."
   ✅ "Returns null if the user is not found."

4. Second person — direct, less formal
   ❌ "The developer should configure the database connection string."
   ✅ "Configure the database connection string in `.env.local`."

5. Concrete before abstract — example first, then explanation
   ❌ "The system supports idempotent operations using unique keys."
   ✅ "Pass `Idempotency-Key: <uuid>` with payment requests. If the request fails
       and you retry with the same key, the server returns the original response
       without charging the card twice."
```

#### Formatting for Scanability
```markdown
## Use headings to create a table of contents
### Use sub-headings to group related content
#### Use H4 sparingly — three levels usually enough

**Bold** for: UI elements, terms being defined, critical warnings
`Code` for: commands, file paths, variable names, API endpoints, values
_Italic_ for: emphasis, titles, introducing new terms (once)

Use lists when:
- There are 3+ items (otherwise write as prose)
- Items are parallel in structure
- Order matters (numbered) or doesn't (bulleted)

Use tables for:
| Comparison | of options | or | configuration |
|---|---|---|---|
| With | clear | column | headers |

Use code blocks for:
- Any code (even 1 line)
- Commands the reader must run
- Config file contents
- Example API requests/responses

Use callouts for important information:
> **Note**: This only applies to Node.js 18+.
> **Warning**: This action is irreversible.
> **Tip**: Run `--dry-run` first to preview changes.
```

### Documentation Review Checklist

#### Before Merging Docs
- [ ] Accurate — reflects current behavior (not planned or historical)
- [ ] Complete — covers happy path + error cases + prerequisites
- [ ] Consistent — terminology matches rest of docs (e.g. always "user" not sometimes "account")
- [ ] Tested — all commands and code examples actually work
- [ ] Linked — related docs cross-referenced; no dead links
- [ ] Versioned — if behavior is version-specific, version is stated
- [ ] Searchable — headings use keywords users would search for
- [ ] No jargon — acronyms expanded on first use; internal jargon avoided

#### Documentation Debt Signals
```
Signs docs need urgent attention:
  - Slack/GitHub issues with "how do I..." that should be in docs
  - Onboarding takes > 2 days because of missing setup docs
  - Different team members give different answers to the same question
  - Runbook missing for a recurring incident
  - API consumers integrating incorrectly due to missing examples
  - "That's not in the docs, just ask Alice" becoming a pattern
```

### Diátaxis Framework (Documentation Structure)
```
The four documentation types serve different needs:

TUTORIALS (learning)          HOW-TO GUIDES (tasks)
  - Learning-oriented           - Goal-oriented
  - Study                       - Work
  - No choices — follow along   - Assumes competence
  - Success guaranteed          - Series of steps
  - Example: "Build your        - Example: "How to deploy
    first API in 5 minutes"       to production"

REFERENCE (information)       EXPLANATION (understanding)
  - Information-oriented        - Understanding-oriented
  - Consult                     - Study
  - Accurate and complete       - Provides context and background
  - Cold, factual               - Opinionated where appropriate
  - Example: "API endpoints     - Example: "Why we use
    and response schemas"         event sourcing"
```

### Auto-Generated Documentation

#### TypeDoc (TypeScript)
```bash
pnpm add -D typedoc typedoc-plugin-markdown
# typedoc.json
{
  "entryPoints": ["src/index.ts"],
  "out": "docs/api",
  "plugin": ["typedoc-plugin-markdown"],
  "excludePrivate": true,
  "excludeInternal": true,
  "readme": "none"
}
pnpm typedoc
```

#### mkdocs (Python / any language)
```yaml
# mkdocs.yml
site_name: My Project Docs
theme:
  name: material
  features:
    - navigation.tabs
    - search.suggest
    - content.code.copy

nav:
  - Home: index.md
  - Getting Started:
    - Installation: getting-started/installation.md
    - Quick Start: getting-started/quickstart.md
  - API Reference: api/
  - Architecture: architecture/
  - Runbooks: runbooks/

plugins:
  - search
  - mkdocstrings:  # auto-generate from docstrings
      handlers:
        python:
          options:
            show_source: false
```

```bash
mkdocs serve         # local preview at localhost:8000
mkdocs build         # output to site/
mkdocs gh-deploy     # deploy to GitHub Pages
```

### Documentation CI/CD
```yaml
# GitHub Actions — lint and deploy docs
- name: Lint markdown
  run: npx markdownlint-cli "**/*.md" --ignore node_modules

- name: Check for dead links
  run: npx markdown-link-check docs/**/*.md

- name: Check spelling
  run: npx cspell "**/*.md"

- name: Deploy to GitHub Pages
  if: github.ref == 'refs/heads/main'
  run: mkdocs gh-deploy --force
```

### Documentation Maintenance
```
Living documentation practices:
  - Docs updated in the same PR as the code change — not "will update later"
  - ADRs never edited after acceptance — add new ADR to supersede
  - Runbooks tested quarterly by on-call rotation (chaos/game days)
  - API docs generated from code (OpenAPI spec / TypeDoc) — never hand-edited
  - README quick-start tested monthly by running it on a clean machine
  - Changelog updated before every release (not after)
  - Dead links checked weekly in CI

Documentation ownership:
  - Each team owns docs for their services
  - No single "documentation team" — docs are engineering responsibility
  - Docs reviewed by at least one person who didn't write them
  - Non-obvious docs have a "last verified" date
```

---

