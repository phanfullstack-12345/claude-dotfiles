# Reference: fullstack-guide
# Load this file when working on tasks matching this domain.

## 🖥️ Senior Fullstack Engineer

### Technical Leadership Principles
- **Boring technology**: choose proven tools over cutting-edge — you maintain it for years.
- **Incremental delivery**: ship working software in small increments, not big-bang releases.
- **Reversibility**: prefer reversible decisions; mark irreversible ones as such in ADRs.
- **Pave the path**: make the right thing the easy thing — good tooling, templates, linting.
- **Code review as teaching**: comments explain why, not just what; ask questions, don't dictate.

### System Design Process
```
1. Clarify requirements
   - Functional: what does it do?
   - Non-functional: scale? latency? consistency? availability?
   
2. Estimate scale (back-of-envelope)
   - DAU × actions/day = requests/day → RPS
   - Data per request × RPS × retention = storage
   - Read/write ratio → cache strategy
   
3. High-level design (boxes and arrows)
   - Client → API Gateway → Services → DBs
   - Identify bottlenecks early
   
4. Deep dive on critical components
   - DB schema, API contracts, caching, async flows
   
5. Identify failure modes
   - What breaks under 10× load?
   - What happens when DB is down?
   - What if the queue fills up?
```

### API Design & Versioning
```ts
// REST versioning strategies
/api/v1/users          // URL versioning — most common, visible
Accept: application/vnd.api+json;version=1  // Header versioning — cleaner URLs

// Breaking vs non-breaking changes
// NON-BREAKING (backward compatible):
//   - Adding new optional fields to response
//   - Adding new optional query params
//   - Adding new endpoints

// BREAKING (requires new version):
//   - Removing fields from response
//   - Changing field types
//   - Changing behavior of existing endpoints
//   - Removing endpoints

// Deprecation header
Deprecation: true
Sunset: Sat, 01 Jan 2026 00:00:00 GMT
Link: <https://api.example.com/v2/users>; rel="successor-version"
```

### Performance Engineering

#### Frontend Performance
```ts
// React performance patterns
// 1. Virtualize long lists
import { FixedSizeList } from "react-window";

// 2. Code splitting at route level
const Dashboard = lazy(() => import("./Dashboard"));

// 3. Defer non-critical JS
<script defer src="analytics.js" />

// 4. Web Vitals monitoring
import { onLCP, onFID, onCLS } from "web-vitals";
onLCP(metric => sendToAnalytics({ metric }));

// 5. Image optimization
<Image src={img} width={800} height={600} priority={isAboveFold} />
```

#### Backend Performance
```ts
// N+1 query — most common performance killer
// ❌ N+1
const posts = await Post.findAll();
for (const post of posts) {
  post.author = await User.findByPk(post.authorId);  // 1 query per post
}

// ✅ Eager loading / DataLoader
const posts = await Post.findAll({ include: [{ model: User, as: "author" }] });

// ✅ DataLoader for GraphQL
const userLoader = new DataLoader(async (ids) => {
  const users = await User.findAll({ where: { id: ids } });
  return ids.map(id => users.find(u => u.id === id));
});
```

### Technical Debt Management
```
Debt types:
  Deliberate (documented) → "We chose this shortcut consciously — pay back in Q3"
  Accidental (discovered) → Found during refactor — log as tech debt ticket
  Bit rot → Code that was fine but dependencies moved on

Management approach:
  - 20% of sprint capacity reserved for tech debt
  - Every feature ticket includes debt notes ("while here, fix X")
  - Hotspot map: files with highest churn + complexity = refactor candidates
  - Track with "debt score" per module: coupling + complexity + test coverage
```

### Monorepo Patterns
```bash
# Turborepo setup
pnpm add -g turbo
turbo build --filter=./apps/web...   # build web + its dependencies
turbo test --filter=[HEAD^1]         # only test changed packages
turbo run lint build test --parallel # run pipeline

# Nx for polyglot monorepos (Node + Python + Go)
nx affected:build --base=main
nx graph  # visualize dependency graph
```

### Code Review Leadership
```
Review checklist for senior reviewers:
  Architecture: Does this fit our patterns? Any better approach?
  Correctness:  Edge cases? Error handling? Concurrent access?
  Security:     Input validation? Auth checks? Data exposure?
  Performance:  N+1? Missing indexes? Unnecessary allocations?
  Tests:        Coverage for new paths? Tests meaningful?
  Maintainability: Self-explanatory? Complexity justified?

Comment tone:
  ❌ "This is wrong"
  ✅ "This could fail under concurrent writes — consider optimistic locking"
  ❌ "Bad variable name"
  ✅ "Could we rename `d` to `deliveryDate` for clarity?"
```

---

## 🎨 Senior Frontend Developer

### Core Web Vitals Engineering
```
LCP (Largest Contentful Paint) < 2.5s   → hero image/text render time
INP (Interaction to Next Paint) < 200ms  → responsiveness to clicks/keystrokes
CLS (Cumulative Layout Shift) < 0.1     → visual stability score

Diagnose with:
  - Lighthouse CI in CI pipeline (fail on score regression)
  - WebPageTest for real-world waterfall
  - Chrome DevTools Performance panel (flame chart, long tasks)
  - Field data: Chrome User Experience Report (CrUX), RUM via web-vitals.js
```

#### LCP Optimization
```html
<!-- 1. Preload the LCP resource -->
<link rel="preload" href="/hero.webp" as="image" fetchpriority="high" />

<!-- 2. Explicit size prevents layout calc delay -->
<img src="/hero.webp" width="1200" height="600" fetchpriority="high" alt="..." />

<!-- 3. Server-push critical CSS inline in <head> — zero render-blocking -->
<style>/* only above-fold critical styles */</style>
```

```ts
// 4. Defer non-critical third-party scripts
// 5. Use next/image or equivalent — auto-sizing, WebP, lazy loading
// 6. Remove render-blocking JS — defer or async all scripts
// 7. Reduce TTFB: CDN, edge caching, server-side rendering

// Measure and report
import { onLCP, onINP, onCLS } from "web-vitals";
onLCP(metric => analytics.track("web_vital", { name: "LCP", value: metric.value }));
```

#### INP Optimization (Interaction Responsiveness)
```ts
// Long tasks block the main thread — break them up
// ❌ Blocks main thread for 200ms+
function processLargeDataset(items: Item[]) {
  items.forEach(item => heavyTransform(item));
}

// ✅ Yield to browser between chunks
async function processLargeDataset(items: Item[]) {
  for (let i = 0; i < items.length; i++) {
    heavyTransform(items[i]);
    if (i % 50 === 0) await scheduler.yield();  // yield every 50 items
  }
}

// ✅ Move heavy work off main thread
const worker = new Worker("./transform.worker.ts");
worker.postMessage({ items });
worker.onmessage = ({ data }) => setResults(data);
```

### Accessibility (WCAG 2.2)
```tsx
// Accessible interactive components
const Dialog = ({ isOpen, onClose, title, children }) => {
  const dialogRef = useRef<HTMLDialogElement>(null);

  useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;
    isOpen ? dialog.showModal() : dialog.close();
  }, [isOpen]);

  // Trap focus + ESC handled by native <dialog>
  return (
    <dialog
      ref={dialogRef}
      aria-labelledby="dialog-title"
      aria-describedby="dialog-body"
      onClose={onClose}  // fires on ESC
    >
      <h2 id="dialog-title">{title}</h2>
      <div id="dialog-body">{children}</div>
      <button onClick={onClose} aria-label="Close dialog">✕</button>
    </dialog>
  );
};
```

```bash
# Accessibility testing pipeline
npx axe-core --browser chromium https://localhost:3000   # automated a11y scan
# axe DevTools in browser for manual inspection

# Screen reader testing (manual — required for WCAG AA)
# macOS: VoiceOver (Cmd+F5)
# Windows: NVDA (free) or JAWS
# iOS: VoiceOver
# Android: TalkBack

# Color contrast check
npx contrast-ratio "#3b82f6" "#ffffff"   # must be ≥ 4.5:1 for text
```

**WCAG 2.2 AA Checklist:**
- [ ] 4.5:1 contrast ratio for normal text; 3:1 for large text (18pt+)
- [ ] All functionality reachable by keyboard (no mouse traps)
- [ ] Focus indicator visible on all interactive elements
- [ ] All images have alt text (empty `alt=""` for decorative)
- [ ] Form inputs have programmatic labels
- [ ] Error messages reference specific fields
- [ ] No content flashes more than 3× per second
- [ ] Target size ≥ 24×24px (WCAG 2.2 2.5.8)
- [ ] Dragging operations have single-pointer alternative

### Design Systems & Component Architecture

#### Component API Design
```tsx
// Design system component — flexible, typed, composable
interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "primary" | "secondary" | "ghost" | "destructive";
  size?: "sm" | "md" | "lg";
  loading?: boolean;
  leftIcon?: React.ReactNode;
  rightIcon?: React.ReactNode;
  asChild?: boolean;  // Radix pattern — render as child element
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ variant = "primary", size = "md", loading, leftIcon, rightIcon, children, disabled, ...props }, ref) => {
    return (
      <button
        ref={ref}
        disabled={disabled || loading}
        aria-busy={loading}
        data-variant={variant}
        data-size={size}
        {...props}
      >
        {loading ? <Spinner aria-hidden /> : leftIcon}
        {children}
        {rightIcon}
      </button>
    );
  }
);
Button.displayName = "Button";
```

#### Design Token Architecture
```ts
// tokens.ts — single source of truth
export const tokens = {
  color: {
    brand: {
      "50":  "#eff6ff",
      "500": "#3b82f6",
      "900": "#1e3a8a",
    },
    semantic: {
      primary:    "var(--color-brand-500)",
      danger:     "var(--color-red-500)",
      background: "var(--color-neutral-50)",
    },
  },
  space: { 1: "0.25rem", 2: "0.5rem", 4: "1rem", 8: "2rem" },
  radius: { sm: "0.25rem", md: "0.5rem", full: "9999px" },
  shadow: { sm: "0 1px 2px rgb(0 0 0 / 0.05)", md: "0 4px 6px rgb(0 0 0 / 0.1)" },
} as const;

// CSS custom properties from tokens (auto-generated via Style Dictionary or manual)
// :root { --color-brand-500: #3b82f6; }
```

### Micro-Frontends (Module Federation)

```ts
// Host app — webpack.config.ts
new ModuleFederationPlugin({
  name: "host",
  remotes: {
    checkout: "checkout@https://checkout.example.com/remoteEntry.js",
    analytics: "analytics@https://analytics.example.com/remoteEntry.js",
  },
  shared: { react: { singleton: true }, "react-dom": { singleton: true } },
})

// Remote (checkout) — exposes its components
new ModuleFederationPlugin({
  name: "checkout",
  filename: "remoteEntry.js",
  exposes: { "./CheckoutFlow": "./src/CheckoutFlow" },
  shared: { react: { singleton: true } },
})

// Consuming in host
const CheckoutFlow = lazy(() => import("checkout/CheckoutFlow"));
```

- Coordinate: shared auth state (cookie/token), shared design tokens, error boundaries per remote.
- CI: each micro-frontend deploys independently — contract tests ensure compatibility.
- Runtime integration only: never import from another MFE at build time.

### Testing Strategy

#### Testing Pyramid for Frontend
```
E2E (Playwright) — 10%
  └── Critical user flows (checkout, signup, key workflows)
  └── Cross-browser: chromium, firefox, webkit

Integration (Testing Library) — 30%
  └── Pages/routes with mocked API responses
  └── Component interactions spanning multiple components

Unit (Vitest) — 60%
  └── Pure utility functions
  └── Custom hooks (renderHook)
  └── Complex component logic
```

```tsx
// React Testing Library — test behavior, not implementation
import { render, screen, userEvent } from "@testing-library/react";

test("submits form with valid data", async () => {
  const onSubmit = vi.fn();
  render(<LoginForm onSubmit={onSubmit} />);

  await userEvent.type(screen.getByLabelText(/email/i), "user@example.com");
  await userEvent.type(screen.getByLabelText(/password/i), "secret123");
  await userEvent.click(screen.getByRole("button", { name: /sign in/i }));

  expect(onSubmit).toHaveBeenCalledWith({ email: "user@example.com", password: "secret123" });
});
```

```ts
// Playwright E2E
import { test, expect } from "@playwright/test";

test("user can complete checkout", async ({ page }) => {
  await page.goto("/products");
  await page.getByText("Add to Cart").first().click();
  await page.getByRole("link", { name: /cart/i }).click();
  await expect(page.getByTestId("cart-count")).toHaveText("1");
  await page.getByRole("button", { name: /checkout/i }).click();
  await expect(page).toHaveURL(/\/checkout/);
});
```

### Bundle Optimization
```ts
// Analyze bundle
ANALYZE=true pnpm build  // with @next/bundle-analyzer

// Code splitting — route-level (automatic in Next.js / Vite)
const HeavyChart = lazy(() => import("./HeavyChart"));  // 200KB+ chart lib

// Tree-shaking: named imports only
import { format } from "date-fns";  // ✅ — only format is bundled
import dateFns from "date-fns";     // ❌ — entire library bundled

// Dynamic imports for conditionally-needed modules
async function loadExporter() {
  const { exportToPDF } = await import("./pdf-exporter");  // only loaded on demand
  return exportToPDF;
}

// Bundle size budget (in CI)
// bundlesize config or Next.js experimental.bundleAnalyzer
```

**Performance Budget Targets:**
| Metric | Target | Fail threshold |
|---|---|---|
| JS bundle (gzipped) | < 100KB per route | > 200KB |
| CSS (gzipped) | < 20KB | > 50KB |
| LCP | < 2.5s | > 4s |
| INP | < 200ms | > 500ms |

### State Management Architecture

#### Decision Framework
```
Local UI state (toggle, form dirty) → useState / useReducer
Server state (fetched data)         → TanStack Query (React Query)
Global sync state (theme, user)     → Zustand / Jotai
Complex derived state               → Zustand computed / useMemo
Real-time state (WebSocket)         → Zustand + socket subscription
URL state (filters, pagination)     → useSearchParams (Next.js) / nuqs
```

```ts
// Zustand store — typed, minimal
interface UserStore {
  user: User | null;
  setUser: (user: User | null) => void;
  preferences: Preferences;
  updatePreferences: (patch: Partial<Preferences>) => void;
}

const useUserStore = create<UserStore>((set) => ({
  user: null,
  setUser: (user) => set({ user }),
  preferences: defaultPreferences,
  updatePreferences: (patch) =>
    set((state) => ({ preferences: { ...state.preferences, ...patch } })),
}));

// Selector — only re-render when specific slice changes
const theme = useUserStore((state) => state.preferences.theme);
```

### Progressive Enhancement
- Build for the most constrained environment first; add enhancements for capable environments.
- Base layer: HTML + server-rendered content — works without JS.
- Enhancement layer: client-side JS adds interactivity, animations, real-time updates.
- Test with JS disabled — critical content/forms should still work (or gracefully degrade).
- Service Worker for offline support and background sync.

### Cross-Browser Compatibility
```ts
// Feature detection (not browser detection)
if ("IntersectionObserver" in window) {
  // use IntersectionObserver
} else {
  // fallback: load all images immediately
}

// Polyfills — only for genuinely unsupported features
// @babel/preset-env + core-js: transpile and polyfill based on browserslist target

// browserslist (.browserslistrc)
> 0.5%
last 2 versions
not dead
not IE 11
```

---

## ⚙️ Senior Backend Developer

### API Design Patterns

#### Idempotency
```ts
// Idempotency keys — safe to retry without side effects
// Client generates key per logical operation; server deduplicates

app.post("/payments", async (req, res) => {
  const idempotencyKey = req.headers["idempotency-key"];
  if (!idempotencyKey) return res.status(400).json({ error: "Idempotency-Key required" });

  // Check if we've seen this key
  const cached = await redis.get(`idem:${idempotencyKey}`);
  if (cached) return res.status(200).json(JSON.parse(cached));  // replay cached response

  const result = await processPayment(req.body);

  // Store result for 24h — client can safely retry
  await redis.setex(`idem:${idempotencyKey}`, 86400, JSON.stringify(result));
  return res.status(201).json(result);
});
```

#### Pagination Patterns
```ts
// Cursor-based (preferred for real-time/large data)
GET /api/posts?cursor=eyJpZCI6MTAwfQ&limit=20

interface CursorPage<T> {
  data: T[];
  nextCursor: string | null;  // base64-encoded cursor
  hasMore: boolean;
}

// Offset-based (simpler, OK for small/static datasets)
GET /api/posts?page=2&limit=20

interface OffsetPage<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}
```

#### Contract Testing
```ts
// Pact — consumer-driven contract testing
// Consumer defines what it expects from the API
// Provider verifies it actually provides that

// Consumer test (frontend team defines the contract)
const provider = new PactV3({ consumer: "WebApp", provider: "UsersAPI" });

provider
  .uponReceiving("a request for user profile")
  .withRequest({ method: "GET", path: "/users/123" })
  .willRespondWith({
    status: 200,
    body: { id: 123, email: like("user@example.com"), name: like("Alice") }
  });
```

### Database Optimization

#### Query Planning & Indexing
```sql
-- EXPLAIN ANALYZE — understand query plan before shipping
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
SELECT u.name, COUNT(o.id) as order_count
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
WHERE u.status = 'active'
GROUP BY u.id;

-- Look for: Seq Scan (needs index?), nested loops on large tables, hash joins

-- Composite index — column order matters (selectivity first, then query order)
CREATE INDEX CONCURRENTLY idx_orders_user_status_created
  ON orders (user_id, status, created_at DESC);
-- Covers: WHERE user_id = ? AND status = ? ORDER BY created_at DESC

-- Partial index — index only what you query
CREATE INDEX idx_users_active ON users (email) WHERE status = 'active';

-- Expression index — for function-based queries
CREATE INDEX idx_lower_email ON users (LOWER(email));
-- Now: WHERE LOWER(email) = 'user@example.com' uses the index

-- CONCURRENTLY — build index without locking table (production-safe)
```

#### Connection Pooling
```ts
// PgBouncer config (transaction pooling for PostgreSQL)
// pool_mode = transaction    — connection returned to pool after each transaction
// pool_mode = session        — connection held for entire session (for prepared statements)
// max_client_conn = 1000     — connections from app → PgBouncer
// default_pool_size = 20     — connections PgBouncer → PostgreSQL

// Application-side pooling (pg library)
const pool = new Pool({
  max: 10,              // max connections per app instance
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 2_000,
});

// Drizzle ORM with connection pooling
const db = drizzle(pool);
```

#### Read Replicas
```ts
// Route reads to replica, writes to primary
class DatabaseRouter {
  private primary = new Pool({ host: process.env.DB_PRIMARY_HOST });
  private replica = new Pool({ host: process.env.DB_REPLICA_HOST });

  query(sql: string, params: any[], { write = false } = {}) {
    return write ? this.primary.query(sql, params) : this.replica.query(sql, params);
  }
}

// Use write DB for reads that must see their own writes (read-your-writes)
const user = await db.query("SELECT * FROM users WHERE id = $1", [id], { write: true });
```

### Caching Architecture

#### Multi-Layer Cache
```ts
// L1: In-process (fastest — microseconds)
const localCache = new Map<string, { value: any; expires: number }>();

// L2: Redis (shared across instances — milliseconds)
const redis = new Redis(process.env.REDIS_URL);

async function getUser(id: string): Promise<User> {
  // L1 check
  const l1 = localCache.get(`user:${id}`);
  if (l1 && l1.expires > Date.now()) return l1.value;

  // L2 check
  const l2 = await redis.get(`user:${id}`);
  if (l2) {
    const user = JSON.parse(l2);
    localCache.set(`user:${id}`, { value: user, expires: Date.now() + 30_000 }); // 30s L1
    return user;
  }

  // Cache miss — load from DB
  const user = await db.users.findUnique({ where: { id } });
  await redis.setex(`user:${id}`, 300, JSON.stringify(user)); // 5min L2
  localCache.set(`user:${id}`, { value: user, expires: Date.now() + 30_000 });
  return user;
}
```

#### Cache Invalidation Strategies
```ts
// 1. TTL-based (simplest)
await redis.setex(key, 300, value);  // expire after 5min

// 2. Event-driven (strong consistency)
async function updateUser(id: string, data: Partial<User>) {
  await db.users.update({ where: { id }, data });
  await redis.del(`user:${id}`);           // invalidate cache
  await redis.del(`user:profile:${id}`);   // invalidate derived cache
  eventBus.emit("user.updated", { id });   // notify other services
}

// 3. Cache-aside with version tag
const version = await redis.incr(`user:${id}:version`);
await redis.setex(`user:${id}:v${version}`, 300, JSON.stringify(user));

// 4. Write-through (cache updated with every write — strong consistency, higher write cost)
// 5. Write-behind (async cache update after write — lower write latency, risk of loss)
```

### Background Jobs & Queues

#### Queue Architecture
```ts
// BullMQ (Redis-backed queues for Node.js)
import { Queue, Worker, QueueEvents } from "bullmq";

const emailQueue = new Queue("emails", { connection: redis });

// Producer — add jobs
await emailQueue.add("sendWelcome", { userId, email }, {
  attempts: 3,
  backoff: { type: "exponential", delay: 5000 },
  removeOnComplete: 100,   // keep last 100 completed
  removeOnFail: 500,       // keep last 500 failed for inspection
});

// Worker — process jobs
const worker = new Worker("emails", async (job) => {
  const { userId, email } = job.data;
  await sendEmail(email, welcomeTemplate(userId));
  job.updateProgress(100);
}, {
  connection: redis,
  concurrency: 5,   // 5 parallel jobs
});

worker.on("failed", (job, err) => {
  logger.error({ jobId: job.id, err }, "Email job failed");
});
```

#### Retry Patterns
```ts
// Idempotent job handlers — safe to re-run
async function processOrderJob(job: Job<OrderPayload>) {
  const { orderId } = job.data;

  // Check if already processed
  const processed = await db.orderProcessingLog.findUnique({ where: { orderId } });
  if (processed) return { skipped: true };  // idempotent — already done

  await db.$transaction(async (tx) => {
    await tx.order.update({ where: { id: orderId }, data: { status: "processed" } });
    await tx.orderProcessingLog.create({ data: { orderId, processedAt: new Date() } });
  });
}
```

### Service Communication

#### Circuit Breaker
```ts
import CircuitBreaker from "opossum";

const paymentOptions = {
  timeout: 3000,           // call fails if > 3s
  errorThresholdPercentage: 50,  // open circuit if 50% fail
  resetTimeout: 30000,     // try again after 30s
};

const breaker = new CircuitBreaker(callPaymentService, paymentOptions);

breaker.on("open",    () => logger.warn("Payment circuit OPEN — using fallback"));
breaker.on("close",   () => logger.info("Payment circuit CLOSED — recovered"));
breaker.on("halfOpen",() => logger.info("Payment circuit testing..."));

async function processPayment(data: PaymentData) {
  return breaker.fire(data).catch(() => queueForRetryLater(data)); // fallback
}
```

#### gRPC for Internal Services
```proto
// payment.proto
syntax = "proto3";
package payment;

service PaymentService {
  rpc Charge(ChargeRequest) returns (ChargeResponse);
  rpc Refund(RefundRequest) returns (stream RefundEvent);  // server streaming
}

message ChargeRequest {
  string order_id = 1;
  int64 amount_cents = 2;
  string currency = 3;
}
```

```ts
// gRPC client (Node.js)
import { credentials } from "@grpc/grpc-js";
import { PaymentServiceClient } from "./generated/payment_grpc_pb";

const client = new PaymentServiceClient("payment-svc:50051", credentials.createInsecure());
const response = await promisify(client.charge.bind(client))(request);
```

### Error Handling & Resilience

#### Structured Error Hierarchy
```ts
// Base error with context
class AppError extends Error {
  constructor(
    message: string,
    public readonly code: string,        // machine-readable: "USER_NOT_FOUND"
    public readonly statusCode: number,  // HTTP: 404
    public readonly context?: Record<string, unknown>,
    public readonly isOperational = true // vs programming errors
  ) {
    super(message);
    this.name = this.constructor.name;
    Error.captureStackTrace(this, this.constructor);
  }
}

class NotFoundError extends AppError {
  constructor(resource: string, id: string) {
    super(`${resource} ${id} not found`, "NOT_FOUND", 404, { resource, id });
  }
}

class ValidationError extends AppError {
  constructor(errors: ZodError) {
    super("Validation failed", "VALIDATION_ERROR", 422, { errors: errors.flatten() });
  }
}

// Global error handler (Express)
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  if (err instanceof AppError && err.isOperational) {
    return res.status(err.statusCode).json({ code: err.code, message: err.message, context: err.context });
  }
  // Programming errors — log + 500
  logger.error({ err, path: req.path }, "Unhandled error");
  res.status(500).json({ code: "INTERNAL_ERROR", message: "An unexpected error occurred" });
});
```

### Observability Setup

#### Structured Logging
```ts
import pino from "pino";

const logger = pino({
  level: process.env.LOG_LEVEL ?? "info",
  formatters: {
    level: (label) => ({ level: label }),  // use string level, not number
  },
  base: {
    service: "payment-service",
    environment: process.env.NODE_ENV,
    version: process.env.APP_VERSION,
  },
});

// Always include request context
app.use((req, res, next) => {
  req.log = logger.child({
    requestId: req.headers["x-request-id"] ?? crypto.randomUUID(),
    userId: req.user?.id,
    path: req.path,
    method: req.method,
  });
  next();
});

// Log at appropriate levels
req.log.info({ orderId }, "Processing payment");
req.log.warn({ userId, attempts }, "Rate limit approaching");
req.log.error({ err, orderId }, "Payment failed");
```

#### Metrics (Prometheus)
```ts
import { Registry, Counter, Histogram } from "prom-client";

const registry = new Registry();

const httpRequestDuration = new Histogram({
  name: "http_request_duration_seconds",
  help: "HTTP request duration",
  labelNames: ["method", "route", "status_code"],
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5],
  registers: [registry],
});

const businessMetric = new Counter({
  name: "orders_processed_total",
  help: "Total orders processed",
  labelNames: ["status", "payment_method"],
  registers: [registry],
});

// Middleware to record metrics
app.use((req, res, next) => {
  const end = httpRequestDuration.startTimer({ method: req.method, route: req.route?.path });
  res.on("finish", () => end({ status_code: res.statusCode }));
  next();
});
```

### Rate Limiting Patterns
```ts
// Sliding window with Redis (no burst problem of fixed window)
async function rateLimitSliding(userId: string, limit: number, windowSec: number): Promise<boolean> {
  const key = `rate:${userId}`;
  const now = Date.now();
  const windowStart = now - windowSec * 1000;

  const pipeline = redis.pipeline();
  pipeline.zremrangebyscore(key, 0, windowStart);   // remove old entries
  pipeline.zadd(key, now, `${now}-${Math.random()}`); // add current request
  pipeline.zcard(key);                               // count in window
  pipeline.expire(key, windowSec);                   // auto-expire key
  const results = await pipeline.exec();

  const count = results[2][1] as number;
  return count <= limit;
}

// Leaky bucket for smooth output rate
// Token bucket for burst allowance
// Different limits per tier: free=100/min, pro=1000/min, enterprise=unlimited
```

### Authentication Architecture
```ts
// Access token + refresh token pattern
interface TokenPair {
  accessToken: string;    // short-lived: 15min, stateless JWT
  refreshToken: string;   // long-lived: 30 days, opaque, stored in DB
}

async function refreshTokens(refreshToken: string): Promise<TokenPair> {
  // Validate refresh token exists and not revoked
  const stored = await db.refreshToken.findUnique({
    where: { token: hashToken(refreshToken) },
    include: { user: true },
  });

  if (!stored || stored.expiresAt < new Date() || stored.revokedAt) {
    throw new UnauthorizedError("Invalid refresh token");
  }

  // Rotate: revoke old, issue new (token rotation)
  await db.refreshToken.update({ where: { id: stored.id }, data: { revokedAt: new Date() } });

  const newPair = await issueTokenPair(stored.user);
  return newPair;
}
```

### API Documentation (OpenAPI)
```ts
// Spec-first approach with Zod + zod-openapi
import { createRoute, OpenAPIHono } from "@hono/zod-openapi";
import { z } from "@hono/zod-openapi";

const UserSchema = z.object({
  id: z.string().uuid().openapi({ example: "550e8400-e29b-41d4-a716-446655440000" }),
  email: z.string().email().openapi({ example: "user@example.com" }),
  createdAt: z.string().datetime(),
}).openapi("User");

const getUserRoute = createRoute({
  method: "get",
  path: "/users/{id}",
  tags: ["Users"],
  summary: "Get user by ID",
  request: { params: z.object({ id: z.string().uuid() }) },
  responses: {
    200: { content: { "application/json": { schema: UserSchema } }, description: "User found" },
    404: { content: { "application/json": { schema: ErrorSchema } }, description: "User not found" },
  },
});
```

### Backend Performance Checklist
- [ ] All queries use indexes (EXPLAIN ANALYZE run on slow/common queries)
- [ ] N+1 queries eliminated (DataLoader, eager loading, batch queries)
- [ ] Connection pooling configured (PgBouncer or app-level pool)
- [ ] Caching applied to expensive/frequently-read data
- [ ] Async operations use queues (no blocking operations in request path)
- [ ] Rate limiting on all public endpoints
- [ ] Circuit breakers on external service calls
- [ ] Health check endpoint (`/health`) includes DB + dependencies
- [ ] Graceful shutdown: drain connections before SIGTERM exits
- [ ] Request timeout set globally (no unbounded requests)

---

