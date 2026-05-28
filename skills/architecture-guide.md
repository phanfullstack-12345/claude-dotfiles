# Reference: architecture-guide
# Load this file when working on tasks matching this domain.

## 🏛️ Software Architecture

### Core Principles
- **SOLID**: Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion.
- **DRY** (Don't Repeat Yourself), **KISS** (Keep It Simple), **YAGNI** (You Ain't Gonna Need It).
- Separation of concerns — every layer does one thing well.
- Design for change: depend on abstractions, not concretions.
- Prefer composition over inheritance.

### Architectural Patterns

#### Modular Monolith → Microservices
- Start with a **modular monolith** — clear module boundaries, no shared DB tables across modules.
- Extract to microservices only when: independent scaling, independent deployments, or team autonomy requires it.
- Each microservice owns its data — no shared database. Communicate via API or events.
- Use **strangler fig pattern** for gradual migration from monolith.

#### Hexagonal Architecture (Ports & Adapters)
- Domain layer has zero framework dependencies.
- Ports = interfaces defined by the domain (driven ports: repositories, driven adapters: controllers/routes).
- Adapters = implementations: HTTP controllers, DB repositories, message consumers.
- Test domain logic in isolation — swap adapters without touching domain.

```
src/
├── domain/          # Entities, value objects, domain services — NO framework imports
│   ├── entities/
│   ├── repositories/    # Interfaces (ports)
│   └── services/
├── application/     # Use cases — orchestrate domain + ports
│   └── use-cases/
├── infrastructure/  # Adapters — DB, HTTP, queues
│   ├── persistence/ # TypeORM/Prisma repo implementations
│   └── http/        # Controllers
└── main.ts
```

#### Clean Architecture
- Dependencies point inward: Frameworks → Adapters → Use Cases → Entities.
- Entities: enterprise business rules — pure TypeScript/Java/Python classes.
- Use Cases: application business rules — orchestrate entities.
- Interface Adapters: convert data between use cases and external formats.
- Frameworks & Drivers: outermost ring — DBs, UI, web frameworks.

#### Domain-Driven Design (DDD)
- **Bounded Contexts**: explicit boundaries around domain models — different contexts can have different models for the same concept (e.g. `User` in Auth vs Billing).
- **Aggregates**: consistency boundary — only the aggregate root is referenced from outside.
- **Domain Events**: things that happened — `UserRegistered`, `OrderPlaced`.
- **Value Objects**: immutable, no identity — `Money`, `Email`, `Address`.
- **Repository**: abstract persistence behind an interface, per aggregate root.
- **Anti-corruption Layer**: translates between bounded contexts.

#### Event-Driven Architecture (EDA)
- Events = facts that happened (past tense) — `OrderShipped`, not `ShipOrder`.
- **Event sourcing**: store events as source of truth; derive state by replaying.
- **CQRS**: separate read model (query) from write model (command) — different DTOs, different DBs allowed.
- At-least-once delivery: consumers must be idempotent.
- **Outbox pattern**: write event to DB in same transaction as state change; relay reads from outbox.

```
// Outbox pattern
BEGIN TRANSACTION;
  INSERT INTO orders (id, status) VALUES (...);
  INSERT INTO outbox (event_type, payload) VALUES ('OrderCreated', {...});
COMMIT;
-- Relay process polls outbox → publishes to Kafka/RabbitMQ → marks sent
```

### API Design

#### REST
- Resources are nouns, plural: `/users`, `/orders/{id}/items`.
- HTTP verbs: `GET` (read), `POST` (create), `PUT` (replace), `PATCH` (partial update), `DELETE`.
- Status codes: `200` OK, `201` Created, `204` No Content, `400` Bad Request, `401` Unauth, `403` Forbidden, `404` Not Found, `409` Conflict, `422` Validation Error, `500` Server Error.
- Versioning: URL prefix (`/api/v1/`) for major breaking changes; headers for minor.
- Pagination: cursor-based for large/real-time data; offset for small static datasets.
- HATEOAS links in responses for discoverability (optional but good for public APIs).

#### GraphQL
- Schema-first: define `.graphql` schema before resolvers.
- Solve N+1 with **DataLoader** — batch and cache DB calls per request.
- Mutations return the modified object — never void.
- Use `@nestjs/graphql` with code-first or schema-first approach.
- Rate limit by query complexity (`graphql-query-complexity`) not just request count.
- Subscriptions via WebSocket for real-time (prefer SSE for unidirectional).

#### gRPC
- Use for internal service-to-service calls — lower latency, strong typing.
- Define contracts in `.proto` files — commit to repo, share via package.
- Streaming: client-streaming, server-streaming, bidirectional.
- Use `@nestjs/microservices` with gRPC transport in NestJS.

### Messaging & Async

#### RabbitMQ
- Exchanges: `direct` (routing key exact match), `topic` (wildcard), `fanout` (broadcast), `headers`.
- Use **durable** queues and **persistent** messages for guaranteed delivery.
- Dead Letter Exchange (DLX) for failed messages — never silently discard.
- Prefetch count (`channel.prefetch(1)`) to prevent one consumer being overwhelmed.
- ACK after successful processing — NACK + requeue on transient errors.

#### Apache Kafka
- Topics are append-only logs — consumers track their own offset.
- Partitions enable parallelism — messages with same key go to same partition (ordering guarantee).
- Consumer groups: each group reads all messages; each partition read by one consumer per group.
- Retention: configure by size or time — Kafka is not a queue, it's a log.
- Use **Avro** or **Protobuf** with Schema Registry for schema evolution.
- Idempotent producers + exactly-once semantics for financial data.

### Scalability & Resilience Patterns
- **Circuit Breaker**: fail fast when downstream is unhealthy — states: Closed → Open → Half-Open.
- **Retry with exponential backoff + jitter**: don't hammer a recovering service.
- **Bulkhead**: isolate resources per service — thread pool or connection pool per downstream.
- **Rate Limiting**: token bucket or sliding window — protect both inbound and outbound.
- **Saga**: manage distributed transactions — choreography (events) or orchestration (central coordinator).
- **Cache-aside**: app checks cache → on miss, load from DB and populate cache.
- **Read replicas**: route read queries to replicas; writes to primary.
- **Database sharding**: horizontal partition by key — last resort, adds complexity.

### Caching Strategy
```
L1: In-process cache (Node Map / Guava) — microseconds, process-local
L2: Redis / Memcached — milliseconds, shared across instances
L3: CDN edge cache — geographic proximity for static/semi-static content
DB: Query cache, materialized views
```
- Cache invalidation: TTL + event-driven invalidation on write.
- Cache stampede: use probabilistic early expiration or locking on cache miss.
- Never cache user-specific sensitive data in shared cache without namespacing.

### Architecture Documentation
- **ADR (Architecture Decision Record)**: one Markdown file per significant decision.
  ```
  # ADR-001: Use PostgreSQL as Primary Database
  ## Status: Accepted
  ## Context: ...
  ## Decision: ...
  ## Consequences: ...
  ```
- **C4 Model**: Context → Containers → Components → Code diagrams.
- Store ADRs in `docs/adr/` — commit to repo, never in wikis alone.
- OpenAPI spec: write spec first (`openapi.yaml`), generate stubs — not the reverse.

### Design Patterns Reference
| Pattern | Category | Use when |
|---|---|---|
| Repository | Data access | Abstract DB from business logic |
| Unit of Work | Data access | Group DB operations in one transaction |
| Factory | Creational | Complex object creation logic |
| Builder | Creational | Many optional constructor params |
| Strategy | Behavioral | Swap algorithms at runtime |
| Observer / Event Emitter | Behavioral | Decouple event producers from consumers |
| Decorator | Structural | Add behavior without modifying class |
| Facade | Structural | Simplify complex subsystem interface |
| CQRS | Architectural | Separate read and write models |
| Outbox | Messaging | Guaranteed event delivery |
| Saga | Distributed | Coordinate multi-service transactions |
| Strangler Fig | Migration | Incrementally replace legacy system |

---

