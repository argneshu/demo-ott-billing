# Functional Design: Self-Serve Premium Upgrade

Inputs: `epic-brief.md`, `requirements.md`, `stories.md`, `atlas-deep-dive.md`, answers in `spec/spec-generation/functional-design-generation.md` (Q1 A, Q2 A). Technology-agnostic logic first, then the existing-stack mapping.

## 1. Domain model (existing, in-memory)
- **User** (`users[email]`): `id, name, email, password, plan, price, renew_at`. Upgrade changes `plan` to "Premium" and `price` to "$40/month"; nothing else.
- **BillingProfile** (`billing_data[email]`): `plan_name, price, renew_at, usages[], included_usage{title, items[], help}`. Upgrade replaces `plan_name`, `price`, `usages` and `included_usage` with the Premium set; `renew_at` is never touched.
- **Plan catalogue (new constants)**: Standard = $20, Premium = $40, `CYCLE_DAYS = 30`. Premium usage payload is the fixed structure from REQ-F-06 (module constant, deep-copied per user so accounts never share mutable lists).

## 2. Business rules
| Rule | Definition |
|---|---|
| BR-1 Days remaining | `raw = (renew_date - today).days`; `days_remaining = min(max(raw, 0), 30)`. An unparseable `renew_at` gives 0 (REQ-F-11). |
| BR-2 Prorated charge | `round((40 - 20) * days_remaining / 30, 2)`. Range 0.00 to 20.00. 15 days gives 10.00, 29 gives 19.33. (Python `round` is banker's rounding on floats; the tests pin the expected values above.) |
| BR-3 Eligibility | Only a known user on "Standard" may upgrade. Known and Premium: 400 "Already on Premium plan". Unknown: 401 "Not authenticated". |
| BR-4 Renewal unchanged | `renew_at` is read for proration and never written (REQ-F-09). |
| BR-5 Atomic in-memory update | Compute everything first; mutate `users[email]` and `billing_data[email]` only after all checks pass, so a failure leaves state untouched. |
| BR-6 Date source (Q1 A) | Backend uses the server local date; the browser preview uses the browser local date. The backend amount is authoritative. |
| BR-7 Registered users | If a known user has no `billing_data` entry, one is created with the Premium set. |

## 3. Upgrade flow (backend)
1. Validate body (`email` non-empty string; otherwise 422).
2. Look up user; unknown gives 401.
3. If plan is Premium, return 400 (no mutation).
4. `days = days_remaining(users[email].renew_at)`; `charge = prorate(days)`.
5. Mutate `users[email]` and `billing_data[email]` (BR-5).
6. Return `{plan_name, price, renew_at, prorated_charge, usages, included_usage}`.

## 4. Frontend design (`Billing.jsx`, styles in `App.css`)
**Components**: `Billing` (existing page) owns state; new small pieces in the same file: `UpgradeModal` (presentational).
**State**
- `data` (existing billing payload), `showUpgrade` (bool), `upgrading` (bool, disables Confirm while the request runs), `upgradeError` (string or null), `successMessage` (string or null).

**Pure helper (exported for unit tests)**: `daysRemaining(renewAt, today = new Date())` and `proratedCharge(days)` implement BR-1 and BR-2 identically to the backend; unparseable date gives 0.

**Interaction flow**
1. `data.plan_name === "Standard"` renders the "Upgrade to Premium" button below the plan card; Premium renders nothing (REQ-F-01).
2. Click sets `showUpgrade = true`; the modal (`role="dialog"`, `aria-modal`, labelled by its title) shows Standard $20/mo, Premium $40/mo, days remaining and "You'll be charged $X.XX today for the N days remaining in your cycle." Focus moves to the dialog (REQ-F-02, REQ-NF-07).
3. Cancel, Escape or the close control sets `showUpgrade = false` with no request; focus returns to the upgrade button (REQ-F-08).
4. Confirm sets `upgrading = true` and sends one `POST /api/billing/upgrade` with `{ email: token }`.
   - **Success**: `setData(response)` (response has the full billing shape), close the modal, set `successMessage` to "You're now on Premium! Your next full cycle bills at $40/month." (Q2 A: no amount), clear it after a few seconds. The button disappears because `plan_name` is now Premium (REQ-F-07).
   - **Failure** (non-2xx or network error): keep the modal open, set `upgradeError`, leave `data` unchanged, re-enable Confirm (REQ-F-10).
5. `token` comes from `AuthContext`; no new context or dependency.

**Validation**: no form inputs; the only user inputs are the two modal buttons.
**API integration points**: `GET /api/billing` (existing), `POST /api/billing/upgrade` (new).

## 5. Error handling summary
| Case | Result |
|---|---|
| Already Premium | 400, no change |
| Unknown user | 401 |
| Missing or non-string email | 422 |
| Bad `renew_at` | 0 days, charge 0.00 |
| Unexpected exception | global handler, safe 500 body, logged without secrets |
| Request failure in browser | modal open with inline error, no state change |

## 6. Testable Properties (PBT-01)
| Component | Property | Category | Test |
|---|---|---|---|
| `prorate(days)` | result always in [0.00, 20.00] for any integer days | Invariant | Hypothesis |
| `prorate(days)` | non-decreasing in days; 0.00 at days <= 0; 20.00 at days >= 30 | Invariant | Hypothesis |
| `prorate(days)` | result has at most 2 decimals | Invariant | Hypothesis |
| `days_remaining(renew_at)` | always an integer in [0, 30] for any date string, including garbage | Invariant | Hypothesis (text and dates) |
| `renew_at` formatting | `strptime(strftime(d, "%b %d, %Y"), "%b %d, %Y") == d` for any date | Round-trip | Hypothesis |
| `POST /upgrade` | second upgrade of the same user always returns 400 and leaves state unchanged | Idempotence | Hypothesis over emails and dates |
| `POST /upgrade` | `renew_at` after equals `renew_at` before for any date | Invariant | Hypothesis |
| Frontend `proratedCharge` | agrees with the backend formula for days 0..40 | Oracle | table test (backend values as oracle); fast-check not added (no new runtime deps) |
| Premium payload | deep copy per user; mutating one user's payload never changes another's | Invariant | example test |
