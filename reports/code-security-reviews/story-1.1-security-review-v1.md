# Code Security Review Report

**Date**: 2026-10-14
**Reviewer**: AI Security Audit (AIRE Security Baseline)
**Rules Source**: `aire-workflow/extensions/security/baseline/security-baseline.md`
**Project**: demo-ott-billing
**Tech Stack**: Python 3.14, FastAPI 0.143.0, Pydantic 2, in-memory dicts (no database); React/Vite frontend (not touched by this story)
**Scan Scope**: This work unit's diff (Story 1.1, `src/backend/main.py`, `src/backend/requirements-dev.txt`, tests) and the attack surface it reaches (`POST /api/billing/upgrade` and the `users` / `billing_data` dicts). Not a full-codebase audit.
**Review version**: v1

---

## Executive Summary

- **Total Findings**: 6 on the changed surface (1 High waived by user decision, 4 Medium, 1 Low) plus pre-existing items noted separately
- **Critical/Blocker**: 0
- **High**: 1 (SEC-001, waived by the user's accepted deviation REQ-NF-01)
- **Medium**: 4
- **Low**: 1
- **Security Rules Checked**: 16/16
- **Rules Compliant**: 3/16 (SECURITY-09, 10, 12 on the changed surface)
- **Rules Non-Compliant**: 7/16 (SECURITY-03, 04, 05, 08, 11, 13, 15; SECURITY-04 is pre-existing)
- **Rules N/A**: 6/16 (SECURITY-01, 02, 06, 07, 14, 16)
- **Overall Risk Rating**: Medium (the endpoint trusts a caller-supplied email, accepted for this POC)

---

## Findings Summary Table

| # | Severity | Security Rule | Title | File(s) | Line(s) |
|---|----------|--------------|-------|---------|---------|
| SEC-001 | High (waived) | SECURITY-08 | Upgrade endpoint has no authentication or object-level authorization | `src/backend/main.py` | 231-246 |
| SEC-002 | Medium | SECURITY-05 | Email field has no maximum length or format validation | `src/backend/main.py` | 85-86 |
| SEC-003 | Medium | SECURITY-15 / SECURITY-03 | No global exception handler or logging for the new endpoint | `src/backend/main.py` | 231-246 |
| SEC-004 | Medium | SECURITY-13 | Plan change is not recorded in an audit log (who, what, when) | `src/backend/main.py` | 243-245 |
| SEC-005 | Medium | SECURITY-11 | No rate limiting on the upgrade endpoint | `src/backend/main.py` | 231 |
| SEC-006 | Low | SECURITY-10 | `requirements.txt` has no pinned versions or lock file (pre-existing manifest; the new dev manifest is pinned) | `src/backend/requirements.txt` | 1-3 |

---

## Critical / Blocker Findings

None.

---

## High Findings

### [SEC-001] Upgrade endpoint has no authentication or object-level authorization (WAIVED)
- **Severity**: High
- **Security Rule**: SECURITY-08 - Application-Level Access Control
- **Verification Criteria Violated**: every handler has an authorization guard; no endpoint acts on a resource ID without verifying the caller owns it
- **File(s)**: `src/backend/main.py` (Lines 231-246)
- **Description**: `POST /api/billing/upgrade` takes `email` from the request body and upgrades that account. Any caller who knows an email can upgrade that account. The existing POC auth model uses the email as the token and no endpoint verifies a credential.
- **Evidence**: `user = users.get(payload.email)` followed by `user["plan"] = "Premium"` with no check that the caller is that user.
- **Impact**: an unauthenticated caller can switch another account to Premium. In this POC there is no payment, so the impact is limited to unwanted plan changes.
- **Remediation**: require the caller's token (the same `email` query parameter the other endpoints use, ideally a real signed token) and return 401/403 when it does not match the body email; take identity only from the token.
- **Decision on record**: the user chose to follow the Epic as written (Requirements Q1 A, approved in `spec/plans/requirements.md` REQ-NF-01) and accept this as a documented POC deviation. It is therefore reported here, not remediated, and not scored in J2 SEC-01. Reversing it means changing REQ-NF-01 first.
- **References**: CWE-862 / CWE-639, OWASP A01:2025

---

## Medium Findings

### [SEC-002] Email field has no maximum length or format validation
- **Severity**: Medium - **Security Rule**: SECURITY-05 - **Criteria**: string inputs have explicit max-length constraints; type checking
- **File(s)**: `src/backend/main.py` (Lines 85-86)
- **Description**: `UpgradeRequest.email` is a plain `str`. Pydantic rejects non-strings, but a very long string is accepted and looked up.
- **Remediation**: `email: StrictStr = Field(min_length=1, max_length=254)`. Planned in Story 1.2 AC-3.
- **References**: CWE-20, OWASP A05:2025

### [SEC-003] No global exception handler or logging for the new endpoint
- **Severity**: Medium - **Security Rule**: SECURITY-15, SECURITY-03 - **Criteria**: a global error handler is configured; logging framework configured
- **File(s)**: `src/backend/main.py` (Lines 231-246); the application has no handler or logger anywhere
- **Description**: an unexpected exception would surface through the framework default (a generic 500 body, no stack trace to the client), but nothing is logged.
- **Remediation**: add a global handler that logs the exception (no secrets) and returns a generic body. Planned in Story 1.2 AC-4.
- **References**: CWE-755, OWASP A10:2025

### [SEC-004] Plan change is not audit-logged
- **Severity**: Medium - **Security Rule**: SECURITY-13 - **Criteria**: critical data changes are logged with actor, timestamp and before/after values
- **File(s)**: `src/backend/main.py` (Lines 243-245)
- **Description**: the plan and price change leaves no record. No story in this epic covers it.
- **Remediation**: log an audit event (email, old plan, new plan, charge, timestamp) via the logger added in Story 1.2. Recommend a follow-up ticket.
- **References**: CWE-778, OWASP A09:2025

### [SEC-005] No rate limiting on the upgrade endpoint
- **Severity**: Medium - **Security Rule**: SECURITY-11 - **Criteria**: rate limiting on public-facing APIs
- **File(s)**: `src/backend/main.py` (Line 231)
- **Description**: no throttling exists anywhere in the app (pre-existing); the new endpoint inherits it. Abuse is bounded because a second upgrade is refused (HTTP 400).
- **Remediation**: add middleware-level rate limiting when the app gets real authentication.
- **References**: CWE-770, OWASP A06:2025

---

## Low Findings

### [SEC-006] Runtime dependencies are unpinned and there is no lock file
- **Severity**: Low - **Security Rule**: SECURITY-10 - **Criteria**: a lock file exists; exact versions
- **File(s)**: `src/backend/requirements.txt` (pre-existing, not changed by this story)
- **Description**: the new `requirements-dev.txt` pins exact versions; the runtime manifest does not. `pip-audit` found no known vulnerabilities.
- **Remediation**: pin and lock the runtime dependencies. Pre-existing; recommend `/raise-defect`.
- **References**: CWE-1104, OWASP A03:2025

---

## Pre-existing findings (not this change - recorded, never remediated here)
- SECURITY-04: no HTTP security headers (the SPA is served by `StaticFiles` without CSP/HSTS/nosniff/frame headers).
- SECURITY-08 / SECURITY-09: `CORSMiddleware` allows every origin with credentials (`main.py:12`, also the one semgrep finding `wildcard-cors`).
- SECURITY-09 / SECURITY-12: seed account with a default password; plaintext password comparison and storage; email is the access token; no brute-force protection, no session expiry.
- SECURITY-03: no logging configured anywhere in the application.
- Recommend raising these with `/raise-defect`; they existed on the epic branch before this story.

---

## Security Baseline Compliance Matrix

| Security Rule | Rule Name | Status | Findings |
|---|---|---|---|
| SECURITY-01 | Encryption at Rest and in Transit | N/A - no data store; data is in process memory | 0 |
| SECURITY-02 | Access Logging on Network Intermediaries | N/A - no load balancer, gateway or CDN in the repo | 0 |
| SECURITY-03 | Application-Level Logging | Non-Compliant (no logging; see SEC-003) | 1 |
| SECURITY-04 | HTTP Security Headers | Non-Compliant, pre-existing (the change adds no HTML endpoint) | 0 on the change |
| SECURITY-05 | Input Validation | Non-Compliant (SEC-002) | 1 |
| SECURITY-06 | Least-Privilege Access Policies | N/A - no IAM | 0 |
| SECURITY-07 | Restrictive Network Configuration | N/A - no network resources | 0 |
| SECURITY-08 | Application-Level Access Control | Non-Compliant, waived (SEC-001) | 1 |
| SECURITY-09 | Security Hardening | Compliant on the change (error bodies carry no internals); pre-existing default credentials noted | 0 on the change |
| SECURITY-10 | Software Supply Chain Security | Compliant for the new dev manifest; runtime manifest pre-existing (SEC-006) | 1 Low |
| SECURITY-11 | Secure Design Principles | Non-Compliant on rate limiting (SEC-005); misuse case (repeat upgrade) handled | 1 |
| SECURITY-12 | Authentication and Credential Management | Compliant on the change (no credentials returned, logged or stored); pre-existing weaknesses noted | 0 on the change |
| SECURITY-13 | Software and Data Integrity Verification | Non-Compliant (SEC-004, no audit trail); no deserialization or XML | 1 |
| SECURITY-14 | Alerting and Monitoring | N/A - no deployed monitoring in this repo | 0 |
| SECURITY-15 | Exception Handling and Fail-Safe Defaults | Non-Compliant (SEC-003); the endpoint fails closed and mutates only after checks | 1 |
| SECURITY-16 | Cryptographic Standards | N/A - no cryptography in the change | 0 |

Counts: 3 compliant, 7 non-compliant, 6 N/A.

---

## OWASP Reference Mapping
SECURITY-08 to A01:2025, SECURITY-05 to A05:2025, SECURITY-15 / 03 to A10:2025 / A09:2025, SECURITY-13 to A08:2025, SECURITY-11 to A06:2025, SECURITY-10 to A03:2025.

---

## Recommendations Priority

### Immediate (Blocks Deployment)
1. None for this POC, with the accepted SEC-001 deviation recorded. Before any real deployment, SEC-001 must be fixed.

### Short-Term (Current Sprint)
1. Story 1.2: SEC-002 (bounded `StrictStr` email) and SEC-003 (global handler with logging).

### Medium-Term (Current Release)
1. SEC-004 audit logging of plan changes; SEC-005 rate limiting.

### Long-Term (Backlog)
1. SEC-006 pin and lock runtime dependencies; the pre-existing items above.

---

## Appendix

### Methodology
- Manual code review against the AIRE Security Baseline (SECURITY-01 through SECURITY-16), scoped to this work unit's diff.
- Supporting evidence: semgrep (1 pre-existing finding, 0 new), pip-audit (0 vulnerabilities), gitleaks (0 findings).

### Excluded from Scope
- Frontend code (not touched by Story 1.1) and all code not in this diff, except where noted as pre-existing.
