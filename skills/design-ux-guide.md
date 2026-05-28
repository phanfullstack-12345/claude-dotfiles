# Reference: design-ux-guide
# Load this file when working on tasks matching this domain.

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

