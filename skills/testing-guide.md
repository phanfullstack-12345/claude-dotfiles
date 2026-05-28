# Reference: testing-guide
# Load this file when working on tasks matching this domain.

## 🧪 Testing — Senior QA Engineer & Senior Developer

### Testing Philosophy
- Tests are executable specifications — they document intent, not just verify output.
- Test behavior, not implementation. If refactoring breaks tests without changing behavior, the tests are wrong.
- **Shift left**: catch bugs early (unit) — not late (prod). Cost of fixing a bug: unit < integration < staging < prod.
- Tests must be: **F**ast, **I**solated, **R**epeatable, **S**elf-validating, **T**imely (FIRST).
- A failing test is a gift — it found a problem before users did.
- Flaky tests are worse than no tests — they erode trust. Fix or delete immediately.

### Testing Pyramid
```
         ▲
        /E2E\          ← 10% — Playwright / Cypress — real browser, critical user flows
       /──────\
      /Integr. \       ← 30% — API tests, DB tests, service boundaries
     /──────────\
    /    Unit    \     ← 60% — pure functions, components, business logic
   ──────────────────
```

- **Unit**: milliseconds per test, no I/O, no network. Test one thing in isolation.
- **Integration**: test how components work together — real DB, real HTTP, mocked external APIs.
- **E2E**: test the full user journey in a real browser — slow, brittle, high-value when done right.
- **Contract**: verify API consumers and providers agree on the interface (Pact).
- **Performance**: verify response times and throughput under load (k6, Locust).
- **Security**: automated vuln scanning + manual pen testing (OWASP ZAP, Semgrep).

### Unit Testing

#### JavaScript / TypeScript (Vitest / Jest)
```ts
// vitest.config.ts
import { defineConfig } from "vitest/config";
export default defineConfig({
  test: {
    environment: "node",        // or "jsdom" for browser-like
    coverage: {
      provider: "v8",
      reporter: ["text", "lcov"],
      thresholds: { branches: 80, functions: 80, lines: 80 },
    },
  },
});
```

```ts
// Unit test patterns
import { describe, it, expect, vi, beforeEach } from "vitest";

describe("calculateDiscount", () => {
  it("applies 10% for orders over $100", () => {
    expect(calculateDiscount(150, "STANDARD")).toBe(15);
  });

  it("applies no discount below threshold", () => {
    expect(calculateDiscount(80, "STANDARD")).toBe(0);
  });

  it("throws on negative amount", () => {
    expect(() => calculateDiscount(-10, "STANDARD")).toThrow("Amount must be positive");
  });
});

// Mocking — spy on dependencies
describe("UserService.create", () => {
  const mockRepo = { save: vi.fn(), findByEmail: vi.fn() };
  const service = new UserService(mockRepo);

  beforeEach(() => vi.clearAllMocks());

  it("hashes password before saving", async () => {
    mockRepo.findByEmail.mockResolvedValue(null);
    mockRepo.save.mockResolvedValue({ id: "1", email: "user@example.com" });

    await service.create({ email: "user@example.com", password: "secret" });

    const savedUser = mockRepo.save.mock.calls[0][0];
    expect(savedUser.password).not.toBe("secret");           // must be hashed
    expect(savedUser.password).toMatch(/^\$argon2/);         // argon2 prefix
  });

  it("throws ConflictError when email already exists", async () => {
    mockRepo.findByEmail.mockResolvedValue({ id: "1" });

    await expect(service.create({ email: "user@example.com", password: "secret" }))
      .rejects.toThrow(ConflictError);
  });
});

// Parameterized tests — avoid duplication
it.each([
  ["admin",  true],
  ["editor", true],
  ["viewer", false],
])("user with role %s can delete: %s", (role, expected) => {
  expect(canDelete({ role })).toBe(expected);
});
```

#### Python (pytest)
```python
# pytest.ini / pyproject.toml
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "--strict-markers --tb=short -q"
markers = [
  "slow: marks tests as slow",
  "integration: marks tests as integration tests",
]

# Unit test patterns
import pytest
from unittest.mock import AsyncMock, patch, MagicMock

class TestCalculateDiscount:
    def test_applies_10_percent_over_100(self):
        assert calculate_discount(150, "STANDARD") == 15.0

    def test_no_discount_below_threshold(self):
        assert calculate_discount(80, "STANDARD") == 0.0

    @pytest.mark.parametrize("amount,code,expected", [
        (150, "STANDARD", 15.0),
        (200, "PREMIUM",  40.0),   # 20% for premium
        (50,  "STANDARD",  0.0),
    ])
    def test_discount_scenarios(self, amount, code, expected):
        assert calculate_discount(amount, code) == expected

    def test_raises_on_negative_amount(self):
        with pytest.raises(ValueError, match="Amount must be positive"):
            calculate_discount(-10, "STANDARD")


# Fixtures — shared setup
@pytest.fixture
def mock_user_repo():
    repo = MagicMock()
    repo.find_by_email = AsyncMock(return_value=None)
    repo.save = AsyncMock(return_value={"id": "1", "email": "user@example.com"})
    return repo

@pytest.fixture
def user_service(mock_user_repo):
    return UserService(repo=mock_user_repo)

@pytest.mark.asyncio
async def test_create_hashes_password(user_service, mock_user_repo):
    await user_service.create(email="user@example.com", password="secret")
    saved = mock_user_repo.save.call_args[0][0]
    assert saved["password"] != "secret"
    assert saved["password"].startswith("$argon2")
```

#### Java (JUnit 5 + Mockito)
```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock private UserRepository userRepository;
    @InjectMocks private UserService userService;

    @Test
    void createUser_hashesPassword() {
        when(userRepository.findByEmail(any())).thenReturn(Optional.empty());
        when(userRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        User created = userService.create(new CreateUserRequest("user@example.com", "secret"));

        assertThat(created.getPassword()).doesNotContain("secret");
        assertThat(created.getPassword()).startsWith("$2a$");  // BCrypt prefix
    }

    @Test
    void createUser_throwsOnDuplicateEmail() {
        when(userRepository.findByEmail("user@example.com"))
            .thenReturn(Optional.of(new User()));

        assertThatThrownBy(() -> userService.create(new CreateUserRequest("user@example.com", "pw")))
            .isInstanceOf(ConflictException.class)
            .hasMessageContaining("already in use");
    }

    @ParameterizedTest
    @CsvSource({"admin,true", "editor,true", "viewer,false"})
    void canDelete_byRole(String role, boolean expected) {
        assertThat(userService.canDelete(role)).isEqualTo(expected);
    }
}
```

### Integration Testing

#### Node.js API Integration Tests
```ts
// Use supertest + real Express app; mock only external services (email, payments)
import request from "supertest";
import { app } from "../src/app";
import { db } from "../src/db";

describe("POST /api/users", () => {
  beforeEach(async () => {
    await db.user.deleteMany();          // clean slate per test
  });

  afterAll(async () => {
    await db.$disconnect();
  });

  it("creates a user and returns 201", async () => {
    const res = await request(app)
      .post("/api/users")
      .send({ email: "alice@example.com", password: "Secret123!" })
      .expect(201);

    expect(res.body).toMatchObject({
      id: expect.any(String),
      email: "alice@example.com",
    });
    expect(res.body.password).toBeUndefined();   // never expose password hash
  });

  it("returns 409 on duplicate email", async () => {
    await db.user.create({ data: { email: "alice@example.com", password: "hash" } });

    await request(app)
      .post("/api/users")
      .send({ email: "alice@example.com", password: "Secret123!" })
      .expect(409);
  });

  it("returns 422 on invalid email", async () => {
    const res = await request(app)
      .post("/api/users")
      .send({ email: "not-an-email", password: "Secret123!" })
      .expect(422);

    expect(res.body.errors).toBeDefined();
  });
});
```

#### FastAPI Integration Tests (Python)
```python
import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.db import get_db, engine
from sqlalchemy.orm import Session

@pytest.fixture(autouse=True)
def clean_db():
    # truncate tables before each test
    with Session(engine) as session:
        session.execute(text("TRUNCATE TABLE users RESTART IDENTITY CASCADE"))
        session.commit()

@pytest.mark.asyncio
async def test_create_user_returns_201():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        resp = await client.post("/users", json={"email": "alice@example.com", "password": "Secret123!"})
    assert resp.status_code == 201
    assert resp.json()["email"] == "alice@example.com"
    assert "password" not in resp.json()

@pytest.mark.asyncio
async def test_create_user_duplicate_email():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        await client.post("/users", json={"email": "alice@example.com", "password": "Secret123!"})
        resp = await client.post("/users", json={"email": "alice@example.com", "password": "OtherPw1!"})
    assert resp.status_code == 409
```

#### Database Testing (Testcontainers)
```ts
// Real database in Docker — no mocks, no surprises
import { PostgreSqlContainer } from "@testcontainers/postgresql";

let container: StartedPostgreSqlContainer;

beforeAll(async () => {
  container = await new PostgreSqlContainer("postgres:16-alpine").start();
  process.env.DATABASE_URL = container.getConnectionUri();
  await runMigrations();           // apply real migrations to test DB
}, 30_000);

afterAll(async () => {
  await container.stop();
});

it("persists and retrieves user", async () => {
  const user = await userRepo.create({ email: "test@example.com" });
  const found = await userRepo.findById(user.id);
  expect(found.email).toBe("test@example.com");
});
```

```python
# Python — pytest-docker or testcontainers-python
from testcontainers.postgres import PostgresContainer

@pytest.fixture(scope="session")
def postgres():
    with PostgresContainer("postgres:16-alpine") as pg:
        yield pg.get_connection_url()
```

### E2E Testing (Playwright)

#### Setup & Configuration
```ts
// playwright.config.ts
import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [["html"], ["github"]],
  use: {
    baseURL: process.env.E2E_BASE_URL ?? "http://localhost:3000",
    trace: "on-first-retry",
    screenshot: "only-on-failure",
    video: "retain-on-failure",
  },
  projects: [
    { name: "chromium", use: { ...devices["Desktop Chrome"] } },
    { name: "firefox",  use: { ...devices["Desktop Firefox"] } },
    { name: "mobile",   use: { ...devices["iPhone 14"] } },
  ],
  webServer: {
    command: "pnpm start",
    url: "http://localhost:3000",
    reuseExistingServer: !process.env.CI,
  },
});
```

#### Test Patterns
```ts
import { test, expect, Page } from "@playwright/test";

// Page Object Model — encapsulate selectors and actions
class LoginPage {
  constructor(private page: Page) {}

  async goto() { await this.page.goto("/login"); }

  async login(email: string, password: string) {
    await this.page.getByLabel("Email").fill(email);
    await this.page.getByLabel("Password").fill(password);
    await this.page.getByRole("button", { name: /sign in/i }).click();
  }

  async expectErrorMessage(text: string) {
    await expect(this.page.getByRole("alert")).toContainText(text);
  }
}

class DashboardPage {
  constructor(private page: Page) {}
  async expectWelcome(name: string) {
    await expect(this.page.getByText(`Welcome, ${name}`)).toBeVisible();
  }
}

test.describe("Authentication", () => {
  test("user can log in with valid credentials", async ({ page }) => {
    const login = new LoginPage(page);
    const dashboard = new DashboardPage(page);

    await login.goto();
    await login.login("alice@example.com", "Secret123!");

    await expect(page).toHaveURL("/dashboard");
    await dashboard.expectWelcome("Alice");
  });

  test("shows error on invalid credentials", async ({ page }) => {
    const login = new LoginPage(page);
    await login.goto();
    await login.login("alice@example.com", "wrong-password");
    await login.expectErrorMessage("Invalid email or password");
  });
});

// Authentication fixture — reuse logged-in state
test.use({ storageState: "e2e/.auth/user.json" });

test.beforeAll(async ({ browser }) => {
  const context = await browser.newContext();
  const page = await context.newPage();
  // perform login once, save session
  await page.goto("/login");
  await page.getByLabel("Email").fill("alice@example.com");
  await page.getByLabel("Password").fill("Secret123!");
  await page.getByRole("button", { name: /sign in/i }).click();
  await page.waitForURL("/dashboard");
  await context.storageState({ path: "e2e/.auth/user.json" });
  await context.close();
});
```

#### Visual Regression Testing
```ts
// Playwright visual comparisons
test("homepage matches snapshot", async ({ page }) => {
  await page.goto("/");
  await page.waitForLoadState("networkidle");
  await expect(page).toHaveScreenshot("homepage.png", {
    fullPage: true,
    mask: [page.locator(".timestamp")],  // mask dynamic content
    maxDiffPixelRatio: 0.02,             // 2% pixel difference threshold
  });
});
```

### React Component Testing (Testing Library)
```tsx
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { server } from "../mocks/server";    // MSW mock server
import { http, HttpResponse } from "msw";

describe("UserProfile", () => {
  it("displays user name after loading", async () => {
    server.use(
      http.get("/api/user/1", () =>
        HttpResponse.json({ id: "1", name: "Alice", email: "alice@example.com" })
      )
    );

    render(<UserProfile userId="1" />);
    expect(screen.getByRole("status")).toBeInTheDocument();  // loading spinner

    await waitFor(() => {
      expect(screen.getByText("Alice")).toBeInTheDocument();
    });
    expect(screen.queryByRole("status")).not.toBeInTheDocument();
  });

  it("shows error state on API failure", async () => {
    server.use(
      http.get("/api/user/1", () => HttpResponse.error())
    );

    render(<UserProfile userId="1" />);

    await waitFor(() => {
      expect(screen.getByRole("alert")).toHaveTextContent("Failed to load profile");
    });
  });

  it("calls onUpdate when form is submitted", async () => {
    const user = userEvent.setup();
    const onUpdate = vi.fn();
    render(<EditProfileForm initialName="Alice" onUpdate={onUpdate} />);

    await user.clear(screen.getByLabelText(/name/i));
    await user.type(screen.getByLabelText(/name/i), "Alice Smith");
    await user.click(screen.getByRole("button", { name: /save/i }));

    expect(onUpdate).toHaveBeenCalledWith({ name: "Alice Smith" });
  });
});
```

#### MSW (Mock Service Worker) — API Mocking
```ts
// src/mocks/handlers.ts
import { http, HttpResponse } from "msw";

export const handlers = [
  http.get("/api/users/:id", ({ params }) => {
    return HttpResponse.json({ id: params.id, name: "Alice", email: "alice@example.com" });
  }),
  http.post("/api/users", async ({ request }) => {
    const body = await request.json();
    return HttpResponse.json({ id: "new-id", ...body }, { status: 201 });
  }),
];

// src/mocks/server.ts
import { setupServer } from "msw/node";
import { handlers } from "./handlers";
export const server = setupServer(...handlers);

// vitest setup.ts
beforeAll(() => server.listen({ onUnhandledRequest: "error" }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

### Performance Testing

#### k6 (Load Testing)
```js
// k6 load test script — k6 run load-test.js
import http from "k6/http";
import { check, sleep } from "k6";
import { Rate, Trend } from "k6/metrics";

const errorRate = new Rate("errors");
const apiDuration = new Trend("api_duration", true);

export const options = {
  stages: [
    { duration: "2m", target: 50 },    // ramp up to 50 users over 2min
    { duration: "5m", target: 50 },    // stay at 50 users for 5min
    { duration: "2m", target: 200 },   // spike to 200 users
    { duration: "5m", target: 200 },   // sustain spike
    { duration: "2m", target: 0 },     // ramp down
  ],
  thresholds: {
    http_req_duration: ["p(95)<500"],   // 95% of requests < 500ms
    http_req_failed:   ["rate<0.01"],   // error rate < 1%
    errors:            ["rate<0.05"],
  },
};

export default function () {
  const res = http.get("https://api.example.com/users", {
    headers: { Authorization: `Bearer ${__ENV.TOKEN}` },
  });

  const success = check(res, {
    "status is 200":        (r) => r.status === 200,
    "response time < 500ms":(r) => r.timings.duration < 500,
    "body has users":       (r) => JSON.parse(r.body).length > 0,
  });

  errorRate.add(!success);
  apiDuration.add(res.timings.duration);
  sleep(1);
}
```

#### Locust (Python Load Testing)
```python
from locust import HttpUser, task, between

class APIUser(HttpUser):
    wait_time = between(1, 3)
    token = None

    def on_start(self):
        resp = self.client.post("/auth/login", json={"email": "test@example.com", "password": "pw"})
        self.token = resp.json()["accessToken"]
        self.client.headers["Authorization"] = f"Bearer {self.token}"

    @task(3)  # weight: called 3× more than weight-1 tasks
    def list_users(self):
        self.client.get("/users")

    @task(1)
    def create_order(self):
        with self.client.post("/orders", json={"productId": "123", "qty": 1},
                              catch_response=True) as resp:
            if resp.status_code == 201:
                resp.success()
            else:
                resp.failure(f"Unexpected status: {resp.status_code}")

# Run: locust -f locustfile.py --host=https://api.example.com
```

### Contract Testing (Pact)
```ts
// Consumer side — defines what it expects
import { PactV3, MatchersV3 } from "@pact-foundation/pact";
const { like, eachLike } = MatchersV3;

const provider = new PactV3({ consumer: "WebApp", provider: "UserService" });

describe("UserService contract", () => {
  it("returns user profile", async () => {
    await provider
      .uponReceiving("a request for user 123")
      .withRequest({ method: "GET", path: "/users/123" })
      .willRespondWith({
        status: 200,
        body: {
          id: like("123"),
          email: like("alice@example.com"),
          name: like("Alice"),
          createdAt: like("2024-01-01T00:00:00Z"),
        },
      })
      .executeTest(async (mockServer) => {
        const client = new UserClient(mockServer.url);
        const user = await client.getUser("123");
        expect(user.email).toBeTruthy();
      });
  });
});

// Provider side — verifies it honours the contract
// Run: pact-provider-verifier --provider-base-url http://localhost:3000 --pact-broker-url https://pact.example.com
```

### Security Testing
```bash
# OWASP ZAP — automated DAST
docker run -t owasp/zap2docker-stable zap-baseline.py \
  -t https://staging.example.com \
  -r zap-report.html \
  -I   # don't fail on warnings

# Semgrep — SAST (static analysis)
semgrep --config=p/owasp-top-ten src/
semgrep --config=p/typescript src/
semgrep --config=auto src/ --output=semgrep-results.json

# Dependency audit
pnpm audit --audit-level=high
pip-audit --require-hashes
npm audit --json | jq '.vulnerabilities | to_entries[] | select(.value.severity == "critical")'

# Secret scanning
gitleaks detect --source . --exit-code 1
trufflehog git file://. --since-commit HEAD~10
```

### Test Data Management

#### Factories & Fixtures
```ts
// TypeScript — @anatine/zod-mock or custom factory
import { faker } from "@faker-js/faker";

const userFactory = {
  build: (overrides: Partial<User> = {}): User => ({
    id:        faker.string.uuid(),
    email:     faker.internet.email(),
    name:      faker.person.fullName(),
    role:      "viewer",
    createdAt: faker.date.past(),
    ...overrides,
  }),

  buildMany: (count: number, overrides: Partial<User> = {}): User[] =>
    Array.from({ length: count }, () => userFactory.build(overrides)),
};

// Usage
const adminUser = userFactory.build({ role: "admin" });
const users = userFactory.buildMany(10, { role: "viewer" });
```

```python
# Python — factory_boy
import factory
from factory.faker import Faker
from app.models import User

class UserFactory(factory.Factory):
    class Meta:
        model = User

    id    = factory.LazyFunction(lambda: str(uuid.uuid4()))
    email = Faker("email")
    name  = Faker("name")
    role  = "viewer"

    class Params:
        admin = factory.Trait(role="admin")

# Usage
user  = UserFactory()
admin = UserFactory(admin=True)
users = UserFactory.build_batch(10)
```

#### Database Seeding
```ts
// Prisma seed script — prisma/seed.ts
import { PrismaClient } from "@prisma/client";
const db = new PrismaClient();

async function main() {
  await db.user.upsert({
    where: { email: "admin@example.com" },
    update: {},
    create: { email: "admin@example.com", name: "Admin", role: "admin" },
  });
}

main().catch(console.error).finally(() => db.$disconnect());
```

### Test Quality Standards

#### What Makes a Good Test
```
✅ Tests one thing — clear failure message tells you exactly what broke
✅ Descriptive name: "it returns 404 when user not found" not "test user endpoint"
✅ Arrange-Act-Assert structure — readable and consistent
✅ No logic in tests (no if/loops) — tests should be dumb
✅ Tests edge cases: null, empty, max values, concurrent access
✅ Doesn't test implementation details (private methods, internal state)
✅ Fast — unit tests in < 1ms, integration in < 100ms

❌ Testing the framework or language (don't test that Prisma saves to DB)
❌ Shared mutable state between tests — use beforeEach to reset
❌ Time-dependent tests (Date.now()) — inject time or mock it
❌ Magic numbers and strings without explanation
❌ Asserting too much in one test — hard to diagnose failures
```

#### Coverage Strategy
```
Coverage targets (not maximums — quality > quantity):
  Unit tests:        80%+ branches, 90%+ lines on business logic
  Integration tests: 100% of API endpoints (all happy + error paths)
  E2E:               100% of critical user journeys (checkout, signup, login)

What 100% coverage does NOT mean:
  ✗ Zero bugs         (you might test the wrong thing)
  ✗ Good tests        (tests can be trivially wrong)
  ✓ Every code branch was executed at least once

Enforce in CI:
  vitest --coverage --coverage.thresholds.branches=80
  pytest --cov=app --cov-fail-under=80
  mvn jacoco:check  # fail build if below threshold
```

### CI/CD Testing Pipeline
```yaml
# GitHub Actions — full test pipeline
name: Test
on: [push, pull_request]

jobs:
  unit-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: "20", cache: "pnpm" }
      - run: pnpm install --frozen-lockfile
      - run: pnpm test --coverage
      - uses: actions/upload-artifact@v4
        with: { name: coverage, path: coverage/ }

  integration-test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16-alpine
        env: { POSTGRES_DB: test, POSTGRES_PASSWORD: test }
        options: --health-cmd pg_isready
    steps:
      - uses: actions/checkout@v4
      - run: pnpm install --frozen-lockfile
      - run: pnpm db:migrate
        env: { DATABASE_URL: postgresql://postgres:test@localhost/test }
      - run: pnpm test:integration
        env: { DATABASE_URL: postgresql://postgres:test@localhost/test }

  e2e-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: "20", cache: "pnpm" }
      - run: pnpm install --frozen-lockfile
      - run: pnpm exec playwright install --with-deps chromium
      - run: pnpm build && pnpm start &
      - run: pnpm test:e2e
      - uses: actions/upload-artifact@v4
        if: failure()
        with: { name: playwright-report, path: playwright-report/ }
```

### TDD (Test-Driven Development)
```
Red → Green → Refactor cycle:

1. RED:    Write a failing test for the feature you want to add
2. GREEN:  Write the minimum code to make the test pass (no more)
3. REFACTOR: Clean up the code without breaking the tests

TDD benefits:
  - Forces you to design the interface before implementation
  - Ensures every line of code exists because a test requires it
  - Gives you a regression safety net instantly
  - Documentation through tests

When to TDD:
  ✅ Pure business logic functions
  ✅ Algorithm implementations
  ✅ Parser / transformer code
  ✅ Bug fixes (write test that reproduces bug first)

When NOT to TDD:
  ❌ UI layout (test behavior instead)
  ❌ Configuration code
  ❌ When you're still exploring the domain (prototype → test → refactor)
```

### QA Engineer Test Planning

#### Test Plan Structure
```
1. Scope
   - Features under test: [list]
   - Out of scope: [list]
   - Test environments: dev, staging, production smoke

2. Test Types
   - Functional testing: core user flows
   - Regression testing: previously broken areas
   - Exploratory testing: unscripted, experience-based
   - Smoke testing: quick sanity after each deploy
   - Accessibility testing: WCAG AA compliance

3. Entry Criteria (when to start testing)
   - All unit + integration tests pass
   - Build deployed to staging
   - Test data seeded

4. Exit Criteria (when testing is done)
   - All planned test cases executed
   - Zero P1/P2 bugs open
   - P3 bugs triaged and accepted or deferred

5. Risk Assessment
   - High risk: payment flows, auth, data migration
   - Medium risk: new features, changed integrations
   - Low risk: UI tweaks, copy changes

6. Test Schedule
   - Sprint testing: 2 days before release
   - Regression: automated in CI + manual for high-risk areas
   - Hotfix: smoke test only
```

#### Bug Report Template
```markdown
## Summary
[One sentence describing the bug]

## Severity
P1 - Critical (data loss, security breach, system down)
P2 - High (major feature broken, no workaround)
P3 - Medium (feature broken, workaround exists)
P4 - Low (cosmetic, minor inconvenience)

## Steps to Reproduce
1. Navigate to /checkout
2. Add item to cart
3. Click "Proceed to payment"
4. Observe error

## Expected Behavior
Payment form should appear

## Actual Behavior
500 error displayed, console shows "Cannot read property 'id' of undefined"

## Environment
- Browser: Chrome 120 / Firefox 121 / Safari 17
- OS: macOS 14.2
- URL: https://staging.example.com
- User role: registered user (not guest)

## Evidence
[Screenshot / Video / Console log / Network trace]

## Notes
Only reproducible when cart has > 1 item. Guest checkout works fine.
```

#### Exploratory Testing Charter
```
Charter: Explore the [feature/area] to discover [risks/problems]
Time box: 60 minutes
Focus: [specific user scenario or risk area]

What to vary:
  - User roles (admin, editor, viewer, guest)
  - Data conditions (empty, single item, max items, special chars)
  - Device/browser combinations
  - Network conditions (slow, offline, reconnect)
  - Concurrent actions (two users editing same record)
  - Edge timing (session expiry mid-flow, token refresh during submit)

Document: observations, questions, bugs found, areas to revisit
```

### Senior Developer — Testing Checklist
- [ ] New feature has unit tests covering happy path + edge cases + error paths
- [ ] API endpoint has integration test with real DB (not mocked)
- [ ] Critical user flow covered by E2E test
- [ ] No `any` casts in test files — tests should be type-safe too
- [ ] Test names describe behavior: "returns 404 when user not found" not "test404"
- [ ] Mocks reset between tests (`beforeEach(() => vi.clearAllMocks())`)
- [ ] Flaky tests investigated and fixed before merge
- [ ] Coverage thresholds not regressed
- [ ] Performance-sensitive code has benchmark or load test

---

