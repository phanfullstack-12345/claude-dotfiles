# Reference: security-guide
# Load this file when working on tasks matching this domain.

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

