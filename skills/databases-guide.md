# Reference: databases-guide
# Load this file when working on tasks matching this domain.

## 🔍 Search Engines

### Elasticsearch / OpenSearch (shared patterns)
- Index templates with explicit mappings — never rely on dynamic mapping in production.
- Use ILM (Index Lifecycle Management) for log/time-series indices.
- Aliases for zero-downtime reindex: write to alias, reindex to new index, flip alias.
- Shard sizing: aim for 20–50GB per shard; monitor shard count.
- Always set `number_of_replicas: 1` minimum in production.
- Bulk API for indexing — never index documents one-by-one in loops.
- Use `_source` filtering and `stored_fields` to reduce response payload.
- Circuit breakers: tune `indices.breaker.total.limit` to avoid OOM.

### OpenSearch Specific
- Use OpenSearch Dashboards (not Kibana) for visualization.
- Security plugin: enable TLS + internal user database or LDAP/SAML.
- Fine-grained access control: index-level permissions per role.

### Elasticsearch Specific
- Use Elastic Stack 8+ with security enabled by default.
- API keys over basic auth for application access.
- Use Elastic APM for application performance monitoring if already on Elastic stack.

---

## 🗄 Databases

### MySQL
- Version 8.0+; use `utf8mb4` charset and `utf8mb4_unicode_ci` collation always.
- InnoDB engine always; never MyISAM.
- Indexes: add on all FK columns, all `WHERE` and `ORDER BY` columns.
- Use `EXPLAIN` before shipping any complex query.
- Migrations: versioned SQL files or Laravel migrations — never alter schema manually.
- Connection pooling: PgBouncer equivalent (ProxySQL) for high-traffic apps.
- Backups: daily `mysqldump` + binary log retention for point-in-time recovery.

### PostgreSQL
- Version 16+; use schemas to namespace objects in shared DBs.
- `UUID` primary keys with `gen_random_uuid()` for distributed systems.
- JSONB for semi-structured data; add GIN indexes on queried JSONB fields.
- Use `pg_stat_statements` for query performance monitoring.
- Migrations: Flyway, Liquibase, or framework-native migrations — always version-controlled.
- Pooling: **PgBouncer** in transaction mode for production.
- Vacuuming: monitor bloat; tune `autovacuum` for high-write tables.

### MongoDB
- Version 6+; always use replica sets — never standalone in production.
- Schema validation with JSON Schema at the collection level.
- Index all query fields; use `explain("executionStats")` to verify index usage.
- Avoid `$where` and JavaScript server-side execution.
- Use transactions for multi-document writes when atomicity matters.
- Atlas or self-hosted with authentication + TLS always enabled.
- Backups: mongodump + oplog tailing for point-in-time recovery.

---


## 🗄 Databases

### MySQL
- Version 8.0+; use `utf8mb4` charset and `utf8mb4_unicode_ci` collation always.
- InnoDB engine always; never MyISAM.
- Indexes: add on all FK columns, all `WHERE` and `ORDER BY` columns.
- Use `EXPLAIN` before shipping any complex query.
- Migrations: versioned SQL files or Laravel migrations — never alter schema manually.
- Connection pooling: PgBouncer equivalent (ProxySQL) for high-traffic apps.
- Backups: daily `mysqldump` + binary log retention for point-in-time recovery.

### PostgreSQL
- Version 16+; use schemas to namespace objects in shared DBs.
- `UUID` primary keys with `gen_random_uuid()` for distributed systems.
- JSONB for semi-structured data; add GIN indexes on queried JSONB fields.
- Use `pg_stat_statements` for query performance monitoring.
- Migrations: Flyway, Liquibase, or framework-native migrations — always version-controlled.
- Pooling: **PgBouncer** in transaction mode for production.
- Vacuuming: monitor bloat; tune `autovacuum` for high-write tables.

### MongoDB
- Version 6+; always use replica sets — never standalone in production.
- Schema validation with JSON Schema at the collection level.
- Index all query fields; use `explain("executionStats")` to verify index usage.
- Avoid `$where` and JavaScript server-side execution.
- Use transactions for multi-document writes when atomicity matters.
- Atlas or self-hosted with authentication + TLS always enabled.
- Backups: mongodump + oplog tailing for point-in-time recovery.

---

## 📦 Ansible

### Structure
```
ansible/
├── inventory/
│   ├── production/
│   └── staging/
├── roles/
│   └── <role-name>/
│       ├── tasks/main.yml
│       ├── handlers/main.yml
│       ├── defaults/main.yml
│       └── templates/
├── playbooks/
└── ansible.cfg
```

### Best Practices
- Idempotent tasks always — every playbook safe to run multiple times.
- Use roles for reusable components — no monolithic playbooks.
- Variables: defaults in `roles/<role>/defaults/main.yml`; secrets in Ansible Vault.
- Never commit unencrypted secrets — `ansible-vault encrypt_string` for inline secrets.
- Tags on all tasks: `--tags deploy`, `--tags config` for targeted runs.
- Use `check mode` (`--check`) before running destructive playbooks in production.
- Handlers for service restarts — never restart services in tasks directly.
- Test roles with **Molecule** + Docker driver.

---

