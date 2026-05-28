# Reference: react-nextjs-guide
# Load this file when working on tasks matching this domain.

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

