# Accessibility Test Steps - Story 1.4: Upgrade confirmation modal with prorated preview

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

### TC-A11Y-01 - Dialog semantics and initial focus

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-NF-07 (WCAG 4.1.2, 2.4.3) |
| **Type** | Accessibility |
| **Priority** | P1 |
| **Preconditions** | The locally built instance in System Under Test is running. A browser is available; sign in at http://localhost:5173 as `tpg@example.com` / `password` unless stated. |
| **Test data** | Seed account; screen reader or accessibility inspector |

**Steps**
1. Open the dialog.

**Expected result**
- The dialog is exposed with role dialog and an accessible name.
- Keyboard focus is inside the dialog; Tab does not leave it while open.

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

### TC-A11Y-02 - Escape and focus return

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-NF-07 (WCAG 2.1.2, 2.4.3) |
| **Type** | Accessibility |
| **Priority** | P1 |
| **Preconditions** | The locally built instance in System Under Test is running. A browser is available; sign in at http://localhost:5173 as `tpg@example.com` / `password` unless stated. |
| **Test data** | Seed account |

**Steps**
1. Open the dialog by keyboard (Tab to the button, Enter).
2. Press Escape.

**Expected result**
- The dialog closes and focus returns to the "Upgrade to Premium" button.

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

### TC-A11Y-03 - Zoom and readability

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-NF-07 (WCAG 1.4.4, 1.4.3) |
| **Type** | Accessibility |
| **Priority** | P3 |
| **Preconditions** | The locally built instance in System Under Test is running. A browser is available; sign in at http://localhost:5173 as `tpg@example.com` / `password` unless stated. |
| **Test data** | Seed account; browser zoom 200% |

**Steps**
1. Zoom to 200% and open the dialog.

**Expected result**
- All dialog text and both buttons remain visible and usable without horizontal scrolling; text contrast is readable.

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

