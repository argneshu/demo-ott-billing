# Code Generation Plan - Story 1.1: Backend prorated upgrade to Premium

Branch: `story/1.1-backend-prorated-upgrade-to-premium` (cut from `epic/self-serve-premium-upgrade`) | Tracker: LOCAL | Requires: none
Covers: REQ-F-03, REQ-F-04, REQ-F-06, REQ-F-09, REQ-F-11, REQ-NF-03, REQ-NF-04
Inputs: stories.md (Story 1.1 ACs), requirements.md, functional-design.md, nfr.md, architecture.md (ARCH-01..06), spec/behavior/story-1.1.feature, spec/test-plans/story-1.1-*/.
Design references: none registered (Context Project: No) - built from ACs and design docs only.

## Story context
Standard users upgrade to Premium via `POST /api/billing/upgrade` in `src/backend/main.py`. In-memory `users` and `billing_data` dicts are mutated. No frontend work in this story (no Frontend Components Generation step: Playwright readiness and UI automation are N/A).

Scope note (recorded decision): the eligibility guards (already Premium returns 400, unknown email returns 401) ship in this story because without them the endpoint would let a Premium account be upgraded again and an unknown email would raise an unhandled KeyError, which the blocking J2 gate (SEC-05, SEC-08) and ARCH-01 treat as defects. Story 1.2 still owns tightened body validation (422), the global exception handler, and the dedicated rejection-path tests and scenarios.

## Steps
- [ ] Step 1: Business logic - constants and proration helpers in `src/backend/main.py`: `calculate_days_remaining(renew_at, today=None)` clamped 0..30 with unparseable date giving 0, injectable `today`; `prorate(days_remaining)` = `round((40-20)*days/30, 2)` (REQ-F-03, REQ-F-11, AC-1, AC-2, ARCH-02)
- [ ] Step 2: Business logic - Premium plan factory `premium_billing_profile(renew_at)` returning a fresh copy of the REQ-F-06 payload per call (REQ-F-06, AC-3, AC-5, ARCH-03)
- [ ] Step 3: API Layer - `UpgradeRequest` model and `POST /api/billing/upgrade`: look up user, 401 if unknown, 400 if already Premium, compute days and charge, then mutate `users` and `billing_data`, return `{plan_name, price, renew_at, prorated_charge, usages, included_usage}`; never write `renew_at`, never return the password (REQ-F-04, REQ-F-09, AC-3, AC-4, ARCH-01, ARCH-04, ARCH-05)
- [ ] Step 4: Dev dependencies - `src/backend/requirements-dev.txt`, `pytest.ini` (no new runtime dependencies) (REQ-NF-04, AC-5)
- [ ] Step 5: Unit Test & Coverage - `tests/unit/backend/test_main_upgrade.py` (examples for days 0, 15, 29, 30+, unparseable date, Premium payload, renewal unchanged, isolation between accounts) and `tests/unit/backend/test_proration_properties.py` (Hypothesis: charge in [0.00, 20.00], 2 decimals, non-decreasing, 0 at 0 days and 20.00 at 30+, days always 0..30 for any text, `renew_at` format round-trip, `renew_at` unchanged for any date); coverage on changed lines meets `unitTestCoverageMin` (REQ-NF-02, REQ-NF-03, AC-5)
- [ ] Step 6: Behavioural gate - step definitions in `tests/behavior/steps/billing_steps.py` and `tests/behavior/test_story_1_1.py` bound to `spec/behavior/story-1.1.feature` (B1, B2); runner `tests/.evals/behavior/run.sh` and `Containerfile` bootstrapped; Podman is not installed on this machine so the tiers run natively with the recorded exception (AC-1..AC-5)
- [ ] Step 7: API & Contract Testing Gate - `tests/api/test_upgrade_contract.py` against the real endpoint: functional, response codes, error body shape, request validation, response schema (the endpoint is an API Layer step) (AC-3, AC-4)
- [ ] Step 8: Test placement verification (tests under `tests/unit/backend`, `tests/api`, `tests/behavior`; none under `src/`)
- [ ] Step 9: Full regression vs baseline (baseline: 0 tests)
- [ ] Step 10: Static Eval Gate D1-D7 vs baseline (ruff, mypy, semgrep, pip-audit, pip-licenses, radon, gitleaks)
- [ ] Step 11: Playwright UI automation - N/A (no Frontend Components Generation step)
- [ ] Step 12: Playwright E2E regression - N/A (tests/e2e held no spec at baseline)
- [ ] Step 13: Documentation - none beyond the evidence set (no README change in the plan)

## Trace summary (REQ/AC -> plan steps)
| Item | Steps |
|---|---|
| REQ-F-03, AC-1 | 1, 5, 6 |
| REQ-F-11, AC-2 | 1, 5, 6 |
| REQ-F-04, REQ-F-06, AC-3 | 2, 3, 5, 6, 7 |
| REQ-F-09, AC-4 | 3, 5, 6, 7 |
| REQ-NF-03, AC-5 | 2, 5, 6 |
| REQ-NF-04 | 4 |
