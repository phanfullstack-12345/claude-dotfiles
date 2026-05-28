---
name: migrate
description: "Use when running, writing, or reviewing database migrations, schema changes, or data transformations"
---

# Migrate Skill

## Before Writing a Migration

```bash
# Check current migration status
pnpm prisma migrate status
# or
pnpm run db:status
# or Laravel
php artisan migrate:status
```

- Confirm you're targeting the correct environment (`DATABASE_URL` in `.env`).
- Read the last 3 migrations for naming and style conventions.
- Check if the table is large (> 1M rows) — large tables need special care.

## Writing the Migration

### Prisma
```bash
pnpm prisma migrate dev --name add_column_to_users
# Edit the generated SQL in prisma/migrations/<timestamp>/migration.sql if needed
pnpm prisma migrate dev  # apply to local DB
```

### Drizzle
```bash
pnpm drizzle-kit generate:pg
pnpm drizzle-kit push:pg  # dev only
```

### Raw SQL (Flyway/Liquibase style)
```sql
-- V20240115_001__add_status_to_orders.sql
-- Always: idempotent where possible, explicit types, safe defaults

ALTER TABLE orders
  ADD COLUMN IF NOT EXISTS status VARCHAR(50) NOT NULL DEFAULT 'pending';

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_status ON orders(status);
```

### Laravel
```bash
php artisan make:migration add_status_to_orders_table
# Edit the generated file
php artisan migrate --pretend  # preview SQL before running
php artisan migrate
```

## Safety Rules

- **Never** modify an existing migration that has been run in staging/production — create a new one.
- **Always** add `IF NOT EXISTS` / `IF EXISTS` guards for DDL operations.
- **Large tables**: use `CREATE INDEX CONCURRENTLY` (Postgres) to avoid locking.
- **Renaming columns**: add new column → backfill → swap app code → drop old (never rename directly).
- **Dropping columns**: deprecate in app first → deploy → then drop in a follow-up migration.
- **Rollback plan**: every migration should have a corresponding `down()` method or rollback script.

## Verify After Migration

```bash
# Check schema matches expectation
pnpm prisma db pull          # introspect actual DB
pnpm prisma validate         # validate schema file

# Spot-check data
SELECT count(*), status FROM orders GROUP BY status LIMIT 5;

# Run full test suite against migrated DB
pnpm test:integration
```

## Output Format
Report: (1) migration name and what changed, (2) any data backfill performed, (3) rollback procedure.
