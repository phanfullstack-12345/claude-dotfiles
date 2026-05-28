---
name: test-gen
description: "Use when generating, writing, or improving tests — includes unit tests, integration tests, E2E tests, or when asked to increase test coverage for existing code"
---

# Test-Gen Skill

## Before Writing Tests

```bash
# Check existing test coverage
pnpm test --coverage
pnpm vitest run --coverage   # Vitest
pytest --cov=src --cov-report=term-missing  # Python

# Find untested files
npx ts-coverage src/ --threshold 80

# Understand what the code does before testing it
# Read the implementation file first — never guess behavior
```

- Write tests that document intent, not just pass.
- Test behavior (what it does), not implementation (how it does it).
- If you can't test it without reading the source, the API is poorly designed.

## Test Naming Convention

```ts
// Pattern: "it [does X] when [condition Y]"
it("returns 404 when user not found")
it("hashes password before saving")
it("throws ConflictError when email already exists")
it("applies 10% discount for orders over $100")
it("sends welcome email after successful registration")
```

## Unit Test Patterns (Vitest / Jest)

```ts
import { describe, it, expect, vi, beforeEach } from "vitest";

describe("calculateDiscount", () => {
  it("applies 10% for orders over $100", () => {
    expect(calculateDiscount(150, "STANDARD")).toBe(15);
  });

  it("returns 0 below the $100 threshold", () => {
    expect(calculateDiscount(80, "STANDARD")).toBe(0);
  });

  it("throws on negative amount", () => {
    expect(() => calculateDiscount(-10, "STANDARD")).toThrow("Amount must be positive");
  });

  // Parameterized — avoid duplication
  it.each([
    [150, "STANDARD", 15],
    [200, "PREMIUM",  40],
    [50,  "STANDARD",  0],
  ])("amount=%i code=%s → discount=%i", (amount, code, expected) => {
    expect(calculateDiscount(amount, code)).toBe(expected);
  });
});

// Mocking dependencies
describe("UserService.create", () => {
  const mockRepo = { save: vi.fn(), findByEmail: vi.fn() };
  const service = new UserService(mockRepo);

  beforeEach(() => vi.clearAllMocks());

  it("hashes password before saving", async () => {
    mockRepo.findByEmail.mockResolvedValue(null);
    mockRepo.save.mockResolvedValue({ id: "1", email: "test@test.com" });

    await service.create({ email: "test@test.com", password: "secret" });

    const saved = mockRepo.save.mock.calls[0][0];
    expect(saved.password).not.toBe("secret");
    expect(saved.password).toMatch(/^\$argon2/);
  });
});
```

## Integration Test Patterns (API)

```ts
import request from "supertest";
import { app } from "../src/app";
import { db } from "../src/db";

describe("POST /api/users", () => {
  beforeEach(async () => {
    await db.user.deleteMany();   // clean slate
  });

  afterAll(() => db.$disconnect());

  it("creates user and returns 201", async () => {
    const res = await request(app)
      .post("/api/users")
      .send({ email: "alice@example.com", password: "Secret123!" })
      .expect(201);

    expect(res.body).toMatchObject({ email: "alice@example.com" });
    expect(res.body.password).toBeUndefined();   // never expose hash
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

## React Component Tests (Testing Library)

```tsx
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

it("submits form with valid data", async () => {
  const user = userEvent.setup();
  const onSubmit = vi.fn();

  render(<LoginForm onSubmit={onSubmit} />);

  await user.type(screen.getByLabelText(/email/i), "user@example.com");
  await user.type(screen.getByLabelText(/password/i), "Secret123!");
  await user.click(screen.getByRole("button", { name: /sign in/i }));

  expect(onSubmit).toHaveBeenCalledWith({
    email: "user@example.com",
    password: "Secret123!",
  });
});

it("shows error on empty submission", async () => {
  const user = userEvent.setup();
  render(<LoginForm onSubmit={vi.fn()} />);

  await user.click(screen.getByRole("button", { name: /sign in/i }));

  expect(screen.getByRole("alert")).toHaveTextContent("Email is required");
});
```

## Python Tests (pytest)

```python
import pytest

class TestCalculateDiscount:
    def test_applies_10_percent_over_100(self):
        assert calculate_discount(150, "STANDARD") == 15.0

    def test_no_discount_below_threshold(self):
        assert calculate_discount(80, "STANDARD") == 0.0

    @pytest.mark.parametrize("amount,code,expected", [
        (150, "STANDARD", 15.0),
        (200, "PREMIUM",  40.0),
    ])
    def test_scenarios(self, amount, code, expected):
        assert calculate_discount(amount, code) == expected

    def test_raises_on_negative_amount(self):
        with pytest.raises(ValueError, match="Amount must be positive"):
            calculate_discount(-10, "STANDARD")
```

## Coverage Targets

| Layer | Target |
|---|---|
| Business logic / services | 85%+ branches |
| API endpoints | 100% (happy + all error paths) |
| Utility functions | 90%+ lines |
| UI components | Key interactions |

```bash
# Enforce in CI
pnpm vitest run --coverage --coverage.thresholds.branches=80
pytest --cov=app --cov-fail-under=80
```

## What NOT to Test

- Framework internals (don't test that Prisma saves to DB)
- Implementation details (private methods, internal state)
- Simple getter/setter properties with no logic
- Third-party library behavior

## Output Format
Report: (1) files tested, (2) coverage before → after, (3) key edge cases covered, (4) any gaps remaining.
