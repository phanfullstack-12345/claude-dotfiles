Bootstrap a new Next.js 14+ project with the full recommended stack.

Ask the user for:
1. Project name (kebab-case)
2. Whether to include: auth (NextAuth v5), DB (Prisma + PostgreSQL), or just frontend

Then run:
```
pnpm create next-app@latest <name> --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"
```

After scaffolding:
- Set `strict: true` + `noUncheckedIndexedAccess: true` in tsconfig.json
- Install: `zod`, `@tanstack/react-query`, `zustand`
- If auth: install `next-auth@beta`
- If DB: install `prisma`, run `npx prisma init`
- Create `.env.example` documenting all required env vars
- Create `.env.local` (gitignored) with placeholder values
- Add `pnpm lint && tsc --noEmit` as a pre-commit check note in README

Report what was created and what env vars need to be filled in.
