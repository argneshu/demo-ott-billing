EPIC TICKET: Self-Serve Premium Upgrade (LOCAL tracker; described in spec/plans/epic-brief.md, from Atlas epic doc 6225)

# User Stories: Self-Serve Premium Upgrade

Approach: feature/layer-based (backend first, then the UI steps). Personas: `spec/plans/personas.md`. Requirements: `spec/plans/requirements.md`.
Every story also meets REQ-NF-02 (automated tests) and REQ-NF-04 (no new runtime dependencies); their ACs are named per story below.

---

## Story 1.1: Backend prorated upgrade to Premium
**Requires**: none
**Persona**: Standard Subscriber (via the API) | **Covers**: REQ-F-03, REQ-F-04, REQ-F-06, REQ-F-09, REQ-F-11, REQ-NF-03, REQ-NF-04
**Tracker ID**: LOCAL | **Estimate**: S

As a Standard subscriber, I want the backend to switch my plan to Premium and compute a prorated charge, so that I only pay for the days left in my cycle.

- **AC-1 (REQ-F-03)** Given `renew_at` is `"MMM DD, YYYY"`, when days remaining is computed, then `days_remaining = clamp((renew_date - today).days, 0, 30)` and `prorated_charge = round((40 - 20) * (days_remaining / 30), 2)`. 0 days gives 0.00, 15 gives 10.00, 29 gives 19.33, 30 or more gives 20.00.
- **AC-2 (REQ-F-11)** Given `renew_at` cannot be parsed, when proration runs, then it is treated as 0 days (charge 0.00) and no server error occurs.
- **AC-3 (REQ-F-04, REQ-F-06)** Given a known Standard user, when `POST /api/billing/upgrade` is called with `{ "email": "<email>" }`, then `users[email]` becomes plan "Premium" and price "$40/month", `billing_data[email]` holds the Premium feature set (usages `video-quality` "4K Ultra HD", `screens` "Can watch on 4 devices at once", `downloads` "Can download on 6 devices"; included_usage "Plan perks" with `ad-free`, `spatial-audio`, `dolby-vision`, each 100, help "Perks included in your Premium plan."), and the response is `{ plan_name, price, renew_at, prorated_charge, usages, included_usage }`.
- **AC-4 (REQ-F-09)** Given an upgrade, then `renew_at` in `users[email]`, in `billing_data[email]` and in the response equals its value before the upgrade.
- **AC-5 (REQ-NF-02, REQ-NF-03)** Given the code, then pytest unit tests cover AC-1..AC-4 (days 0, 15, 29, 30+) and Hypothesis property tests prove: charge in [0.00, 20.00], 2-decimal rounding, non-decreasing in days, 0.00 at 0 days and 20.00 at 30+; `strftime`/`strptime` of `renew_at` round-trips. Test packages are dev-only (REQ-NF-04).

## Story 1.2: Upgrade request rejection paths
**Requires**: 1.1
**Persona**: Standard Subscriber, Premium Subscriber | **Covers**: REQ-F-05, REQ-NF-01
**Tracker ID**: LOCAL | **Estimate**: S
**Note**: per the Q1 A decision there is no token check; the deviation is recorded in REQ-NF-01 and not an AC here.

As a client of the API, I want clear errors for invalid upgrade requests, so that bad requests never change an account.

- **AC-1 (REQ-F-05)** Given a user already on Premium, when `POST /api/billing/upgrade` is called, then HTTP 400 `{ "detail": "Already on Premium plan" }` is returned and nothing is mutated.
- **AC-2 (REQ-F-05)** Given an email that is not a known user, when the endpoint is called, then HTTP 401 `{ "detail": "Not authenticated" }` is returned and nothing is created.
- **AC-3 (REQ-NF-01)** Given a body with a missing, empty or non-string `email`, then HTTP 422 is returned and nothing is mutated.
- **AC-4 (REQ-NF-01)** Given an unhandled exception in the endpoint, then a global handler logs it (no password or secret in the log) and returns a safe generic 500 body without a stack trace.
- **AC-5 (REQ-NF-02, REQ-NF-03)** Given the code, then pytest tests cover AC-1..AC-4, including a property test that a second upgrade of any upgraded user always returns 400.

## Story 1.3: Upgrade button for Standard users
**Requires**: none
**Persona**: Standard Subscriber, Premium Subscriber | **Covers**: REQ-F-01, REQ-NF-07
**Tracker ID**: LOCAL | **Estimate**: S

As a Standard subscriber, I want to see an upgrade button on my Billing page, so that I know I can move to Premium.

- **AC-1 (REQ-F-01)** Given a logged-in Standard user, when the Billing page loads, then an "Upgrade to Premium" button is visible below the current plan card.
- **AC-2 (REQ-F-01)** Given a logged-in Premium user, when the Billing page loads, then the button is not rendered.
- **AC-3 (REQ-NF-07)** Given the button, then it is a real `button` element, keyboard-focusable and operable, styled in `src/frontend/src/App.css`, and clicking it does nothing yet beyond a no-op handler hook for Story 1.4.
- **AC-4 (REQ-NF-02)** Given the UI, then a Playwright test logs in as the seed Standard user and asserts the button is visible, and a second case asserts it is absent for a Premium user (the `/api/billing` response is mocked in the browser, so this story needs no backend change).

## Story 1.4: Upgrade confirmation modal with prorated preview
**Requires**: 1.3
**Persona**: Standard Subscriber | **Covers**: REQ-F-02, REQ-F-03, REQ-F-08, REQ-NF-07
**Tracker ID**: LOCAL | **Estimate**: M

As a Standard subscriber, I want to see exactly what I will be charged before I confirm, so that I can decide with no surprise.

- **AC-1 (REQ-F-02, REQ-NF-07)** Given a Standard user, when they click "Upgrade to Premium", then a modal (`role="dialog"`, labelled, focus moved into it) opens showing current plan Standard ($20/mo), new plan Premium ($40/mo), the days remaining, and the sentence "You'll be charged $X.XX today for the N days remaining in your cycle.", with Confirm Upgrade and Cancel buttons; no API call has been made.
- **AC-2 (REQ-F-03)** Given `renew_at`, then the client computes days remaining and the amount with the same rule as the backend (floor 0, cap 30, 2-decimal rounding; unparseable date gives 0 days), verified by unit tests for 0, 15, 29, 30+ days.
- **AC-3 (REQ-F-08)** Given the modal is open, when the user clicks Cancel, presses Escape or closes it, then no API call is made, the Billing page is unchanged and focus returns to the upgrade button.
- **AC-4 (REQ-NF-02)** Given the UI, then a Playwright test opens the modal, checks the displayed amount for the seed user's `renew_at`, and checks Cancel makes no `/api/billing/upgrade` request.

## Story 1.5: Confirm upgrade and refresh Billing page
**Requires**: 1.1, 1.4
**Persona**: Standard Subscriber | **Covers**: REQ-F-07, REQ-F-09, REQ-F-10, REQ-NF-05
**Tracker ID**: LOCAL | **Estimate**: M

As a Standard subscriber, I want my Billing page to show Premium right after I confirm, so that I can see the upgrade worked without reloading.

- **AC-1 (REQ-F-07, REQ-F-09)** Given the open modal, when the user clicks Confirm Upgrade, then the frontend sends one `POST /api/billing/upgrade` with `{ email: token }` and on success updates state with no full page reload: plan Premium, price $40/month, the same renewal date, Premium usage cards, and the upgrade button removed; the modal closes.
- **AC-2 (REQ-F-07)** Given a successful upgrade, then the message "You're now on Premium! Your next full cycle bills at $40/month." is shown briefly and then disappears.
- **AC-3 (REQ-F-10)** Given the request fails (network or server error), then the modal stays open, an inline error is shown and the page state is unchanged.
- **AC-4 (REQ-NF-05)** Given the change, then login, registration, session restore and the Standard billing display behave as before.
- **AC-5 (REQ-NF-02)** Given the UI, then a Playwright E2E runs the full flow (login, upgrade, success message, Premium data, button gone, no reload) and one failure case (backend upgrade request forced to fail, modal stays open).

---

## Requirements Coverage Matrix
| REQ-ID | Covering stories | Status |
|---|---|---|
| REQ-F-01 | 1.3 | Full |
| REQ-F-02 | 1.4 | Full |
| REQ-F-03 | 1.1 (backend), 1.4 (client preview) | Full |
| REQ-F-04 | 1.1 | Full |
| REQ-F-05 | 1.2 | Full |
| REQ-F-06 | 1.1 | Full |
| REQ-F-07 | 1.5 | Full |
| REQ-F-08 | 1.4 | Full |
| REQ-F-09 | 1.1 (backend), 1.5 (UI) | Full |
| REQ-F-10 | 1.5 | Full |
| REQ-F-11 | 1.1 | Full |
| REQ-NF-01 | 1.2 | Full |
| REQ-NF-02 | 1.1, 1.2, 1.3, 1.4, 1.5 (each has a test AC) | Full |
| REQ-NF-03 | 1.1, 1.2 | Full |
| REQ-NF-04 | 1.1 | Full |
| REQ-NF-05 | 1.5 | Full |
| REQ-NF-06 | N/A (resiliency not applied, Q6 B) | N/A |
| REQ-NF-07 | 1.3, 1.4 | Full |
