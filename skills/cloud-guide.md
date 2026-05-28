# Reference: cloud-guide
# Load this file when working on tasks matching this domain.

## ☁️ Cloud Developer

### Infrastructure as Code

#### Terraform (Deep Dive)
- Always use **remote state** (S3 + DynamoDB lock / GCS + state lock) — never local state in teams.
- Module structure:
  ```
  terraform/
  ├── modules/           # Reusable modules
  │   ├── vpc/
  │   ├── eks/
  │   └── rds/
  ├── environments/
  │   ├── dev/
  │   ├── staging/
  │   └── prod/
  └── shared/            # Shared resources (DNS, IAM base roles)
  ```
- Workspaces for lightweight env separation; separate state files for strict isolation.
- `terraform plan -out=tfplan` then `terraform apply tfplan` — never apply without reviewing plan.
- Lint with `tflint`; security scan with `tfsec` or `checkov` in CI.
- Pin provider versions in `required_providers` block — never use `~>` for major versions.
- Sensitive outputs: mark with `sensitive = true`; never log them.

```hcl
# Good practice
terraform {
  required_version = ">= 1.7"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.40" }
  }
  backend "s3" {
    bucket         = "my-tf-state"
    key            = "prod/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "tf-lock"
    encrypt        = true
  }
}
```

#### Pulumi (TypeScript)
- Use when you want full programming language power in IaC (loops, conditionals, abstractions).
- `pulumi new aws-typescript` / `pulumi new gcp-typescript`.
- Stack = environment: `pulumi stack select prod`.
- Secrets: `pulumi config set --secret DB_PASSWORD` — encrypted in state.
- Component Resources for reusable infrastructure modules.

### Serverless

#### AWS Lambda
- Keep functions small and single-purpose — one trigger, one job.
- Cold start mitigation: Provisioned Concurrency for latency-sensitive; SnapStart for Java.
- Bundle size matters: tree-shake, use Lambda Layers for shared dependencies.
- Always set `POWERTOOLS_SERVICE_NAME` + use AWS Lambda Powertools (Python/TS) for observability.
- Memory = CPU proxy: tune with AWS Lambda Power Tuning tool.
- Dead Letter Queue (DLQ) on async invocations — never lose events silently.

```ts
// Lambda Powertools pattern (TypeScript)
import { Logger } from "@aws-lambda-powertools/logger";
import { Tracer } from "@aws-lambda-powertools/tracer";
import { Metrics, MetricUnit } from "@aws-lambda-powertools/metrics";

const logger = new Logger({ serviceName: "order-service" });
const tracer = new Tracer({ serviceName: "order-service" });
const metrics = new Metrics({ namespace: "MyApp", serviceName: "order-service" });

export const handler = async (event: APIGatewayEvent) => {
  logger.info("Processing order", { orderId: event.pathParameters?.id });
  metrics.addMetric("OrderProcessed", MetricUnit.Count, 1);
  // ...
};
```

#### GCP Cloud Functions / Cloud Run
- **Cloud Functions**: event-driven, stateless, max 9min timeout.
- **Cloud Run**: preferred for HTTP workloads — containerized, scales to zero, no cold start constraint.
- Use Eventarc for event routing between GCP services.
- `GOOGLE_CLOUD_PROJECT` env var always set — use for service discovery.

### Observability Stack

#### OpenTelemetry (OTel)
- Instrument once, export anywhere — vendor-neutral.
- Three pillars: **Traces** (request flow), **Metrics** (aggregated numbers), **Logs** (events).
- Auto-instrumentation for Node.js: `@opentelemetry/auto-instrumentations-node`.
- Manual spans for business-critical operations:
  ```ts
  const tracer = trace.getTracer("my-service");
  const span = tracer.startSpan("processOrder");
  span.setAttributes({ "order.id": orderId, "order.total": total });
  try {
    await processOrder(orderId);
  } finally {
    span.end();
  }
  ```
- Export to: Jaeger (dev), GCP Cloud Trace / AWS X-Ray / Grafana Tempo (prod).

#### Prometheus + Grafana
- Metrics: counters (ever-increasing), gauges (current value), histograms (distribution), summaries.
- Expose `/metrics` endpoint — Prometheus scrapes on interval.
- Alert on: error rate > 1%, p99 latency > 500ms, pod restarts > 3 in 5min.
- Grafana dashboards as code: store JSON in repo; deploy via `grafana-operator` or Terraform.
- `recording rules` for expensive queries — precompute at scrape time.

#### Log Aggregation
- Structured JSON logs always — never raw strings.
- Fields every log must have: `timestamp`, `level`, `service`, `traceId`, `spanId`, `userId` (if applicable).
- Stack options: **ELK** (Elasticsearch + Logstash + Kibana), **Grafana Loki** (log-native, cheaper).
- Log levels: ERROR (pages someone), WARN (needs attention), INFO (normal operations), DEBUG (dev only — never in prod by default).

### GitOps

#### ArgoCD
- Git is the single source of truth for cluster state — no `kubectl apply` in CI.
- App-of-apps pattern: one root ArgoCD Application manages all others.
- Sync policies: `automated` with `selfHeal: true` for non-prod; manual sync for prod.
- Image updater: auto-commit new image tags to Git → ArgoCD deploys.
- RBAC: separate projects per team/environment.

```yaml
# ArgoCD Application
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app-prod
  namespace: argocd
spec:
  project: production
  source:
    repoURL: https://github.com/org/k8s-manifests
    targetRevision: main
    path: apps/my-app/prod
  destination:
    server: https://kubernetes.default.svc
    namespace: my-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Cloud Security
- **OIDC federation**: GitHub Actions / GitLab CI authenticate to AWS/GCP via OIDC — no long-lived keys.
- **Secrets management**: HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager — rotate automatically.
- **Least privilege IAM**: per-workload service accounts; audit with IAM Access Analyzer / GCP IAM Recommender.
- **Security scanning in CI**: `tfsec`/`checkov` (IaC), `trivy` (containers), `Snyk` (dependencies).
- **VPC design**: private subnets for everything; NAT Gateway for outbound; no public IPs on compute.
- **Encryption**: at rest (KMS-managed keys), in transit (TLS 1.2+ everywhere, mTLS between services).
- **CSPM**: AWS Security Hub / GCP Security Command Center — continuous compliance checks.

### Cost Optimization (FinOps)
- Tag everything: `environment`, `team`, `service`, `cost-center` — enforce via policy.
- Right-size before reserving: use Compute Optimizer (AWS) / Recommender (GCP).
- Spot/Preemptible for stateless workloads (CI runners, batch jobs, dev environments).
- Reserved Instances / Committed Use Discounts for stable baseline load (1–3 year).
- S3/GCS lifecycle policies: auto-transition to cheaper storage tiers.
- Delete idle resources: unattached EBS volumes, unused load balancers, old snapshots.
- Budget alerts at 50%, 80%, 100% of monthly budget — notify before overspend.

### GCP (Expanded)
- **Cloud Run**: preferred for HTTP microservices — auto-scale, pay-per-request, no cluster mgmt.
- **GKE Autopilot**: managed node pools, auto-provisioning, built-in security hardening.
- **Pub/Sub**: async messaging, fan-out, retry with exponential backoff, dead letter topics.
- **Workflows**: orchestrate multi-step cloud operations with retry and error handling.
- **Cloud Spanner**: globally distributed relational DB — use for global apps needing SQL + HA.
- **Artifact Registry**: store container images, npm, Maven, Python packages — not Container Registry.
- **Cloud Armor**: WAF + DDoS protection on load balancer.
- **VPC Service Controls**: perimeter around sensitive data — prevent data exfiltration.

### AWS (Expanded)
- **ECS Fargate**: serverless containers — no EC2 management; use for simple microservices.
- **EKS**: full Kubernetes — use when team has K8s expertise or needs advanced workloads.
- **EventBridge**: event bus for decoupled architectures — schedule rules, cross-account events.
- **SQS + SNS**: SQS for reliable queue; SNS for fan-out to multiple SQS queues.
- **Step Functions**: serverless workflow orchestration — visualize state machines.
- **API Gateway**: managed API layer — rate limiting, auth, caching, OpenAPI import.
- **CloudFormation / CDK**: CDK (TypeScript) preferred — type-safe IaC with full programming model.
- **WAF + Shield**: protect ALB/CloudFront from OWASP attacks and DDoS.

### Multi-Cloud & Hybrid
- Abstract cloud-specific services behind interfaces — swap provider without rewriting business logic.
- Use Terraform for cross-cloud provisioning (same workflow, different providers).
- DNS-based failover for multi-region/multi-cloud DR.
- Object storage abstraction: MinIO-compatible API works locally, on AWS (S3), GCP (GCS), UpCloud.
- Avoid cloud-proprietary lock-in for core data stores — prefer portable options (PostgreSQL, Redis).

---


## 🏗️ Cloud Architecture

### Well-Architected Framework Pillars
| Pillar | Key Questions |
|---|---|
| **Operational Excellence** | How do we run and improve? Runbooks, observability, CI/CD |
| **Security** | Who can do what? Least privilege, encryption, audit |
| **Reliability** | How do we recover from failure? HA, DR, chaos testing |
| **Performance Efficiency** | Right resource for the job? Scaling, caching, benchmarking |
| **Cost Optimization** | Pay only for what you need? Right-sizing, reserved capacity |
| **Sustainability** | Minimize environmental impact? Efficient regions, auto-scaling |

### High Availability Patterns

#### Multi-Region Active-Active
```
Region A (Primary)          Region B (Secondary)
  ALB/GLB                     ALB/GLB
   ↓                            ↓
  App Tier ←─────sync──────→ App Tier
   ↓                            ↓
  DB (Primary) ──replication──→ DB (Replica+Promote)
   ↓                            ↓
  Global DNS (Route53/Cloud DNS) — failover policy
```
- RPO (Recovery Point Objective): max data loss tolerance → dictates replication lag.
- RTO (Recovery Time Objective): max downtime tolerance → dictates automation speed.
- Active-active: both regions serve traffic, near-zero RTO/RPO — highest cost.
- Active-passive: secondary on standby — lower cost, higher RTO.

#### Database HA
```
PostgreSQL HA stack:
  Primary → Streaming replication → Replica (sync)
                                  → Replica (async)
  Patroni/pg_auto_failover: automatic primary election
  PgBouncer: connection pooling in front
  
RDS Multi-AZ: synchronous standby, automatic failover ~60s
Aurora: 6-way replication across 3 AZs, failover ~30s, global database option
```

### Landing Zone Design
```
Management Account
├── Security Account      (GuardDuty, Security Hub, CloudTrail aggregation)
├── Log Archive Account   (centralized S3 log bucket, read-only)
├── Shared Services Account (DNS, AD, Transit Gateway)
├── Network Account       (VPCs, TGW, Direct Connect, VPN)
└── Workload Accounts
    ├── Dev               (loose guardrails, low cost)
    ├── Staging           (mirrors prod topology)
    └── Production        (strict SCPs, full HA)
```
- Service Control Policies (SCPs): deny regions you don't use, deny root API usage.
- AWS Control Tower / GCP Organization Policies for guardrails at scale.
- Each account = blast radius boundary — compromise of one doesn't affect others.

### Network Topology

#### Hub-Spoke (Most Common)
```
                [Hub VPC]
              Transit Gateway / VPC Peering
    ┌──────────────┼──────────────┐
[Dev VPC]    [Staging VPC]    [Prod VPC]
              ↕                    ↕
         [Shared Services VPC]  [Security VPC]
```
- Transit Gateway: connects 100s of VPCs/accounts — hub-spoke at scale.
- VPC Peering: point-to-point, free within region — use for simple 2-3 VPC setups.
- PrivateLink: expose services without VPC peering — service consumer model.

#### Zero Trust Network
- No implicit trust based on network location — verify every request.
- mTLS between all services (service mesh: Istio/Linkerd).
- Every request authenticated + authorized: service accounts + RBAC.
- Micro-segmentation: each service only talks to services it needs.
- BeyondCorp model for admin access: device posture + identity, no VPN.

### Scalability Architecture

#### Auto-Scaling Strategies
```yaml
# K8s HPA — scale on CPU/memory/custom metrics
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
spec:
  minReplicas: 2
  maxReplicas: 50
  metrics:
  - type: Resource
    resource:
      name: cpu
      target: { type: Utilization, averageUtilization: 60 }
  - type: External  # custom metric: queue depth
    external:
      metric: { name: sqs_messages_visible }
      target: { type: AverageValue, averageValue: "10" }
```

- **Scale-out first** (horizontal) — stateless services should scale horizontally.
- **Scale-up for databases** — vertical scaling + read replicas before sharding.
- **KEDA** (K8s Event-Driven Autoscaling): scale based on queue depth, Kafka lag, cron.
- Pre-warm for known traffic spikes: scheduled scaling before events.

### Disaster Recovery Tiers
| Tier | Strategy | RTO | RPO | Cost |
|---|---|---|---|---|
| 1 | Backup & Restore | Hours | Hours | $ |
| 2 | Pilot Light | 10-30min | Minutes | $$ |
| 3 | Warm Standby | Minutes | Seconds | $$$ |
| 4 | Multi-site Active-Active | Near-zero | Near-zero | $$$$ |

- Document DR runbooks; test DR quarterly with game days.
- Automate failover where possible — humans are slow under pressure.
- Chaos engineering: **Netflix Chaos Monkey**, **AWS Fault Injection Simulator**.

### Architecture Decision Framework
```
For each architectural decision, evaluate:
1. Consistency requirements   → strong (SQL) vs eventual (NoSQL/events)
2. Scale requirements         → current vs 10x vs 100x load
3. Team capability            → what can the team maintain?
4. Build vs buy               → OSS vs managed service vs custom
5. Failure modes              → what breaks when this fails?
6. Cost at scale              → $ per 1M requests / GB / user
7. Reversibility              → how hard to undo in 6 months?
```

---

