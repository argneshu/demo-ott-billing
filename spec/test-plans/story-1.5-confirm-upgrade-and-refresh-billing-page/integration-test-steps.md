# Integration Test Steps - Story 1.5: Confirm upgrade and refresh Billing page

Scope: manual test steps derived from the acceptance criteria only (black-box). Requirements: REQ-F-07, REQ-F-09, REQ-F-10, REQ-NF-05.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/self-serve-premium-upgrade` |
| This story's PR | Story 1.5 PR into the epic branch (number recorded in the Story Tracker once raised); execute only after it has merged |
| Confirm the story is in the build | `git log --oneline | grep "1.5"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | Frontend http://localhost:5173 (Vite dev server); API http://localhost:8000 (frontend proxies `/api` to it) |
| Local services that must be up | Backend API and frontend dev server; no other services |
| Test data / accounts to seed | Seed account `tpg@example.com` / `password` (Standard, renews `Oct 30, 2026`). Extra accounts are created through the registration screen or `POST /api/auth/register` |

> If the build or local run fails, that is a **blocker on the dev team** - report it and do not log functional failures against a system that never started.

### TC-INT-01 - UI and API agree after the upgrade

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-07 |
| **Type** | Integration |
| **Priority** | P1 |
| **Preconditions** | The locally built instance in System Under Test is running. A browser is available; sign in at http://localhost:5173 as `tpg@example.com` / `password` unless stated. HTTP tool available. |
| **Test data** | Seed account |

**Steps**
1. Upgrade through the UI.
2. Call `GET /api/billing?email=tpg@example.com`.
3. Reload the Billing page.

**Expected result**
- The API returns Premium, "$40/month" and the original `renew_at`.
- After the reload the page still shows Premium and no upgrade button.

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

### TC-INT-02 - A failed request changes nothing on the server

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-F-10 |
| **Type** | Integration |
| **Priority** | P1 |
| **Preconditions** | The locally built instance in System Under Test is running. A browser is available; sign in at http://localhost:5173 as `tpg@example.com` / `password` unless stated. HTTP tool available. |
| **Test data** | Seed account |

**Steps**
1. Make the upgrade request fail (block it in DevTools so it never reaches the server).
2. Click "Confirm Upgrade".
3. Call `GET /api/billing?email=tpg@example.com`.

**Expected result**
- The API still returns Standard, "$20/month".
- The UI shows the inline error and unchanged Standard data.

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

