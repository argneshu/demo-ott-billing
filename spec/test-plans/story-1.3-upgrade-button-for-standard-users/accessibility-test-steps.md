# Accessibility Test Steps - Story 1.3: Upgrade button for Standard users

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

### TC-A11Y-01 - Keyboard focus and activation

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-NF-07 (WCAG 2.1.1) |
| **Type** | Accessibility |
| **Priority** | P1 |
| **Preconditions** | The locally built instance in System Under Test is running. A browser is available; sign in at http://localhost:5173 as `tpg@example.com` / `password` unless stated. |
| **Test data** | Seed account |

**Steps**
1. Open Billing and use only the Tab key to reach the button.
2. Press Enter, then Space (when the dialog from Story 1.4 is present it opens; otherwise nothing breaks).

**Expected result**
- The button receives focus in a logical tab order.
- Enter and Space both activate it; no script error appears in the browser console.

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

### TC-A11Y-02 - Visible focus and accessible name

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-NF-07 (WCAG 2.4.7, 4.1.2) |
| **Type** | Accessibility |
| **Priority** | P2 |
| **Preconditions** | The locally built instance in System Under Test is running. A browser is available; sign in at http://localhost:5173 as `tpg@example.com` / `password` unless stated. |
| **Test data** | Seed account, a screen reader or the browser accessibility inspector |

**Steps**
1. Tab to the button and look at the focus indicator.
2. Inspect the button's role and name.

**Expected result**
- A visible focus indicator is shown.
- The element is exposed as a button named "Upgrade to Premium".

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

