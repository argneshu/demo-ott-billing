# Requirements: Self-Serve Premium Upgrade

## Intent Analysis
- **User request**: "using aire and helix mcp fetch the solution document and start implementing the epic requirements"
- **Source of truth**: Epic brief `spec/plans/epic-brief.md` (Atlas epic 6225, story 6226); existing-system truth `spec/plans/atlas-deep-dive.md` (Atlas deep dive 6025 v26)
- **Request type**: New Feature (enhancement of the read-only Billing page)
- **Scope estimate**: Multiple components (backend `main.py`, frontend `Billing.jsx` + `App.css`)
- **Complexity estimate**: Simple to Moderate
- **Requirements depth**: Standard
- **Context Project artifacts consulted**: none (Existing Knowledge: No; New References: No)
- **Clarifying answers**: `spec/spec-generation/requirement-verification-questions.md` (Q1 A, Q2 A, Q3 A, Q4 A, Q5 A, Q6 B, Q7 A)

## Existing system (from Atlas deep dive and source)
- Backend: FastAPI, in-memory `users` and `billing_data` dicts keyed by email; seed user `tpg@example.com` (Standard, renew_at `Oct 30, 2026`). The "token" is the email, passed as an `email` query param on GET endpoints. CORS is `*`.
- Frontend: React/Vite; `Billing.jsx` is read-only and loads `GET /api/billing`; `AuthContext.jsx` supplies the token.
- No tests, no test tooling and no CI exist today.

## Functional Requirements
| ID | Requirement | Source |
|---|---|---|
| REQ-F-01 | The Billing page shows an "Upgrade to Premium" button, below the current plan card, only when `plan_name` is "Standard". It is not rendered for Premium. | AC-1 |
| REQ-F-02 | Clicking the button opens a confirmation modal showing the current plan (Standard, $20/mo), the new plan (Premium, $40/mo), days remaining in the cycle (from `renew_at` and today) and the prorated charge, e.g. "You'll be charged $10.00 today for the 15 days remaining in your cycle." The modal has Confirm Upgrade and Cancel buttons. Nothing is charged or changed until Confirm. The preview amount is computed client-side. | AC-2, Q3 A |
| REQ-F-03 | Proration: `prorated_charge = round((40 - 20) * (days_remaining / 30), 2)`, where `days_remaining` is `renew_at` (`"MMM DD, YYYY"`) minus today in days, floored at 0 and capped at 30 (cycle fixed at 30 days). So `days_remaining <= 0` gives $0.00 and the upgrade still proceeds; `>= 30` gives $20.00. The frontend and backend use the same rule. | AC-3, Q2 A |
| REQ-F-04 | `POST /api/billing/upgrade` with `{ "email": "<user_email>" }`, for a known Standard user: set `users[email]["plan"]="Premium"` and `["price"]="$40/month"`; replace `billing_data[email]` plan fields with the Premium feature set (REQ-F-06); return `{ plan_name: "Premium", price: "$40/month", renew_at: <unchanged>, prorated_charge: <float>, usages: [...], included_usage: {...} }`. | AC-4 |
| REQ-F-05 | Error responses: already Premium returns HTTP 400 `{ "detail": "Already on Premium plan" }`; unknown user returns HTTP 401 `{ "detail": "Not authenticated" }`, consistent with existing endpoints. | AC-4, Q4 A |
| REQ-F-06 | Premium plan data returned and stored by the backend: usages `video-quality` "4K Ultra HD", `screens` "Can watch on 4 devices at once", `downloads` "Can download on 6 devices" (ids, labels, help text exactly as in the epic brief); included_usage titled "Plan perks" with `ad-free`, `spatial-audio`, `dolby-vision` (each `used_percent` 100) and help "Perks included in your Premium plan." | Epic brief |
| REQ-F-07 | On Confirm, the frontend POSTs `{ email: token }`, then updates page state from the response with no full page reload: plan Premium, price $40/month, same renewal date, Premium usage cards, upgrade button removed. A transient success message shows: "You're now on Premium! Your next full cycle bills at $40/month." | AC-5 |
| REQ-F-08 | Cancel or closing the modal makes no API call and leaves the page unchanged. | AC-6 |
| REQ-F-09 | `renew_at` is identical in backend and UI before and after the upgrade (the Premium price applies from the next cycle). | AC-7 |
| REQ-F-10 | If the Confirm request fails (network or server error), the modal stays open, an inline error is shown and no page state changes. | Q4 A |
| REQ-F-11 | An unparseable `renew_at` is treated as 0 days remaining (prorated charge $0.00) rather than raising a server error. | Q4 A |

## Non-Functional Requirements
| ID | Requirement | Source |
|---|---|---|
| REQ-NF-01 | **Security Baseline (blocking).** Validate the request body (`email` is a non-empty string; reject malformed bodies with 422); no secrets or passwords in responses or logs; a global exception handler returns a safe response. **Accepted deviation (Q1 A, user decision):** the endpoint takes `email` from the body with no token check, matching the existing POC auth model, so any caller can upgrade any account (SECURITY-08/SECURITY-12). It is recorded here as a documented POC deviation and will be reported as a finding by the security review. Out of scope: real authentication, password hashing and the CORS wildcard (pre-existing Atlas findings). | Q1 A, Security Baseline |
| REQ-NF-02 | **Testing.** Backend unit tests (pytest + FastAPI TestClient) for the endpoint and proration covering 0, 15, 29 and 30+ days, already-Premium, unknown user and unparseable date; a Playwright E2E for the full UI flow (CTA, modal, confirm, cancel, success message, no reload). Unit coverage meets the `unitTestCoverageMin` threshold in `tests/.evals/config.json`. | Q5 A, Playwright extension |
| REQ-NF-03 | **Property-based testing (Q7 A: all PBT rules enforced).** The proration function has property tests, using Hypothesis: output always in [0.00, 20.00], rounded to 2 decimals, non-decreasing in `days_remaining`, equals 0 at 0 days and 20.00 at 30 or more; the date parsing round-trips (`strftime` then `strptime`); a second upgrade of the same user always returns 400 (idempotence of the state transition). Functional Design records testable properties (PBT-01). | Q7 A |
| REQ-NF-04 | No new runtime dependencies (`package.json`, `requirements.txt`); test-only tooling (pytest, httpx, hypothesis, Playwright) goes in dev/test dependency files. | Epic brief |
| REQ-NF-05 | No regressions: login, registration, session restore and Standard billing display behave as before. | Definition of Done |
| REQ-NF-06 | Resiliency baseline: NOT applied (Q6 B; PoC, in-memory, single process). | Q6 B |
| REQ-NF-07 | Styles for the button, modal overlay, confirmation text, error and success message live in `src/frontend/src/App.css`; the modal is keyboard-accessible (focus on open, Escape closes, labelled dialog). | Epic brief, usability |

## Out of Scope
Downgrades, refunds or credits, payment verification or decline flows, payment SDKs (Stripe etc.), additional or enterprise plans, persistent database storage, real authentication.

## Assumptions
- "Today" is the server's local date; the frontend uses the browser's date for the preview.
- The upgrade for a registered user with no `billing_data` entry creates one with the Premium feature set.
- Seed user `tpg@example.com` with `renew_at` "Oct 30, 2026" is the demo and E2E account; tests control "today" by patching the date, not by editing seed data.

## Traceability to Epic Acceptance Criteria
AC-1 -> REQ-F-01 | AC-2 -> REQ-F-02 | AC-3 -> REQ-F-03 | AC-4 -> REQ-F-04, REQ-F-05, REQ-F-06 | AC-5 -> REQ-F-07 | AC-6 -> REQ-F-08 | AC-7 -> REQ-F-09
