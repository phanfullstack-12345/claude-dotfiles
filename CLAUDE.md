# ~/.claude/CLAUDE.md — Global Claude Code Instructions

Personal global config. Applies to every project.
Project-level `CLAUDE.md` files override specific sections.

---

## 🧠 General Behavior

- Read relevant files before making changes — never assume contents.
- Prefer editing existing files over creating new ones.
- After every task, give a short summary: what changed and why.
- Ask for clarification when requirements are ambiguous — don't guess.
- Never delete files, folders, or records without explicit confirmation.
- Outline multi-step plans before executing — wait for approval on destructive ops.
- Keep responses focused — don't over-explain unless asked.

---

## 🌐 Web Development — React.js

### Setup & Tooling
- Use **Vite** for new projects; **Next.js 14+ (App Router)** for SSR/SSG/full-stack.
- TypeScript by default — `strict: true` in `tsconfig.json`.
- Package manager: `pnpm` preferred; lock file always committed.
- Linting: ESLint + `eslint-config-airbnb-typescript`; formatting: Prettier.
- Run `pnpm lint && tsc --noEmit` before finishing any task.

### Component Rules
- Functional components only — no class components.
- `const` arrow functions for components: `const MyComponent = () => {}`.
- Co-locate styles, tests, and types with the component file.
- Split at ~200 lines; extract sub-components rather than growing large files.
- Use `React.memo` and `useMemo`/`useCallback` only when profiling shows need.

### State Management
- Local state: `useState` / `useReducer`.
- Server state: **TanStack Query (React Query)** — no manual fetch in `useEffect`.
- Global client state: **Zustand** (preferred) or **Jotai**.
- Avoid Redux unless existing project uses it.

### Routing (Next.js App Router)
- Use Server Components by default; add `"use client"` only when needed.
- Collocate `loading.tsx`, `error.tsx`, `not-found.tsx` per route segment.
- API routes go in `app/api/` using Route Handlers.

### Performance
- Core Web Vitals targets: LCP < 2.5s, CLS < 0.1, INP < 200ms.
- Lazy-load below-the-fold components with `React.lazy` + `Suspense`.
- Images: always use `next/image` or set explicit width/height.
- Bundle-split by route automatically (Next.js) or manually with dynamic imports.

---

## ⚡ Next.js (App Router — 14+)

### Project Setup
- Bootstrap with: `pnpm create next-app@latest --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"`.
- `strict: true` in `tsconfig.json` always.
- Environment variables: public vars prefixed `NEXT_PUBLIC_`; server-only vars never prefixed.
- Store secrets in `.env.local` (gitignored); document all keys in `.env.example`.
- Absolute imports via `@/` alias — never use deep relative paths (`../../../`).

### App Router Structure
```
src/
├── app/
│   ├── (marketing)/          # Route group — no URL segment
│   │   ├── page.tsx
│   │   └── layout.tsx
│   ├── (dashboard)/
│   │   ├── layout.tsx        # Shared dashboard shell
│   │   └── settings/
│   │       ├── page.tsx
│   │       ├── loading.tsx   # Streaming skeleton
│   │       ├── error.tsx     # Error boundary
│   │       └── not-found.tsx
│   ├── api/
│   │   └── [...route]/
│   │       └── route.ts      # Route Handler
│   ├── layout.tsx            # Root layout (html + body)
│   └── globals.css
├── components/
│   ├── ui/                   # Primitive components (Button, Input…)
│   └── features/             # Domain-specific components
├── lib/                      # Utilities, clients, helpers
├── hooks/                    # Custom React hooks
├── actions/                  # Server Actions
└── types/                    # Shared TypeScript types
```

### Server vs Client Components
- **Default to Server Components** — they render on the server, reduce JS bundle, can access DB directly.
- Add `"use client"` only when you need: `useState`, `useEffect`, browser APIs, event listeners, or third-party client libs.
- Never mark a component `"use client"` just to make it "work" — diagnose why it fails as a Server Component first.
- Push `"use client"` boundary as far down the tree as possible (leaf components).
- Server Components can import Client Components; Client Components **cannot** import Server Components.
- Pass server data as props into Client Components — don't re-fetch on client what you already have on server.

```tsx
// ✅ Server Component — fetch directly, no useEffect
export default async function UserProfile({ id }: { id: string }) {
  const user = await db.user.findUnique({ where: { id } }); // direct DB call
  return <ProfileCard user={user} />;
}

// ✅ Client Component — only for interactivity
"use client";
export function LikeButton({ postId }: { postId: string }) {
  const [liked, setLiked] = useState(false);
  return <button onClick={() => setLiked(true)}>{liked ? "❤️" : "🤍"}</button>;
}
```

### Data Fetching
- Server Components: `async/await` directly — no `useEffect`, no `fetch` wrapper needed.
- Use `fetch()` with Next.js cache options for HTTP data sources:
  ```ts
  // Static (cached indefinitely)
  fetch(url, { cache: "force-cache" });
  // Dynamic (never cached)
  fetch(url, { cache: "no-store" });
  // Revalidate every N seconds (ISR)
  fetch(url, { next: { revalidate: 60 } });
  ```
- ORM/DB calls (Prisma, Drizzle): no `fetch` needed — call directly in Server Components.
- Client-side fetching: **TanStack Query** — never raw `useEffect` + `fetch`.
- Parallel fetching: `Promise.all([fetchA(), fetchB()])` to avoid waterfall.
- Deduplication: Next.js dedupes identical `fetch()` calls in the same render tree automatically.

### Server Actions
- Use Server Actions for form submissions and mutations — no API route needed for simple cases.
- Define in `actions/` directory with `"use server"` at top of file.
- Validate input with **Zod** before any DB operation.
- Return typed results: `{ success: true, data }` or `{ success: false, error: string }`.
- Use `revalidatePath()` or `revalidateTag()` after mutations to invalidate cache.

```ts
// actions/create-post.ts
"use server";
import { z } from "zod";
import { revalidatePath } from "next/cache";

const schema = z.object({ title: z.string().min(1), body: z.string().min(10) });

export async function createPost(formData: FormData) {
  const parsed = schema.safeParse(Object.fromEntries(formData));
  if (!parsed.success) return { success: false, error: parsed.error.flatten() };
  await db.post.create({ data: parsed.data });
  revalidatePath("/posts");
  return { success: true };
}
```

### Rendering Strategies
| Strategy | When to use | How |
|---|---|---|
| **SSG** (Static) | Marketing pages, blogs, docs | `fetch` with `force-cache`; no dynamic params |
| **ISR** (Incremental Static) | Content that changes occasionally | `next: { revalidate: N }` |
| **SSR** (Dynamic) | User-specific, real-time data | `cache: "no-store"` or `cookies()`/`headers()` in component |
| **CSR** (Client) | Highly interactive, user-only UI | `"use client"` + TanStack Query |

- Force dynamic rendering: export `export const dynamic = "force-dynamic"` from the page.
- Force static: export `export const dynamic = "force-static"`.
- Generate static params for dynamic routes: `export async function generateStaticParams()`.

### Route Handlers (API Routes)
- File: `app/api/<path>/route.ts` — export named functions `GET`, `POST`, `PUT`, `DELETE`, `PATCH`.
- Always validate request body with Zod.
- Return `NextResponse.json()` with explicit status codes.
- Protect with middleware or auth check at the top of the handler.

```ts
// app/api/posts/route.ts
import { NextRequest, NextResponse } from "next/server";

export async function GET(req: NextRequest) {
  const { searchParams } = req.nextUrl;
  const page = Number(searchParams.get("page") ?? 1);
  const posts = await db.post.findMany({ skip: (page - 1) * 10, take: 10 });
  return NextResponse.json({ posts });
}

export async function POST(req: NextRequest) {
  const body = await req.json();
  const parsed = createPostSchema.safeParse(body);
  if (!parsed.success) return NextResponse.json({ error: parsed.error }, { status: 400 });
  const post = await db.post.create({ data: parsed.data });
  return NextResponse.json({ post }, { status: 201 });
}
```

### Middleware
- File: `middleware.ts` at project root (next to `src/`).
- Use for: auth redirects, locale detection, A/B testing, request logging.
- Keep middleware **fast and lightweight** — it runs on every matched request on the Edge.
- Use `matcher` config to limit which routes middleware runs on.
- Never do heavy DB calls in middleware — use JWT/session cookies instead.

```ts
// middleware.ts
import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

export function middleware(request: NextRequest) {
  const token = request.cookies.get("session")?.value;
  if (!token && request.nextUrl.pathname.startsWith("/dashboard")) {
    return NextResponse.redirect(new URL("/login", request.url));
  }
  return NextResponse.next();
}

export const config = {
  matcher: ["/dashboard/:path*", "/api/protected/:path*"],
};
```

### Authentication
- Use **NextAuth.js v5 (Auth.js)** for most projects — supports credentials, OAuth, magic links.
- Session strategy: JWT for stateless (Edge-compatible); database sessions for richer session data.
- Protect pages: check session in Server Components or use middleware redirect.
- Never expose session tokens in client-side logs or error messages.

### Metadata & SEO
- Define metadata per route using the `metadata` export or `generateMetadata` async function.
- Root layout sets default metadata; pages override with specific titles/descriptions.
- Use `robots.ts` and `sitemap.ts` in `app/` for dynamic robots.txt and sitemap.xml.

```ts
// app/blog/[slug]/page.tsx
export async function generateMetadata({ params }: { params: { slug: string } }) {
  const post = await getPost(params.slug);
  return {
    title: post.title,
    description: post.excerpt,
    openGraph: { title: post.title, images: [post.coverImage] },
  };
}
```

### Images & Fonts
- Always use `next/image` — never raw `<img>` tags.
- Set `width` and `height` or use `fill` + a sized parent to prevent CLS.
- Use `priority` on above-the-fold hero images.
- Fonts: use `next/font` (Google Fonts or local) — zero layout shift, self-hosted automatically.

```ts
// app/layout.tsx
import { Inter, Playfair_Display } from "next/font/google";
const inter = Inter({ subsets: ["latin"], variable: "--font-inter" });
const playfair = Playfair_Display({ subsets: ["latin"], variable: "--font-playfair" });
```

### Error Handling
- `error.tsx`: catches runtime errors in a route segment — must be `"use client"`.
- `global-error.tsx` in app root: catches errors in root layout.
- `not-found.tsx`: rendered by `notFound()` call or unmatched routes.
- Always log errors server-side (Sentry, console.error) before returning error UI.

### Performance Checklist
- [ ] Server Components used by default; `"use client"` boundary pushed to leaves
- [ ] No `useEffect` for data that can be fetched on server
- [ ] `next/image` on all images with `width`/`height` or `fill`
- [ ] `next/font` for all custom fonts
- [ ] Dynamic imports for heavy client components: `dynamic(() => import("./HeavyChart"))`
- [ ] `loading.tsx` on slow data-fetching routes for streaming skeletons
- [ ] Parallel data fetching with `Promise.all` — no sequential awaits
- [ ] Bundle analyzed: `ANALYZE=true pnpm build` with `@next/bundle-analyzer`

### Deployment
- **Vercel**: zero-config, optimal — just `vercel deploy`. Set env vars in Vercel dashboard.
- **Docker** (self-hosted / K8s):
  ```dockerfile
  FROM node:20-alpine AS builder
  WORKDIR /app
  COPY package*.json ./
  RUN npm ci
  COPY . .
  RUN npm run build

  FROM node:20-alpine AS runner
  WORKDIR /app
  ENV NODE_ENV=production
  COPY --from=builder /app/.next/standalone ./
  COPY --from=builder /app/.next/static ./.next/static
  COPY --from=builder /app/public ./public
  USER node
  EXPOSE 3000
  CMD ["node", "server.js"]
  ```
  Requires `output: "standalone"` in `next.config.ts`.
- **Static export** (no server): `output: "export"` in `next.config.ts` — no SSR, no API routes, no middleware.

### next.config.ts Essentials
```ts
import type { NextConfig } from "next";

const config: NextConfig = {
  output: "standalone",           // for Docker deployments
  images: {
    remotePatterns: [{ hostname: "cdn.example.com" }],
  },
  experimental: {
    typedRoutes: true,            // type-safe Link href
  },
  headers: async () => [          // security headers
    {
      source: "/(.*)",
      headers: [
        { key: "X-Frame-Options", value: "DENY" },
        { key: "X-Content-Type-Options", value: "nosniff" },
        { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
      ],
    },
  ],
};

export default config;
```

---

## 📱 Mobile Development — React Native

### Setup
- Use **Expo** (managed workflow) for new projects; bare workflow only if native modules require it.
- TypeScript by default.
- Navigation: **React Navigation v6+** (stack, tab, drawer).
- State: same as React.js — TanStack Query + Zustand.

### Platform Handling
- Use `Platform.OS` for platform-specific logic; prefer `Platform.select()` over inline ternaries.
- Create platform files when logic diverges significantly: `Component.ios.tsx` / `Component.android.tsx`.
- Test on both iOS simulator and Android emulator before marking done.

### Performance
- Use `FlatList` / `FlashList` — never `ScrollView` for long lists.
- Avoid anonymous functions in render — memoize callbacks.
- Use `react-native-reanimated` for 60fps animations.
- Profile with Flipper or React DevTools profiler.

### Native & Device
- Permissions: request at point-of-need, not on app launch.
- Deep linking: configure in `app.json` (Expo) and test on device.
- Push notifications: **Expo Notifications** or **Firebase Cloud Messaging**.
- Storage: `expo-secure-store` for sensitive data; `AsyncStorage` for preferences.

### Build & Release
- EAS Build for cloud builds: `eas build --platform all`.
- OTA updates via EAS Update for JS-only changes.
- Version bump: `app.json` `version` + `android.versionCode` + `ios.buildNumber`.

---

## 🐘 PHP & Laravel

### Standards
- PHP 8.2+ — use typed properties, enums, readonly classes, named arguments.
- PSR-12 coding standard; enforce with PHP CS Fixer.
- Static analysis: PHPStan level 8+ or Psalm.
- Autoloading: Composer PSR-4 only.

### Laravel Conventions
- Follow Laravel conventions — don't fight the framework.
- Fat models, thin controllers; business logic in Service or Action classes.
- Form Requests for all validation — never validate in controllers directly.
- Use Eloquent relationships; avoid raw queries unless performance-critical.
- Events + Listeners for side effects (emails, notifications, logs).
- Jobs + Queues for anything async or slow (emails, webhooks, imports).
- Use `php artisan make:*` — don't create files manually.
- Always run `php artisan migrate --pretend` before running migrations in production.

### Laravel Security
- Never expose `.env` — use `config()` helpers, never `env()` outside config files.
- Mass assignment: always define `$fillable` or `$guarded` on models.
- Authorization: Gates and Policies — never raw role checks in controllers.
- Sanctum for SPA/mobile auth; Passport for OAuth server.
- CSRF protection enabled on all web routes.

### Testing (Laravel)
- Feature tests for API endpoints; unit tests for services and helpers.
- Use `RefreshDatabase` trait; factories for all seedable models.
- Test file naming mirrors app structure: `app/Services/PaymentService` → `tests/Unit/Services/PaymentServiceTest`.

---

## 🦅 NestJS

### Setup & Tooling
- NestJS 10+ with TypeScript strict mode — always.
- Bootstrap: `pnpm add -g @nestjs/cli && nest new project-name`.
- Package manager: `pnpm` preferred.
- Linting: ESLint with `@nestjs/eslint-config`; formatting: Prettier.
- Run `pnpm lint && tsc --noEmit` before finishing any task.

### Project Structure
```
src/
├── app.module.ts              # Root module
├── main.ts                    # Bootstrap (pipes, guards, interceptors global setup)
├── common/
│   ├── decorators/            # Custom decorators
│   ├── filters/               # Exception filters
│   ├── guards/                # Auth guards
│   ├── interceptors/          # Logging, transform interceptors
│   └── pipes/                 # Validation pipes
├── config/                    # ConfigModule setup
└── modules/
    └── users/
        ├── users.module.ts
        ├── users.controller.ts
        ├── users.service.ts
        ├── users.repository.ts   # optional — data access
        ├── dto/
        │   ├── create-user.dto.ts
        │   └── update-user.dto.ts
        └── entities/
            └── user.entity.ts
```

### Core Principles
- **One module per domain** — `UsersModule`, `AuthModule`, `OrdersModule`.
- Controllers thin — delegate all logic to Services.
- Services handle business logic; Repositories handle data access.
- DTOs for all request/response — never expose entities directly.
- Use `@nestjs/config` (`ConfigModule`) for all env vars — never `process.env` inline.
- Register `ValidationPipe` globally in `main.ts`:

```ts
// main.ts
async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,        // strip unknown properties
      forbidNonWhitelisted: true,
      transform: true,        // auto-transform payloads to DTO classes
    }),
  );
  app.useGlobalFilters(new HttpExceptionFilter());
  app.setGlobalPrefix("api/v1");
  await app.listen(3000);
}
```

### Controllers
```ts
@Controller("users")
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  findAll(@Query() query: PaginationDto): Promise<User[]> {
    return this.usersService.findAll(query);
  }

  @Get(":id")
  findOne(@Param("id", ParseIntPipe) id: number): Promise<User> {
    return this.usersService.findOneOrFail(id);
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  create(@Body() dto: CreateUserDto): Promise<User> {
    return this.usersService.create(dto);
  }

  @Patch(":id")
  update(@Param("id", ParseIntPipe) id: number, @Body() dto: UpdateUserDto) {
    return this.usersService.update(id, dto);
  }

  @Delete(":id")
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(@Param("id", ParseIntPipe) id: number) {
    return this.usersService.remove(id);
  }
}
```

### DTOs & Validation
- Use `class-validator` + `class-transformer` — always.
- `@IsString()`, `@IsEmail()`, `@IsInt()`, `@Min()`, `@Max()`, `@IsOptional()`, etc.
- `PartialType(CreateDto)` for update DTOs — DRY.
- `PickType`, `OmitType`, `IntersectionType` for DTO composition.

```ts
// create-user.dto.ts
import { IsEmail, IsString, MinLength, IsEnum } from "class-validator";

export class CreateUserDto {
  @IsEmail()
  email: string;

  @IsString()
  @MinLength(8)
  password: string;

  @IsEnum(Role)
  role: Role;
}

// update-user.dto.ts
import { PartialType } from "@nestjs/mapped-types";
export class UpdateUserDto extends PartialType(CreateUserDto) {}
```

### Services & Exception Handling
```ts
@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User) private readonly usersRepo: Repository<User>,
  ) {}

  async findOneOrFail(id: number): Promise<User> {
    const user = await this.usersRepo.findOne({ where: { id } });
    if (!user) throw new NotFoundException(`User ${id} not found`);
    return user;
  }

  async create(dto: CreateUserDto): Promise<User> {
    const existing = await this.usersRepo.findOne({ where: { email: dto.email } });
    if (existing) throw new ConflictException("Email already in use");
    const user = this.usersRepo.create(dto);
    return this.usersRepo.save(user);
  }
}
```

### Guards, Interceptors, Pipes
- **Guards** (`@UseGuards`): auth, roles, rate limiting — return `true`/`false`.
- **Interceptors** (`@UseInterceptors`): transform response, logging, caching.
- **Pipes** (`@UsePipes`): validate and transform input.
- **Filters** (`@UseFilters`): catch exceptions and return structured error responses.
- Register globally in `main.ts` or module-level — prefer global for consistency.

```ts
// roles.guard.ts
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<Role[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (!requiredRoles) return true;
    const { user } = context.switchToHttp().getRequest();
    return requiredRoles.some(role => user.roles.includes(role));
  }
}
```

### Authentication (JWT + Passport)
- `@nestjs/passport` + `passport-jwt` + `@nestjs/jwt`.
- `JwtStrategy` validates token; `JwtAuthGuard` protects routes.
- Store `userId` and `roles` in JWT payload — minimal, no sensitive data.
- Refresh tokens: store hashed in DB; rotate on use.

```ts
// jwt.strategy.ts
@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(config: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      secretOrKey: config.getOrThrow<string>("JWT_SECRET"),
    });
  }

  validate(payload: JwtPayload) {
    return { userId: payload.sub, email: payload.email, roles: payload.roles };
  }
}
```

### Database — TypeORM
- Use `@nestjs/typeorm` with `TypeOrmModule.forRootAsync()` + `ConfigService`.
- Entities in `entities/` per module — `@Entity()`, `@Column()`, `@OneToMany()`, etc.
- Migrations always — never `synchronize: true` in production.
- Repository pattern: inject with `@InjectRepository(Entity)`.

```ts
// TypeORM async config
TypeOrmModule.forRootAsync({
  imports: [ConfigModule],
  useFactory: (config: ConfigService) => ({
    type: "postgres",
    host: config.getOrThrow("DB_HOST"),
    port: config.getOrThrow<number>("DB_PORT"),
    database: config.getOrThrow("DB_NAME"),
    username: config.getOrThrow("DB_USER"),
    password: config.getOrThrow("DB_PASSWORD"),
    entities: [__dirname + "/**/*.entity{.ts,.js}"],
    migrations: [__dirname + "/migrations/*{.ts,.js}"],
    synchronize: false,   // NEVER true in production
    logging: config.get("NODE_ENV") === "development",
  }),
  inject: [ConfigService],
}),
```

### Configuration
```ts
// config/database.config.ts
export default registerAs("database", () => ({
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT ?? "5432", 10),
}));

// Access anywhere
constructor(
  @Inject(databaseConfig.KEY)
  private dbConfig: ConfigType<typeof databaseConfig>,
) {}
```

### Testing (NestJS)
- Unit tests: `Test.createTestingModule()` with mocked providers.
- E2E tests: `@nestjs/testing` + `supertest` — spin up real app.
- Mock services with `jest.fn()` — never mock the database in unit tests.
- Test file naming: `users.service.spec.ts`, `users.e2e-spec.ts`.

```ts
// Unit test — service
describe("UsersService", () => {
  let service: UsersService;
  let repo: jest.Mocked<Repository<User>>;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      providers: [
        UsersService,
        { provide: getRepositoryToken(User), useValue: { findOne: jest.fn(), save: jest.fn() } },
      ],
    }).compile();
    service = module.get(UsersService);
    repo = module.get(getRepositoryToken(User));
  });

  it("throws NotFoundException when user not found", async () => {
    repo.findOne.mockResolvedValue(null);
    await expect(service.findOneOrFail(99)).rejects.toThrow(NotFoundException);
  });
});
```

### Performance & Best Practices
- Use `@nestjs/throttler` for rate limiting on public endpoints.
- `@nestjs/cache-manager` for response caching (Redis in production).
- Interceptors for response serialization (`ClassSerializerInterceptor`) — hide passwords, internal fields with `@Exclude()`.
- Swagger: `@nestjs/swagger` — `@ApiProperty()` on all DTO fields, auto-generated docs at `/api/docs`.
- Health checks: `@nestjs/terminus` — expose `/health` endpoint.

---

## 🌿 Drupal

### Standards
- Drupal 10+ with Composer-managed dependencies.
- Follow Drupal coding standards (use `phpcs --standard=Drupal`).
- Custom code goes in custom modules under `web/modules/custom/` — never patch core or contrib.
- Use hooks sparingly; prefer event subscribers and services.

### Architecture
- Services defined in `*.services.yml`; injected via DI — no `\Drupal::service()` in classes.
- Config management: all config in `config/sync/` — deploy via `drush config:import`.
- Custom entities: use typed data and content entity base classes properly.
- Twig templates: logic-free — move logic to preprocess hooks or Twig extensions.

### Deployment
- Always run `drush updatedb && drush config:import && drush cache:rebuild` in CI.
- Use Drush `state` and `config` systems — never hardcode environment-specific values.
- Database updates in `.install` files; never modify schema outside update hooks.

---

## ☕ Java & Spring Boot

### Standards
- Java 21 LTS; use records, sealed classes, pattern matching, virtual threads.
- Build tool: **Maven** (standard) or **Gradle** (Kotlin DSL preferred).
- Code style: Google Java Style Guide; enforce with Checkstyle.
- Static analysis: SpotBugs + PMD in CI.

### Spring Boot Conventions
- Constructor injection only — never `@Autowired` on fields.
- `@Service` for business logic; `@Repository` for data access; `@Controller`/`@RestController` thin.
- DTOs for API request/response — never expose entities directly.
- Use Spring Data JPA repositories; write JPQL for complex queries; native SQL as last resort.
- Validation: `@Valid` + Bean Validation annotations on DTOs.
- Exception handling: `@ControllerAdvice` + `@ExceptionHandler` globally.
- Actuator: expose `/health`, `/info`, `/metrics` — secure other endpoints.

### Spring Security
- Use Spring Security 6+; lambda DSL configuration.
- JWT stateless auth for REST APIs; sessions for web apps.
- Method-level security with `@PreAuthorize`.
- Never store passwords in plaintext — BCrypt with strength 12.

### Testing (Java)
- JUnit 5 + Mockito for unit tests.
- `@SpringBootTest` + Testcontainers for integration tests.
- `@WebMvcTest` for controller layer tests.
- Test coverage: JaCoCo with 80% minimum on service layer.

---

## 🤖 AI / LLM Stack

### LangGraph
- Define graphs with typed state using `TypedDict` or Pydantic models.
- Nodes are pure functions where possible — side effects in dedicated tool nodes.
- Use `StateGraph` for stateful multi-step flows; `MessageGraph` for chat agents.
- Always define explicit `END` conditions — guard against infinite loops.
- Checkpoint with `SqliteSaver` (dev) or `PostgresSaver` (prod) for resumable flows.
- Test graphs with `graph.invoke()` + snapshot tests on state output.

### LangSmith
- Set `LANGCHAIN_TRACING_V2=true` in all environments (dev, staging, prod).
- Tag runs with `project`, `environment`, and `version` metadata.
- Use datasets for regression testing LLM behavior — add failing cases to datasets.
- Monitor latency and token usage per run in the LangSmith dashboard.
- Use `@traceable` decorator on custom functions that should appear in traces.

### LangFuse
- Use LangFuse for production observability when self-hosting is required.
- Instrument with `@observe()` decorator or manual `langfuse.trace()`.
- Track: input/output, latency, token cost, model name, user ID per trace.
- Create Scores for quality evaluation — tie to human feedback or automated evals.
- Use LangFuse datasets for A/B testing prompt versions.

### General LLM Best Practices
- Always set explicit `max_tokens` — never let the model run unbounded.
- Use structured output (JSON mode, tool calling, Pydantic) over parsing free text.
- Prompt versioning: store prompts in code or a prompt registry — not hardcoded strings.
- Retry with exponential backoff on rate limit errors (429).
- Log every LLM call: model, prompt, response, latency, cost, user context.
- Evaluate systematically — build evals before optimizing prompts.
- Keep system prompts and user prompts separate; never concatenate them naively.
- PII: scrub sensitive data before sending to third-party LLM APIs.

---

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

## 🎨 Design — Figma

### Working with Figma Files
- Always inspect Figma designs before writing CSS/styles — match exactly.
- Extract: spacing (4px grid), colors (hex/rgba), typography (size, weight, line-height), border-radius.
- Use design tokens from Figma Variables when available — map to CSS custom properties.
- Component states: inspect all variants (default, hover, active, disabled, error).
- Check responsive frames: desktop, tablet, mobile breakpoints.
- Assets: export SVGs at 1x; PNGs at 2x for raster. Use `@2x` naming convention.

### Design-to-Code Principles
- Pixel-perfect on key screens; ±2px tolerance on secondary screens.
- Never approximate colors — extract exact hex values.
- Respect spacing system: if the design uses an 8px grid, use multiples of 8.
- Dark mode: if Figma has a dark mode frame, implement it simultaneously.
- Accessibility: check contrast ratios in Figma; flag anything below WCAG AA (4.5:1).

---

## 🖌️ Design Skills — UX/UI Designer

### Design Fundamentals

#### Core Principles
- **Visual hierarchy**: guide the eye — size, weight, color, contrast, spacing signal importance.
- **Gestalt principles**: proximity (group related items), similarity (consistent patterns), continuity (lead the eye), closure (complete incomplete shapes).
- **8px spacing grid**: all spacing in multiples of 8 (or 4 for fine-grained control). Never arbitrary values.
- **Color theory**: 60-30-10 rule (dominant / secondary / accent). Limit palette to 3–5 colors + neutrals.
- **Typography scale**: modular scale (1.25× or 1.333×). One serif + one sans-serif max. Line height 1.4–1.6 for body.
- **Contrast**: minimum 4.5:1 text on background (WCAG AA); 3:1 for large text and UI components.
- **Affordance**: interactive elements must look interactive. Buttons look pressable, links look clickable.
- **Whitespace**: negative space is a design element — don't fill every pixel.

#### Design Process
```
1. Discover        → user research, stakeholder interviews, competitive audit, analytics
2. Define          → persona, journey map, problem statement, success metrics
3. Ideate          → crazy 8s, sketches, wireframes — quantity before quality
4. Design          → mid-fi wireframes → hi-fi mockups → design system components
5. Prototype       → interactive flow in Figma / Framer — simulate real interactions
6. Test            → usability testing (5 users catch 85% of issues), A/B testing
7. Handoff         → annotated specs, design tokens, component docs for devs
8. Measure         → track success metrics; iterate based on data
```

### UX Research & Strategy

#### User Research Methods
| Method | When | Output |
|---|---|---|
| **User interviews** | Discovery, exploration | Qualitative insights, mental models |
| **Surveys** | Validate at scale | Quantitative data, priorities |
| **Usability testing** | Validate designs | Task completion rate, friction points |
| **Card sorting** | IA / navigation | Category groupings, labels |
| **Tree testing** | Validate IA | Navigation success rate |
| **Heatmaps / session replay** | Post-launch | Actual user behavior |
| **A/B testing** | Optimize conversions | Statistical significance data |
| **Contextual inquiry** | Complex workflows | In-context observation |

#### Personas & Journey Maps
```
Persona template:
  Name + photo (real, not stock)
  Demographics: age, role, tech comfort
  Goals: what they're trying to achieve
  Frustrations: what blocks them today
  Quote: captures their mindset in one sentence
  Behaviors: tools they use, workflows they follow

Journey map stages:
  Awareness → Consideration → Decision → Onboarding → Adoption → Advocacy
  For each stage: actions, thoughts, emotions, pain points, opportunities
```

#### Problem Statement (HMW Format)
```
"How might we [help persona] [achieve goal] [context/constraint]?"

Example:
"How might we help first-time users set up their account in under 2 minutes
without requiring technical knowledge?"
```

### Information Architecture

#### Navigation Patterns
| Pattern | Best for |
|---|---|
| **Top nav** | Marketing sites, content-heavy, few primary sections |
| **Side nav** | SaaS dashboards, many sections, deep hierarchies |
| **Tab bar** | Mobile apps, 3–5 primary destinations |
| **Hamburger menu** | Secondary nav on mobile, rarely-used sections |
| **Mega menu** | E-commerce, large content sites with many categories |
| **Breadcrumbs** | Deep hierarchies, e-commerce, documentation |
| **Bottom nav** | iOS/Android primary navigation (thumb-friendly) |

#### IA Principles
- Limit primary navigation to 5–7 items (cognitive load).
- Every page/screen needs a clear purpose and hierarchy.
- 3-click rule is a myth — but minimize friction to key actions.
- Label navigation with user language, not internal jargon.
- Use progressive disclosure: show what's needed now, reveal complexity on demand.

### Web Design

#### Responsive Design System
```
Breakpoints (Tailwind-aligned):
  xs:  < 640px   → mobile portrait (single column)
  sm:  640–767px → mobile landscape
  md:  768–1023px → tablet
  lg:  1024–1279px → laptop
  xl:  1280–1535px → desktop
  2xl: ≥ 1536px  → wide screen

Grid system:
  Mobile:  4 columns, 16px gutter, 16px margin
  Tablet:  8 columns, 24px gutter, 32px margin
  Desktop: 12 columns, 24px gutter, auto margin (max-width: 1280px)

Component behavior at breakpoints:
  - Stack: side-by-side → stacked vertically
  - Collapse: visible nav → hamburger
  - Resize: text scales (clamp()), images fill container
  - Hide: supplementary content hidden on mobile
```

#### Landing Page Design
```
Above fold:
  - Hero headline: 1 clear value proposition (6–10 words)
  - Subheadline: expand the value prop (1–2 sentences)
  - Primary CTA: action-oriented ("Start free trial", not "Submit")
  - Supporting visual: product screenshot or illustration

Below fold flow:
  1. Social proof (logos, testimonials, ratings)
  2. Problem → Solution (before/after)
  3. Features (benefits-led, not feature-led)
  4. How it works (3-step visual)
  5. Testimonials (specific, with name + photo + company)
  6. Pricing or CTA
  7. FAQ (handle objections)
  8. Final CTA + footer
```

#### Typography System (Web)
```
Scale (modular, 1.25×):
  xs:   12px / 0.75rem
  sm:   14px / 0.875rem
  base: 16px / 1rem       ← body text
  lg:   20px / 1.25rem
  xl:   24px / 1.5rem
  2xl:  32px / 2rem
  3xl:  40px / 2.5rem
  4xl:  56px / 3.5rem     ← hero headlines

Line heights:
  Tight (headings):  1.1–1.3
  Normal (body):     1.5–1.7
  Loose (captions):  1.8–2.0

Font pairing examples:
  Professional: Inter (sans) + nothing — Inter handles both
  Editorial:    Playfair Display (serif headlines) + Inter (body)
  Tech/SaaS:    Space Grotesk (headings) + Inter (body)
  Warm/Brand:   DM Serif Display + DM Sans
```

### Mobile Design (iOS & Android)

#### Platform Design Guidelines
| Aspect | iOS (HIG) | Android (Material 3) |
|---|---|---|
| Navigation | Tab bar (bottom) | Navigation bar (bottom) |
| Back | Swipe left / back button | System back gesture |
| FAB | Rare | Common (primary action) |
| Typography | SF Pro | Roboto / brand font |
| Icons | SF Symbols | Material Symbols |
| Elevation | Flat / blur | Tonal surface + shadow |
| Modals | Sheet (bottom) | Bottom sheet / dialog |
| Haptics | Defined patterns | Vibration patterns |

#### Mobile Touch Targets
```
Minimum tap target: 44×44pt (iOS) / 48×48dp (Android)
Recommended:        48×48pt minimum, 56×56 for primary actions
Spacing between targets: 8pt minimum

Thumb zone (one-handed use):
  ✅ Natural reach: bottom 60% of screen
  ⚠️ Stretch zone:  top 20% of screen
  ❌ Difficult:     top corners

→ Place primary actions in natural reach zone (bottom)
→ Place destructive actions in difficult zone (top, behind gesture)
```

#### Mobile Design Patterns
```
Onboarding:
  - 3–5 screens max; skip button always visible
  - Progressive: don't ask permissions until needed
  - Value-first: show the app, then ask for email

Forms on mobile:
  - One question per screen (step-by-step)
  - Auto-advance when selection is clear
  - Show keyboard type: numeric, email, tel, url
  - Large tap targets for selects/checkboxes

Empty states:
  - Explain why it's empty
  - Show the action to fill it
  - Illustrate with a friendly visual

Loading states:
  - Skeleton screens > spinners (reduce perceived wait)
  - Optimistic UI: show result before server confirms
  - Progressive loading: above-fold first
```

#### iOS-Specific Patterns
```
Navigation:
  - NavigationStack: push/pop for hierarchical content
  - Tab bar: 3–5 items, icon + label
  - Sheet: presented over content, drag to dismiss

Gestures:
  - Swipe left to delete (destructive, requires confirmation)
  - Long press for context menu
  - Pinch to zoom
  - Pull to refresh

Safe areas:
  - Always respect Dynamic Island / notch (top safe area)
  - Respect home indicator (bottom safe area: 34pt)
  - Content never behind system UI
```

#### Android-Specific Patterns
```
Navigation:
  - Bottom navigation bar: 3–5 primary destinations
  - Navigation rail: tablets/foldables (side)
  - Navigation drawer: secondary destinations

Material 3 components:
  - FAB (Floating Action Button): primary screen action
  - Chips: filters, tags, selections
  - Cards: tonal, filled, outlined
  - Snackbar: 4s auto-dismiss, one action max

Edge-to-edge design:
  - Draw behind status bar and nav bar
  - WindowInsets: inset content from system bars
  - Dynamic color: pull palette from wallpaper (Material You)
```

### Desktop Application Design

#### Desktop UI Patterns
```
Window structure:
  Title bar → Toolbar/Menu bar → Content area → Status bar

Navigation types:
  - MDI (Multiple Document Interface): tabbed documents (VS Code, browsers)
  - SDI (Single Document Interface): one document per window (Calculator)
  - Explorer pattern: tree nav + content panel (Finder, File Explorer)
  - Ribbon: Office-style grouped toolbar for feature-rich apps

Keyboard-first:
  - Every action must have a keyboard shortcut
  - Tab order must be logical
  - Keyboard navigation fully functional without mouse
  - Display shortcuts in menus, tooltips, UI
```

#### Electron / Cross-Platform Desktop
```
OS conventions to respect:
  macOS:   ⌘+Q quit, ⌘+W close tab, ⌘+, preferences, traffic light buttons
  Windows: Alt+F4 close, Ctrl+Z undo, taskbar icon, system tray
  Linux:   GTK/Qt conventions, respect DE (GNOME/KDE) patterns

Window chrome:
  - macOS: use native title bar + traffic light, or custom + hidden title
  - Windows: Mica material, snap assist, Fluent Design language
  - All: respect system dark mode (prefers-color-scheme)

Context menus:
  - Right-click always available
  - Show relevant actions only (context-sensitive)
  - Keyboard shortcut shown inline
  - Destructive actions at bottom, separated
```

#### Dense Information Displays
- Desktop has more pixels — use them: sidebars, panels, split panes.
- Data tables: sortable columns, resizable, row selection, bulk actions.
- Resizable panels with drag handles — remember sizes (localStorage/app state).
- Keyboard navigation essential: arrow keys in lists, Enter to select, Esc to cancel.
- Tooltips on hover (not tap — desktop has hover state).
- Right-click context menus for power users.

### SaaS / Software App Design

#### Dashboard Design
```
Dashboard hierarchy:
  1. KPIs / Summary cards    → at-a-glance health
  2. Primary charts          → trends over time
  3. Data tables             → detailed breakdown
  4. Secondary metrics       → supplementary context
  5. Actions / shortcuts     → quick access to key workflows

Chart selection guide:
  Comparison over time    → Line chart
  Part of whole           → Donut / Pie (≤5 segments)
  Compare categories      → Bar chart (horizontal for long labels)
  Distribution            → Histogram
  Correlation             → Scatter plot
  Progress to goal        → Progress bar / Gauge
  Geographic data         → Map / Choropleth
  Hierarchy / tree        → Treemap / Sunburst
  Flow / funnel           → Funnel chart / Sankey

Dashboard anti-patterns:
  ❌ More than 8–10 metrics on one screen
  ❌ Pie charts with >5 slices
  ❌ 3D charts (distort values)
  ❌ Truncated y-axis (makes small differences look big)
  ❌ No empty state / loading state
```

#### Form Design (Complex Apps)
```
Multi-step forms:
  - Progress indicator shows current step + total
  - Validation inline (on blur), not on submit
  - Save draft automatically
  - Allow back navigation without losing data
  - Summary/review step before final submit

Field design:
  - Labels above fields (not placeholder — placeholder disappears on focus)
  - Error messages below field, in red, specific: "Enter a valid email address"
  - Helper text below label, in gray, before interaction
  - Required fields: mark required (not optional) — less cognitive load
  - Character count for limited fields (visible at 80% of limit)

Autocomplete / search:
  - Debounce 300ms before querying
  - Show loading state while searching
  - Keyboard navigation (↑↓ to navigate, Enter to select, Esc to close)
  - Highlight matched text in results
  - "No results" state with suggestion
```

#### Settings & Configuration UX
```
Settings organization:
  - Group by function, not by implementation
  - Most-used settings first, advanced/dangerous last
  - Search within settings for large apps
  - Immediate preview of visual changes
  - Undo for destructive settings changes

Danger zones:
  - Destructive actions visually separated (red section, border)
  - Double confirmation: "Delete account" → type "DELETE" → confirm
  - Show consequences before confirming: "This will delete X items"
  - Provide export before deletion: "Download your data first"
```

#### Empty States
```
Types and treatments:
  First-use empty state:
    → Illustration + headline + explanation + primary CTA
    → Example: "No projects yet — Create your first project"

  No results (search/filter):
    → Icon + "No results for '[query]'" + clear filter CTA
    → Suggest: "Try a different search term"

  Error state:
    → Error icon + what went wrong + how to fix it + retry CTA
    → Never blame the user: "Couldn't load data" not "You must be connected"

  Success / completion:
    → Celebrate briefly, then redirect to next action
    → Confetti, check animation — but only once
```

### Design Systems

#### Component Documentation Standard
```
For every component, document:
  1. Usage: when to use / when NOT to use
  2. Variants: all states (default, hover, focus, active, disabled, error)
  3. Props/API: all configuration options
  4. Sizing: S / M / L variants and when to use each
  5. Spacing: padding, margin, gap
  6. Accessibility: keyboard behavior, ARIA roles, screen reader output
  7. Do / Don't: visual examples of correct and incorrect usage
  8. Code example: ready-to-paste snippet
```

#### Token Hierarchy
```
Primitive tokens (base values — never used in components directly):
  color-blue-500: #3b82f6
  space-4: 16px
  radius-md: 8px

Semantic tokens (reference primitives — used in components):
  color-action-primary: {color-blue-500}
  color-surface-default: {color-neutral-0}
  space-component-padding-md: {space-4}

Component tokens (component-specific — optional, for overrides):
  button-padding-x: {space-component-padding-md}
  button-border-radius: {radius-md}
```

#### Design System Governance
- Single source of truth: one Figma library + one code repo.
- Version design system like software: semver, changelog, migration guides.
- Contribution process: proposal → design review → code review → publish.
- Breaking changes require deprecation period + migration path.
- Regular audits: find and consolidate one-off components that should be in the system.

### Prototyping & Handoff

#### Figma Prototyping Levels
```
Level 1 — Click-through:
  Static screens connected by click interactions
  Use for: stakeholder presentations, early concept validation

Level 2 — Interactive:
  Micro-interactions, overlays, component states
  Use for: usability testing, developer reference

Level 3 — High-fidelity:
  Variables, conditionals, realistic data
  Use for: complex flows, animated handoffs, sign-off from stakeholders

Level 4 — Framer / ProtoPie:
  Code-driven animations, real APIs, physics
  Use for: executive demos, marketing prototypes
```

#### Developer Handoff Checklist
- [ ] All layers named semantically (not "Rectangle 42")
- [ ] Components use Auto Layout — no fixed heights/widths on flexible elements
- [ ] All text uses style definitions (not local overrides)
- [ ] All colors use token variables (no hex values directly in layers)
- [ ] Spacing uses 8px grid consistently
- [ ] All states documented (default, hover, focus, active, disabled, error, loading)
- [ ] Responsive frames provided (mobile, tablet, desktop)
- [ ] Assets exported and named correctly
- [ ] Annotations for non-obvious interactions and motion
- [ ] Design tokens exported / linked to code tokens

### Motion & Animation Design

#### Motion Principles
- **Purposeful**: every animation communicates meaning — not just decoration.
- **Fast**: UI animations: 150–300ms. Longer = feels sluggish.
- **Natural**: use ease curves that mimic physics (ease-out for entering, ease-in for leaving).
- **Consistent**: same interaction = same motion throughout the app.
- **Respectful**: honor `prefers-reduced-motion` — provide static alternatives.

#### Easing Reference
```
ease-out (decelerate):   entering elements — start fast, slow to stop
ease-in  (accelerate):   exiting elements  — start slow, fast exit
ease-in-out:             repositioning     — slow start, fast middle, slow end
linear:                  loaders, progress bars, continuous motion
spring:                  natural bouncy feel — Framer Motion spring()
```

#### Common Animation Patterns
```
Page/screen transition:
  Fade + slight Y translate (8–16px): 200ms ease-out
  Slide: new page slides in from right; back = slide out to right

Element entrance:
  Stagger children: 30–50ms delay between items
  Fade-in-up: opacity 0→1, translateY 16px→0: 200ms ease-out

Micro-interactions:
  Button press: scale(0.97): 100ms ease-out → scale(1): 100ms ease-out
  Toggle: 200ms spring, color transition
  Checkbox: path animation draws checkmark: 150ms ease-out

Loading:
  Skeleton pulse: 1.5s ease-in-out infinite (subtle, not distracting)
  Spinner: 800ms linear infinite
  Progress: linear, matches real progress
```

### Design Tools

#### Figma (Primary)
- **Auto Layout**: use everywhere — never position with absolute coordinates for responsive components.
- **Variables**: tokens for colors, spacing, radii — link to code tokens for parity.
- **Components**: main components in dedicated library file; publish for team.
- **Variants**: group related states in one component set (not separate components).
- **Interactive components**: prototype within component for reusable hover/focus states.
- **Dev Mode**: annotates spacing, tokens, code snippets — use for handoff.

#### Supplementary Tools
| Tool | Purpose |
|---|---|
| **Framer** | High-fidelity prototypes with code, marketing sites |
| **ProtoPie** | Complex interactions, sensor-based, conditional logic |
| **Principle** | macOS app animation prototyping |
| **Lottie / After Effects** | Export animations as JSON for production use |
| **Spline** | 3D design for web, interactive 3D components |
| **Maze** | Remote usability testing, tree testing, surveys |
| **Hotjar / FullStory** | Heatmaps, session recordings, user behavior |
| **Contrast** | Accessibility contrast checker |
| **Font Pair** | Typography pairing research |

### Design QA (Before Handoff)

#### Visual QA Checklist
- [ ] Spacing consistent with 8px grid (no 7px, 11px, 23px gaps)
- [ ] All text uses defined type styles — no ad hoc font sizes
- [ ] All colors use defined tokens — no raw hex values in layers
- [ ] Contrast meets WCAG AA (4.5:1 text, 3:1 UI components)
- [ ] Component states complete: default, hover, focus, active, disabled, error
- [ ] Dark mode variants provided (if app supports dark mode)
- [ ] Responsive breakpoints designed (mobile / tablet / desktop)
- [ ] Empty states designed for all data-driven screens
- [ ] Loading states designed (skeleton or spinner)
- [ ] Error states designed (network error, validation, permission denied)
- [ ] Interactions annotated (especially non-obvious gestures/animations)
- [ ] Assets exported at correct sizes and formats (SVG for icons, WebP for images)
- [ ] Figma file organized: pages named, layers named, unused styles removed

---

## 🌐 HTML

### Semantic HTML5
```html
<!-- ✅ Semantic structure — meaningful to browsers, screen readers, SEO -->
<header>
  <nav aria-label="Main navigation">
    <ul role="list">
      <li><a href="/" aria-current="page">Home</a></li>
      <li><a href="/about">About</a></li>
    </ul>
  </nav>
</header>

<main>
  <article>
    <header>
      <h1>Article Title</h1>
      <time datetime="2024-01-15">January 15, 2024</time>
    </header>
    <section aria-labelledby="intro-heading">
      <h2 id="intro-heading">Introduction</h2>
      <p>Content...</p>
    </section>
    <figure>
      <img src="chart.png" alt="Sales growth 40% YoY from 2022 to 2024" />
      <figcaption>Annual sales growth</figcaption>
    </figure>
  </article>
  <aside aria-label="Related articles">...</aside>
</main>

<footer>
  <address>Contact: <a href="mailto:hi@example.com">hi@example.com</a></address>
</footer>
```

**Semantic element guide:**
| Element | Use for |
|---|---|
| `<header>` | Page or section header |
| `<nav>` | Navigation links |
| `<main>` | Primary page content (one per page) |
| `<article>` | Independently distributable content |
| `<section>` | Thematic grouping with heading |
| `<aside>` | Tangentially related content |
| `<footer>` | Page or section footer |
| `<figure>/<figcaption>` | Self-contained media + caption |
| `<time>` | Dates/times with machine-readable `datetime` |
| `<mark>` | Highlighted/relevant text |
| `<details>/<summary>` | Disclosure widget (no JS needed) |

### Accessibility (a11y)

#### ARIA Essentials
```html
<!-- Roles — only when semantic HTML isn't enough -->
<div role="alert" aria-live="polite">Form saved successfully</div>
<div role="status" aria-live="polite">Loading...</div>

<!-- Labels — every interactive element needs one -->
<button aria-label="Close dialog">✕</button>
<input type="search" aria-label="Search products" />

<!-- Expanded/collapsed state -->
<button aria-expanded="false" aria-controls="menu-list">Menu</button>
<ul id="menu-list" hidden>...</ul>

<!-- Described by -->
<input aria-describedby="pwd-hint" type="password" />
<p id="pwd-hint">At least 8 characters, one uppercase</p>

<!-- Required + invalid -->
<input aria-required="true" aria-invalid="true" />
<span role="alert">This field is required</span>
```

#### Focus Management
```html
<!-- Skip link — keyboard users can skip nav -->
<a href="#main-content" class="skip-link">Skip to main content</a>

<!-- Focusable elements: a[href], button, input, select, textarea, [tabindex="0"] -->
<!-- Never use tabindex > 0 — breaks natural tab order -->

<!-- Dialog focus trap (must be implemented in JS) -->
<dialog aria-modal="true" aria-labelledby="dialog-title">
  <h2 id="dialog-title">Confirm Action</h2>
  <!-- Focus first focusable element on open; trap Tab/Shift+Tab inside -->
</dialog>
```

#### Screen Reader Testing Checklist
- [ ] All images have meaningful `alt` text (empty `alt=""` for decorative)
- [ ] Form inputs have associated `<label>` (via `for`/`id` or `aria-label`)
- [ ] Color is not the only way to convey meaning
- [ ] Contrast ratio ≥ 4.5:1 (text), ≥ 3:1 (large text/UI components)
- [ ] Keyboard-only navigation works for all interactions
- [ ] Focus indicator visible (no `outline: none` without replacement)
- [ ] Dynamic content changes announced (`aria-live`)
- [ ] Page has one `<h1>`; heading hierarchy is logical (h1 → h2 → h3)

### Forms
```html
<!-- Complete accessible form pattern -->
<form novalidate>  <!-- novalidate = use custom validation UI -->
  <fieldset>
    <legend>Shipping Address</legend>

    <div class="field">
      <label for="street">Street address <span aria-hidden="true">*</span></label>
      <input
        id="street"
        type="text"
        name="street"
        autocomplete="street-address"
        required
        aria-required="true"
        aria-describedby="street-error"
      />
      <span id="street-error" role="alert" hidden>Street address is required</span>
    </div>
  </fieldset>

  <!-- Input types — use correct type for mobile keyboard + validation -->
  <input type="email"    autocomplete="email" />
  <input type="tel"      autocomplete="tel" />
  <input type="number"   inputmode="numeric" />
  <input type="url"      />
  <input type="date"     />
  <input type="password" autocomplete="current-password" />
  <input type="search"   role="searchbox" />

  <button type="submit">Submit</button>
</form>
```

### Performance HTML
```html
<!-- Resource hints -->
<link rel="preconnect" href="https://fonts.googleapis.com" />
<link rel="dns-prefetch" href="https://cdn.example.com" />
<link rel="preload" href="/fonts/Inter.woff2" as="font" type="font/woff2" crossorigin />
<link rel="prefetch" href="/dashboard" />  <!-- next likely page -->

<!-- Images — always width + height to prevent CLS -->
<img
  src="hero.webp"
  width="1200" height="600"
  alt="..."
  loading="lazy"        <!-- defer off-screen images -->
  decoding="async"
  fetchpriority="high"  <!-- for LCP image -->
/>

<!-- Script loading -->
<script src="app.js" defer></script>       <!-- load async, exec after HTML parsed -->
<script src="critical.js" async></script>  <!-- load + exec async (no order guarantee) -->
<script type="module" src="app.js"></script> <!-- always deferred -->

<!-- Meta essentials -->
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<meta name="description" content="Page description for SEO, 150-160 chars" />
<meta property="og:title" content="Page Title" />
<meta property="og:image" content="https://example.com/og.png" />
<link rel="canonical" href="https://example.com/page" />
```

### Web Components
```html
<!-- Custom element with shadow DOM -->
<my-alert type="success">Changes saved!</my-alert>

<script>
class MyAlert extends HTMLElement {
  static observedAttributes = ["type"];

  connectedCallback() {
    const shadow = this.attachShadow({ mode: "open" });
    shadow.innerHTML = `
      <style>:host { display: block; padding: 1rem; border-radius: 4px; }
             :host([type="success"]) { background: #d1fae5; }</style>
      <slot></slot>
    `;
  }

  attributeChangedCallback(name, _, newVal) {
    // react to attribute changes
  }
}
customElements.define("my-alert", MyAlert);
</script>
```

---

## 🎨 CSS

### Specificity & Cascade
```css
/* Specificity: inline > ID > class/pseudo > element */
/* 0-0-0-0: universal (*) */
/* 0-0-0-1: element (div, p) */
/* 0-0-1-0: class (.btn), attribute ([type]), pseudo-class (:hover) */
/* 0-1-0-0: ID (#header) */
/* 1-0-0-0: inline style */

/* Modern approach: keep specificity flat, use :where() to lower */
:where(button) { /* specificity 0 — easily overridden */ }
:is(nav, footer) a { /* specificity of highest selector inside :is() */ }

/* Cascade layers — control override order explicitly */
@layer reset, base, components, utilities;
@layer components { .btn { padding: 0.5rem 1rem; } }
@layer utilities  { .mt-4 { margin-top: 1rem; } }  /* utilities always win */
```

### Custom Properties (Variables)
```css
/* Design tokens as CSS variables */
:root {
  /* Color system */
  --color-primary-50:  #eff6ff;
  --color-primary-500: #3b82f6;
  --color-primary-900: #1e3a8a;

  /* Typography */
  --font-sans: 'Inter', system-ui, sans-serif;
  --text-sm: 0.875rem;
  --text-base: 1rem;
  --text-xl: 1.25rem;
  --leading-normal: 1.5;

  /* Spacing (4px grid) */
  --space-1: 0.25rem;  /* 4px */
  --space-2: 0.5rem;   /* 8px */
  --space-4: 1rem;     /* 16px */
  --space-8: 2rem;     /* 32px */

  /* Shadows */
  --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1);

  /* Transitions */
  --transition-fast: 150ms ease;
  --transition-base: 250ms ease;
}

/* Dark mode via media query */
@media (prefers-color-scheme: dark) {
  :root {
    --color-bg: #0f172a;
    --color-text: #f1f5f9;
  }
}

/* Dark mode via class (user toggle) */
[data-theme="dark"] { --color-bg: #0f172a; }
```

### Flexbox
```css
/* Container */
.flex-container {
  display: flex;
  flex-direction: row;       /* row | column | row-reverse | column-reverse */
  flex-wrap: wrap;           /* nowrap | wrap | wrap-reverse */
  justify-content: space-between; /* main axis: flex-start | center | space-between | space-around | space-evenly */
  align-items: center;       /* cross axis: stretch | flex-start | center | flex-end | baseline */
  align-content: flex-start; /* multi-line cross axis (when wrapping) */
  gap: 1rem;                 /* row-gap + column-gap */
}

/* Items */
.flex-item {
  flex: 1;          /* shorthand: flex-grow flex-shrink flex-basis → 1 1 0% */
  flex: 0 0 200px;  /* fixed width, no grow/shrink */
  flex: 1 1 auto;   /* grow + shrink, basis = content */
  align-self: flex-end;  /* override container align-items */
  order: -1;             /* reorder visually without changing DOM */
}

/* Common patterns */
/* Center anything */
.center { display: flex; align-items: center; justify-content: center; }

/* Sticky footer */
.page { display: flex; flex-direction: column; min-height: 100vh; }
.page main { flex: 1; }   /* main grows, footer stays at bottom */

/* Equal-width columns */
.cols > * { flex: 1; }
```

### CSS Grid
```css
/* Explicit grid */
.grid {
  display: grid;
  grid-template-columns: repeat(12, 1fr);          /* 12-column grid */
  grid-template-rows: auto 1fr auto;               /* header, main, footer */
  grid-template-areas:
    "header header header"
    "sidebar main   main"
    "footer footer footer";
  gap: 1rem 2rem;   /* row-gap column-gap */
}

.header  { grid-area: header; }
.sidebar { grid-area: sidebar; }
.main    { grid-area: main; }
.footer  { grid-area: footer; }

/* Item placement */
.item {
  grid-column: 2 / 4;     /* col 2 to 4 */
  grid-column: span 3;    /* span 3 columns */
  grid-row: 1 / -1;       /* full height */
}

/* Auto-fill responsive grid (no media queries needed) */
.card-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 1.5rem;
}

/* Subgrid (align nested elements to parent grid) */
.card {
  grid-column: span 2;
  display: grid;
  grid-template-rows: subgrid;  /* inherit parent row tracks */
}
```

### Responsive Design
```css
/* Mobile-first — base styles for mobile, enhance upward */
.container { padding: 1rem; }

@media (min-width: 640px)  { .container { max-width: 640px; margin: 0 auto; } }
@media (min-width: 1024px) { .container { max-width: 1024px; padding: 2rem; } }
@media (min-width: 1280px) { .container { max-width: 1280px; } }

/* Container queries — component-level responsiveness */
.card-wrapper { container-type: inline-size; container-name: card; }

@container card (min-width: 400px) {
  .card { display: flex; gap: 1rem; }
}

/* Fluid typography with clamp() */
h1 { font-size: clamp(1.5rem, 4vw, 3rem); }  /* min, preferred, max */
.content { width: clamp(280px, 90%, 1200px); margin: 0 auto; }

/* Logical properties (supports RTL) */
.box {
  margin-inline: auto;          /* left + right */
  padding-block: 1rem;         /* top + bottom */
  border-inline-start: 2px solid; /* left (or right in RTL) */
}
```

### Animations & Transitions
```css
/* Transitions — for state changes (hover, focus) */
.btn {
  background: var(--color-primary-500);
  transition:
    background-color var(--transition-fast),
    transform var(--transition-fast),
    box-shadow var(--transition-fast);
}
.btn:hover {
  background: var(--color-primary-600);
  transform: translateY(-1px);
  box-shadow: var(--shadow-md);
}

/* Keyframe animations */
@keyframes fade-in {
  from { opacity: 0; transform: translateY(8px); }
  to   { opacity: 1; transform: translateY(0); }
}

.modal {
  animation: fade-in 200ms ease forwards;
}

/* Reduced motion — always respect */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}

/* View Transitions API */
@view-transition { navigation: auto; }
::view-transition-old(root) { animation: slide-out 300ms ease; }
::view-transition-new(root) { animation: slide-in 300ms ease; }
```

### Modern CSS (2024+)
```css
/* CSS Nesting (no preprocessor needed) */
.card {
  padding: 1rem;
  border-radius: 8px;

  &:hover { box-shadow: var(--shadow-md); }

  & .title {
    font-size: var(--text-xl);
    font-weight: 600;
  }

  @media (min-width: 768px) { padding: 2rem; }
}

/* :has() — parent selector */
.form:has(input:invalid) .submit-btn { opacity: 0.5; pointer-events: none; }
.card:has(> img) { padding-top: 0; }  /* card with direct img child */

/* :is() and :where() */
:is(h1, h2, h3) { line-height: 1.2; }
:where(article, section) p { margin-block: 1em; }

/* @layer for specificity management */
@layer base, components, utilities;

/* color-mix() */
.btn-hover { background: color-mix(in srgb, var(--color-primary) 80%, black); }

/* Scroll-driven animations */
@keyframes reveal { from { opacity: 0; } to { opacity: 1; } }
.section {
  animation: reveal linear;
  animation-timeline: view();
  animation-range: entry 0% entry 30%;
}
```

### CSS Architecture (BEM + Utility)
```css
/* BEM — Block__Element--Modifier */
.card { }                      /* Block */
.card__title { }               /* Element */
.card__title--truncated { }    /* Modifier */
.card--featured { }            /* Block modifier */

/* Component file structure (co-located with component) */
/* Button.module.css */
.root { }
.root.primary { }
.root.large { }
.icon { }

/* Tailwind utility approach — prefer for React/Next.js */
/* Only write custom CSS for: complex animations, pseudo-elements, dynamic values */
```

### Performance
```css
/* Avoid layout thrashing (triggers reflow) — prefer transform/opacity */
/* ❌ Causes reflow */        /* ✅ GPU-accelerated */
.moving { left: 100px; }     .moving { transform: translateX(100px); }
.fading { visibility: hidden; } .fading { opacity: 0; }

/* will-change — hint browser to create compositor layer (use sparingly) */
.animated { will-change: transform; }  /* only for elements that actually animate */

/* contain — limit style/layout recalculation scope */
.card { contain: layout style; }  /* changes inside don't affect outside */

/* Font loading — prevent FOIT/FOUT */
@font-face {
  font-family: 'Inter';
  src: url('/fonts/inter.woff2') format('woff2');
  font-display: swap;    /* show fallback immediately, swap when loaded */
}

/* Critical CSS inline in <head>; async load the rest */
<style>/* above-fold critical CSS */</style>
<link rel="preload" href="styles.css" as="style" onload="this.rel='stylesheet'" />
```

---

## 🟨 JavaScript (Vanilla / ES2024+)

### Language Fundamentals
- Use ES modules (`import`/`export`) — never CommonJS `require()` in new code.
- `const` by default; `let` when reassignment needed; never `var`.
- Prefer destructuring: `const { name, age } = user` over `user.name`, `user.age`.
- Optional chaining `?.` and nullish coalescing `??` over manual null checks.
- Template literals over string concatenation.
- Spread `...` over `Object.assign()` for shallow copies.
- `Array.from()` or spread for array-like conversions — never `Array.prototype.slice.call()`.

### Async Patterns
- `async/await` always — no raw `.then()/.catch()` chains unless chaining is genuinely cleaner.
- Always `try/catch` around `await` — never unhandled promise rejections.
- Parallel async: `Promise.all([a(), b(), c()])` — never sequential `await` when independent.
- `Promise.allSettled()` when you need results regardless of individual failures.
- Avoid `async` in loops — use `Promise.all(array.map(async item => ...))`.

```js
// ✅ Parallel — fast
const [user, posts, comments] = await Promise.all([
  fetchUser(id), fetchPosts(id), fetchComments(id)
]);

// ❌ Sequential — slow waterfall
const user = await fetchUser(id);
const posts = await fetchPosts(id);
const comments = await fetchComments(id);
```

### Modern APIs
- `fetch` for HTTP — no axios unless project already uses it.
- `URLSearchParams` for query string building.
- `AbortController` for cancellable fetches.
- `structuredClone()` for deep cloning — no `JSON.parse(JSON.stringify())`.
- `crypto.randomUUID()` for UUIDs in browser/Node 19+.
- `Intl` API for formatting dates, numbers, currencies — no manual formatting.
- `queueMicrotask()` over `setTimeout(fn, 0)` for microtask scheduling.

### DOM & Browser
- `querySelector` / `querySelectorAll` — no jQuery.
- Event delegation for dynamic lists — single listener on parent, check `event.target`.
- `IntersectionObserver` for lazy loading and scroll triggers.
- `ResizeObserver` for responsive element behavior.
- `MutationObserver` for watching DOM changes.
- `requestAnimationFrame` for all animations — never `setInterval` for visual updates.
- Clean up: remove event listeners, cancel observers, clear timers in teardown.

### Code Quality
- Linting: **ESLint** with `eslint:recommended` + `plugin:import/recommended`.
- Formatting: **Prettier** — no manual style debates.
- No `console.log` in committed code — use a proper logger or remove before commit.
- Pure functions where possible — same input always produces same output.
- Avoid mutation of function arguments — return new values.

---

## 🔷 TypeScript

### Configuration
```json
// tsconfig.json — always use strict mode
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "forceConsistentCasingInFileNames": true,
    "esModuleInterop": true,
    "skipLibCheck": true
  }
}
```

### Type System Rules
- Never use `any` — use `unknown` when type is truly unknown, then narrow with type guards.
- Prefer `interface` for object shapes that may be extended; `type` for unions, intersections, primitives.
- Use `readonly` on properties that should not be mutated.
- Discriminated unions over optional properties for variant types.
- `satisfies` operator to validate objects against a type without widening.
- Avoid type assertions (`as`) — use type guards instead.
- Generic constraints: `<T extends object>` not bare `<T>` when possible.

```ts
// ✅ Discriminated union — exhaustive, clear
type Result<T> =
  | { status: "success"; data: T }
  | { status: "error"; error: string }
  | { status: "loading" };

// ✅ Type guard — narrows unknown safely
function isUser(val: unknown): val is User {
  return typeof val === "object" && val !== null && "id" in val && "email" in val;
}

// ❌ Type assertion — bypasses type system
const user = response.data as User; // dangerous
```

### Utility Types — Use Them
- `Partial<T>` — all properties optional (patch payloads).
- `Required<T>` — all properties required.
- `Pick<T, K>` / `Omit<T, K>` — shape subsets.
- `Readonly<T>` — immutable object.
- `Record<K, V>` — typed dictionaries.
- `ReturnType<typeof fn>` — infer return type.
- `Parameters<typeof fn>` — infer parameter types.
- `NonNullable<T>` — strip `null | undefined`.

### Patterns
- Zod for runtime validation + TypeScript type inference from schemas.
- `as const` for literal type inference on config objects and tuples.
- Template literal types for string pattern enforcement.
- Mapped types for transforming object shapes systematically.
- No `enum` — use `as const` objects with a derived union type instead:

```ts
// ✅ Preferred over enum
const Status = { Active: "active", Inactive: "inactive", Pending: "pending" } as const;
type Status = typeof Status[keyof typeof Status]; // "active" | "inactive" | "pending"
```

### Project Conventions
- Run `tsc --noEmit` in CI — zero type errors before merge.
- Separate `types/` directory for shared domain types.
- Co-locate component-specific types in the same file.
- Export types explicitly: `export type { User }` not `export { User }`.
- `@ts-expect-error` over `@ts-ignore` — documents why the suppression exists.

---

## 🎨 Canvas API (HTML5)

### Setup & Context
- Always check context availability before using:
```js
const canvas = document.getElementById("canvas");
const ctx = canvas.getContext("2d");
if (!ctx) throw new Error("Canvas 2D context not supported");
```
- Set canvas dimensions via JS properties, not CSS (CSS scales, JS sets actual pixel buffer):
```js
canvas.width = 800;   // actual pixel buffer
canvas.height = 600;
// CSS can scale the display size separately
```
- For sharp rendering on HiDPI/Retina screens:
```js
const dpr = window.devicePixelRatio ?? 1;
canvas.width = width * dpr;
canvas.height = height * dpr;
canvas.style.width = `${width}px`;
canvas.style.height = `${height}px`;
ctx.scale(dpr, dpr);
```

### Drawing Patterns
- Always `ctx.save()` before changing state; `ctx.restore()` after — never leave dirty state.
- Draw order matters: background → midground → foreground (painter's algorithm).
- Batch similar draw calls — minimize state changes (fillStyle, strokeStyle, font) between draws.
- Use `ctx.beginPath()` before every new path — forgetting it accumulates paths silently.
- `ctx.clearRect(0, 0, canvas.width, canvas.height)` to clear before each animation frame.

```js
// ✅ Correct pattern
ctx.save();
ctx.fillStyle = "#ff6b6b";
ctx.beginPath();
ctx.arc(x, y, radius, 0, Math.PI * 2);
ctx.fill();
ctx.restore();
```

### Animation Loop
- Always use `requestAnimationFrame` — never `setInterval` for animation.
- Store the frame ID to cancel on cleanup.
- Calculate delta time for frame-rate-independent movement.

```js
let frameId;
let lastTime = 0;

function animate(timestamp) {
  const delta = timestamp - lastTime;
  lastTime = timestamp;

  ctx.clearRect(0, 0, canvas.width, canvas.height);
  update(delta);   // move things
  draw();          // draw things

  frameId = requestAnimationFrame(animate);
}

frameId = requestAnimationFrame(animate);

// Cleanup
cancelAnimationFrame(frameId);
```

### Performance
- Use `OffscreenCanvas` for heavy rendering in Web Workers.
- Cache expensive paths: pre-draw static elements to an offscreen canvas, blit with `drawImage`.
- Avoid reading pixels (`getImageData`) in hot loops — it forces GPU→CPU sync and stalls rendering.
- Group fills/strokes of the same color — each state change has overhead.
- Use integer coordinates for pixel-snapped drawing (no sub-pixel blur on straight lines).
- `ctx.imageSmoothingEnabled = false` for pixel art / sharp image scaling.

### Text
```js
ctx.font = "bold 16px 'Inter', sans-serif";
ctx.textAlign = "center";    // left | right | center | start | end
ctx.textBaseline = "middle"; // top | hanging | middle | alphabetic | bottom
ctx.fillText("Hello", x, y);

// Measure before draw
const metrics = ctx.measureText("Hello");
const textWidth = metrics.width;
```

### Hit Detection
- Use `ctx.isPointInPath(path, x, y)` for shape hit testing.
- For complex scenes: maintain a logical model of objects with bounding boxes; test mouse coords against model, not canvas pixels.

---

## 📊 D3.js (v7+)

### Core Philosophy
- D3 is **not a chart library** — it's a data transformation + DOM binding toolkit. Think in data joins, not draw calls.
- D3 manipulates SVG, Canvas, or HTML — choose SVG for interactive/zoomable charts; Canvas for 10k+ data points.
- D3 = **Data → DOM** mapping via selections and joins. Master this mental model first.

### Setup
```js
import * as d3 from "d3";              // full library
import { select, scaleLinear } from "d3"; // tree-shakeable imports (preferred)
```
- D3 v7 is fully modular — import only what you need to keep bundle small.
- Use `d3@7` — not v5/v6; API changed significantly.

### The Data Join Pattern (Core Mental Model)
```js
// The fundamental D3 pattern: select → data → join → enter/update/exit
const circles = svg
  .selectAll("circle")           // select (even if empty)
  .data(dataset, d => d.id)      // bind data, key by id for stable joins
  .join(
    enter => enter.append("circle")   // new data points
      .attr("r", 0)
      .call(enter => enter.transition().attr("r", d => scale(d.value))),
    update => update                   // existing data points
      .call(update => update.transition().attr("cx", d => xScale(d.x))),
    exit => exit                       // removed data points
      .call(exit => exit.transition().attr("r", 0).remove())
  );
```
- Always provide a **key function** to `.data()` for stable element identity during updates.
- Use `.join()` (v5+) over `.enter()` / `.exit()` — cleaner and handles all three cases.

### Scales
```js
// Linear scale — continuous numeric
const xScale = d3.scaleLinear()
  .domain([0, d3.max(data, d => d.value)])  // input range
  .range([margin.left, width - margin.right]) // output range
  .nice(); // round domain to nice values

// Band scale — categorical (bar charts)
const yScale = d3.scaleBand()
  .domain(data.map(d => d.category))
  .range([margin.top, height - margin.bottom])
  .padding(0.2);

// Time scale
const timeScale = d3.scaleTime()
  .domain(d3.extent(data, d => d.date))
  .range([0, width]);

// Color scales
const colorScale = d3.scaleOrdinal(d3.schemeTableau10);
const sequentialColor = d3.scaleSequential(d3.interpolateViridis).domain([0, 100]);
```

### Axes
```js
// Always render axes into a <g> element
const xAxis = d3.axisBottom(xScale)
  .ticks(6)
  .tickFormat(d => d3.format(".2s")(d)); // SI prefix: 1.2k, 3.4M

svg.append("g")
  .attr("class", "x-axis")
  .attr("transform", `translate(0, ${height - margin.bottom})`)
  .call(xAxis)
  .call(g => g.select(".domain").remove()) // remove axis line if desired
  .call(g => g.selectAll(".tick line").attr("stroke", "#ccc"));
```

### Transitions & Animation
```js
// Chain transitions for smooth updates
selection
  .transition()
  .duration(500)
  .ease(d3.easeCubicOut)
  .attr("cx", d => xScale(d.x))
  .attr("cy", d => yScale(d.y));

// Staggered entrance
selection
  .transition()
  .delay((d, i) => i * 50) // stagger by index
  .duration(300)
  .attr("opacity", 1);
```

### Interactivity
```js
// Tooltip pattern
const tooltip = d3.select("body").append("div")
  .attr("class", "tooltip")
  .style("opacity", 0)
  .style("position", "absolute")
  .style("pointer-events", "none");

selection
  .on("mouseover", (event, d) => {
    tooltip.transition().duration(200).style("opacity", 1);
    tooltip.html(`<strong>${d.name}</strong>: ${d.value}`)
      .style("left", `${event.pageX + 12}px`)
      .style("top", `${event.pageY - 28}px`);
  })
  .on("mouseout", () => tooltip.transition().duration(300).style("opacity", 0));

// Zoom & Pan
const zoom = d3.zoom()
  .scaleExtent([0.5, 10])
  .on("zoom", (event) => {
    g.attr("transform", event.transform);
  });
svg.call(zoom);
```

### Responsive Charts
```js
// Use ResizeObserver to redraw on container resize
const container = document.getElementById("chart");
const ro = new ResizeObserver(entries => {
  const { width } = entries[0].contentRect;
  redraw(width); // recalculate scales, re-render
});
ro.observe(container);

// Or viewBox approach — scales automatically with CSS
svg.attr("viewBox", `0 0 ${width} ${height}`)
   .attr("preserveAspectRatio", "xMidYMid meet")
   .style("width", "100%")
   .style("height", "auto");
```

### D3 + React Integration
```tsx
// Approach 1: D3 for math, React for DOM (preferred in React projects)
function BarChart({ data }) {
  const xScale = d3.scaleLinear().domain([0, d3.max(data, d => d.value)]).range([0, width]);
  return (
    <svg width={width} height={height}>
      {data.map(d => (
        <rect key={d.id} x={0} y={yScale(d.name)} width={xScale(d.value)} height={yScale.bandwidth()} />
      ))}
    </svg>
  );
}

// Approach 2: D3 owns the DOM — use useRef, run D3 in useEffect
function D3Chart({ data }) {
  const svgRef = useRef(null);
  useEffect(() => {
    const svg = d3.select(svgRef.current);
    // ... full D3 imperative code here
    return () => svg.selectAll("*").remove(); // cleanup
  }, [data]);
  return <svg ref={svgRef} />;
}
```
- Prefer Approach 1 in React — let React own the DOM; use D3 only for scales, shapes, and math.
- Use Approach 2 only for complex D3 graphs (force layouts, geographic projections, zoomable trees) where D3 DOM control is essential.

### Common Patterns
```js
// Line chart path
const line = d3.line()
  .x(d => xScale(d.date))
  .y(d => yScale(d.value))
  .curve(d3.curveMonotoneX); // smooth curve
svg.append("path").datum(data).attr("d", line).attr("fill", "none").attr("stroke", "#4f46e5");

// Area chart
const area = d3.area()
  .x(d => xScale(d.date))
  .y0(height - margin.bottom)
  .y1(d => yScale(d.value))
  .curve(d3.curveMonotoneX);

// Pie / Donut
const pie = d3.pie().value(d => d.value).sort(null);
const arc = d3.arc().innerRadius(60).outerRadius(100); // innerRadius > 0 = donut
const arcs = svg.selectAll("path").data(pie(data)).join("path").attr("d", arc);

// Force-directed graph
const simulation = d3.forceSimulation(nodes)
  .force("link", d3.forceLink(links).id(d => d.id).distance(80))
  .force("charge", d3.forceManyBody().strength(-300))
  .force("center", d3.forceCenter(width / 2, height / 2));
```

---

## 📊 Data Engineering

### Core Concepts
- **ELT over ETL**: load raw data first, transform in warehouse — cheaper, more flexible.
- **Idempotency**: every pipeline run must be safe to re-run — no duplicates, no data loss.
- **Immutable raw layer**: never modify raw/bronze data — always re-derive from source.
- **Data contracts**: agree on schema + SLA with data producers before building pipelines.
- **Lineage**: track where data came from and how it was transformed — essential for debugging.

### Data Architecture Layers (Medallion)
```
Bronze (Raw)    → Exact copy of source data, immutable, partitioned by ingest date
Silver (Clean)  → Validated, deduplicated, typed, standardized schemas
Gold (Curated)  → Business-ready aggregates, denormalized for query performance
```

### Pipeline Orchestration

#### Apache Airflow
```python
from airflow.decorators import dag, task
from datetime import datetime, timedelta

@dag(
    schedule="0 2 * * *",           # 2am daily
    start_date=datetime(2024, 1, 1),
    catchup=False,
    default_args={"retries": 3, "retry_delay": timedelta(minutes=5)},
    tags=["orders", "daily"],
)
def orders_pipeline():
    @task()
    def extract() -> list[dict]:
        return fetch_orders_from_api()

    @task()
    def transform(raw: list[dict]) -> list[dict]:
        return [clean_order(o) for o in raw]

    @task()
    def load(clean: list[dict]):
        bulk_insert_to_warehouse(clean)

    load(transform(extract()))

orders_pipeline()
```

- Use `@task` decorator (TaskFlow API) — cleaner than classic Operators.
- **Sensors**: wait for S3 file, DB condition, external DAG completion.
- Set `catchup=False` for most pipelines — re-runs of missed intervals cause data duplication.
- Use `pool` to limit concurrent DB connections.
- XCom for small values only (<48KB) — large data passes through storage (S3/GCS).

#### Prefect / Dagster (Modern Alternatives)
```python
# Prefect 2 — Python-native, no YAML
from prefect import flow, task

@task(retries=3, cache_key_fn=task_input_hash)
def extract_orders(date: str) -> list:
    return fetch(date)

@flow(name="orders-daily")
def orders_flow(date: str = "today"):
    raw = extract_orders(date)
    clean = transform(raw)
    load(clean)
```

### Data Transformation — dbt

```sql
-- models/orders/orders_daily.sql
{{ config(materialized='incremental', unique_key='order_date') }}

WITH source AS (
    SELECT * FROM {{ source('raw', 'orders') }}
    {% if is_incremental() %}
    WHERE created_at >= (SELECT MAX(order_date) FROM {{ this }})
    {% endif %}
),
transformed AS (
    SELECT
        DATE(created_at)        AS order_date,
        COUNT(*)                AS total_orders,
        SUM(amount)             AS revenue,
        COUNT(DISTINCT user_id) AS unique_customers
    FROM source
    GROUP BY 1
)
SELECT * FROM transformed
```

```bash
dbt run --select orders/        # run orders models
dbt test --select orders/       # test data quality
dbt docs generate && dbt docs serve   # auto-generated lineage docs
```

- **Materialization**: `table` (full refresh), `incremental` (append/merge new rows), `view` (no storage).
- **Sources**: define upstream tables; dbt tracks freshness with `dbt source freshness`.
- **Tests**: `unique`, `not_null`, `accepted_values`, `relationships` — run in CI.
- **Packages**: `dbt-utils`, `dbt-expectations` for extra test macros.

### Streaming Data

#### Apache Kafka (Producer/Consumer)
```python
# Producer
from confluent_kafka import Producer

producer = Producer({"bootstrap.servers": "kafka:9092"})
producer.produce(
    topic="orders",
    key=order_id.encode(),
    value=json.dumps(order).encode(),
    callback=delivery_report
)
producer.flush()

# Consumer (idempotent processing)
consumer = Consumer({
    "bootstrap.servers": "kafka:9092",
    "group.id": "order-processor",
    "auto.offset.reset": "earliest",
    "enable.auto.commit": False,       # manual commit after processing
})
consumer.subscribe(["orders"])
while True:
    msg = consumer.poll(1.0)
    if msg and not msg.error():
        process(msg.value())
        consumer.commit()              # only commit after successful process
```

#### Apache Flink / Spark Streaming
```python
# PySpark Structured Streaming
from pyspark.sql import SparkSession
from pyspark.sql.functions import window, count

spark = SparkSession.builder.getOrCreate()

orders = (spark.readStream
    .format("kafka")
    .option("kafka.bootstrap.servers", "kafka:9092")
    .option("subscribe", "orders")
    .load())

windowed = (orders
    .withWatermark("timestamp", "10 minutes")   # late data tolerance
    .groupBy(window("timestamp", "5 minutes"), "product_id")
    .agg(count("*").alias("order_count")))

query = (windowed.writeStream
    .format("delta")
    .outputMode("append")
    .option("checkpointLocation", "/checkpoints/orders")
    .start())
```

### Data Warehouse Patterns

#### Star Schema
```sql
-- Fact table: large, append-only, foreign keys
CREATE TABLE fact_orders (
    order_id        BIGINT,
    order_date_key  INT REFERENCES dim_date(date_key),
    customer_key    INT REFERENCES dim_customer(customer_key),
    product_key     INT REFERENCES dim_product(product_key),
    quantity        INT,
    revenue         DECIMAL(10,2)
);

-- Dimension: descriptive, slowly changing (SCD)
CREATE TABLE dim_customer (
    customer_key  SERIAL PRIMARY KEY,
    customer_id   VARCHAR,
    name          VARCHAR,
    segment       VARCHAR,
    valid_from    DATE,
    valid_to      DATE,   -- SCD Type 2: track history
    is_current    BOOLEAN
);
```

#### BigQuery / Snowflake Best Practices
```sql
-- BigQuery: partition + cluster for cost/performance
CREATE TABLE orders_partitioned
PARTITION BY DATE(created_at)
CLUSTER BY customer_id, status
AS SELECT * FROM raw_orders;

-- Avoid SELECT * — only select needed columns (columnar storage)
SELECT customer_id, SUM(revenue) FROM orders_partitioned
WHERE DATE(created_at) BETWEEN '2024-01-01' AND '2024-01-31'  -- partition pruning
GROUP BY 1;
```

### Data Quality & Testing
```python
# Great Expectations
import great_expectations as gx

context = gx.get_context()
suite = context.add_expectation_suite("orders_suite")

validator = context.get_validator(batch_request=batch_request, expectation_suite=suite)
validator.expect_column_values_to_not_be_null("order_id")
validator.expect_column_values_to_be_between("amount", min_value=0, max_value=100000)
validator.expect_column_pair_values_A_to_be_greater_than_B("delivered_at", "ordered_at")
validator.save_expectation_suite()
results = validator.validate()
```

### Feature Store (ML Engineering)
```python
# Feast feature store
from feast import FeatureStore

store = FeatureStore(repo_path=".")

# Retrieve features for training
training_df = store.get_historical_features(
    entity_df=entity_df,
    features=["user_stats:lifetime_value", "user_stats:order_count"]
).to_df()

# Real-time retrieval for inference
features = store.get_online_features(
    features=["user_stats:lifetime_value"],
    entity_rows=[{"user_id": 123}]
).to_dict()
```

---

## 🔌 Embedded Systems

### Core Principles
- **No dynamic allocation on MCU**: avoid `malloc`/`free` — fragmentation causes hard-to-debug crashes. Use static allocation or memory pools.
- **Deterministic behavior**: embedded systems must be predictable — avoid unbounded loops, use watchdog timers.
- **Resource constraints**: RAM in KB, flash in KB/MB, CPU in MHz — every byte and cycle matters.
- **Hardware abstraction**: isolate hardware-specific code in HAL (Hardware Abstraction Layer).
- **Fail safe**: hardware fails — always handle: no sensor response, corrupted data, power loss mid-write.

### C for Embedded (Best Practices)
```c
/* Use fixed-width integer types — sizes are platform-defined otherwise */
#include <stdint.h>
#include <stdbool.h>

uint8_t  sensor_val;    /* 0-255, 1 byte */
uint16_t adc_reading;   /* 0-65535, 2 bytes */
uint32_t timestamp_ms;  /* milliseconds uptime */
int32_t  temperature;   /* signed, millidegrees */

/* Volatile for hardware registers and ISR-shared variables */
volatile uint32_t tick_count = 0;

/* Bit manipulation — common in embedded */
#define LED_PIN   (1 << 5)          /* Pin 5 */
GPIOA->ODR |= LED_PIN;              /* Set high */
GPIOA->ODR &= ~LED_PIN;             /* Set low */
GPIOA->ODR ^= LED_PIN;              /* Toggle */

/* Circular buffer — ISR-safe ring buffer */
typedef struct {
    uint8_t  buf[64];
    uint8_t  head;
    uint8_t  tail;
} RingBuf;
```

### RTOS (FreeRTOS)
```c
/* Tasks — don't use bare super-loops for complex systems */
void sensor_task(void *pvParameters) {
    TickType_t xLastWakeTime = xTaskGetTickCount();
    for (;;) {
        read_sensor();
        vTaskDelayUntil(&xLastWakeTime, pdMS_TO_TICKS(100)); /* 100ms periodic */
    }
}

/* Inter-task communication via queues */
QueueHandle_t xQueue = xQueueCreate(10, sizeof(uint16_t));

/* In producer task (or ISR) */
uint16_t reading = read_adc();
xQueueSendFromISR(xQueue, &reading, &xHigherPriorityTaskWoken);

/* In consumer task */
uint16_t val;
if (xQueueReceive(xQueue, &val, portMAX_DELAY) == pdPASS) {
    process(val);
}

/* Mutex for shared resources */
SemaphoreHandle_t xMutex = xSemaphoreCreateMutex();
if (xSemaphoreTake(xMutex, pdMS_TO_TICKS(100)) == pdPASS) {
    /* access shared resource */
    xSemaphoreGive(xMutex);
}
```

### Hardware Interfaces
```c
/* I2C — for sensors (temp, IMU, OLED) */
HAL_I2C_Master_Transmit(&hi2c1, DEVICE_ADDR << 1, &reg, 1, HAL_MAX_DELAY);
HAL_I2C_Master_Receive(&hi2c1, DEVICE_ADDR << 1, data, 2, HAL_MAX_DELAY);

/* SPI — for fast peripherals (displays, flash) */
HAL_GPIO_WritePin(CS_GPIO, CS_PIN, GPIO_PIN_RESET);  /* CS low */
HAL_SPI_TransmitReceive(&hspi1, tx_buf, rx_buf, len, HAL_MAX_DELAY);
HAL_GPIO_WritePin(CS_GPIO, CS_PIN, GPIO_PIN_SET);    /* CS high */

/* UART — for debug, GPS, BLE modules */
HAL_UART_Transmit(&huart2, (uint8_t*)"Hello\r\n", 7, HAL_MAX_DELAY);

/* ADC — analog sensors */
HAL_ADC_Start(&hadc1);
HAL_ADC_PollForConversion(&hadc1, HAL_MAX_DELAY);
uint32_t val = HAL_ADC_GetValue(&hadc1);

/* PWM — motors, LEDs */
HAL_TIM_PWM_Start(&htim3, TIM_CHANNEL_1);
__HAL_TIM_SET_COMPARE(&htim3, TIM_CHANNEL_1, duty_cycle);  /* 0–ARR */
```

### Arduino / ESP32 (Rapid Prototyping)
```cpp
// ESP32 + FreeRTOS tasks
void wifi_task(void *param) {
    WiFi.begin(SSID, PASSWORD);
    while (WiFi.status() != WL_CONNECTED) { delay(500); }
    for (;;) {
        send_telemetry();
        vTaskDelay(pdMS_TO_TICKS(5000));
    }
}

void setup() {
    xTaskCreatePinnedToCore(wifi_task, "WiFi", 4096, NULL, 1, NULL, 0);  /* Core 0 */
    xTaskCreatePinnedToCore(sensor_task, "Sensor", 2048, NULL, 2, NULL, 1); /* Core 1 */
}
```

### Power Management
```c
/* STM32 low-power modes */
HAL_PWR_EnterSLEEPMode(PWR_MAINREGULATOR_ON, PWR_SLEEPENTRY_WFI);  /* light sleep */
HAL_PWR_EnterSTOPMode(PWR_LOWPOWERREGULATOR_ON, PWR_STOPENTRY_WFI); /* deep sleep */
HAL_PWR_EnterSTANDBYMode();   /* lowest power, RAM lost */

/* Wake sources: RTC alarm, GPIO interrupt, UART */
/* Design for: measure → sleep → wake → transmit → sleep (duty cycling) */
```

### OTA Firmware Update
```c
/* ESP32 OTA via HTTPS */
esp_https_ota_config_t config = {
    .http_config = &http_config,
    .partial_http_download = true,
    .max_http_request_size = 4096,
};
esp_err_t ret = esp_https_ota(&config);
if (ret == ESP_OK) esp_restart();
```

### Debugging Embedded Systems
```bash
# OpenOCD + GDB for ARM Cortex-M
openocd -f interface/stlink.cfg -f target/stm32f4x.cfg &
arm-none-eabi-gdb firmware.elf
(gdb) target remote :3333
(gdb) monitor reset halt
(gdb) load                    # flash firmware
(gdb) break main
(gdb) continue

# Logic analyzer (sigrok/PulseView)
sigrok-cli -d fx2lafw --config samplerate=1m --samples 1m \
  --channels D0,D1 --triggers D0=r > capture.sr

# Serial debug output
screen /dev/ttyUSB0 115200
picocom -b 115200 /dev/ttyUSB0
```

### MISRA C (Safety-Critical)
- Mandatory in automotive (AUTOSAR), medical, aerospace.
- Key rules: no dynamic memory, no recursion, all switch cases have default, no `goto`.
- Static analysis: **PC-lint**, **Polyspace**, **Parasoft C/C++test**.
- For hobbyist/IoT: follow spirit — initialize all variables, check return values, avoid UB.

---

## 🎮 Game Development

### Game Loop Architecture
```ts
// Fixed timestep game loop — physics runs at constant rate
let accumulator = 0;
const FIXED_DT = 1000 / 60;  // 60 physics updates/sec

function gameLoop(timestamp: number) {
    const frameTime = Math.min(timestamp - lastTime, 250);  // cap at 250ms (tab unfocus)
    lastTime = timestamp;
    accumulator += frameTime;

    while (accumulator >= FIXED_DT) {
        update(FIXED_DT);        // physics/game logic — fixed step
        accumulator -= FIXED_DT;
    }

    const alpha = accumulator / FIXED_DT;  // interpolation factor
    render(alpha);               // render between states for smooth visuals

    requestAnimationFrame(gameLoop);
}
```

### Entity Component System (ECS)
```ts
// ECS separates data (components) from logic (systems)
// Entities are just IDs; components are plain data; systems operate on components

// Components — pure data, no logic
interface Position { x: number; y: number; }
interface Velocity { dx: number; dy: number; }
interface Health   { current: number; max: number; }

// System — operates on all entities with matching components
function movementSystem(world: World, dt: number) {
    for (const [entity, [pos, vel]] of world.query<[Position, Velocity]>()) {
        pos.x += vel.dx * dt;
        pos.y += vel.dy * dt;
    }
}

// Entity is just an ID
const player = world.createEntity();
world.addComponent(player, Position, { x: 0, y: 0 });
world.addComponent(player, Velocity, { dx: 1, dy: 0 });
world.addComponent(player, Health,   { current: 100, max: 100 });
```

### Unity (C#) — Key Patterns
```csharp
// MonoBehaviour lifecycle
public class Player : MonoBehaviour {
    [SerializeField] private float speed = 5f;
    private Rigidbody2D rb;

    void Awake() { rb = GetComponent<Rigidbody2D>(); }  // init refs

    void Update() {            // every frame — input, animation
        float x = Input.GetAxis("Horizontal");
        float y = Input.GetAxis("Vertical");
        rb.velocity = new Vector2(x, y) * speed;
    }

    void FixedUpdate() { }     // fixed timestep — physics

    void OnTriggerEnter2D(Collider2D other) {
        if (other.CompareTag("Enemy")) TakeDamage(10);
    }
}

// Object pooling — reuse instead of Instantiate/Destroy
public class BulletPool : MonoBehaviour {
    private Queue<GameObject> pool = new();

    public GameObject Get() {
        if (pool.Count > 0) {
            var obj = pool.Dequeue();
            obj.SetActive(true);
            return obj;
        }
        return Instantiate(prefab);
    }

    public void Return(GameObject obj) {
        obj.SetActive(false);
        pool.Enqueue(obj);
    }
}
```

### Unreal Engine (C++) — Key Patterns
```cpp
// Actor lifecycle
UCLASS()
class AMyActor : public AActor {
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Stats")
    float Health = 100.0f;

protected:
    virtual void BeginPlay() override;  // game start
    virtual void Tick(float DeltaTime) override;

public:
    UFUNCTION(BlueprintCallable)
    void TakeDamage(float Amount);
};

// Gameplay Ability System (GAS) for complex games
// GameplayTags for flexible state management (not enums)
// Replication: UPROPERTY(Replicated) for networked properties
```

### Game AI

#### Finite State Machine
```ts
enum EnemyState { Idle, Patrol, Chase, Attack, Flee }

class EnemyAI {
    state = EnemyState.Idle;

    update(dt: number, distToPlayer: number) {
        switch (this.state) {
            case EnemyState.Idle:
                if (distToPlayer < ALERT_RANGE) this.state = EnemyState.Chase;
                break;
            case EnemyState.Chase:
                if (distToPlayer < ATTACK_RANGE) this.state = EnemyState.Attack;
                if (distToPlayer > LOSE_RANGE)   this.state = EnemyState.Patrol;
                break;
            case EnemyState.Attack:
                this.attack();
                if (this.health < 20) this.state = EnemyState.Flee;
                break;
        }
    }
}
```

#### Behavior Trees
```
Root
└── Selector (?)           ← first succeeding child wins
    ├── Sequence (→)       ← all must succeed (attack)
    │   ├── IsPlayerVisible
    │   ├── IsInRange
    │   └── AttackPlayer
    └── Sequence (→)       ← fallback (patrol)
        ├── HasPatrolPath
        └── MoveToNextWaypoint
```

#### Pathfinding (A*)
```ts
function aStar(start: Node, goal: Node, grid: Grid): Node[] {
    const open = new PriorityQueue<Node>();
    const gScore = new Map([[start, 0]]);
    const fScore = new Map([[start, heuristic(start, goal)]]);
    open.push(start, fScore.get(start)!);

    while (!open.isEmpty()) {
        const current = open.pop();
        if (current === goal) return reconstructPath(current);

        for (const neighbor of grid.neighbors(current)) {
            const tentativeG = gScore.get(current)! + cost(current, neighbor);
            if (tentativeG < (gScore.get(neighbor) ?? Infinity)) {
                gScore.set(neighbor, tentativeG);
                fScore.set(neighbor, tentativeG + heuristic(neighbor, goal));
                open.push(neighbor, fScore.get(neighbor)!);
            }
        }
    }
    return [];  // no path
}
```

### Multiplayer Networking
```ts
// Authoritative server model — server is truth, clients predict
// Client-side prediction: apply input locally immediately
// Server reconciliation: receive server state, correct if diverged
// Entity interpolation: smooth rendering between server updates

// Netcode patterns:
// Lockstep: all clients simulate same state — works for RTS
// Client-side prediction + rollback: modern FPS/fighting games
// Dead reckoning: extrapolate position for lag hiding

// WebSocket game server (Node.js)
const io = new Server(httpServer);
io.on("connection", (socket) => {
    socket.on("playerInput", (input: Input) => {
        const player = gameState.players.get(socket.id);
        applyInput(player, input);           // server authoritative update
        io.emit("gameState", gameState.serialize()); // broadcast to all
    });
});
```

### Shader Basics (GLSL/WGSL)
```glsl
/* Vertex shader — transform vertices */
attribute vec3 position;
attribute vec2 uv;
uniform mat4 modelViewProjection;
varying vec2 vUv;

void main() {
    vUv = uv;
    gl_Position = modelViewProjection * vec4(position, 1.0);
}

/* Fragment shader — color each pixel */
uniform sampler2D diffuseMap;
uniform float time;
varying vec2 vUv;

void main() {
    vec2 animated = vUv + vec2(sin(time * 0.5) * 0.01, 0.0);  /* UV scroll */
    gl_FragColor = texture2D(diffuseMap, animated);
}
```

### Game Performance Optimization
- **Draw calls**: minimize — batch same-material objects; use GPU instancing for repeated meshes.
- **Object pooling**: never `Instantiate`/`Destroy` per frame — pool bullets, particles, enemies.
- **LOD (Level of Detail)**: swap high-poly mesh to low-poly at distance — automatic in Unreal/Unity.
- **Occlusion culling**: don't render what the camera can't see — Unity Occlusion Baking, Unreal HLOD.
- **Profiling**: Unity Profiler / Unreal Insights — fix hotspots, don't guess.
- **Physics layers**: only check collisions between relevant layers — reduces broadphase cost.
- **Coroutines/async for non-gameplay work**: don't block game loop for file I/O, network, save.

---

## 🤖 Claude Code Skills

### What Claude Code Can Do
- Read, write, edit, and refactor files across the entire codebase.
- Run terminal commands: build, test, lint, migrate, deploy scripts.
- Search codebase: `grep`, `find`, `ripgrep` for pattern discovery.
- Install packages, run servers, execute scripts.
- Multi-step agentic tasks: plan → execute → verify → iterate.

### How to Work With Claude Code Effectively
- **Be specific about scope**: "refactor the auth module" is better than "improve the code".
- **Give context**: mention the framework, version, and constraints upfront.
- **Confirm before destructive ops**: Claude will always ask — never skip confirmation dialogs.
- **Use `/clear`** to reset context when switching to an unrelated task.
- **Use `/compact`** on long sessions to compress history and free context.
- **Reference files explicitly**: "look at `src/lib/auth.ts`" beats "look at the auth file".

### Claude Code Commands Reference
```bash
claude                          # start interactive session
claude "fix the TypeScript errors in src/api/"  # one-shot task
claude --continue               # resume last session
claude --print "explain this codebase"  # non-interactive output

# In-session slash commands
/help                           # list all commands
/clear                          # clear conversation history
/compact                        # summarize + compress context
/memory                         # view/edit CLAUDE.md instructions
/cost                           # show token usage for session
/doctor                         # check Claude Code health
/model                          # switch model mid-session
/allowed-tools                  # see what tools are enabled
/diff                           # show pending file changes
```

### CLAUDE.md Best Practices
- Global `~/.claude/CLAUDE.md` → personal standards, applies everywhere.
- Project `./CLAUDE.md` → project-specific overrides (stack, commands, structure).
- Keep instructions actionable and specific — vague rules are ignored.
- Update `CLAUDE.md` when you make architectural decisions — it's living documentation.
- Use headings to organize — Claude Code parses structure.

### Agentic Task Patterns
```bash
# Code review
claude "review src/api/payments.ts for security issues and suggest fixes"

# Refactoring
claude "refactor the UserService class to use dependency injection, run tests after"

# Debugging
claude "the /api/checkout endpoint returns 500 intermittently, investigate and fix"

# Feature implementation
claude "implement pagination on the /api/posts endpoint, add tests, update API docs"

# Database
claude "write a migration to add soft deletes to the users table"
```

---

## 🤖 AI Vibe Code Developer

### Mindset
- AI is a **senior pair programmer** — brief it like one: give context, constraints, and the "why".
- You own the output — never ship AI-generated code you don't fully understand.
- Iterate fast: small → working → review → expand. Don't ask for 500 lines in one shot.
- AI excels at: boilerplate, patterns, refactoring, test generation, documentation. You own: architecture, business logic decisions, security review.
- **Vibe coding**: stay in flow — let AI handle syntax/ceremony, you handle intent and review.

### Effective Prompting for Code
- Always give: **what** (goal), **where** (file/function), **constraints** (framework, style, must not break X).
- Bad: "add auth". Good: "add JWT auth to `src/api/users.ts` using `@nestjs/passport`, follow existing service patterns, don't change the DB schema".
- Include error messages verbatim — AI can't guess what the error says.
- Reference existing patterns: "follow the pattern in `users.service.ts`".
- Specify output format: "edit only the file, no explanations, no new dependencies".
- For complex tasks: ask for a **plan first**, approve it, then execute step by step.

### AI-Assisted Development Phases

#### Planning
```
"I'm building X. My constraints are Y. What are the main architectural risks?
Give me a 5-step implementation plan, starting with the riskiest part."
```
- Use AI to stress-test your approach before writing code.
- Ask for alternatives: "what's wrong with my current plan?" or "what would you do differently?"

#### Implementation
- One feature/fix per conversation — don't let context drift.
- Commit working code before starting the next feature — gives you a restore point.
- If AI goes in wrong direction: stop, `/clear`, re-brief with corrected constraints.
- Use `@filename` references to give AI exact context — don't describe the code, show it.

#### Review & Verification
- After every AI edit: read the diff yourself before running it.
- Ask AI to review its own output: "what edge cases does this miss?" or "what could go wrong here?"
- Run tests after every change — never assume AI edits are regression-free.
- Security-sensitive code: always run `/security-review` before merging.

#### Debugging with AI
- Paste the full error + stack trace + relevant code — not paraphrases.
- Give reproduction steps: "this fails when I call `POST /users` with `{email: null}`".
- Share what you already tried — prevents AI suggesting things you've ruled out.
- If AI fix doesn't work: say exactly what happened, don't re-ask the same question.

### Multi-Agent Patterns
- Spawn subagents for **independent** research (Explore agent) — keeps main context clean.
- Use Plan mode for complex multi-step tasks — get alignment before execution.
- Background agents for long-running tasks (CI checks, test runs) — don't block main thread.
- Worktree isolation for risky changes — changes in isolated branch, main checkout untouched.

### Knowing When NOT to Use AI
- **Security-critical code**: crypto implementations, auth flows — write manually, AI-assist only for review.
- **Performance-critical hot paths**: AI often writes correct but not optimal code — profile and verify.
- **When you don't understand the domain**: learn first, then let AI help implement.
- **Ambiguous requirements**: clarify with humans before asking AI to build it.

### AI Code Quality Checklist
- [ ] Do I understand every line of the generated code?
- [ ] Are there no hardcoded secrets, test data, or debug logs?
- [ ] Does it handle errors properly (not just happy path)?
- [ ] Are edge cases covered (null, empty, large input, concurrent access)?
- [ ] Does it follow the existing project patterns?
- [ ] Have tests been added or updated?
- [ ] Has `/security-review` been run on auth/data-handling changes?

---

## 🧹 Vibe Coding Cleanup Specialist

### The Role & The Controversy

**Vibe coding** = using AI to generate large amounts of code rapidly, prioritizing speed and working output over code quality, security, maintainability, or understanding. The result ships — but leaves a technical landmine.

The **Vibe Coding Cleanup Specialist** (also called AI Code Auditor, LLM Output Engineer, or AI Tech Debt Remediator) is an emerging role focused on taking AI-generated codebases and bringing them to production-grade standards.

**Why it's controversial:**
- Some engineers see it as glorifying bad practice — "just write it right the first time"
- Others argue AI-generated code is no worse than rushed junior code, which has always needed review
- Companies love the cost narrative: fast AI generation + cheap cleanup vs. slow careful engineering
- Senior engineers resent being cleanup crews for AI output they consider fundamentally broken
- Startups counter: shipping fast and cleaning up later is how every successful startup worked
- There's genuine debate about whether cleanup specialists enable or discourage responsible AI use

**The reality:** The role exists, the demand is real, and understanding how to do it well is valuable regardless of where you stand on the controversy.

---

### Recognising Vibe-Coded Code

Before cleaning, identify it. Vibe-coded code has consistent fingerprints:

#### Structural Tells
```
✦ Massive functions (200+ lines) that do 5 different things
✦ Deeply nested callbacks or conditionals (6+ levels)
✦ Inconsistent naming: camelCase + snake_case + PascalCase in the same file
✦ Duplicated logic copied rather than extracted
✦ Files that are too long (1000+ lines) — AI doesn't split naturally
✦ No separation of concerns: HTTP handling + business logic + DB access in one function
✦ Comments describing what the code does (AI wrote them), not why
✦ Generated boilerplate left in: TODO comments, placeholder strings, "example.com" URLs
✦ Imports of packages that aren't actually used anywhere
✦ Both old and new patterns side by side (AI continued from both directions)
```

#### Logic & Safety Tells
```
✦ Missing authentication checks on routes — AI assumed auth was "elsewhere"
✦ No input validation: req.body.email used directly in a query
✦ Error handling is console.log then continue — no propagation
✦ Hardcoded secrets, localhost URLs, or test credentials
✦ Race conditions: shared state mutated inside async loops
✦ N+1 queries: DB call inside a loop with no batching
✦ No pagination on endpoints that return potentially unbounded data
✦ SQL queries built with string concatenation (injection risk)
✦ Promise rejections swallowed: .catch(() => {}) with empty handler
✦ Memory leaks: event listeners or timers never cleaned up
```

#### Dependency Tells
```
✦ package.json with 50+ dependencies for a simple CRUD app
✦ Multiple libraries doing the same job (axios + fetch + got all imported)
✦ Packages that don't exist on npm (hallucinated imports)
✦ Outdated packages — AI training data has a cutoff, so it recommends old versions
✦ Dev dependencies in production dependencies or vice versa
✦ No lockfile, or lockfile not committed
```

---

### Cleanup Methodology — The 5-Phase Process

#### Phase 1: Triage (Don't Touch Yet)
```bash
# Get a full picture before changing anything
git log --oneline -20           # understand commit history
wc -l **/*.ts                   # find largest files
find . -name "*.ts" | xargs grep -l "console.log" | wc -l  # log hygiene
grep -r "TODO\|FIXME\|HACK\|XXX" src/ --include="*.ts"      # debt markers
grep -r "any" src/ --include="*.ts" | wc -l                  # TypeScript holes

# Check what's actually broken
pnpm test 2>&1 | tail -30       # test status
pnpm lint 2>&1 | head -50       # lint violations
npx tsc --noEmit 2>&1 | wc -l  # type errors

# Security quick scan
npx audit 2>&1
gitleaks detect --source .
grep -r "password\|secret\|api_key\|token" src/ --include="*.ts" -i | grep -v "test\|spec\|mock"
```

**Produce a triage report before writing a single line:**
```markdown
## Triage Report — [Project Name] — [Date]

### Scale
- Files: X | Lines: X | Test coverage: X%

### Critical (Fix before any deployment)
- [ ] Hardcoded API key in src/config.ts:12
- [ ] SQL injection in src/routes/users.ts:45
- [ ] No auth check on DELETE /api/users/:id

### High (Fix this sprint)
- [ ] 0 tests on payment processing logic
- [ ] N+1 query in OrderService.getAll() — 50 DB calls per request
- [ ] Uncaught promise rejections in 12 files

### Medium (Fix next sprint)
- [ ] 847 TypeScript `any` casts
- [ ] No error handling on 3rd party API calls
- [ ] Duplicated user validation logic in 4 places

### Low (Ongoing)
- [ ] Inconsistent naming conventions
- [ ] Unused imports in 23 files
- [ ] No JSDoc on public APIs

### Estimated cleanup effort: X sprints
```

#### Phase 2: Safety Net First (Tests Before Refactoring)
```
Rule: Never refactor code that has no tests.
      Write characterization tests first to capture current behavior,
      then refactor with confidence.
```

```ts
// Characterization test — document what code DOES (not what it SHOULD do)
// Write these before you understand the code fully
describe("OrderService.calculateTotal (characterization)", () => {
  it("returns 0 for empty cart", async () => {
    const result = await orderService.calculateTotal([]);
    expect(result).toBe(0);  // capture current behavior
  });

  it("applies discount code before tax (discovered behavior)", async () => {
    // found by running the code — may or may not be the intended order
    const result = await orderService.calculateTotal([item], "SAVE10");
    expect(result).toBe(90.00);  // snapshot the current output
  });
});
```

**Characterization test goal:** If you run the tests before cleanup and after cleanup, they should all still pass. If one fails, your refactor changed behavior — investigate.

#### Phase 3: Security Cleanup (Highest Priority)

```ts
// Pattern: find and fix injection vulnerabilities

// ❌ Vibe-coded — SQL injection
async function getUser(email: string) {
  return db.query(`SELECT * FROM users WHERE email = '${email}'`);
}

// ✅ Fixed — parameterized query
async function getUser(email: string) {
  return db.query("SELECT * FROM users WHERE email = $1", [email]);
}

// ❌ Vibe-coded — missing auth
app.delete("/api/users/:id", async (req, res) => {
  await db.user.delete({ where: { id: req.params.id } });
  res.json({ deleted: true });
});

// ✅ Fixed — auth + authorization + ownership check
app.delete("/api/users/:id", authenticate, async (req, res) => {
  if (req.user.id !== req.params.id && req.user.role !== "admin") {
    return res.status(403).json({ error: "Forbidden" });
  }
  await db.user.delete({ where: { id: req.params.id } });
  res.status(204).send();
});

// ❌ Vibe-coded — hardcoded secrets
const stripe = new Stripe("sk_live_abc123real_key_here");

// ✅ Fixed — environment variable with validation
if (!process.env.STRIPE_SECRET_KEY) throw new Error("STRIPE_SECRET_KEY is required");
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);
```

**Security cleanup checklist:**
```
□ All secrets moved to environment variables + .env.example created
□ All SQL / NoSQL queries parameterized
□ Input validation added at every API boundary (Zod/yup)
□ Auth middleware applied to every protected route
□ Authorization (not just authentication) checked on each operation
□ File upload endpoints validate type, size, and store outside webroot
□ Error responses scrubbed of stack traces / internal info
□ Dependencies audited: npm audit --audit-level=high
□ Secrets scan run: gitleaks detect --source .
□ If secrets were committed: rotate them immediately + rewrite git history
```

#### Phase 4: Structural Cleanup (Refactoring)

**Extract and organize — follow the Strangler Fig pattern for large refactors:**

```ts
// ❌ Vibe-coded — 200-line function doing everything
export async function handleCheckout(req, res) {
  // validate cart (40 lines)
  // check inventory (30 lines)
  // apply discounts (25 lines)
  // calculate tax (20 lines)
  // charge card (30 lines)
  // create order (25 lines)
  // send confirmation email (20 lines)
  // update inventory (15 lines)
}

// ✅ Cleaned — each concern is its own function/service
export async function handleCheckout(req: Request, res: Response) {
  const cart = CartValidator.parse(req.body);           // throws on invalid
  await InventoryService.reserve(cart.items);
  const pricing = PricingEngine.calculate(cart);
  const payment = await PaymentService.charge(pricing.total, cart.paymentMethod);
  const order = await OrderService.create({ cart, pricing, payment });
  await NotificationService.sendOrderConfirmation(order);
  res.status(201).json(order);
}
```

**Deduplication — find and consolidate:**
```bash
# Find duplicated validation logic
grep -r "isValidEmail\|validateEmail\|email.*regex" src/ --include="*.ts" -l

# Find copy-pasted blocks (jscpd)
npx jscpd src/ --min-lines 10 --reporters console
```

```ts
// ❌ Vibe-coded — same validation in 4 places
// users.ts:     if (!email.includes("@")) throw new Error("invalid email")
// auth.ts:      if (!email.match(/.*@.*/)) return false
// profile.ts:   email.split("@").length === 2  // bad regex
// signup.ts:    z.string().email()              // correct but not shared

// ✅ Cleaned — one shared validator
// src/lib/validators.ts
export const emailSchema = z.string().email("Invalid email address");
export const validateEmail = (email: string) => emailSchema.parse(email);
// imported everywhere else
```

**Fix N+1 queries:**
```ts
// ❌ Vibe-coded — 1 query per post (N+1)
async function getPosts() {
  const posts = await db.post.findMany();
  for (const post of posts) {
    post.author = await db.user.findUnique({ where: { id: post.authorId } });
    post.tags = await db.tag.findMany({ where: { postId: post.id } });
  }
  return posts;
}

// ✅ Fixed — one query with eager loading
async function getPosts() {
  return db.post.findMany({
    include: { author: true, tags: true },
  });
}
```

**Add proper error handling:**
```ts
// ❌ Vibe-coded — silent failures
async function sendWelcomeEmail(userId: string) {
  try {
    await emailService.send(userId);
  } catch (e) {
    console.log("email failed");  // swallowed — no retry, no alert
  }
}

// ✅ Fixed — explicit handling with retry + alerting
async function sendWelcomeEmail(userId: string) {
  try {
    await withRetry(() => emailService.send(userId), { attempts: 3, delay: 1000 });
  } catch (err) {
    logger.error({ userId, err }, "Welcome email failed after 3 attempts");
    await alerting.notify("email-failures", { userId, err });
    // don't rethrow — non-critical; user still created successfully
  }
}
```

#### Phase 5: Hardening (Production-Readiness)

```ts
// Add rate limiting (probably missing)
import rateLimit from "express-rate-limit";
app.use("/api/", rateLimit({ windowMs: 15 * 60 * 1000, max: 100 }));
app.use("/api/auth/", rateLimit({ windowMs: 15 * 60 * 1000, max: 10 }));

// Add request validation middleware (probably missing)
app.use(express.json({ limit: "10kb" }));  // prevent large payload attacks

// Add security headers (probably missing)
import helmet from "helmet";
app.use(helmet());

// Add health check (definitely missing)
app.get("/health", async (req, res) => {
  const db = await checkDatabaseConnection();
  res.json({ status: db ? "ok" : "degraded", timestamp: new Date().toISOString() });
});

// Add graceful shutdown (missing)
process.on("SIGTERM", async () => {
  server.close(async () => {
    await db.$disconnect();
    process.exit(0);
  });
});
```

---

### Common Vibe-Code Anti-Patterns & Fixes

| Anti-Pattern | Why It Happens | Fix |
|---|---|---|
| `any` everywhere in TypeScript | AI avoids type errors by casting | Replace with real types; use `unknown` + type guards |
| `console.log` as error handling | AI demos use print debugging | Replace with structured logger (pino/winston) |
| No `.env.example` | AI doesn't think about onboarding | Create `.env.example` with all required vars documented |
| Missing `await` on async calls | AI misses async chains under pressure | `tsc --noEmit` + `@typescript-eslint/no-floating-promises` |
| Returning sensitive data in API responses | AI returns full model objects | Use DTOs / response transformers; strip password, tokens |
| Pagination missing | AI writes simple `findAll()` | Add cursor or offset pagination on all list endpoints |
| No DB transactions | AI treats multi-step ops as atomic | Wrap related mutations in `db.$transaction()` |
| Magic numbers/strings | AI hardcodes values | Extract to named constants or config |
| Circular dependencies | AI imports freely | Run `madge --circular src/` and fix |
| Missing `Content-Type` validation | AI assumes well-formed requests | Validate `req.is("application/json")` |

---

### Tooling for Vibe Code Cleanup

#### Code Analysis
```bash
# TypeScript — find all the any's and errors
npx tsc --noEmit 2>&1 | grep "error TS" | wc -l
npx ts-prune              # find unused exports

# ESLint — vibe-code specific rules
# Add to .eslintrc:
# "@typescript-eslint/no-explicit-any": "error"
# "@typescript-eslint/no-floating-promises": "error"
# "no-console": ["warn", { "allow": ["error"] }]
# "no-unused-vars": "error"

# Complexity analysis
npx complexity-report src/ --max-cyclomatic 10

# Dead code detection
npx knip                  # finds unused files, deps, exports

# Duplicate code detection
npx jscpd src/ --min-lines 8

# Circular dependency detection
npx madge --circular src/ --extensions ts
```

#### Security Scanning
```bash
gitleaks detect --source . --exit-code 1       # secrets in code
semgrep --config=p/owasp-top-ten src/          # OWASP issues
npx audit --audit-level=high                   # CVE dependencies
snyk test                                       # advanced CVE + license scan
```

#### Dependency Cleanup
```bash
# Find unused dependencies
npx depcheck

# Find packages with known issues
npm audit --json | jq '.vulnerabilities | keys[]'

# Check if imported package actually exists
# (catches hallucinated packages from AI)
cat package.json | jq '.dependencies | keys[]' | xargs -I {} sh -c 'node -e "require(\"{}\")" 2>&1 | grep -q "Cannot find" && echo "MISSING: {}"'

# Find duplicate packages (different versions of same lib)
npm ls --json | npx npm-duplicate-packages
```

---

### The Cleanup Specialist's Conversation with the AI

When using AI (Claude Code) to help clean up AI-generated code:

```
Effective prompts for cleanup work:

"Review src/api/users.ts for security vulnerabilities. Focus on:
auth checks, input validation, SQL injection, and data exposure.
For each issue: show the vulnerable code, explain the risk, show the fix."

"This function is 200 lines long and does too much. Extract it into
separate functions. Keep the same external behavior — don't change logic,
just organize. Add types for all parameters and return values."

"Find all places in src/ where we're swallowing errors (empty catch blocks
or console.log only). List each location with the file:line and suggest
proper error handling for each case."

"Audit package.json for: unused dependencies, duplicated functionality,
packages that should be devDependencies, and packages with high CVEs.
Show me what to remove and why."

"Write characterization tests for OrderService.calculateTotal() before
I refactor it. Tests should capture current behavior exactly, including
edge cases you can infer from the code."
```

---

### Prioritisation Framework

When the cleanup backlog is overwhelming, use this priority matrix:

```
IMPACT vs EFFORT matrix:

High Impact, Low Effort (DO FIRST):
  → Fix SQL injection / auth holes
  → Move hardcoded secrets to env vars
  → Add request validation (Zod) to top-traffic endpoints
  → Fix N+1 queries on slow endpoints

High Impact, High Effort (PLAN & SCHEDULE):
  → Add test coverage to critical business logic
  → Refactor monolithic services into domain modules
  → Implement proper error handling throughout
  → TypeScript strict mode + remove all `any`

Low Impact, Low Effort (FILL TIME):
  → Fix naming inconsistencies
  → Remove unused imports
  → Add JSDoc to public functions
  → Consolidate duplicate validation

Low Impact, High Effort (DEFER OR DROP):
  → Rewrite working code in a "better" pattern
  → Change ORM when current one works
  → Perfect test coverage on non-critical code
  → Architectural purism over shipping velocity
```

---

### Communicating with Stakeholders

The cleanup specialist often has to justify time spent not shipping features:

```markdown
## How to frame cleanup work in business terms:

SECURITY issues → "This is a data breach waiting to happen.
  If exploited: [specific consequence]. Cost to fix now: X hours.
  Cost after breach: legal fees + compliance + reputation + customer loss."

PERFORMANCE issues → "The /orders endpoint makes 50 DB queries per request.
  At 100 concurrent users, our DB is receiving 5,000 queries/second.
  Fix: 4 hours. Payoff: can handle 10× traffic without scaling DB."

TEST COVERAGE → "We have 0 tests on payment logic. Every deploy is a gamble.
  Adding tests: 2 days. Prevented incidents: we've had 3 payment bugs in 2 months
  costing X hours of incident response each."

TECH DEBT generally → "We're paying 20% interest on every feature — it takes
  longer to add new things because the codebase fights us. This cleanup
  removes that interest charge."

What NOT to say:
  ❌ "The code is messy and it bothers me"
  ❌ "This isn't how you're supposed to do it"
  ❌ "The AI wrote bad code"  (blame-y, doesn't drive action)
  ✅ Always connect to business outcome: risk, cost, speed, reliability
```

---

### Cleanup Metrics — Proving Progress

Track these to show value over time:

```bash
# Baseline these before starting, track weekly
echo "TypeScript errors:  $(npx tsc --noEmit 2>&1 | grep -c 'error TS')"
echo "ESLint violations:  $(pnpm lint 2>&1 | grep -c 'error\|warning')"
echo "Test coverage:      $(pnpm test --coverage 2>&1 | grep 'All files' | awk '{print $10}')"
echo "any casts:          $(grep -r ': any' src/ --include='*.ts' | wc -l)"
echo "Console.logs:       $(grep -r 'console.log' src/ --include='*.ts' | wc -l)"
echo "TODO/FIXME:         $(grep -r 'TODO\|FIXME' src/ --include='*.ts' | wc -l)"
echo "Unused deps:        $(npx depcheck 2>&1 | grep -c 'Unused')"
echo "Audit issues:       $(npm audit --json 2>&1 | jq '.metadata.vulnerabilities.high + .metadata.vulnerabilities.critical')"
```

**Weekly report format:**
```
Week of 2024-01-22 — Cleanup Progress

Metric              | Baseline | This Week | Change
--------------------|----------|-----------|--------
TypeScript errors   |   847    |    612    |  -235 ✅
Test coverage       |    4%    |    23%    |  +19% ✅
Critical CVEs       |     6    |      1    |   -5  ✅
console.logs        |   203    |    156    |  -47  ✅
any casts           |   1,203  |  1,198    |   -5  ➡️ (slow)
ESLint violations   |   2,841  |  1,102    | -1739 ✅
```

---

### When to Rewrite vs. Clean Up

The hardest decision in this role:

```
Rewrite signals (consider starting fresh):
  ✦ Core logic is fundamentally wrong (not just messy)
  ✦ Security model is baked into architecture (can't patch routes)
  ✦ No tests AND no one understands the code AND frequent bugs
  ✦ Cleanup effort > rewrite effort (run the numbers)
  ✦ Blocking all new feature development

Clean up signals (incrementally improve):
  ✦ Code works, just messy
  ✦ Users depend on current behavior (even undocumented quirks)
  ✦ Team understands the domain, just not the code
  ✦ Rewrite risk > cleanup risk
  ✦ Can ship cleanup in incremental PRs

Middle path (strangler fig):
  ✦ Build new modules alongside old ones
  ✦ Route new traffic to new code
  ✦ Migrate old data/logic gradually
  ✦ Delete old code when new covers everything
  ✦ Each incremental step is independently deployable
```

---

## 🧠 Token & Context Management (Claude Code)

### Understanding Context
- Claude Code has a context window — everything in the conversation (code, tool outputs, messages) consumes tokens.
- **Longer context = slower + more expensive** — keep context focused on the current task.
- When context fills: Claude auto-compacts (summarizes history). You can trigger manually with `/compact`.
- Each `/compact` loses fine-grained history — use before context is 80%+ full, not after.

### Context Strategies

#### Keep Context Focused
- `/clear` when switching to a completely unrelated task — don't carry dead context.
- One task per session for complex features; use `/compact` mid-session for long tasks.
- Don't paste entire files when a function or section suffices — use `file.ts:45-90` references.
- Remove noise: if you pasted a 500-line file to find one function, `/compact` after finding it.

#### CLAUDE.md as Persistent Context
- What goes in `CLAUDE.md`: conventions, architecture decisions, stack choices, off-limits ops.
- What does NOT go in `CLAUDE.md`: task-specific state, WIP notes, debug logs — these belong in conversation.
- Keep project `CLAUDE.md` under ~200 lines — long files dilute signal.
- Update project `CLAUDE.md` when you make architectural decisions: "we use Zustand not Redux because..."

#### .claudeignore — Exclude Noise from Context
Create `.claudeignore` in project root to prevent Claude from reading noisy directories:
```
# .claudeignore
node_modules/
.next/
dist/
build/
coverage/
*.min.js
*.map
**/*.lock
**/__pycache__/
.venv/
*.pyc
```
Follows `.gitignore` syntax. Critical for large monorepos — prevents Claude reading 10k irrelevant files.

#### Chunking Large Tasks
- Break work into **phases** — complete and verify each before starting next.
- Commit at the end of each phase — gives Claude a clean checkpoint.
- Describe the full plan upfront, then say "let's start with phase 1 only".
- After each phase: `/compact` if context is heavy, then brief the next phase fresh.

### Token-Efficient Patterns

#### Referencing Code
```
# ❌ Paste whole file
# ✅ Reference specific location
"Look at src/services/auth.service.ts lines 45-80 — the validateToken function"

# ❌ Describe vaguely
"The auth service has some validation logic somewhere"
# ✅ Be precise
"@src/services/auth.service.ts — specifically the refreshToken method"
```

#### Task Scoping
```
# ❌ Open-ended (Claude reads everything)
"Refactor the codebase to use async/await"

# ✅ Scoped (Claude reads only what's needed)
"Refactor src/api/users.ts to use async/await — only that file, leave others for now"
```

#### Avoiding Context Bloat
- Don't ask Claude to "explain the whole codebase" — ask targeted questions.
- After a long debug session: `/compact` then re-state the goal cleanly.
- Use `Explore` subagent for codebase search — it doesn't pollute main context.
- Test output: if test runner prints 500 lines, grep for failures before pasting.

### Memory System — Persisting Between Sessions
- Auto-memory directory: `~/.claude/projects/<cwd>/memory/` — survives `/clear` and session restarts.
- Save to memory: things that are **non-obvious** and **reusable** (user preferences, project quirks, architectural decisions).
- Don't save to memory: task state, temporary notes, things derivable from the code.
- Memory types: `user` (who you are), `feedback` (how to work together), `project` (ongoing context), `reference` (where to find things).

### /compact vs /clear — When to Use Which
| Situation | Use |
|---|---|
| Context > 60%, still on same task | `/compact` — summarize + continue |
| Switching to unrelated task | `/clear` — fresh start |
| Stuck in wrong direction | `/clear` — re-brief from scratch |
| Long session, same goal | `/compact` every ~hour |
| After a major milestone/commit | Either — preference |

### Cost Optimization
- Use `haiku` model for: file searches, simple renames, boilerplate generation.
- Use `sonnet` for: standard coding tasks, debugging, code review.
- Use `opus` for: complex architecture, multi-file refactors, security analysis.
- `/cost` shows token usage for current session — check before long tasks.
- Background agents (subagents) run independently — their tokens are separate.
- Avoid re-reading files you just edited — Claude tracks file state.

---

## 🐛 Debug Skills

### Debugging Methodology (Scientific Method)
1. **Reproduce** — get a consistent repro first. Can't debug a flake reliably.
2. **Isolate** — find the smallest failing case (unit, then integration, then e2e).
3. **Hypothesize** — form a specific, testable hypothesis about the cause.
4. **Test** — change ONE thing and observe. Never change multiple variables.
5. **Explain** — understand WHY the fix works before committing it.

### Browser DevTools

#### Network Tab
```
- Filter by XHR/Fetch — see all API calls
- Check: Status, Headers (Authorization present?), Payload, Response, Timing
- "Preserve log" to keep logs across page navigations
- Right-click → "Copy as cURL" to replay in terminal
- Waterfall view for performance: TTFB, download time
```

#### Console
```js
// Conditional breakpoint — break only when condition is true
// Right-click gutter in Sources → Add conditional breakpoint

// Log with context (not bare console.log)
console.log({ userId, action, payload });

// Group related logs
console.group("Auth flow");
console.log("token validated");
console.groupEnd();

// Time operations
console.time("db-query");
await db.query(...);
console.timeEnd("db-query"); // → db-query: 45.3ms
```

#### Performance Tab
- Record → interact → stop → analyze flame chart.
- Look for: long tasks (>50ms), layout thrashing, forced reflows.
- "Bottom-up" view: which functions consumed most time.
- Memory snapshot: heap snapshot before/after to find leaked objects.

### Node.js Debugging

#### VS Code Debugger
```json
// .vscode/launch.json
{
  "configurations": [
    {
      "type": "node",
      "request": "launch",
      "name": "Debug NestJS",
      "runtimeExecutable": "pnpm",
      "runtimeArgs": ["run", "start:debug"],
      "port": 9229,
      "restart": true
    },
    {
      "type": "node",
      "request": "attach",
      "name": "Attach to process",
      "port": 9229,
      "restart": true
    }
  ]
}
```

#### CLI Debugging
```bash
# Start with inspector
node --inspect src/index.js          # attach Chrome DevTools at chrome://inspect
node --inspect-brk src/index.js      # break on first line

# NestJS
nest start --debug                    # port 9229
nest start --debug --watch            # with hot reload

# Debug specific test
node --inspect-brk node_modules/.bin/jest --runInBand --testPathPattern=users
```

#### Memory Leaks (Node.js)
```bash
# Heap snapshot via CLI
node --expose-gc --inspect index.js
# In Chrome DevTools → Memory → Take snapshot → interact → Take snapshot → Compare

# clinic.js (best for production-like profiling)
npx clinic doctor -- node index.js
npx clinic flame -- node index.js    # flame graph
npx clinic bubbleprof -- node index.js  # async bottlenecks
```

### Python Debugging

```python
# pdb — built-in debugger
import pdb; pdb.set_trace()   # breakpoint
# or Python 3.7+
breakpoint()

# pdb commands: n(ext), s(tep), c(ontinue), p(rint) var, l(ist), q(uit)
# pp var — pretty print, bt — backtrace, u/d — up/down stack frame

# ipdb — pdb with IPython UX
pip install ipdb
import ipdb; ipdb.set_trace()

# pytest debugging
pytest --pdb              # drop into pdb on failure
pytest --pdb -x           # stop at first failure
pytest -s                 # show print statements (don't capture)
pytest --tb=long          # full traceback
```

#### Async Debugging (Python)
```python
# Debug asyncio issues
import asyncio
asyncio.get_event_loop().set_debug(True)

# Log all tasks
for task in asyncio.all_tasks():
    print(task)

# PYTHONTRACEMALLOC for memory
python -X tracemalloc=10 app.py
```

### Network & API Debugging

```bash
# Verbose curl with timing
curl -v -w "\nTime: %{time_total}s\n" https://api.example.com/endpoint

# Decode JWT without external tools
echo "eyJ..." | cut -d. -f2 | base64 -d 2>/dev/null | jq .

# Watch HTTP traffic on port
sudo tcpdump -i any -A port 3000

# mitmproxy — intercept and modify HTTP/HTTPS
mitmproxy --port 8080
# Set proxy: HTTP_PROXY=http://localhost:8080

# httpie — human-friendly curl
http GET api.example.com/users Authorization:"Bearer $TOKEN"
```

### Database Debugging

```sql
-- PostgreSQL: explain query plan
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'x@x.com';
-- Look for: Seq Scan (add index?), high rows estimate vs actual

-- Find slow queries
SELECT query, mean_exec_time, calls
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;

-- Check active locks
SELECT pid, query, state, wait_event_type, wait_event
FROM pg_stat_activity
WHERE state != 'idle';

-- Kill blocking query
SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE pid = <blocking_pid>;
```

```bash
# MySQL slow query log
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 1;  -- log queries > 1s

# MongoDB explain
db.users.find({ email: "x" }).explain("executionStats")
```

### Distributed Systems Debugging
- **Correlation IDs**: every request gets a UUID; propagate via `X-Request-ID` header through all services.
- **Distributed tracing**: Jaeger/Zipkin/OpenTelemetry — follow a request across microservices.
- Check **clock skew** between services — timestamps out of sync cause mysterious ordering bugs.
- **Log aggregation**: Loki/ELK — search by `traceId` to see the full picture.
- Chaos engineering: **fault injection** to find hidden failure modes before prod does.

### Debugging Checklist
- [ ] Can I reproduce it consistently?
- [ ] Is it a code bug or a config/env issue?
- [ ] Did it ever work? What changed?
- [ ] Is it in all environments or specific to one?
- [ ] What do the logs say at ERROR and WARN level?
- [ ] Is there a related test I can add to pin the bug?
- [ ] Have I explained the fix to myself (rubber duck)?

---

## 🔐 Security — Senior Engineer

### Threat Modeling (STRIDE)
Before writing security controls, model threats first:
- **S**poofing — can an attacker impersonate a user or service?
- **T**ampering — can data be modified in transit or at rest?
- **R**epudiation — can actions be denied without audit trail?
- **I**nformation Disclosure — can sensitive data leak?
- **D**enial of Service — can availability be disrupted?
- **E**levation of Privilege — can an attacker gain higher permissions?

For each threat: rate likelihood × impact → prioritize mitigations accordingly.

### OWASP Top 10 — With Mitigations

| # | Vulnerability | Mitigation |
|---|---|---|
| A01 | Broken Access Control | Enforce server-side; deny by default; test IDOR on every endpoint |
| A02 | Cryptographic Failures | TLS 1.2+ everywhere; bcrypt/argon2 for passwords; AES-256-GCM for data at rest |
| A03 | Injection (SQL/LDAP/OS) | Parameterized queries always; ORM; never interpolate user input into queries |
| A04 | Insecure Design | Threat model; defense in depth; fail securely |
| A05 | Security Misconfiguration | Disable debug in prod; remove default accounts; security headers; scan with automated tools |
| A06 | Vulnerable Components | `npm audit`/`pip-audit` in CI; SBOM; pin dependencies; auto-update alerts |
| A07 | Auth & Session Failures | MFA; secure session IDs; short-lived tokens; logout invalidates server-side |
| A08 | SSRF | Allowlist outbound URLs; block internal IP ranges (169.254.x.x, 10.x.x.x) |
| A09 | Logging & Monitoring | Log auth events, failures, suspicious patterns; alert on anomalies |
| A10 | SSTI / Server-Side Injection | Never render user input in templates; use safe templating engines |

### Authentication Hardening
```ts
// Password hashing — argon2 preferred over bcrypt
import argon2 from "argon2";
const hash = await argon2.hash(password, { type: argon2.argon2id, memoryCost: 65536, timeCost: 3 });
const valid = await argon2.verify(hash, password);

// bcrypt if argon2 unavailable — cost factor 12+
import bcrypt from "bcrypt";
const hash = await bcrypt.hash(password, 12);
```

- **Session fixation**: regenerate session ID on login.
- **Account enumeration**: return identical responses for "user not found" and "wrong password".
- **Brute force**: rate limit login by IP + username; exponential backoff; CAPTCHA after N failures.
- **MFA**: TOTP (Google Authenticator); backup codes hashed in DB; hardware key (WebAuthn) for high-value accounts.
- **Passwordless**: magic links expire in 15min; single-use; bind to IP optionally.

### Authorization — RBAC / ABAC
```ts
// RBAC — roles define permissions
const permissions = {
  admin:   ["users:read", "users:write", "users:delete"],
  editor:  ["users:read", "users:write"],
  viewer:  ["users:read"],
};

// ABAC — attributes define access (more flexible)
function canAccess(user: User, resource: Resource, action: string): boolean {
  if (user.orgId !== resource.orgId) return false;        // org boundary
  if (resource.ownerId === user.id) return true;          // own resource
  return user.permissions.includes(`${resource.type}:${action}`);
}
```

- Always enforce authorization **server-side** — client-side checks are UX only.
- Test **IDOR** (Insecure Direct Object Reference): can user A access user B's resources by changing an ID?
- **Principle of least privilege**: grant minimum permissions needed; revoke when done.
- Log every authorization decision for sensitive resources.

### Cryptography Best Practices
```ts
// ✅ Use Web Crypto API (browser) or crypto module (Node.js 19+)
import { webcrypto } from "crypto";

// Generate secure random token
const token = webcrypto.getRandomValues(new Uint8Array(32));
const tokenHex = Buffer.from(token).toString("hex"); // 64-char hex string

// HMAC for webhook signatures
const key = await webcrypto.subtle.importKey("raw", Buffer.from(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
const sig = await webcrypto.subtle.sign("HMAC", key, Buffer.from(payload));

// AES-GCM for symmetric encryption (includes auth tag — tamper-proof)
const iv = webcrypto.getRandomValues(new Uint8Array(12)); // unique per encryption
// Store iv alongside ciphertext
```

- **Never** use MD5 or SHA-1 for security purposes.
- **Never** roll your own crypto — use established libraries.
- Keys: store in KMS (AWS KMS, GCP Cloud KMS, HashiCorp Vault) — never in code or env vars.
- TLS: minimum 1.2; prefer 1.3; disable RC4, 3DES cipher suites; enable HSTS.

### API Security
```ts
// Security headers — set on every response
app.use((req, res, next) => {
  res.setHeader("X-Content-Type-Options", "nosniff");
  res.setHeader("X-Frame-Options", "DENY");
  res.setHeader("X-XSS-Protection", "0");               // disabled — use CSP instead
  res.setHeader("Referrer-Policy", "strict-origin-when-cross-origin");
  res.setHeader("Permissions-Policy", "geolocation=(), camera=(), microphone=()");
  res.setHeader("Strict-Transport-Security", "max-age=63072000; includeSubDomains; preload");
  next();
});
```

#### Content Security Policy (CSP)
```
Content-Security-Policy:
  default-src 'self';
  script-src 'self' 'nonce-{random}';    # nonce per request, no 'unsafe-inline'
  style-src 'self' 'unsafe-inline';      # allow inline styles (or nonce)
  img-src 'self' data: https:;
  connect-src 'self' https://api.example.com;
  frame-ancestors 'none';                # clickjacking prevention
  upgrade-insecure-requests;
```
- Start with `Content-Security-Policy-Report-Only` to detect violations before enforcing.
- Never use `unsafe-eval` or `unsafe-inline` for scripts.

#### CORS
```ts
// ✅ Explicit allowlist
const allowedOrigins = ["https://app.example.com", "https://admin.example.com"];
app.use(cors({
  origin: (origin, cb) => cb(null, allowedOrigins.includes(origin ?? "")),
  credentials: true,
  methods: ["GET", "POST", "PUT", "PATCH", "DELETE"],
  allowedHeaders: ["Content-Type", "Authorization"],
}));
```

#### Rate Limiting
```ts
// Token bucket per user + per IP
const rateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,    // 15 minutes
  max: 100,                      // 100 requests per window
  keyGenerator: (req) => req.user?.id ?? req.ip,  // per-user when authed
  handler: (req, res) => res.status(429).json({ error: "Too many requests" }),
});

// Stricter for auth endpoints
const authLimiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 10 });
app.post("/auth/login", authLimiter, loginHandler);
```

### Input Validation & Injection Prevention
```ts
// SQL — parameterized queries, NEVER string interpolation
// ❌
const q = `SELECT * FROM users WHERE email = '${email}'`;
// ✅
const user = await db.query("SELECT * FROM users WHERE email = $1", [email]);

// NoSQL injection (MongoDB)
// ❌
db.users.find({ email: req.body.email });  // { email: { $gt: "" } } bypasses auth
// ✅
const email = z.string().email().parse(req.body.email);  // validate type first
db.users.find({ email });

// Path traversal
// ❌
fs.readFile(`./uploads/${filename}`);
// ✅
const safe = path.basename(filename);   // strip directory components
const fullPath = path.join(UPLOADS_DIR, safe);
if (!fullPath.startsWith(UPLOADS_DIR)) throw new Error("Path traversal");
```

### SSRF Prevention
```ts
import { Resolver } from "dns/promises";
import { isPrivate } from "ip";

async function isSafeUrl(url: string): Promise<boolean> {
  const parsed = new URL(url);
  if (!["http:", "https:"].includes(parsed.protocol)) return false;
  
  const resolver = new Resolver();
  const [address] = await resolver.resolve4(parsed.hostname);
  if (isPrivate(address)) return false;          // block 10.x, 172.16.x, 192.168.x
  if (address === "127.0.0.1") return false;     // block loopback
  return true;
}
```

### Secret Management
```bash
# Scan for secrets before commit
git secrets --scan           # git-secrets
gitleaks detect --source .   # gitleaks (recommended)
trufflehog git file://. --since-commit HEAD~1

# Pre-commit hook (add to .pre-commit-config.yaml)
- repo: https://github.com/gitleaks/gitleaks
  rev: v8.18.0
  hooks:
    - id: gitleaks
```
- Rotate immediately if a secret is exposed — treat exposure as a breach.
- Use short-lived credentials: OIDC tokens, temporary STS credentials, Vault dynamic secrets.
- Never log secrets — redact in logging middleware before any output.

### Dependency & Supply Chain Security
```bash
# Audit
npm audit --audit-level=high     # fail CI on high/critical
pip-audit --require-hashes       # also verifies hash integrity
composer audit

# Lock file integrity
npm ci                           # install from lockfile exactly — not npm install
pip install --require-hashes -r requirements.txt

# SBOM generation
syft . -o cyclonedx-json > sbom.json   # software bill of materials
grype sbom.json                         # scan SBOM for CVEs
```
- Pin **all** dependencies (direct + transitive) with lockfiles — commit them.
- Enable Dependabot / Renovate for automated security updates.
- Verify checksums for downloaded binaries in CI (`sha256sum`).

### Container Security
```dockerfile
# ✅ Security hardening
FROM node:20.11-alpine AS runtime
# Run as non-root
RUN addgroup -S app && adduser -S app -G app
# Read-only filesystem where possible
USER app
# Drop capabilities
# In docker-compose or K8s: securityContext.readOnlyRootFilesystem: true
```

```bash
# Scan image for CVEs
trivy image my-app:latest --severity HIGH,CRITICAL --exit-code 1

# Check Dockerfile for misconfigs
hadolint Dockerfile
```

Kubernetes security context:
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop: ["ALL"]
```

### Security Testing Pipeline
```
PRE-COMMIT: gitleaks (secrets), hadolint (Dockerfile)
CI:         SAST (Semgrep/CodeQL), npm audit/pip-audit, trivy (container)
STAGING:    DAST (OWASP ZAP), tfsec (IaC), API fuzzing
PRE-PROD:   Penetration test (annual or on major changes)
PROD:       CSPM, runtime anomaly detection (Falco, GuardDuty)
```

### Security Code Review Checklist
- [ ] All inputs validated at system boundaries (never trust user input)
- [ ] No secrets in code, logs, or error messages
- [ ] Auth checked on every endpoint — no accidental public routes
- [ ] IDOR tested — can I access another user's resource by changing an ID?
- [ ] SQL/NoSQL queries use parameterized form — no string interpolation
- [ ] File uploads: type validated, size limited, stored outside webroot
- [ ] Dependencies audited — no known high/critical CVEs
- [ ] Error messages don't leak stack traces or system info to client
- [ ] Rate limiting on auth and public endpoints
- [ ] Sensitive operations logged with user + IP + timestamp

### Incident Response (Security Breach)
1. **Contain**: revoke compromised credentials, isolate affected systems.
2. **Assess**: what data was accessed/exfiltrated? What's the blast radius?
3. **Notify**: legal, affected users (GDPR: 72h), regulators if required.
4. **Remediate**: patch the vulnerability, rotate all potentially-affected secrets.
5. **Post-mortem**: timeline, root cause, what controls failed, what to add.

---

## 🧬 AI/ML Engineering — LLM, RAG, Agents

### LLM Fundamentals
- Tokens ≠ words: ~4 chars/token (English); pricing and context limits are in tokens, not words.
- Temperature: 0 = deterministic/factual, 0.7 = balanced, 1.0+ = creative/varied.
- Context window: everything the model "sees" — system prompt + history + tools + output.
- Top-p (nucleus sampling): only sample from top-p probability mass — use with temperature.
- **System prompt** sets persona/constraints; **user turn** is the task; never merge them.
- Always set `max_tokens` explicitly — unbounded generation wastes money and causes timeouts.

### Prompt Engineering

#### Core Techniques
```python
# Chain-of-thought — force reasoning before answer
system = "Think step by step before giving your final answer."

# Few-shot — show examples in prompt
system = """Classify sentiment as positive/negative/neutral.
Examples:
"I love this!" → positive
"It's broken." → negative
"It works." → neutral
Now classify: {input}"""

# Role prompting
system = "You are a senior TypeScript engineer reviewing code for security issues."

# Structured output — JSON mode / tool use
system = "Always respond with valid JSON matching the schema: {fields}"
```

#### Prompt Versioning
- Store prompts in code, not hardcoded strings — use a prompt registry or constants file.
- Version prompts like code: `PROMPT_V2 = "..."` — never silently edit live prompts.
- A/B test prompt changes with LangSmith datasets or LangFuse experiments.
- Eval before deploy: regression suite of known inputs → expected outputs.

### RAG Architecture (Retrieval-Augmented Generation)

#### Pipeline
```
Documents → Chunking → Embedding → Vector Store
                                        ↓
Query → Embed query → Similarity search → Retrieved chunks → LLM → Answer
```

#### Chunking Strategies
```python
# Fixed-size (simple, baseline)
chunks = [text[i:i+512] for i in range(0, len(text), 512)]

# Semantic chunking (better quality — split at sentence/paragraph boundaries)
from langchain.text_splitter import RecursiveCharacterTextSplitter
splitter = RecursiveCharacterTextSplitter(chunk_size=512, chunk_overlap=64)
chunks = splitter.split_text(document)

# Hierarchical chunking: store both parent (context) and child (precision)
# Retrieve child, return parent to LLM for more context
```

#### Retrieval Strategies
| Strategy | When to use |
|---|---|
| **Dense retrieval** (vector similarity) | Semantic meaning matters, not exact keywords |
| **Sparse retrieval** (BM25/keyword) | Exact terms, codes, names, IDs |
| **Hybrid** (dense + sparse, RRF reranking) | Best of both — production default |
| **Reranking** (cross-encoder) | After initial retrieval — rerank top-k for precision |
| **HyDE** (Hypothetical Document Embeddings) | Generate a hypothetical answer, embed it, search |
| **Multi-query** | Generate N query variants, merge results |

#### Vector Databases
```python
# pgvector — PostgreSQL extension (best for existing Postgres stack)
CREATE EXTENSION vector;
CREATE TABLE embeddings (id SERIAL, content TEXT, embedding vector(1536));
CREATE INDEX ON embeddings USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

# Similarity search
SELECT content FROM embeddings
ORDER BY embedding <=> '[0.1, 0.2, ...]'::vector
LIMIT 10;
```

| DB | Best for |
|---|---|
| **pgvector** | Existing PostgreSQL, simple stack |
| **Weaviate** | Multi-modal, hybrid search built-in |
| **Qdrant** | High-performance, on-prem |
| **Pinecone** | Managed, serverless, zero-ops |
| **Chroma** | Local dev, prototyping |

#### RAG Quality Checklist
- [ ] Chunk overlap to avoid splitting context at boundaries
- [ ] Metadata filtering: filter by date, source, category before vector search
- [ ] Re-ranking applied after initial retrieval
- [ ] Answer grounded in retrieved context (check with LLM-as-judge eval)
- [ ] Hallucination rate measured in evals
- [ ] Fallback: "I don't have enough information" when retrieval score is low

### Agent Systems

#### ReAct Pattern (Reason + Act)
```python
# Agent loop: Think → Tool call → Observe → Think → ... → Answer
from langchain.agents import create_react_agent

# Each step: LLM reasons about what tool to call, calls it, observes result
# Loop until LLM decides it has enough info to answer
```

#### Tool / Function Calling
```python
# Anthropic tool use
tools = [{
    "name": "search_database",
    "description": "Search the product database. Use when user asks about specific products.",
    "input_schema": {
        "type": "object",
        "properties": {
            "query": {"type": "string", "description": "Search query"},
            "limit": {"type": "integer", "default": 10}
        },
        "required": ["query"]
    }
}]

response = client.messages.create(
    model="claude-opus-4-7",
    tools=tools,
    messages=[{"role": "user", "content": "Find laptops under $1000"}]
)
# Check if response.stop_reason == "tool_use" → execute tool → continue loop
```

#### Multi-Agent Orchestration (LangGraph)
```python
from langgraph.graph import StateGraph, END
from typing import TypedDict, Annotated
import operator

class AgentState(TypedDict):
    messages: Annotated[list, operator.add]
    next_agent: str

# Supervisor routes tasks to specialized agents
def supervisor(state: AgentState):
    # Decide which agent handles next step
    return {"next_agent": "researcher" if needs_research(state) else "writer"}

builder = StateGraph(AgentState)
builder.add_node("supervisor", supervisor)
builder.add_node("researcher", research_agent)
builder.add_node("writer", write_agent)
builder.add_conditional_edges("supervisor", lambda s: s["next_agent"],
    {"researcher": "researcher", "writer": "writer", "done": END})
```

#### Agent Patterns
| Pattern | Use case |
|---|---|
| **ReAct** | General tool-using agent |
| **Plan & Execute** | Complex multi-step tasks — plan first, then execute |
| **Reflexion** | Self-critique and retry on failure |
| **Multi-agent supervisor** | Route subtasks to specialized agents |
| **Parallel agents** | Independent tasks run concurrently |
| **Human-in-the-loop** | Pause for approval on sensitive actions |

### MLOps & Evaluation

#### Experiment Tracking
```python
# MLflow
import mlflow
with mlflow.start_run():
    mlflow.log_param("model", "claude-sonnet-4-6")
    mlflow.log_param("temperature", 0.7)
    mlflow.log_metric("accuracy", 0.87)
    mlflow.log_metric("latency_p99", 1.2)
```

#### LLM Evaluation (Evals)
```python
# LLM-as-judge: use a model to score outputs
def evaluate_answer(question, context, answer):
    prompt = f"""Rate this answer 1-5 for correctness and groundedness.
    Question: {question}
    Context: {context}
    Answer: {answer}
    Return JSON: {{"score": int, "reason": str}}"""
    return judge_model.complete(prompt)

# Eval types:
# - Exact match (factual Q&A)
# - LLM-as-judge (open-ended quality)
# - Retrieval precision/recall (RAG eval)
# - Tool call accuracy (agent eval)
# - End-to-end task completion rate
```

#### Fine-tuning (When RAG isn't enough)
- **LoRA / QLoRA**: low-rank adaptation — fine-tune with <1% of original parameters.
- Use fine-tuning for: style/format adherence, domain-specific vocabulary, structured output.
- **Do NOT** use fine-tuning to inject facts — facts drift and hallucinate. Use RAG for facts.
- Dataset: minimum 100 examples; 1000+ for reliable results; curate quality over quantity.
- Evaluate fine-tuned model against base model on held-out test set before deploying.

### LLM Cost Optimization
- **Prompt caching**: cache system prompt + static context (Anthropic Cache Control — up to 90% savings).
- **Model routing**: use Haiku/Flash for classification/routing; Sonnet for generation; Opus for complex reasoning.
- **Batching**: use Batch API for non-real-time workloads (50% discount on Anthropic).
- **Output length**: constrain with `max_tokens`; use structured output to avoid verbose prose.
- **Token counting**: count before sending; reject oversized requests early.
- Monitor cost per user/feature in LangSmith/LangFuse — find expensive outliers.

### Guardrails & Safety
```python
# Input guardrails
def validate_input(user_input: str) -> bool:
    # Check for prompt injection attempts
    injection_patterns = ["ignore previous instructions", "system:", "SYSTEM:"]
    if any(p.lower() in user_input.lower() for p in injection_patterns):
        return False
    # PII detection before sending to external LLM
    if contains_pii(user_input):
        redact_pii(user_input)
    return True

# Output guardrails
def validate_output(response: str) -> str:
    # Check for hallucinated citations, toxic content, PII leakage
    if contains_hallucinated_urls(response):
        response = remove_urls(response)
    return response
```

---

## 🛡️ Cybersecurity Engineering

### Methodology: Offensive → Defensive Thinking
- Think like an attacker to build defenses — every feature is a potential attack surface.
- Security = process, not a product. It's never "done".
- Defense in depth: multiple independent controls — if one fails, others hold.
- Assume breach: design systems that limit blast radius when (not if) something is compromised.

### Penetration Testing Methodology (PTES / OWASP)
```
1. Reconnaissance    → passive (OSINT, Shodan, Censys) + active (nmap, nessus)
2. Scanning          → ports, services, versions, OS fingerprinting
3. Enumeration       → users, shares, services, subdomains, directories
4. Exploitation      → use found vulns; never in prod without written authorization
5. Post-exploitation → persistence, lateral movement, privilege escalation
6. Reporting         → severity rating, PoC, remediation steps
```

**Authorization in writing** before any active testing — never assume.

### Web Application Security Testing

#### Recon & Discovery
```bash
# Subdomain enumeration
subfinder -d example.com -o subdomains.txt
amass enum -passive -d example.com

# Directory/endpoint discovery
ffuf -w /usr/share/wordlists/dirb/common.txt -u https://example.com/FUZZ
gobuster dir -u https://example.com -w wordlist.txt -x php,js,html

# JS analysis for hidden endpoints
cat app.js | grep -E "(api|endpoint|fetch|axios)" | sort -u

# Headers inspection
curl -sI https://example.com | grep -i "server\|x-powered\|x-frame"
```

#### Common Vulnerabilities (Testing)
```bash
# SQL Injection testing (authorized only)
sqlmap -u "https://example.com/users?id=1" --dbs --batch

# XSS payloads (test in isolated env)
# Reflected: "><script>alert(1)</script>
# DOM-based: #"><img src=x onerror=alert(1)>

# IDOR testing
# Enumerate IDs: /api/orders/1, /api/orders/2, /api/orders/3
# Try accessing other users' resources with your token

# JWT vulnerabilities
# Algorithm confusion: change alg to "none"
# Weak secret: crack with hashcat: hashcat -a 0 -m 16500 jwt.txt wordlist.txt

# SSRF
curl "https://example.com/fetch?url=http://169.254.169.254/latest/meta-data/"
```

#### OWASP ZAP (Automated DAST)
```bash
# Run full scan
docker run -t owasp/zap2docker-stable zap-full-scan.py \
  -t https://staging.example.com \
  -r report.html \
  -I  # don't fail on warnings
```

### Network Security
```bash
# Port scanning
nmap -sV -sC -O -p- --min-rate 5000 target.com    # full version+script scan
nmap -sU --top-ports 100 target.com                 # UDP top ports
nmap --script vuln target.com                        # vulnerability scripts

# SSL/TLS analysis
testssl.sh target.com             # comprehensive TLS config check
sslyze target.com                 # fast TLS analysis

# Packet capture
tcpdump -i eth0 -w capture.pcap port 80 or port 443
wireshark capture.pcap            # GUI analysis

# Network monitoring (defensive)
zeek -i eth0                      # protocol analysis + logs
suricata -c suricata.yaml -i eth0 # IDS/IPS rules-based detection
```

### OSINT & Reconnaissance
```bash
# Google dorks
site:example.com filetype:pdf
site:example.com inurl:admin
"example.com" ext:env OR ext:config OR ext:yml

# Certificate transparency logs (find subdomains)
curl "https://crt.sh/?q=%.example.com&output=json" | jq '.[].name_value' | sort -u

# Shodan CLI
shodan search "hostname:example.com"
shodan host 1.2.3.4

# Email harvesting (OSINT)
theHarvester -d example.com -b google,linkedin,github
```

### Defensive Security Engineering

#### Security Information & Event Management (SIEM)
```yaml
# Detection rules pattern (Sigma format — portable across SIEM tools)
title: Brute Force Login Attempt
status: stable
logsource:
  category: authentication
detection:
  selection:
    EventID: 4625         # Windows failed login
  timeframe: 5m
  condition: selection | count() by SourceIP > 10
level: medium
```

#### Intrusion Detection
```bash
# Falco (runtime security for containers/K8s)
# Rule: alert on shell spawned in container
- rule: Shell Spawned in Container
  desc: A shell was spawned in a container
  condition: spawned_process and container and shell_procs
  output: "Shell spawned (user=%user.name container=%container.name)"
  priority: WARNING
```

#### Incident Response Toolkit
```bash
# Capture volatile data first (order of volatility)
1. Memory dump: avml memory.lime
2. Running processes: ps auxf > processes.txt
3. Network connections: ss -tupan > connections.txt
4. Logged-in users: w > users.txt
5. Open files: lsof > open_files.txt
6. Then disk image (non-volatile)

# Log analysis
grep "Failed password" /var/log/auth.log | awk '{print $11}' | sort | uniq -c | sort -rn
journalctl -u sshd --since "2024-01-01" | grep -i "failed\|invalid"
```

### Vulnerability Management
```bash
# CVE scanning
trivy image nginx:latest               # container CVEs
trivy fs .                             # filesystem/code CVEs
nuclei -u https://example.com         # template-based vuln scanning

# Dependency CVEs
grype .                                # any language
osv-scanner .                          # Google OSV database

# Infrastructure misconfiguration
checkov -d terraform/                  # IaC security
kube-bench                             # CIS K8s benchmark
aws-securityhub-findings               # AWS config compliance
```

### Security Hardening Baselines
- **CIS Benchmarks**: use for OS, K8s, cloud hardening checklists.
- **DISA STIGs**: DoD hardening guides — most comprehensive but complex.
- **NIST CSF**: Identify → Protect → Detect → Respond → Recover framework.
- Automate compliance checks in CI: `checkov`, `tfsec`, `kube-bench`, `lynis`.

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

## 📄 Documentation Skills — Senior Engineer & Technical Writer

### Documentation Philosophy
- Documentation is a product — it needs design, iteration, and maintenance.
- Write for the reader, not yourself — they have less context, different goals.
- **Docs as code**: documentation lives in the repo, reviewed in PRs, versioned with code.
- The best documentation is the code itself — clear naming, typed interfaces, error messages.
- Supplemental docs explain **why** (decisions, constraints, trade-offs) — not just what the code does.
- Stale documentation is worse than no documentation — it misleads.

### Documentation Types

| Type | Purpose | Audience | Lives in |
|---|---|---|---|
| **README** | Project overview, quick start | New contributors | Repo root |
| **API reference** | Every endpoint/function documented | Developers integrating | Auto-generated or `docs/api/` |
| **Architecture Decision Record (ADR)** | Why decisions were made | Future engineers | `docs/adr/` |
| **Runbook** | How to operate the system | On-call engineers | `docs/runbooks/` |
| **Tutorial** | Learning-oriented, step-by-step | New users | `docs/tutorials/` |
| **How-to guide** | Goal-oriented, task-specific | Practitioners | `docs/how-to/` |
| **Explanation** | Conceptual understanding | Learners | `docs/concepts/` |
| **Changelog** | What changed between versions | Users upgrading | `CHANGELOG.md` |

### README Best Practices

#### README Structure
```markdown
# Project Name

One-line description of what this does and who it's for.

## Features
- Feature 1 — why it matters
- Feature 2

## Quick Start
```bash
git clone https://github.com/org/repo
cd repo
pnpm install
cp .env.example .env.local   # fill in your values
pnpm dev
```
Open http://localhost:3000 — you should see X.

## Requirements
- Node.js 20+
- PostgreSQL 16+
- Redis 7+

## Configuration
| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DATABASE_URL` | ✅ | — | PostgreSQL connection string |
| `REDIS_URL` | ✅ | — | Redis connection string |
| `JWT_SECRET` | ✅ | — | Min 32 chars, random string |
| `PORT` | ❌ | 3000 | HTTP server port |

## Development
```bash
pnpm dev          # start dev server with hot reload
pnpm test         # run unit + integration tests
pnpm test:e2e     # run Playwright end-to-end tests
pnpm lint         # lint + type check
pnpm db:migrate   # run pending migrations
pnpm db:seed      # seed development data
```

## Architecture
Brief overview + link to detailed docs.
See [Architecture Overview](docs/architecture.md).

## Contributing
See [CONTRIBUTING.md](CONTRIBUTING.md).

## License
MIT
```

#### README Anti-Patterns
```
❌ No installation instructions ("just run it")
❌ Outdated screenshots that no longer match the UI
❌ "TODO: add docs" sections that never get filled
❌ Listing every dependency and their versions
❌ Documenting internal implementation (belongs in code comments)
❌ Wall of text with no code examples
❌ No "quick start" — forcing reader to read everything before trying anything
```

### API Documentation

#### OpenAPI / Swagger
```yaml
# openapi.yaml — spec-first approach
openapi: "3.1.0"
info:
  title: User Service API
  version: "1.0.0"
  description: |
    Manages user accounts, authentication, and authorization.

    **Authentication**: All endpoints except `/auth/login` require a Bearer token.

    **Rate limiting**: 100 requests per 15 minutes per user. Headers:
    `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

paths:
  /users/{id}:
    get:
      summary: Get user by ID
      operationId: getUserById
      tags: [Users]
      security: [{ bearerAuth: [] }]
      parameters:
        - name: id
          in: path
          required: true
          schema: { type: string, format: uuid }
          example: "550e8400-e29b-41d4-a716-446655440000"
      responses:
        "200":
          description: User found
          content:
            application/json:
              schema: { $ref: "#/components/schemas/User" }
              example:
                id: "550e8400-e29b-41d4-a716-446655440000"
                email: "alice@example.com"
                name: "Alice Smith"
                role: "editor"
                createdAt: "2024-01-15T10:30:00Z"
        "404":
          description: User not found
          content:
            application/json:
              schema: { $ref: "#/components/schemas/Error" }
        "401": { $ref: "#/components/responses/Unauthorized" }

components:
  schemas:
    User:
      type: object
      required: [id, email, name, role, createdAt]
      properties:
        id:        { type: string, format: uuid }
        email:     { type: string, format: email }
        name:      { type: string, example: "Alice Smith" }
        role:      { type: string, enum: [admin, editor, viewer] }
        createdAt: { type: string, format: date-time }
      additionalProperties: false

    Error:
      type: object
      required: [code, message]
      properties:
        code:    { type: string, example: "NOT_FOUND" }
        message: { type: string, example: "User 123 not found" }
        context: { type: object }
```

#### JSDoc / TSDoc
```ts
/**
 * Calculates the discount amount for an order.
 *
 * @param amount - The order total in cents (must be positive)
 * @param code - Discount code (STANDARD = 10%, PREMIUM = 20%)
 * @returns The discount amount in cents, or 0 if below threshold
 * @throws {ValueError} If amount is negative
 *
 * @example
 * ```ts
 * calculateDiscount(15000, "STANDARD") // returns 1500 (10% of $150)
 * calculateDiscount(8000, "STANDARD")  // returns 0 (below $100 threshold)
 * ```
 */
export function calculateDiscount(amount: number, code: DiscountCode): number {
  if (amount < 0) throw new ValueError("Amount must be positive");
  if (amount < DISCOUNT_THRESHOLD) return 0;
  return Math.round(amount * DISCOUNT_RATES[code]);
}
```

#### Python Docstrings (Google style)
```python
def calculate_discount(amount: float, code: str) -> float:
    """Calculate discount amount for an order.

    Args:
        amount: Order total in dollars. Must be positive.
        code: Discount code. "STANDARD" = 10%, "PREMIUM" = 20%.

    Returns:
        Discount amount in dollars, or 0 if below $100 threshold.

    Raises:
        ValueError: If amount is negative.

    Example:
        >>> calculate_discount(150, "STANDARD")
        15.0
        >>> calculate_discount(80, "STANDARD")
        0.0
    """
```

### Architecture Decision Records (ADR)

#### ADR Template
```markdown
# ADR-001: Use PostgreSQL as Primary Database

## Status
Accepted | Proposed | Deprecated | Superseded by ADR-XXX

## Date
2024-01-15

## Context
We need a primary database for storing user accounts, orders, and product data.
The team has mixed experience with relational and document databases.
Expected load: 10k DAU, 100 writes/sec, 1000 reads/sec initially.

## Decision
We will use PostgreSQL 16 as our primary database.

## Rationale
- ACID compliance required for financial transactions (orders, payments)
- Team has strong PostgreSQL expertise — lower operational risk
- JSONB support covers semi-structured product attributes without a separate NoSQL DB
- Managed options available on AWS (RDS), GCP (Cloud SQL), and Supabase
- pgvector extension available if we add vector search for recommendations

## Alternatives Considered
| Option | Pros | Cons |
|--------|------|------|
| MySQL 8 | Wide familiarity, MariaDB option | Weaker JSON support, no extensions |
| MongoDB | Flexible schema, easy horizontal scale | Eventual consistency risks for payments |
| CockroachDB | Global distribution, auto-sharding | Complexity overkill at current scale |

## Consequences
- All engineers need basic PostgreSQL knowledge (not a concern — it's universal)
- Horizontal write scaling requires read replicas + app-level routing (acceptable)
- If we grow to 10M+ users, may revisit sharding strategy (ADR-002 if needed)
- ORM: Prisma (TypeScript) or SQLAlchemy (Python) — both support Postgres well
```

### Runbooks

#### Runbook Template
```markdown
# Runbook: High Database Connection Count

## Overview
Alert fires when active PostgreSQL connections exceed 80% of `max_connections`.

## Impact
- Severity: P2 (new connections failing; existing requests may slow down)
- Affected: All users making API requests requiring DB access

## Diagnosis

### Step 1: Check current connection count
```sql
SELECT count(*), state
FROM pg_stat_activity
GROUP BY state;
```
Expected: `idle` < 80, `active` < 20. If `idle` is high → connection leak.

### Step 2: Find top connection consumers
```sql
SELECT application_name, count(*)
FROM pg_stat_activity
GROUP BY application_name
ORDER BY count DESC;
```

### Step 3: Check for long-running queries
```sql
SELECT pid, now() - pg_stat_activity.query_start AS duration, query, state
FROM pg_stat_activity
WHERE state != 'idle' AND now() - pg_stat_activity.query_start > interval '5 minutes';
```

## Mitigation

### Option A: Kill idle connections (immediate relief)
```sql
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE state = 'idle' AND state_change < now() - interval '10 minutes';
```

### Option B: Restart the affected app instance
```bash
kubectl rollout restart deployment/api-deployment -n production
```

### Option C: Scale up PgBouncer pool size (if load is legitimate)
Edit `k8s/pgbouncer-config.yaml`: increase `default_pool_size` from 20 to 40.
Apply: `kubectl apply -f k8s/pgbouncer-config.yaml`

## Prevention
- Ensure all DB connections use connection pooling (PgBouncer)
- Monitor `pg_stat_activity` in Grafana dashboard (link)
- Set `idle_in_transaction_session_timeout = 30s` in PostgreSQL config

## Escalation
If none of the above resolves within 15 minutes, page the database team.
Slack: #db-oncall | PagerDuty: Database Escalation policy
```

### Changelog Writing (Keep a Changelog Format)
```markdown
# Changelog

All notable changes to this project will be documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
Versioning: [Semantic Versioning](https://semver.org/)

## [Unreleased]

## [2.4.0] — 2024-02-01

### Added
- User profile photos with automatic resizing and WebP conversion
- Bulk export to CSV for reports (up to 10,000 records)
- Rate limiting on `/auth` endpoints (10 requests / 15 min)

### Changed
- Password minimum length increased from 8 to 12 characters
- API tokens now expire after 90 days (previously no expiry)

### Fixed
- Cart total incorrect when applying multiple discount codes (#892)
- Checkout form submits twice on slow connections (#901)

### Security
- Updated `jsonwebtoken` to 9.0.2 (CVE-2022-23541)
- Removed MD5 from password reset token generation

## [2.3.1] — 2024-01-20

### Fixed
- Admin panel inaccessible for users with special characters in email (#885)

## [2.3.0] — 2024-01-15
...

[Unreleased]: https://github.com/org/repo/compare/v2.4.0...HEAD
[2.4.0]: https://github.com/org/repo/compare/v2.3.1...v2.4.0
```

### Code Comments — When and How

#### When to Comment
```ts
// ✅ WHY — non-obvious reason or constraint
// Use a 1-second delay here because the payment gateway has an eventual-consistency
// window after capture; charging immediately causes duplicate transaction errors.
await sleep(1000);
await chargeCard(token, amount);

// ✅ Workaround for a specific bug
// Safari 16.x crashes on `crypto.subtle` in service workers (WebKit bug #245734).
// Fall back to the polyfill when SubtleCrypto is unavailable.
const subtle = crypto.subtle ?? await import("./subtle-polyfill");

// ✅ Warning about a subtle invariant
// IMPORTANT: This array must remain sorted by priority DESC.
// The scheduler picks the first item and assumes it has the highest priority.
const jobs = [...pendingJobs].sort((a, b) => b.priority - a.priority);

// ❌ Describing WHAT the code does (obvious from reading it)
// Increment the counter
counter++;

// ❌ Restating the function name
// Gets the user by ID
async function getUserById(id: string) { ... }

// ❌ Tracking history ("added for feature X") — belongs in git log
// Added 2024-01-15 to fix the race condition in checkout
```

#### Comment Quality Standards
```
Comments should survive:
  - Renaming the function they mention
  - Moving the code to another file
  - The original author leaving the team

Good comment tests:
  1. Does removing this comment make the code harder to understand?
  2. Would a new engineer with 3 years experience be confused without it?
  3. Is this still true? (stale comments are dangerous)
```

### Technical Writing Style Guide

#### Clarity Rules
```
1. One idea per sentence — split long compound sentences
   ❌ "The API returns a paginated list of users which can be filtered by role and sorted
       by name or creation date and the default page size is 20."
   ✅ "The API returns a paginated list of users. Default page size: 20.
       Filter by `role`. Sort by `name` or `createdAt` (default: `createdAt DESC`)."

2. Active voice — subject performs the action
   ❌ "The request is validated by the server."
   ✅ "The server validates the request."

3. Present tense — describes current behavior
   ❌ "This function will return null if the user is not found."
   ✅ "Returns null if the user is not found."

4. Second person — direct, less formal
   ❌ "The developer should configure the database connection string."
   ✅ "Configure the database connection string in `.env.local`."

5. Concrete before abstract — example first, then explanation
   ❌ "The system supports idempotent operations using unique keys."
   ✅ "Pass `Idempotency-Key: <uuid>` with payment requests. If the request fails
       and you retry with the same key, the server returns the original response
       without charging the card twice."
```

#### Formatting for Scanability
```markdown
## Use headings to create a table of contents
### Use sub-headings to group related content
#### Use H4 sparingly — three levels usually enough

**Bold** for: UI elements, terms being defined, critical warnings
`Code` for: commands, file paths, variable names, API endpoints, values
_Italic_ for: emphasis, titles, introducing new terms (once)

Use lists when:
- There are 3+ items (otherwise write as prose)
- Items are parallel in structure
- Order matters (numbered) or doesn't (bulleted)

Use tables for:
| Comparison | of options | or | configuration |
|---|---|---|---|
| With | clear | column | headers |

Use code blocks for:
- Any code (even 1 line)
- Commands the reader must run
- Config file contents
- Example API requests/responses

Use callouts for important information:
> **Note**: This only applies to Node.js 18+.
> **Warning**: This action is irreversible.
> **Tip**: Run `--dry-run` first to preview changes.
```

### Documentation Review Checklist

#### Before Merging Docs
- [ ] Accurate — reflects current behavior (not planned or historical)
- [ ] Complete — covers happy path + error cases + prerequisites
- [ ] Consistent — terminology matches rest of docs (e.g. always "user" not sometimes "account")
- [ ] Tested — all commands and code examples actually work
- [ ] Linked — related docs cross-referenced; no dead links
- [ ] Versioned — if behavior is version-specific, version is stated
- [ ] Searchable — headings use keywords users would search for
- [ ] No jargon — acronyms expanded on first use; internal jargon avoided

#### Documentation Debt Signals
```
Signs docs need urgent attention:
  - Slack/GitHub issues with "how do I..." that should be in docs
  - Onboarding takes > 2 days because of missing setup docs
  - Different team members give different answers to the same question
  - Runbook missing for a recurring incident
  - API consumers integrating incorrectly due to missing examples
  - "That's not in the docs, just ask Alice" becoming a pattern
```

### Diátaxis Framework (Documentation Structure)
```
The four documentation types serve different needs:

TUTORIALS (learning)          HOW-TO GUIDES (tasks)
  - Learning-oriented           - Goal-oriented
  - Study                       - Work
  - No choices — follow along   - Assumes competence
  - Success guaranteed          - Series of steps
  - Example: "Build your        - Example: "How to deploy
    first API in 5 minutes"       to production"

REFERENCE (information)       EXPLANATION (understanding)
  - Information-oriented        - Understanding-oriented
  - Consult                     - Study
  - Accurate and complete       - Provides context and background
  - Cold, factual               - Opinionated where appropriate
  - Example: "API endpoints     - Example: "Why we use
    and response schemas"         event sourcing"
```

### Auto-Generated Documentation

#### TypeDoc (TypeScript)
```bash
pnpm add -D typedoc typedoc-plugin-markdown
# typedoc.json
{
  "entryPoints": ["src/index.ts"],
  "out": "docs/api",
  "plugin": ["typedoc-plugin-markdown"],
  "excludePrivate": true,
  "excludeInternal": true,
  "readme": "none"
}
pnpm typedoc
```

#### mkdocs (Python / any language)
```yaml
# mkdocs.yml
site_name: My Project Docs
theme:
  name: material
  features:
    - navigation.tabs
    - search.suggest
    - content.code.copy

nav:
  - Home: index.md
  - Getting Started:
    - Installation: getting-started/installation.md
    - Quick Start: getting-started/quickstart.md
  - API Reference: api/
  - Architecture: architecture/
  - Runbooks: runbooks/

plugins:
  - search
  - mkdocstrings:  # auto-generate from docstrings
      handlers:
        python:
          options:
            show_source: false
```

```bash
mkdocs serve         # local preview at localhost:8000
mkdocs build         # output to site/
mkdocs gh-deploy     # deploy to GitHub Pages
```

### Documentation CI/CD
```yaml
# GitHub Actions — lint and deploy docs
- name: Lint markdown
  run: npx markdownlint-cli "**/*.md" --ignore node_modules

- name: Check for dead links
  run: npx markdown-link-check docs/**/*.md

- name: Check spelling
  run: npx cspell "**/*.md"

- name: Deploy to GitHub Pages
  if: github.ref == 'refs/heads/main'
  run: mkdocs gh-deploy --force
```

### Documentation Maintenance
```
Living documentation practices:
  - Docs updated in the same PR as the code change — not "will update later"
  - ADRs never edited after acceptance — add new ADR to supersede
  - Runbooks tested quarterly by on-call rotation (chaos/game days)
  - API docs generated from code (OpenAPI spec / TypeDoc) — never hand-edited
  - README quick-start tested monthly by running it on a clean machine
  - Changelog updated before every release (not after)
  - Dead links checked weekly in CI

Documentation ownership:
  - Each team owns docs for their services
  - No single "documentation team" — docs are engineering responsibility
  - Docs reviewed by at least one person who didn't write them
  - Non-obvious docs have a "last verified" date
```

---

## 💻 Terminal & Shell Skills

### Navigation & Files
```bash
# Find files
find . -name "*.ts" -not -path "*/node_modules/*"
fd "*.ts" --exclude node_modules          # fd is faster than find

# Search content
grep -r "TODO" src/ --include="*.ts"
rg "functionName" src/                    # ripgrep — fastest

# File operations
ls -la                                    # detailed listing
tree -L 2 --gitignore                     # directory tree
du -sh */ | sort -rh                      # disk usage by folder
stat filename                             # file metadata

# Permissions
chmod 755 script.sh                       # rwxr-xr-x
chmod 644 config.json                     # rw-r--r--
chown user:group file                     # change owner
```

### Process Management
```bash
ps aux | grep node                        # find processes
lsof -i :3000                            # what's using port 3000
kill -9 PID                              # force kill process
pkill -f "node server.js"               # kill by name
nohup ./script.sh &                      # run in background, survive logout
jobs                                     # list background jobs
fg %1                                    # bring job to foreground
```

### Networking
```bash
curl -X POST https://api.example.com/endpoint \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"key": "value"}' | jq .

wget -O output.file https://example.com/file

# Check connectivity
ping -c 4 google.com
traceroute google.com
nslookup domain.com
dig domain.com A

# Ports & connections
netstat -tlnp                            # listening ports
ss -tlnp                                 # modern netstat
```

### Text Processing
```bash
cat file | grep "error" | sort | uniq -c | sort -rn   # frequency count
awk '{print $1, $3}' file.txt            # print columns
sed -i 's/old/new/g' file.txt            # in-place replace
cut -d',' -f1,3 data.csv                 # CSV column extraction
jq '.users[] | .name' data.json          # JSON processing
wc -l file.txt                           # line count
head -20 / tail -20                      # first/last lines
less +F logfile.log                      # tail -f equivalent with scroll
```

### SSH
```bash
ssh user@host -p 22                      # connect
ssh -i ~/.ssh/key.pem user@host          # with key file
ssh -L 5432:localhost:5432 user@host     # local port forwarding (tunnel DB)
ssh -R 8080:localhost:3000 user@host     # remote port forwarding
scp -r ./dist user@host:/var/www/        # copy files to server
rsync -avz --exclude node_modules ./src user@host:/app/  # sync files

# SSH config (~/.ssh/config)
# Host myserver
#   HostName 192.168.1.100
#   User deploy
#   IdentityFile ~/.ssh/deploy_key
#   Port 22
```

### Environment & Variables
```bash
export VAR=value                         # set env var for session
echo $VAR                                # print var
printenv                                 # all env vars
source .env                              # load .env file
env VAR=value command                    # set var for single command
unset VAR                                # remove var
```

### Useful One-Liners
```bash
# Watch a command output every 2s
watch -n 2 "docker ps"

# Run command on file change
while inotifywait -e modify file.ts; do npm run build; done

# Generate a random secret
openssl rand -hex 32

# Base64 encode/decode
echo "hello" | base64
echo "aGVsbG8=" | base64 -d

# Timestamps
date +%Y-%m-%d_%H-%M-%S

# Disk space
df -h
ncdu /var/log                            # interactive disk usage
```

---

## 🐧 Ubuntu / Linux Server Skills

### System Setup & Updates
```bash
# Update system
sudo apt update && sudo apt upgrade -y
sudo apt autoremove -y && sudo apt clean

# Install essentials
sudo apt install -y \
  curl wget git vim htop tmux \
  build-essential software-properties-common \
  ufw fail2ban unattended-upgrades \
  net-tools dnsutils jq tree

# Check OS version
lsb_release -a
uname -r                                 # kernel version
```

### User Management
```bash
# Create deploy user (never run app as root)
sudo adduser deploy
sudo usermod -aG sudo deploy             # add to sudo group
sudo usermod -aG docker deploy           # add to docker group

# SSH key setup for user
sudo mkdir -p /home/deploy/.ssh
sudo cp ~/.ssh/authorized_keys /home/deploy/.ssh/
sudo chown -R deploy:deploy /home/deploy/.ssh
sudo chmod 700 /home/deploy/.ssh
sudo chmod 600 /home/deploy/.ssh/authorized_keys
```

### Firewall (UFW)
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh                       # port 22
sudo ufw allow 80/tcp                    # HTTP
sudo ufw allow 443/tcp                   # HTTPS
sudo ufw allow from 10.0.0.0/8 to any port 5432  # PostgreSQL — private network only
sudo ufw enable
sudo ufw status verbose
```

### Nginx
```bash
sudo apt install nginx -y
sudo systemctl enable nginx
sudo systemctl start nginx

# Config location
/etc/nginx/nginx.conf                    # main config
/etc/nginx/sites-available/             # site configs
/etc/nginx/sites-enabled/               # symlinked active configs

# Enable a site
sudo ln -s /etc/nginx/sites-available/myapp /etc/nginx/sites-enabled/
sudo nginx -t                            # test config
sudo systemctl reload nginx             # reload without downtime
```

```nginx
# /etc/nginx/sites-available/myapp
server {
    listen 80;
    server_name example.com www.example.com;
    return 301 https://$host$request_uri;  # force HTTPS
}

server {
    listen 443 ssl http2;
    server_name example.com;

    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
    add_header Strict-Transport-Security "max-age=31536000" always;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### SSL — Let's Encrypt (Certbot)
```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d example.com -d www.example.com
sudo certbot renew --dry-run             # test auto-renewal
# Auto-renewal via systemd timer is set up automatically
```

### Systemd Services (Run App as Service)
```ini
# /etc/systemd/system/myapp.service
[Unit]
Description=My Node.js App
After=network.target

[Service]
Type=simple
User=deploy
WorkingDirectory=/home/deploy/app
ExecStart=/usr/bin/node dist/index.js
Restart=on-failure
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=myapp
Environment=NODE_ENV=production
EnvironmentFile=/home/deploy/app/.env

[Install]
WantedBy=multi-user.target
```
```bash
sudo systemctl daemon-reload
sudo systemctl enable myapp
sudo systemctl start myapp
sudo systemctl status myapp
journalctl -u myapp -f                  # follow logs
```

### Log Management
```bash
# View logs
journalctl -u nginx --since "1 hour ago"
journalctl -f                            # follow all system logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log

# Log rotation — /etc/logrotate.d/myapp
/home/deploy/app/logs/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    sharedscripts
    postrotate
        systemctl reload myapp
    endscript
}
```

### Performance & Monitoring
```bash
htop                                     # interactive process monitor
iotop                                    # disk I/O monitor
nethogs                                  # network usage by process
vmstat 1                                 # CPU/memory/IO stats every 1s
iostat -xz 1                            # disk stats
free -h                                  # memory usage
df -h                                    # disk space

# Check what's eating resources
top -b -n 1 | head -20
ps aux --sort=-%mem | head -10          # top memory consumers
ps aux --sort=-%cpu | head -10          # top CPU consumers
```

### Security Hardening
```bash
# Disable root SSH login and password auth
sudo vim /etc/ssh/sshd_config
# Set: PermitRootLogin no
# Set: PasswordAuthentication no
# Set: PubkeyAuthentication yes
sudo systemctl restart sshd

# Fail2ban for brute force protection
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
sudo fail2ban-client status sshd

# Automatic security updates
sudo dpkg-reconfigure -plow unattended-upgrades

# Audit open ports
sudo ss -tlnp
sudo nmap -sV localhost
```

### Node.js on Ubuntu
```bash
# Install Node via nvm (preferred — version manageable)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc
nvm install 20
nvm use 20
nvm alias default 20

# Install pnpm
npm install -g pnpm

# PM2 for process management (alternative to systemd for Node)
npm install -g pm2
pm2 start dist/index.js --name myapp
pm2 startup                              # generate startup script
pm2 save                                 # save process list
pm2 logs myapp                          # view logs
pm2 monit                               # monitor dashboard
```

### Server Maintenance Checklist
- [ ] OS packages updated (`apt update && apt upgrade`)
- [ ] SSL certificates valid and auto-renewing
- [ ] Disk space > 20% free (`df -h`)
- [ ] Backups verified and restorable
- [ ] Firewall rules audited (`ufw status`)
- [ ] Failed login attempts reviewed (`fail2ban-client status`)
- [ ] Application logs checked for errors
- [ ] Memory/CPU baseline normal (`htop`)

---

## ⚠️ Off-Limits (Always Require Human Confirmation)

Claude must **never** do the following without explicit confirmation:

- Delete files, folders, or database records
- Run `DROP`, `TRUNCATE`, or `DELETE` without `WHERE` clause
- Modify CI/CD pipeline configs or deployment workflows
- Push to `main`, `staging`, or any protected branch
- Change environment variables in staging or production
- Publish packages, create releases, or tag versions
- Expose, log, or commit secrets of any kind
- Apply Kubernetes manifests to production cluster
- Run Ansible playbooks against production inventory
- Accept ToS, grant OAuth permissions, or click "Deploy to production"
- Modify IAM policies, firewall rules, or security groups

---

## 🔧 Skill Usage — Always Proactive

Always invoke the relevant skill before responding to development tasks. Do NOT skip skills to save time.

| Task context | Skill / Command to invoke |
|---|---|
| Bug report / failing behaviour / "X is broken" | `/fix` — Scout → Diagnose → Plan → Apply → Verify, with 6-question diagnosis + 3-strike stop |
| New feature / "implement X" / "build Y" | `/cook` — Spec (5 items) → Plan → Build → Verify → Review, with artifact-gate |
| "Look at X" / "where does Y live" / area survey | `/scout` — read-only reconnaissance |
| Running or starting the app | `run` |
| Verifying a fix / confirming a feature works | `verify` |
| Reviewing code changes or diffs | `code-review` |
| Reviewing a pull request | `review` |
| Security audit of pending changes | `security-review` |
| Any `.pptx` file involved | `pptx` |
| Any `.xlsx` / `.csv` / `.tsv` file involved | `xlsx` |
| Any `.docx` / Word document involved | `docx` |
| Any `.pdf` file involved | `pdf` |
| Code imports `anthropic` / Anthropic SDK | `claude-api` |
| Configuring hooks, permissions, settings.json | `update-config` |

### Evidence over score
**Never** approve work based on a self-assigned score ("9/10, ship it"). Approval requires:
- Acceptance criteria all green (from `/cook` spec) OR reproduction steps fail post-fix then pass post-fix (from `/fix` diagnosis)
- `.claude-artifacts/verification.json` exists with green commands logged
- `.claude-artifacts/review-decision.json` decision ∈ `{PASS, PASS_WITH_RISK}`
- Zero unresolved **critical** issues from `code-review`

The PreToolUse artifact-gate hook enforces this for `git push`, `gh pr create`, `npm publish`, and `vercel deploy`. To bypass for a one-off command, set `CLAUDE_SKIP_ARTIFACT_GATE=1` and tell the user why.

**Rule:** If the task matches a skill trigger, invoke the skill FIRST — then proceed.

### ⚠️ MANDATORY for Every Development / Coding Task

After completing **any** code change (editing files, fixing bugs, adding features, updating styles, refactoring), ALWAYS run these two skills in order — no exceptions:

1. **`verify`** — Run the app and visually/functionally confirm the change works as intended.
2. **`code-review`** — Review the diff for correctness bugs before calling the task done.

**Do NOT** skip either skill to save time. If the app cannot be started (e.g. Chrome extension disconnected, no dev server), explicitly tell the user what blocked verification and ask them to confirm manually.

Full mandatory checklist for every coding session:
- [ ] Relevant skills from the table above identified and invoked at start
- [ ] Code changes made
- [ ] `verify` invoked — app running and change confirmed visually
- [ ] `code-review` invoked — diff reviewed for bugs
- [ ] Short summary given: what changed and why

---

## 📝 Project-Level Overrides

Each project's own `CLAUDE.md` (in the repo root) can override any section above.
Global rules apply when no project-level override exists.
Conflicts: project-level always wins.
