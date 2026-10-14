# Epic Brief: Self-Serve Premium Upgrade

**Source**: Atlas (via Helix MCP) - Epic doc 6225 v1, Story doc 6226 v1. Tracker: LOCAL.
**System**: Billing-Cycle (StreamPlex) - demo-ott-billing
**Priority**: High

## Epic Overview
Enable Standard plan subscribers to self-serve upgrade to Premium directly from the Billing page, with real-time proration calculation and immediate plan activation - without requiring support intervention or a page reload.

## Problem Statement
The Billing page (`src/frontend/src/pages/Billing.jsx`) is currently entirely read-only. Users on the Standard plan ($20/mo) have no in-product path to upgrade to Premium ($40/mo). This forces any plan change through manual or out-of-band processes, creating friction and lost conversion opportunities.

## Goal
Deliver a mid-cycle upgrade flow that:
1. Shows an upgrade CTA only to Standard plan users
2. Presents a prorated charge preview before commitment
3. Applies the plan change instantly in-memory on the backend
4. Reflects the new Premium plan in the UI without a full page reload

## Scope
**In scope**
- `POST /api/billing/upgrade` backend endpoint with proration logic
- Upgrade CTA button + confirmation modal on the Billing page
- Premium plan feature data (4K, 4 streams, 6 downloads, Dolby Vision perk)
- Client-side state update after confirmed upgrade

**Out of scope**
- Downgrades, refunds, payment SDKs (Stripe etc.), persistent DB, additional plans

## Stories
| # | Story | Status | Estimate |
|---|-------|--------|----------|
| 1 | Mid-Cycle Upgrade Flow (Standard to Premium) | Draft | M (3-5 days) |

## Story 1 - Mid-Cycle Upgrade Flow (Standard to Premium)

> As a Standard plan subscriber ($20/mo), I want to upgrade to Premium ($40/mo) from the Billing page mid-month, so that I get advanced features immediately and only pay a prorated charge for the days remaining in my cycle.

### Context
The Billing page renders plan details and usage cards fetched from `GET /api/billing`, but is read-only. The backend (`src/backend/main.py`) stores billing data in an in-memory dict (`billing_data`) keyed by email, and plan data in a parallel `users` dict. Both must be updated on upgrade. The "token" is the user's email (stored in `localStorage`, passed as a query param); the upgrade endpoint follows the same pattern (POC auth model).

### Acceptance Criteria
- **AC-1 CTA visible to Standard users only**: Standard user sees an "Upgrade to Premium" button in the plan section (below the current plan card). Premium user: button NOT rendered.
- **AC-2 Confirmation modal shows prorated amount before commitment**: modal shows current plan Standard ($20/mo), new plan Premium ($40/mo), days remaining (from `renew_at` and today), prorated charge `($40 - $20) x (days_remaining / days_in_cycle)` rounded to 2 dp, e.g. "You'll be charged $10.00 today for the 15 days remaining in your cycle.", a Confirm Upgrade and a Cancel button. User NOT charged/upgraded yet.
- **AC-3 Proration math**: `prorated_charge = round((40 - 20) * (days_remaining / 30), 2)`; `renew_at` is a `"MMM DD, YYYY"` string; days in cycle fixed at 30. Edge: `days_remaining <= 0` -> $0.00 and upgrade still proceeds; `days_remaining >= 30` -> $20.00.
- **AC-4 Backend endpoint**: `POST /api/billing/upgrade` with `{ "email": "<user_email>" }`. User found and Standard: compute days_remaining and prorated_charge; set `users[email]["plan"]="Premium"` and `["price"]="$40/month"`; update `billing_data[email]` with Premium features; return `{ plan_name: "Premium", price: "$40/month", renew_at: <unchanged>, prorated_charge: <float>, usages: [...], included_usage: {...} }`. Already Premium: HTTP 400 `{ "detail": "Already on Premium plan" }`.
- **AC-5 UI reflects Premium immediately**: on successful response, with no full page reload: plan Premium, price $40/month, renewal date unchanged, usage cards reflect Premium quotas (4K, 4 streams, 6 downloads), upgrade button no longer rendered; transient success message "You're now on Premium! Your next full cycle bills at $40/month."
- **AC-6 Cancel does nothing**: Cancel/close makes no API call and the page is unchanged.
- **AC-7 Renewal date unchanged**: `renew_at` identical in UI and backend after upgrade.

### Premium Plan Feature Data (backend must return)
```python
"usages": [
    {"id": "video-quality", "label": "Video quality", "type": "feature", "value": "4K Ultra HD",
     "help": "The best video resolution available on the Premium plan."},
    {"id": "screens", "label": "Watch at the same time", "type": "feature",
     "value": "Can watch on 4 devices at once",
     "help": "Number of supported devices that can stream simultaneously."},
    {"id": "downloads", "label": "Download on devices", "type": "feature",
     "value": "Can download on 6 devices", "help": "Number of devices for offline viewing."},
],
"included_usage": {
    "title": "Plan perks",
    "items": [
        {"id": "ad-free", "label": "Ad-free streaming", "used_percent": 100},
        {"id": "spatial-audio", "label": "Spatial audio (select titles)", "used_percent": 100},
        {"id": "dolby-vision", "label": "Dolby Vision (select titles)", "used_percent": 100},
    ],
    "help": "Perks included in your Premium plan.",
}
```

### Backend changes
New `UpgradeRequest(BaseModel)` with `email: str`; `POST /api/billing/upgrade` (validate user exists and is Standard; compute days_remaining; compute prorated charge; update `users[email]`; update `billing_data[email]`; return updated billing + `prorated_charge`). Helper `calculate_days_remaining(renew_at)` = `max(0, (strptime(renew_at, "%b %d, %Y").date() - today).days)`.

### Frontend changes (`Billing.jsx`)
1. Render "Upgrade to Premium" when `data.plan_name === "Standard"`. 2. Modal open/close state via `useState`. 3. On open compute days_remaining in JS from `renew_at` and show prorated amount client-side. 4. On Confirm: `POST /api/billing/upgrade` with `{ email: token }`, then `setData(response)`. 5. Transient success message. 6. Remove the button once Premium.

### Definition of Done
- Endpoint implemented in `src/backend/main.py`
- Proration tested manually with at least 3 day-remaining values (0, 15, 29)
- CTA visible for Standard users only; modal renders correct prorated charge before commitment
- On confirmation the page updates without reload; success message shown
- Cancel/close does not trigger upgrade; `renew_at` unchanged; button absent for Premium
- No regressions: login, registration, Standard billing display
- Code reviewed and merged

## Referenced Paths
- High: `src/backend/main.py`, `src/frontend/src/pages/Billing.jsx`
- Medium: `src/frontend/src/context/AuthContext.jsx`, `src/frontend/src/App.css`
- Low: `src/frontend/package.json`, `src/backend/requirements.txt` (no new dependencies expected)
