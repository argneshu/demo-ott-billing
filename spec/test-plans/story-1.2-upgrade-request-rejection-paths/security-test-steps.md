# Security Test Steps - Story 1.2: Upgrade request rejection paths

Scope: manual test steps derived from the acceptance criteria only (black-box). Requirements: REQ-F-05, REQ-NF-01.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/self-serve-premium-upgrade` |
| This story's PR | Story 1.2 PR into the epic branch (number recorded in the Story Tracker once raised); execute only after it has merged |
| Confirm the story is in the build | `git log --oneline | grep "1.2"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | Frontend http://localhost:5173 (Vite dev server); API http://localhost:8000 (frontend proxies `/api` to it) |
| Local services that must be up | Backend API and frontend dev server; no other services |
| Test data / accounts to seed | Seed account `tpg@example.com` / `password` (Standard, renews `Oct 30, 2026`). Extra accounts are created through the registration screen or `POST /api/auth/register` |

> If the build or local run fails, that is a **blocker on the dev team** - report it and do not log functional failures against a system that never started.

### TC-SEC-01 - Error bodies expose nothing sensitive

| Field | Value |
|-------|-------|
| **Traces to** | AC-2, AC-3, AC-4 / REQ-NF-01 |
| **Type** | Security |
| **Priority** | P1 |
| **Preconditions** | The locally built instance in System Under Test is running. A tool for HTTP requests (curl or an API client) is available. |
| **Test data** | Cases from TC-API-02, TC-API-03 |

**Steps**
1. Repeat the 401 and 422 requests and read the full response bodies and the backend console output.

**Expected result**
- No password, token, stack trace or server file path in any body.
- The backend log does not contain the request body or any password.

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

### TC-SEC-02 - Injection-style email is treated as plain data

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-NF-01 |
| **Type** | Security |
| **Priority** | P2 |
| **Preconditions** | The locally built instance in System Under Test is running. A tool for HTTP requests (curl or an API client) is available. |
| **Test data** | Emails: `<script>alert(1)</script>`, `' OR 1=1 --`, a 5,000-character string |

**Steps**
1. Send the upgrade request once for each email.

**Expected result**
- Each request returns HTTP 401 or 422, never HTTP 500 and never 200.
- No account is created and no script is reflected in any response.

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

