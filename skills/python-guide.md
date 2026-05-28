# Reference: python-guide
# Load this file when working on tasks matching this domain.

## 🐍 Python

### Setup & Tooling
- Python 3.12+ — use type hints everywhere, `match` statements, `tomllib`.
- Package manager: **uv** (preferred) — `uv init`, `uv add`, `uv run`. Fall back to `poetry` if project already uses it.
- Formatter: **Ruff** (`ruff format`) — replaces Black. Linter: `ruff check` (replaces flake8/isort).
- Type checking: **mypy** with `strict = true` in `pyproject.toml`, or **pyright**.
- Virtual envs: always use `uv venv` / `poetry shell` — never install packages globally.
- `pyproject.toml` always (not `setup.py` / `requirements.txt` for new projects).

```toml
# pyproject.toml
[tool.mypy]
strict = true
ignore_missing_imports = true

[tool.ruff]
line-length = 100
target-version = "py312"

[tool.ruff.lint]
select = ["E", "F", "I", "UP", "B", "SIM"]
```

### FastAPI
- Use **FastAPI 0.111+** — async by default.
- Pydantic v2 for all request/response models — never raw dicts at API boundaries.
- Dependency injection via `Depends()` — no global state.
- Router separation: `APIRouter` per domain in `routers/` directory.
- Always set `response_model` on route handlers — prevents data leaks.
- Use `HTTPException` with explicit status codes; add a global exception handler.
- Lifespan events (`@asynccontextmanager`) for startup/shutdown — not deprecated `@app.on_event`.

```python
# Structure
src/
├── main.py           # FastAPI app, lifespan, routers
├── routers/          # One file per domain
├── models/           # Pydantic schemas
├── services/         # Business logic
├── repositories/     # DB access layer
└── dependencies.py   # Shared Depends()
```

```python
# ✅ Correct FastAPI pattern
from contextlib import asynccontextmanager
from fastapi import FastAPI, Depends, HTTPException
from pydantic import BaseModel

@asynccontextmanager
async def lifespan(app: FastAPI):
    await db.connect()
    yield
    await db.disconnect()

app = FastAPI(lifespan=lifespan)

class UserResponse(BaseModel):
    id: int
    email: str

@app.get("/users/{user_id}", response_model=UserResponse)
async def get_user(user_id: int, db: AsyncSession = Depends(get_db)):
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user
```

### Pydantic v2
- All models inherit from `BaseModel`.
- Use `model_validator`, `field_validator` over deprecated `@validator`.
- `model_config = ConfigDict(...)` over inner `Config` class.
- `Field(...)` for constraints, aliases, descriptions.
- Serialize with `.model_dump()` not `.dict()` (deprecated).

```python
from pydantic import BaseModel, Field, model_validator, ConfigDict

class CreateUser(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)
    email: str = Field(..., pattern=r"^[^@]+@[^@]+\.[^@]+$")
    age: int = Field(..., ge=0, le=150)

    @model_validator(mode="after")
    def check_email_domain(self) -> "CreateUser":
        if self.email.endswith("@blocked.com"):
            raise ValueError("Blocked email domain")
        return self
```

### Async Patterns
- `async def` for all I/O: DB queries, HTTP calls, file reads.
- `asyncio.gather()` for parallel coroutines — never sequential `await` when independent.
- Use `httpx.AsyncClient` — not `requests` in async code.
- Database: **SQLAlchemy 2.0 async** (`AsyncSession`) or **asyncpg** for raw queries.
- Background tasks: FastAPI `BackgroundTasks` for simple jobs; Celery/ARQ for heavy lifting.

### Testing (Python)
- **pytest** + **pytest-asyncio** for async tests.
- `httpx.AsyncClient` with `ASGITransport` for FastAPI integration tests.
- **factory-boy** or Pydantic factories for test fixtures.
- `pytest-cov` for coverage; aim for 80%+ on service layer.
- Use `pytest.mark.parametrize` to avoid test duplication.

```python
# FastAPI integration test
import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app

@pytest.mark.asyncio
async def test_get_user():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/users/1")
    assert response.status_code == 200
```

### Code Quality
- No bare `except:` — always catch specific exceptions.
- Context managers (`with`, `async with`) for resource management.
- Dataclasses or Pydantic for data containers — no plain dicts for structured data.
- `pathlib.Path` over `os.path` for file operations.
- `logging` module over `print` — use structured logging (structlog or python-json-logger).
- `__all__` in public modules to control exports.

---

## 🐍 Python — Advanced Patterns

### OOP Deep Dive

#### Dataclasses & attrs
```python
from dataclasses import dataclass, field
from typing import ClassVar

@dataclass(frozen=True, order=True)   # immutable + comparable
class Money:
    amount: float
    currency: str = "USD"
    _registry: ClassVar[dict] = {}    # class variable, not instance field

    def __post_init__(self):
        if self.amount < 0:
            raise ValueError("Amount cannot be negative")

    def __add__(self, other: "Money") -> "Money":
        if self.currency != other.currency:
            raise ValueError("Currency mismatch")
        return Money(self.amount + other.amount, self.currency)
```

#### Protocols (Structural Typing — Prefer over ABC)
```python
from typing import Protocol, runtime_checkable

@runtime_checkable
class Serializable(Protocol):
    def to_dict(self) -> dict: ...
    def to_json(self) -> str: ...

class Saveable(Protocol):
    def save(self, path: str) -> None: ...

# Any class implementing these methods satisfies the protocol — no inheritance needed
def persist(obj: Serializable & Saveable, path: str) -> None:
    obj.save(path)
    log(obj.to_json())
```

#### Descriptors (How properties work internally)
```python
class ValidatedField:
    def __set_name__(self, owner, name):
        self.name = f"_{name}"

    def __get__(self, obj, objtype=None):
        if obj is None: return self
        return getattr(obj, self.name, None)

    def __set__(self, obj, value):
        if not isinstance(value, (int, float)) or value < 0:
            raise ValueError(f"{self.name}: must be non-negative number")
        setattr(obj, self.name, value)

class Product:
    price = ValidatedField()
    stock = ValidatedField()
```

#### Metaclasses (Use sparingly — for framework code)
```python
class SingletonMeta(type):
    _instances: dict = {}
    def __call__(cls, *args, **kwargs):
        if cls not in cls._instances:
            cls._instances[cls] = super().__call__(*args, **kwargs)
        return cls._instances[cls]

class Database(metaclass=SingletonMeta):
    def __init__(self): self.connection = connect()
```

### Functional Patterns

#### Generators & Itertools
```python
import itertools

# Generator — lazy, memory-efficient
def read_large_csv(path: str):
    with open(path) as f:
        for line in f:
            yield parse_line(line)   # process one at a time, never loads all

# Generator expression
squares = (x**2 for x in range(1_000_000))  # vs list: uses ~8 bytes, not ~8MB

# itertools recipes
first_ten = list(itertools.islice(read_large_csv("huge.csv"), 10))
grouped = itertools.groupby(sorted(data, key=lambda x: x["dept"]), key=lambda x: x["dept"])
pairs = list(itertools.combinations(items, 2))
product = list(itertools.product(sizes, colors))   # cartesian product

# Chaining
from itertools import chain
all_items = list(chain(list1, list2, list3))
```

#### Decorators
```python
import functools
import time
from typing import Callable, TypeVar, ParamSpec

P = ParamSpec("P")
R = TypeVar("R")

def retry(max_attempts: int = 3, delay: float = 1.0):
    def decorator(func: Callable[P, R]) -> Callable[P, R]:
        @functools.wraps(func)  # preserve docstring, name, type hints
        def wrapper(*args: P.args, **kwargs: P.kwargs) -> R:
            for attempt in range(max_attempts):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    if attempt == max_attempts - 1: raise
                    time.sleep(delay * 2**attempt)  # exponential backoff
        return wrapper
    return decorator

def cache_result(ttl_seconds: int = 300):
    """TTL-based cache decorator"""
    cache: dict = {}
    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args):
            key = args
            if key in cache:
                result, ts = cache[key]
                if time.time() - ts < ttl_seconds:
                    return result
            result = func(*args)
            cache[key] = (result, time.time())
            return result
        return wrapper
    return decorator

@retry(max_attempts=3, delay=0.5)
@cache_result(ttl_seconds=60)
async def fetch_user(user_id: int) -> User: ...
```

#### Context Managers
```python
from contextlib import contextmanager, asynccontextmanager
import contextlib

@contextmanager
def timer(label: str):
    start = time.perf_counter()
    try:
        yield
    finally:
        elapsed = time.perf_counter() - start
        print(f"{label}: {elapsed:.3f}s")

with timer("database query"):
    results = db.query(...)

# Suppress specific exceptions
with contextlib.suppress(FileNotFoundError):
    os.remove("temp.txt")

# Multiple context managers
with contextlib.ExitStack() as stack:
    files = [stack.enter_context(open(f)) for f in file_list]
```

### Concurrency

#### asyncio Deep Dive
```python
import asyncio

# Parallel tasks — don't use sequential await for independent work
async def fetch_dashboard(user_id: int):
    # ❌ Sequential — slow
    profile = await get_profile(user_id)
    orders  = await get_orders(user_id)
    stats   = await get_stats(user_id)

    # ✅ Parallel — fast
    profile, orders, stats = await asyncio.gather(
        get_profile(user_id),
        get_orders(user_id),
        get_stats(user_id),
    )

# Timeout
async def call_with_timeout():
    try:
        result = await asyncio.wait_for(slow_operation(), timeout=5.0)
    except asyncio.TimeoutError:
        return default_value

# Task groups (Python 3.11+)
async def process_batch(items: list):
    async with asyncio.TaskGroup() as tg:
        tasks = [tg.create_task(process(item)) for item in items]
    # All tasks complete here — exceptions propagate cleanly

# Semaphore for concurrency limiting
sem = asyncio.Semaphore(10)  # max 10 concurrent DB connections

async def limited_query(id: int):
    async with sem:
        return await db.fetch(id)
```

#### Threading & Multiprocessing
```python
from concurrent.futures import ThreadPoolExecutor, ProcessPoolExecutor, as_completed

# ThreadPoolExecutor — I/O bound (network, file, DB)
with ThreadPoolExecutor(max_workers=20) as executor:
    futures = {executor.submit(fetch_url, url): url for url in urls}
    for future in as_completed(futures):
        url = futures[future]
        try:
            data = future.result(timeout=10)
        except Exception as e:
            log.error(f"Failed {url}: {e}")

# ProcessPoolExecutor — CPU bound (image processing, ML, compression)
with ProcessPoolExecutor(max_workers=os.cpu_count()) as executor:
    results = list(executor.map(compress_image, image_paths))

# asyncio + executor for blocking code in async context
async def run_blocking():
    loop = asyncio.get_event_loop()
    result = await loop.run_in_executor(None, blocking_function, arg)
```

### Advanced Type Hints
```python
from typing import TypeVar, Generic, Literal, TypeAlias, Never, overload

T = TypeVar("T")
E = TypeVar("E", bound=Exception)

# Generic classes
class Result(Generic[T, E]):
    def __init__(self, value: T | None, error: E | None): ...
    def unwrap(self) -> T: ...

# TypeAlias
UserId: TypeAlias = int
JsonDict: TypeAlias = dict[str, "JsonValue"]
JsonValue: TypeAlias = str | int | float | bool | None | list["JsonValue"] | JsonDict

# Literal types
def set_direction(dir: Literal["left", "right", "up", "down"]) -> None: ...

# Overload for multiple signatures
@overload
def parse(data: str) -> dict: ...
@overload
def parse(data: bytes) -> dict: ...
def parse(data: str | bytes) -> dict:
    return json.loads(data)

# ParamSpec + Concatenate for decorator typing
from typing import ParamSpec, Concatenate
P = ParamSpec("P")
def inject_db(func: Callable[Concatenate[Session, P], T]) -> Callable[P, T]: ...
```

### Performance & Profiling
```python
# cProfile — find slow functions
python -m cProfile -s cumulative -o profile.out script.py
python -m pstats profile.out
# → sort cumulative, stats 20

# line_profiler — line-by-line timing
# pip install line_profiler
@profile  # decorator
def slow_function():
    ...
kernprof -l -v script.py

# memory_profiler — memory per line
from memory_profiler import profile
@profile
def memory_heavy():
    big_list = [i for i in range(1_000_000)]

# timeit — micro-benchmarks
import timeit
timeit.timeit("'-'.join(str(n) for n in range(100))", number=10_000)

# Optimization techniques
# 1. Local variable lookup is faster than global/attribute
# 2. list comprehension > for loop > map(lambda)
# 3. Slots reduce memory for many small objects
class Point:
    __slots__ = ("x", "y")   # no __dict__ — 40% less memory
    def __init__(self, x, y): self.x, self.y = x, y

# 4. numpy for numeric arrays — 100x faster than pure Python lists
import numpy as np
arr = np.array(data)
result = arr * 2 + np.sin(arr)   # vectorized, no Python loop
```

### CLI Development
```python
# Typer — FastAPI-style CLI (recommended)
import typer
from typing import Annotated

app = typer.Typer()

@app.command()
def deploy(
    env: Annotated[str, typer.Argument(help="Target environment")],
    dry_run: Annotated[bool, typer.Option("--dry-run")] = False,
    version: Annotated[str, typer.Option(help="Version tag")] = "latest",
):
    """Deploy the application to the target environment."""
    typer.echo(f"Deploying {version} to {env}" + (" (dry run)" if dry_run else ""))

@app.command()
def rollback(env: str, steps: int = 1): ...

if __name__ == "__main__":
    app()

# Rich — beautiful terminal output
from rich.console import Console
from rich.table import Table
from rich.progress import track

console = Console()
console.print("[bold green]✓[/] Deployment complete")

table = Table(title="Services")
table.add_column("Name"); table.add_column("Status", style="green")
for svc in services:
    table.add_row(svc.name, svc.status)
console.print(table)

for item in track(items, description="Processing..."):
    process(item)
```

### Standard Library Essentials
```python
from pathlib import Path          # file paths (not os.path)
from collections import defaultdict, Counter, deque, namedtuple
from functools import lru_cache, partial, reduce
from itertools import chain, islice, groupby, combinations
import json, csv, re, hashlib
from datetime import datetime, date, timedelta, timezone

# pathlib
p = Path("src") / "app" / "main.py"
p.exists(), p.is_file(), p.suffix   # .py
p.read_text(), p.write_text("code")
list(Path(".").glob("**/*.py"))

# collections
word_count = Counter("hello world".split())  # Counter({'hello': 1, 'world': 1})
graph = defaultdict(list)
graph["a"].append("b")  # no KeyError
q = deque(maxlen=100)   # O(1) appendleft/popleft, circular buffer

# lru_cache
@lru_cache(maxsize=128)
def fibonacci(n: int) -> int:
    return n if n < 2 else fibonacci(n-1) + fibonacci(n-2)

# datetime with timezone (always use UTC internally)
now = datetime.now(tz=timezone.utc)
formatted = now.strftime("%Y-%m-%dT%H:%M:%SZ")
parsed = datetime.fromisoformat("2024-01-15T10:30:00+00:00")
```

---

