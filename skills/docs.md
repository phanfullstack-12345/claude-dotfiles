---
name: docs
description: "Use when writing, updating, or reviewing documentation — includes README files, API docs, inline code comments, ADRs, runbooks, changelogs, or any form of technical writing"
---

# Docs Skill

## Before Writing

```bash
# Find existing docs to update rather than duplicate
find . -name "*.md" | head -20
grep -r "TODO.*docs\|FIXME.*docs" . --include="*.md"

# Check what the code actually does (source of truth)
# Read the relevant files before documenting them
```

- Write for the reader who has LESS context than you.
- One document = one purpose (tutorial, how-to, reference, explanation).
- Update docs in the same PR as the code change — never "will update later".

## README Structure

```markdown
# Project Name
One-line description of what this does and who it's for.

## Quick Start
\`\`\`bash
# Minimal steps to get running
pnpm install && pnpm dev
\`\`\`

## Requirements
- Node.js 20+, PostgreSQL 16+

## Configuration
| Variable | Required | Default | Description |
|---|---|---|---|
| DATABASE_URL | ✅ | — | PostgreSQL connection string |

## Development
\`\`\`bash
pnpm dev        # start dev server
pnpm test       # run tests
pnpm lint       # lint + type check
\`\`\`

## Architecture
Brief overview + link to detailed docs.
```

## Code Comments — Rules

Write comments ONLY when the WHY is non-obvious:

```ts
// ✅ Hidden constraint
// 1s delay — payment gateway has eventual-consistency window after capture;
// charging immediately causes duplicate transaction errors.
await sleep(1000);

// ✅ Workaround for a specific bug
// Safari 16.x crashes on crypto.subtle in service workers (WebKit #245734).
const subtle = crypto.subtle ?? await import("./subtle-polyfill");

// ❌ Restates the code
// Increment counter
counter++;

// ❌ Describes what, not why
// Gets user by ID
async function getUserById(id: string) {}
```

## API Documentation (OpenAPI)

```yaml
paths:
  /users/{id}:
    get:
      summary: Get user by ID        # one line, verb + noun
      description: |                 # extra context if needed
        Returns the full user profile. Requires auth.
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
              example:
                id: "550e8400-e29b-41d4-a716-446655440000"
                email: "alice@example.com"
        "404": { description: User not found }
```

## ADR Template

```markdown
# ADR-NNN: [Decision Title]

## Status
Proposed | Accepted | Deprecated | Superseded by ADR-NNN

## Context
Why does this decision need to be made? What forces are at play?

## Decision
What was decided.

## Rationale
Why this option over the alternatives.

## Consequences
What becomes easier/harder as a result.
```

## Changelog (Keep a Changelog Format)

```markdown
## [1.2.0] — 2024-02-01

### Added
- Cursor-based pagination on GET /api/posts

### Changed
- Password minimum length increased from 8 to 12 characters

### Fixed
- Cart total incorrect when applying multiple discount codes (#892)

### Security
- Updated jsonwebtoken to 9.0.2 (CVE-2022-23541)
```

## Writing Style Rules

- Active voice: "The server validates" not "The request is validated by"
- Present tense: "Returns null if…" not "Will return null if…"
- Second person: "Configure the database" not "The developer should configure"
- Concrete before abstract: show an example first, then explain

## Checklist Before Merging Docs

- [ ] Accurate — reflects current behavior, not planned
- [ ] Complete — covers happy path + errors + prerequisites
- [ ] All code examples tested and working
- [ ] No dead links
- [ ] Terminology consistent with rest of docs

## Output Format
Report: (1) what was documented, (2) file(s) updated, (3) any gaps left for follow-up.
