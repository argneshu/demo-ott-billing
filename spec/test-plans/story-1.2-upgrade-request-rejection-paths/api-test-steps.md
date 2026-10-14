# API Test Steps - Story 1.2: Upgrade request rejection paths

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

### TC-API-01 - Already-Premium account is refused

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-05 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | The locally built instance in System Under Test is running. A tool for HTTP requests (curl or an API client) is available. |
| **Test data** | `fresh4@example.com` / `pw4` |

**Steps**
1. Register and upgrade the account (HTTP 200).
2. Send the upgrade request again.
3. Call `GET /api/billing` for the account.

**Expected result**
- Second request: HTTP 400 with `{"detail":"Already on Premium plan"}`.
- Billing still shows Premium, "$40/month", unchanged `renew_at`.

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

### TC-API-02 - Unknown email is refused

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-05 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | The locally built instance in System Under Test is running. A tool for HTTP requests (curl or an API client) is available. |
| **Test data** | `{"email":"ghost@example.com"}` |

**Steps**
1. Send the upgrade request.
2. Call `GET /api/users/me?email=ghost@example.com`.

**Expected result**
- Upgrade: HTTP 401 with `{"detail":"Not authenticated"}`.
- users/me also returns 401, so no account was created.

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

### TC-API-03 - Malformed bodies are rejected

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-NF-01 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | The locally built instance in System Under Test is running. A tool for HTTP requests (curl or an API client) is available. |
| **Test data** | Bodies: `{}`, `{"email":""}`, `{"email":123}`, `{"email":null}`, and a body that is not JSON |

**Steps**
1. Send the upgrade request once for each body.
2. After all requests, call `GET /api/billing?email=tpg@example.com`.

**Expected result**
- Each request returns HTTP 422.
- The seed account is still Standard, "$20/month".

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

### TC-API-04 - Unexpected failure returns a safe response

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-NF-01 |
| **Type** | API |
| **Priority** | P3 |
| **Preconditions** | The locally built instance in System Under Test is running. A tool for HTTP requests (curl or an API client) is available. TO CONFIRM: there is no public way to force an internal failure; confirm with the developer whether this is covered only by automated unit tests. |
| **Test data** | none |

**Steps**
1. If an approved failure-injection hook exists, trigger it and send an upgrade request.
2. Otherwise record this case as covered by the automated tests (Story 1.2 AC-5) and mark it Not Executable.

**Expected result**
- HTTP 500 with a generic body: no stack trace, file path, password or token.
- The account is still on its previous plan.

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

### TC-API-05 - Repeated upgrades always fail

| Field | Value |
|-------|-------|
| **Traces to** | AC-5 / REQ-F-05 |
| **Type** | API |
| **Priority** | P2 |
| **Preconditions** | The locally built instance in System Under Test is running. A tool for HTTP requests (curl or an API client) is available. |
| **Test data** | `fresh5@example.com` / `pw5` |

**Steps**
1. Register and upgrade the account.
2. Send the upgrade request three more times.
3. Call `GET /api/billing`.

**Expected result**
- Every repeat returns HTTP 400 "Already on Premium plan".
- The account stays Premium with the same `renew_at`.

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

