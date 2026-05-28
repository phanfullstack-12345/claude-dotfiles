# Reference: devops-guide
# Load this file when working on tasks matching this domain.

## 🐳 Docker

### Dockerfile Best Practices
- Multi-stage builds always — separate `builder` and `runtime` stages.
- Pin base image versions: `node:20.11-alpine3.19` not `node:latest`.
- Non-root user in final stage: `USER node` or create `RUN addgroup -S app && adduser -S app -G app`.
- `.dockerignore`: exclude `node_modules`, `.env`, `.git`, `dist`, `coverage`.
- `COPY` dependencies and install before copying source (layer cache optimization).
- Health check in every service image.

```dockerfile
# Example multi-stage Node
FROM node:20.11-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:20.11-alpine AS runtime
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .
USER node
HEALTHCHECK --interval=30s CMD wget -qO- http://localhost:3000/health || exit 1
CMD ["node", "dist/index.js"]
```

### Docker Compose
- Use `docker-compose.yml` for local dev; separate `docker-compose.prod.yml` for overrides.
- Named volumes for persistent data — never bind-mount DB data in production.
- Secrets via environment variables from `.env` file (not committed).
- Set resource limits (`mem_limit`, `cpus`) in production compose files.

---

## ☸️ Kubernetes

### Manifests
- All manifests in `k8s/` or `deploy/k8s/` — organized by namespace or service.
- Use **Helm charts** for reusable deployments; raw manifests for simple one-offs.
- Always set `resources.requests` and `resources.limits` on every container.
- `livenessProbe` + `readinessProbe` on every Deployment.
- Never use `latest` image tag — use immutable digest or semver tags.
- `PodDisruptionBudget` for any service needing HA.

### Config & Secrets
- ConfigMaps for non-sensitive config; Secrets for credentials.
- Never commit raw Secrets to git — use **Sealed Secrets**, **External Secrets Operator**, or **Vault**.
- Environment-specific values via Helm `values-prod.yaml`, `values-staging.yaml`.

### Deployments
- Rolling updates by default; set `maxUnavailable: 0` + `maxSurge: 1` for zero-downtime.
- Namespace per environment: `app-dev`, `app-staging`, `app-prod`.
- RBAC: least-privilege service accounts per workload.
- Network policies: deny-all by default, explicit allow rules.

---

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

## 🔄 CI/CD — GitHub Actions & GitLab CI

### GitHub Actions
```yaml
# Workflow best practices
on:
  push:
    branches: [main, staging]
  pull_request:

jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'pnpm'
```
- Pin action versions to full SHA for security: `actions/checkout@v4` minimum; SHA for third-party.
- Secrets: GitHub Secrets only — never hardcode in workflow files.
- Environments: use GitHub Environments with required reviewers for production deploys.
- Cache dependencies: `actions/cache` or built-in tool caches.
- Matrix builds for cross-platform/version testing.
- Reusable workflows in `.github/workflows/` — DRY across repos.

### GitLab CI
```yaml
# .gitlab-ci.yml best practices
stages: [test, build, deploy]

default:
  image: node:20-alpine
  cache:
    key: $CI_COMMIT_REF_SLUG
    paths: [node_modules/]
```
- Use `rules:` over `only:/except:` (modern syntax).
- Protected branches + protected environments for production.
- Artifacts: upload test reports for MR test summaries.
- Dependency scanning + SAST + container scanning enabled in all projects.
- Use GitLab Container Registry for images built in CI.
- Merge request pipelines: run full CI on every MR; deploy jobs manual-only.

### Shared CI Principles
- Every pipeline: lint → test → build → security scan → deploy.
- Build once, promote the artifact — don't rebuild per environment.
- Fail fast: put quickest checks first.
- Notify on failure: Slack/email alerts on main branch failures.

---

## ⏰ Cron Jobs

- Document every cron job: purpose, schedule, owner, expected runtime.
- Use cron expression format and validate at https://crontab.guru.
- All cron jobs must be idempotent — safe to re-run if they fail mid-execution.
- Lock files or DB locks to prevent overlapping executions.
- Log start time, end time, exit code, and summary for every run.
- Alert on: missed runs, runtime > 2× expected, non-zero exit codes.
- For Laravel: `php artisan schedule:run` via single cron + `->withoutOverlapping()`.
- For Kubernetes: use `CronJob` resource; set `concurrencyPolicy: Forbid`.
- For complex workflows: prefer **Temporal** or **Celery Beat** over raw cron.

---


## ⚙️ DevOps / SRE / Platform Engineering

### SRE Principles

#### SLI / SLO / SLA / Error Budget
```
SLI (Service Level Indicator): measured metric
  → "99.2% of requests returned 200 in <500ms over the last 28 days"

SLO (Service Level Objective): target for SLI
  → "99.5% availability, p99 latency < 500ms"

SLA (Service Level Agreement): contractual commitment to customers
  → "99.9% uptime — financial penalty if breached"

Error Budget = 1 - SLO = allowed failure room
  → 99.5% SLO = 0.5% error budget = ~3.6 hours/month
  
When error budget is exhausted:
  → Freeze feature deployments until reliability work restores budget
```

#### Error Budget Policy
- Error budget > 50%: deploy freely, run experiments.
- Error budget 10-50%: slow down, fix reliability issues.
- Error budget < 10%: freeze all non-reliability changes.
- Budget exhausted: post-mortem required + reliability sprint.

#### SLO Dashboard (Prometheus)
```yaml
# Recording rule for availability SLI
- record: slo:requests:availability
  expr: |
    sum(rate(http_requests_total{status!~"5.."}[5m]))
    /
    sum(rate(http_requests_total[5m]))

# Alert when burning through error budget too fast
- alert: ErrorBudgetBurnFast
  expr: slo:requests:availability < 0.995
  for: 5m
  labels: { severity: critical }
```

### CI/CD Maturity

#### Progressive Delivery
```
Feature Flags → Canary → Blue-Green → Full rollout

Canary deployment:
  v1 (95% traffic) ──┐
                      ├── Load Balancer
  v2 (5% traffic)  ──┘
  
Monitor: error rate, p99 latency, business metrics
Promote if metrics stable → increase to 10%, 25%, 50%, 100%
Auto-rollback if error rate spikes
```

```yaml
# Argo Rollouts canary
spec:
  strategy:
    canary:
      steps:
      - setWeight: 5
      - pause: {duration: 10m}
      - analysis:
          templates: [{templateName: success-rate}]
      - setWeight: 50
      - pause: {duration: 10m}
      - setWeight: 100
```

#### Feature Flags
```ts
// OpenFeature SDK — vendor-neutral
import { OpenFeature } from "@openfeature/server-sdk";

const client = OpenFeature.getClient();

// Check flag
const isEnabled = await client.getBooleanValue("new-checkout-flow", false, {
  targetingKey: user.id,
  attributes: { plan: user.plan, country: user.country }
});

if (isEnabled) { /* new flow */ } else { /* old flow */ }
```
- Providers: **LaunchDarkly**, **Unleash** (self-hosted), **Flagsmith**, **GrowthBook**.
- Clean up flags within 2 sprints of full rollout — tech debt otherwise.
- Never use flags for authorization/security — use proper RBAC.

### Platform Engineering (IDP)

#### Internal Developer Platform
```
Self-service capabilities:
  ├── Service catalog (Backstage)  → discover services, docs, owners
  ├── Scaffolding (templates)      → spin up new service in 5min
  ├── Environments (ephemeral)     → PR = preview env, auto-teardown
  ├── Secrets management           → self-service via Vault UI
  └── Observability                → auto-provisioned dashboards + alerts
```

#### Backstage (IDP Framework)
```yaml
# catalog-info.yaml — service registration
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: payment-service
  annotations:
    github.com/project-slug: org/payment-service
    grafana/dashboard-selector: "service=payment-service"
    vault.io/role: payment-service
spec:
  type: service
  owner: payments-team
  lifecycle: production
  dependsOn:
    - component:user-service
    - resource:postgres-payments
```

### Toil Reduction
- **Toil**: manual, repetitive, automatable work that scales with service load.
- SRE teams cap toil at 50% of time — rest for engineering.
- Identify toil: tasks you do every week/month that don't require human judgment.
- Automate runbooks: convert "how to restart X" into scripts → operator patterns.
- **Runbook automation**: Ansible, Python scripts, K8s operators triggered by alerts.

### Chaos Engineering
```bash
# Chaos Mesh (K8s-native)
kubectl apply -f - <<EOF
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata: { name: pod-kill-test }
spec:
  action: pod-kill
  mode: random-max-percent
  value: "20"           # kill 20% of pods
  selector:
    namespaces: [production]
    labelSelectors: { app: payment-service }
  scheduler: { cron: "@every 30m" }
EOF

# AWS Fault Injection Simulator
aws fis create-experiment-template --cli-input-json file://network-latency-experiment.json
aws fis start-experiment --experiment-template-id EXT123
```

**Game Days**: scheduled chaos exercises — team responds to injected failures in real prod (with safeguards). Builds muscle memory for real incidents.

### On-Call Best Practices
```
Alert design principles:
  - Every alert must be actionable — no "informational" pages
  - Every alert must have a runbook link
  - Alerts fire on symptoms (user impact), not causes
  - P1: wake someone up. P2: business hours. P3: ticket.

Post-mortem culture:
  - Blameless: focus on systems, not people
  - Timeline: reconstruct minute-by-minute
  - Root cause: 5 whys, not just the proximate cause
  - Action items: assigned, time-boxed, tracked
  - Share widely: learnings benefit everyone
```

### Infrastructure Reliability Checklist
- [ ] All services have SLOs defined and dashboards showing error budget
- [ ] Runbooks exist for every P1/P2 alert
- [ ] DR tested in the last quarter
- [ ] Chaos tests run in staging monthly
- [ ] All infra changes go through IaC (zero manual console changes)
- [ ] Secrets rotated automatically (< 90 day TTL)
- [ ] On-call load < 2 interruptions/shift on average

---

