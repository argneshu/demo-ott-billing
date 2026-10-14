# E2E Test Steps - Story 1.5: Confirm upgrade and refresh Billing page

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

### TC-E2E-01 - Full upgrade without a reload

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-07, REQ-F-09 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | The locally built instance in System Under Test is running. A browser is available; sign in at http://localhost:5173 as `tpg@example.com` / `password` unless stated. |
| **Test data** | Seed account; note renewal date `Oct 30, 2026`; DevTools Network tab open (Preserve log on) |

**Steps**
1. Open Billing, open the dialog and click "Confirm Upgrade".

**Expected result**
- Exactly one `POST /api/billing/upgrade` is sent.
- The dialog closes and no full page navigation or reload occurs.
- The page shows Premium, "$40/month", renewal `Oct 30, 2026`, usage cards "4K Ultra HD", "Can watch on 4 devices at once", "Can download on 6 devices".
- The "Upgrade to Premium" button is gone.

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

### TC-E2E-02 - Success message appears and disappears

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-07 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | The locally built instance in System Under Test is running. A browser is available; sign in at http://localhost:5173 as `tpg@example.com` / `password` unless stated. |
| **Test data** | Seed account |

**Steps**
1. Confirm the upgrade and watch the page.

**Expected result**
- The message "You're now on Premium! Your next full cycle bills at $40/month." appears.
- It disappears by itself after a few seconds.

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

### TC-E2E-03 - Failed request keeps the dialog open

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-F-10 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | The locally built instance in System Under Test is running. A browser is available; sign in at http://localhost:5173 as `tpg@example.com` / `password` unless stated. |
| **Test data** | Seed account |

**Steps**
1. Open the dialog.
2. Stop the backend (or block `/api/billing/upgrade` in DevTools).
3. Click "Confirm Upgrade".
4. Restore the backend and click "Confirm Upgrade" again.

**Expected result**
- After the failure: an inline error shows in the dialog, the dialog stays open and the page still shows Standard, "$20/month".
- "Confirm Upgrade" is clickable again; after restoring the backend the retry succeeds as in TC-E2E-01.

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

### TC-E2E-04 - Regression: login, logout, registration, invalid login

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-NF-05 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | The locally built instance in System Under Test is running. A browser is available; sign in at http://localhost:5173 as `tpg@example.com` / `password` unless stated. |
| **Test data** | Seed account; new account `reg1@example.com` / `pw` |

**Steps**
1. Sign in, open Billing, sign out, sign in again.
2. Register `reg1@example.com` and open Billing.
3. Try to sign in with a wrong password.

**Expected result**
- The Billing page shows the current plan after each sign-in.
- The new account lands on Standard, "$20/month" with its own usage cards.
- The wrong password shows "Invalid credentials".

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

### TC-E2E-05 - Browser-test evidence exists for this story

| Field | Value |
|-------|-------|
| **Traces to** | AC-5 / REQ-NF-02 |
| **Type** | E2E |
| **Priority** | P3 |
| **Preconditions** | The locally built instance in System Under Test is running. |
| **Test data** | none |

**Steps**
1. List the files under `tests/e2e/` for this story.
2. Open the latest Playwright run report saved for this story under `reports/`.

**Expected result**
- A spec runs the full upgrade flow against the real backend and a second spec forces the upgrade request to fail and asserts the dialog stays open.
- Both are recorded as passed.

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

