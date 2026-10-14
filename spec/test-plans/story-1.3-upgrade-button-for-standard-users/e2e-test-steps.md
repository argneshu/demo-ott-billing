# E2E Test Steps - Story 1.3: Upgrade button for Standard users

Scope: manual test steps derived from the acceptance criteria only (black-box). Requirements: REQ-F-01, REQ-NF-07.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/self-serve-premium-upgrade` |
| This story's PR | Story 1.3 PR into the epic branch (number recorded in the Story Tracker once raised); execute only after it has merged |
| Confirm the story is in the build | `git log --oneline | grep "1.3"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | Frontend http://localhost:5173 (Vite dev server); API http://localhost:8000 (frontend proxies `/api` to it) |
| Local services that must be up | Backend API and frontend dev server; no other services |
| Test data / accounts to seed | Seed account `tpg@example.com` / `password` (Standard, renews `Oct 30, 2026`). Extra accounts are created through the registration screen or `POST /api/auth/register` |

> If the build or local run fails, that is a **blocker on the dev team** - report it and do not log functional failures against a system that never started.

### TC-E2E-01 - Standard subscriber sees the upgrade button

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-01 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | The locally built instance in System Under Test is running. A browser is available; sign in at http://localhost:5173 as `tpg@example.com` / `password` unless stated. |
| **Test data** | Seed account (Standard) |

**Steps**
1. Sign in and open the Billing page.

**Expected result**
- An "Upgrade to Premium" button is visible.
- It sits below the current plan card, not inside the usage cards.

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

### TC-E2E-02 - Premium subscriber does not see the button

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-01 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | The locally built instance in System Under Test is running. A browser is available; sign in at http://localhost:5173 as `tpg@example.com` / `password` unless stated. A Premium account exists (upgrade one through Story 1.1's API; if that story is not in the build, mark this case Blocked). |
| **Test data** | A registered account upgraded to Premium |

**Steps**
1. Sign in as the Premium account and open the Billing page.

**Expected result**
- The plan shows Premium and no "Upgrade to Premium" button is present anywhere on the page.

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

### TC-E2E-03 - Button after sign-out and sign-in

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-01 |
| **Type** | E2E |
| **Priority** | P3 |
| **Preconditions** | The locally built instance in System Under Test is running. A browser is available; sign in at http://localhost:5173 as `tpg@example.com` / `password` unless stated. |
| **Test data** | Seed account |

**Steps**
1. Sign in, open Billing, sign out, sign in again, open Billing.

**Expected result**
- The button is visible each time for a Standard account.

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

### TC-E2E-04 - Browser-test evidence exists for this story

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-NF-02 |
| **Type** | E2E |
| **Priority** | P3 |
| **Preconditions** | The locally built instance in System Under Test is running. |
| **Test data** | none |

**Steps**
1. List the files under `tests/e2e/` for this story.
2. Open the latest Playwright run report saved for this story under `reports/`.

**Expected result**
- A spec asserts the button is visible for the Standard seed user and a second asserts it is absent when the billing response is mocked as Premium.
- Both tests are recorded as passed.

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

