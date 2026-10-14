# E2E Test Steps - Story 1.4: Upgrade confirmation modal with prorated preview

Scope: manual test steps derived from the acceptance criteria only (black-box). Requirements: REQ-F-02, REQ-F-03, REQ-F-08, REQ-NF-07.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/self-serve-premium-upgrade` |
| This story's PR | Story 1.4 PR into the epic branch (number recorded in the Story Tracker once raised); execute only after it has merged |
| Confirm the story is in the build | `git log --oneline | grep "1.4"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | Frontend http://localhost:5173 (Vite dev server); API http://localhost:8000 (frontend proxies `/api` to it) |
| Local services that must be up | Backend API and frontend dev server; no other services |
| Test data / accounts to seed | Seed account `tpg@example.com` / `password` (Standard, renews `Oct 30, 2026`). Extra accounts are created through the registration screen or `POST /api/auth/register` |

> If the build or local run fails, that is a **blocker on the dev team** - report it and do not log functional failures against a system that never started.

### TC-E2E-01 - Dialog contents

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-02 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | The locally built instance in System Under Test is running. A browser is available; sign in at http://localhost:5173 as `tpg@example.com` / `password` unless stated. |
| **Test data** | Seed account; note today's date |

**Steps**
1. Open Billing and click "Upgrade to Premium".

**Expected result**
- A dialog opens showing current plan Standard at $20/mo and new plan Premium at $40/mo.
- It shows the days remaining and the sentence "You'll be charged $X.XX today for the N days remaining in your cycle."
- It has "Confirm Upgrade" and "Cancel" buttons.
- Browser DevTools Network tab shows no request to `/api/billing/upgrade`.

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

### TC-E2E-02 - Displayed amount matches the rule

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-03 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | The locally built instance in System Under Test is running. A browser is available; sign in at http://localhost:5173 as `tpg@example.com` / `password` unless stated. |
| **Test data** | Seed account (`Oct 30, 2026`) |

**Steps**
1. Work out days remaining from `Oct 30, 2026` and today's date (floor 0, cap 30).
2. Open the dialog and read the days and amount.

**Expected result**
- Days and amount match the working-out; Expected charge = round(20 x days_remaining / 30, 2), days_remaining = renewal date minus today, floored at 0 and capped at 30 (for example 0 gives 0.00, 15 gives 10.00, 29 gives 19.33, 30 or more gives 20.00).

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

### TC-E2E-03 - Boundary amounts

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-03 |
| **Type** | E2E |
| **Priority** | P2 |
| **Preconditions** | The locally built instance in System Under Test is running. A browser is available; sign in at http://localhost:5173 as `tpg@example.com` / `password` unless stated. TO CONFIRM: how the tester sets "today" locally (system clock or a test hook); the seed renewal date is fixed, so only today's date can vary. |
| **Test data** | Browser date set to Oct 30, Oct 15, Oct 01 and Sep 01 2026 |

**Steps**
1. For each date, reload Billing, open the dialog and read the amount.

**Expected result**
- Oct 30 gives $0.00 (0 days); Oct 15 gives $10.00 (15 days); Oct 01 gives $19.33 (29 days); Sep 01 gives $20.00 (30 days, capped).

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

### TC-E2E-04 - Cancel closes the dialog

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-F-08 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | The locally built instance in System Under Test is running. A browser is available; sign in at http://localhost:5173 as `tpg@example.com` / `password` unless stated. |
| **Test data** | Seed account; DevTools Network tab open |

**Steps**
1. Open the dialog and click Cancel.

**Expected result**
- The dialog closes; the page still shows Standard, "$20/month".
- No request to `/api/billing/upgrade` was made.
- Focus is back on the "Upgrade to Premium" button.

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

### TC-E2E-05 - Escape closes the dialog

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-F-08 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | The locally built instance in System Under Test is running. A browser is available; sign in at http://localhost:5173 as `tpg@example.com` / `password` unless stated. |
| **Test data** | Seed account; DevTools Network tab open |

**Steps**
1. Open the dialog and press Escape.

**Expected result**
- Same outcome as TC-E2E-04.

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

### TC-E2E-06 - Close control closes the dialog

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-F-08 |
| **Type** | E2E |
| **Priority** | P2 |
| **Preconditions** | The locally built instance in System Under Test is running. A browser is available; sign in at http://localhost:5173 as `tpg@example.com` / `password` unless stated. |
| **Test data** | Seed account; DevTools Network tab open |

**Steps**
1. Open the dialog and click its close control (or click outside it if that is the designed close behaviour; TO CONFIRM).

**Expected result**
- Same outcome as TC-E2E-04.

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

### TC-E2E-07 - Browser-test evidence exists for this story

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
- A spec opens the dialog for the seed user, asserts the amount for a frozen date, and asserts Cancel sends no request to `/api/billing/upgrade`.
- The tests are recorded as passed.

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

