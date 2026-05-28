# Reference: html-css-js-guide
# Load this file when working on tasks matching this domain.

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

