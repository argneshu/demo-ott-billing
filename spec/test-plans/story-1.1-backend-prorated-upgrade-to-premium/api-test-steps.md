# API Test Steps - Story 1.1: Backend prorated upgrade to Premium

Scope: manual test steps derived from the acceptance criteria only (black-box). Requirements: REQ-F-03, REQ-F-04, REQ-F-06, REQ-F-09, REQ-F-11, REQ-NF-03, REQ-NF-04.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/self-serve-premium-upgrade` |
| This story's PR | Story 1.1 PR into the epic branch (number recorded in the Story Tracker once raised); execute only after it has merged |
| Confirm the story is in the build | `git log --oneline | grep "1.1"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | Frontend http://localhost:5173 (Vite dev server); API http://localhost:8000 (frontend proxies `/api` to it) |
| Local services that must be up | Backend API and frontend dev server; no other services |
| Test data / accounts to seed | Seed account `tpg@example.com` / `password` (Standard, renews `Oct 30, 2026`). Extra accounts are created through the registration screen or `POST /api/auth/register` |

> If the build or local run fails, that is a **blocker on the dev team** - report it and do not log functional failures against a system that never started.

### TC-API-01 - Upgrade a Standard account

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-F-04 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | The locally built instance in System Under Test is running. A tool for HTTP requests (curl or an API client) is available. Seed account is Standard. |
| **Test data** | `POST /api/billing/upgrade` body `{"email":"tpg@example.com"}` |

**Steps**
1. Call `GET /api/billing?email=tpg@example.com` and note `plan_name`, `price`, `renew_at`.
2. Send the upgrade request.
3. Call `GET /api/billing?email=tpg@example.com` and `GET /api/users/me?email=tpg@example.com` again.

**Expected result**
- Upgrade response is HTTP 200 with `plan_name` "Premium", `price` "$40/month", `renew_at`, `prorated_charge`, `usages`, `included_usage`.
- Both follow-up calls show the Premium plan and "$40/month".

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

### TC-API-02 - Prorated charge for a fresh account (30 days remaining)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-03 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | The locally built instance in System Under Test is running. A tool for HTTP requests (curl or an API client) is available. |
| **Test data** | Register `fresh1@example.com` / `pw1` via `POST /api/auth/register` (name "Fresh"); its renewal date is 30 days from today |

**Steps**
1. Register the account and note `renew_at`.
2. Send `POST /api/billing/upgrade` with `{"email":"fresh1@example.com"}`.

**Expected result**
- HTTP 200 with `prorated_charge` 20.0 (30 days remaining, full price difference).
- `renew_at` equals the value noted in step 1.

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

### TC-API-03 - Prorated charge for the seed account today

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-03 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | The locally built instance in System Under Test is running. A tool for HTTP requests (curl or an API client) is available. Seed account is Standard. |
| **Test data** | `tpg@example.com`, renewal `Oct 30, 2026` |

**Steps**
1. Work out days remaining: `Oct 30, 2026` minus today's date, floored at 0 and capped at 30.
2. Send the upgrade request.

**Expected result**
- `prorated_charge` equals round(20 x days_remaining / 30, 2) for the computed days (a past renewal date gives 0.0).
- Expected charge = round(20 x days_remaining / 30, 2), days_remaining = renewal date minus today, floored at 0 and capped at 30 (for example 0 gives 0.00, 15 gives 10.00, 29 gives 19.33, 30 or more gives 20.00).

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

### TC-API-04 - Boundary days: 0, 15, 29 and 30+

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-03 |
| **Type** | API |
| **Priority** | P2 |
| **Preconditions** | The locally built instance in System Under Test is running. A tool for HTTP requests (curl or an API client) is available. TO CONFIRM: how the tester sets "today" locally (system clock or a test hook); the seed renewal date is fixed, so only today's date can vary. |
| **Test data** | Seed account (`Oct 30, 2026`) with today set to Oct 30 2026, Oct 15 2026, Oct 01 2026 and Sep 01 2026 (restart the backend between runs) |

**Steps**
1. For each date, restart the backend and set today's date.
2. Send the upgrade request for `tpg@example.com`.
3. Record `prorated_charge`.

**Expected result**
- Oct 30 gives 0.0; Oct 15 gives 10.0; Oct 01 gives 19.33; Sep 01 gives 20.0.
- The upgrade still succeeds (HTTP 200) when the charge is 0.0.

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

### TC-API-05 - Unparseable renewal date counts as zero days

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-11 |
| **Type** | API |
| **Priority** | P3 |
| **Preconditions** | The locally built instance in System Under Test is running. A tool for HTTP requests (curl or an API client) is available. TO CONFIRM: there is no public way to set a malformed `renew_at`; confirm with the developer whether this is covered only by automated unit tests. |
| **Test data** | none |

**Steps**
1. If a malformed `renew_at` can be set by an approved test hook, upgrade that account.
2. Otherwise record this case as covered by the automated unit tests (Story 1.1 AC-5) and mark it Not Executable.

**Expected result**
- HTTP 200 with `prorated_charge` 0.0 and the account on Premium; no HTTP 500.

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

### TC-API-06 - Premium plan data in the response

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-F-06 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | The locally built instance in System Under Test is running. A tool for HTTP requests (curl or an API client) is available. |
| **Test data** | Register `fresh2@example.com` / `pw2` |

**Steps**
1. Upgrade `fresh2@example.com`.
2. Read `usages` and `included_usage` in the response.

**Expected result**
- `usages` has `video-quality` "4K Ultra HD", `screens` "Can watch on 4 devices at once", `downloads` "Can download on 6 devices".
- `included_usage.title` "Plan perks" with `ad-free`, `spatial-audio`, `dolby-vision`, each `used_percent` 100, and help "Perks included in your Premium plan."
- No `password` field appears anywhere in the response.

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

### TC-API-07 - Renewal date is unchanged

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-F-09 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | The locally built instance in System Under Test is running. A tool for HTTP requests (curl or an API client) is available. |
| **Test data** | `fresh3@example.com` / `pw3` |

**Steps**
1. Register the account and call `GET /api/billing?email=fresh3@example.com`; note `renew_at`.
2. Upgrade the account.
3. Call `GET /api/billing` and `GET /api/users/me` for the account.

**Expected result**
- `renew_at` in the upgrade response, in billing, and in users/me all equal the value from step 1.

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

### TC-API-08 - Premium data is not shared between accounts

| Field | Value |
|-------|-------|
| **Traces to** | AC-5 / REQ-F-06 |
| **Type** | API |
| **Priority** | P2 |
| **Preconditions** | The locally built instance in System Under Test is running. A tool for HTTP requests (curl or an API client) is available. |
| **Test data** | Two new accounts `iso1@example.com` and `iso2@example.com` |

**Steps**
1. Register both accounts.
2. Upgrade only `iso1@example.com`.
3. Call `GET /api/billing` for `iso2@example.com`.

**Expected result**
- `iso2@example.com` still shows Standard, "$20/month" and its Standard usages (Full HD, 2 devices).

**Pass/Fail criteria**: PASS only if every expected result is observed; anything else is a FAIL.
**Cleanup**: Restart the backend to reset the in-memory data.

