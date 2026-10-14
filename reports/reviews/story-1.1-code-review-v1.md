# Code Review - Story 1.1: Backend prorated upgrade to Premium

**Date**: 2026-10-14
**Reviewed By**: REVIEWER (aire)
**Review Number**: 1
**Review Mode**: INITIAL_REVIEW
**Review Target**: Story 1.1
**Status**: APPROVED WITH COMMENTS
**Tracker ID**: LOCAL (Story 1.1)

## Review Summary
**Components Reviewed**: `src/backend/main.py`, `src/backend/requirements-dev.txt`, `pytest.ini`, `tests/conftest.py`, `tests/unit/backend/*.py`, `tests/api/test_upgrade_contract.py`, `tests/behavior/**`, `tests/.evals/behavior/*`
**Stories in Scope**: 1.1
**Tests Reviewed**: Yes, statically; suite NOT re-run. **Coverage**: 100.0% of changed lines and branches (34/34 lines, 4/4 branches) from the Unit Test & Coverage gate, not re-measured (`reports/unit-test-evidence/story-1.1/evidence-manifest.md`).
**API & Contract Tests**: Applicable - 1/1 endpoints checklist-complete (from the API & Contract Testing Gate, not re-run).
**Static Eval Gate (D1-D7)**: PASS (from the Static Eval Gate, not re-run; see `reports/eval-evidence/story-1.1/eval-summary.md`)
**Security Baseline (SECURITY-01...16, diff-scoped)**: 16/16 checked - findings: 0 Blocker / 1 High (SEC-ISS-001, waived by user decision REQ-NF-01) in the issue list - 4 Medium / 1 Low advisory - 6 pre-existing noted (not this change) -> report: `reports/code-security-reviews/story-1.1-security-review-v1.md`
**Judge Gates (blocking - Phase 3.5; never findings)**: J1 Architecture 1.0 (min 0.85) PASS - J2 Security 0.9 (min 0.85) PASS
**Overall Assessment**: All five acceptance criteria and all seven mapped requirements are Met with traced evidence. The only security finding the baseline raises on the changed surface that is rated High is the missing authorization on the upgrade endpoint, which the approved requirements (REQ-NF-01, user decision Q1 A) record as an accepted POC deviation.

## AC & Requirements Verification

### Story 1.1: Backend prorated upgrade to Premium
| # | AC / Requirement | Verdict | Evidence / Gap |
|---|------------------|---------|----------------|
| AC-1 | days remaining clamped 0..30, charge `round((40-20) x days/30, 2)` (0 gives 0.00, 15 gives 10.00, 29 gives 19.33, 30+ gives 20.00) | Met | `src/backend/main.py:99-113`; `tests/unit/backend/test_main_upgrade.py` (parametrised table); behaviour scenario "Prorated charge for the days remaining" |
| AC-2 | unparseable renewal date is zero days, no server error | Met | `src/backend/main.py:102-105`; `test_unparseable_renewal_date_upgrades_with_zero_charge`; scenario "Unparseable renewal date is treated as no days remaining" |
| AC-3 | upgrade applies Premium plan, response contract, Premium feature data | Met | `src/backend/main.py:115-150` (profile), `:231-246` (endpoint); `test_upgrade_applies_premium_and_returns_contract`, `test_upgrade_returns_exact_premium_feature_data`; API contract tests |
| AC-4 | `renew_at` unchanged in response, user record and billing | Met | `src/backend/main.py:239,246` (value only carried); `test_renewal_date_is_unchanged`; property `test_upgrade_never_changes_the_renewal_date` |
| AC-5 | tests: pytest cases (0, 15, 29, 30+) and Hypothesis properties; Premium payload not shared; dev-only test packages | Met | `tests/unit/backend/test_proration_properties.py`, `test_premium_payload_is_not_shared_between_accounts`; `src/backend/requirements-dev.txt` (runtime `requirements.txt` untouched) |
| REQ-F-03 | proration rule | Met | `main.py:99-113` |
| REQ-F-04 | upgrade endpoint contract | Met | `main.py:231-246` |
| REQ-F-06 | Premium plan data | Met | `main.py:115-150` |
| REQ-F-09 | renewal date unchanged | Met | `main.py:239,246` |
| REQ-F-11 | unparseable date counts as 0 | Met | `main.py:102-105` |
| REQ-NF-03 | property-based tests on proration | Met | `tests/unit/backend/test_proration_properties.py` (8 properties) |
| REQ-NF-04 | no new runtime dependencies | Met | diff leaves `src/backend/requirements.txt` unchanged |

Recorded plan decision: the eligibility guards (400 already Premium, 401 unknown email) are implemented in this story because the endpoint would otherwise be unsafe (SEC-05, SEC-08, ARCH-01); Story 1.2 still owns the 422 tightening, the global handler and its own tests and scenarios.

## Issues Found

### SEC-ISS-001: Upgrade endpoint has no authentication or object-level authorization (High, waived)
**Security Rule**: SECURITY-08 - Application-Level Access Control - **Criteria violated**: every handler has an authorization guard; no resource ID is acted on without ownership verification
**File**: `src/backend/main.py:231-246` - **Reference**: CWE-862 / OWASP A01:2025
**Issue**: any caller who knows an account email can upgrade it.
**Suggested Fix**: require the caller's token and reject a mismatch with 401/403.
**Status**: WAIVED, not remediated. The approved requirement REQ-NF-01 (user decision Q1 A) records this as an accepted POC deviation; remediation would reverse an approved requirement and is therefore not part of the auto-remediate loop. It is surfaced in the PR description and the security report and must be fixed before any real deployment.

## Security - Advisory (non-blocking)
- SEC-002 (SECURITY-05): the email has no max length; fixed by Story 1.2 AC-3.
- SEC-003 (SECURITY-15 / 03): no global exception handler or logging; Story 1.2 AC-4.
- SEC-004 (SECURITY-13): no audit trail of plan changes; recommend a follow-up ticket.
- SEC-005 (SECURITY-11): no rate limiting; pre-existing app-wide.
- SEC-006 (SECURITY-10, Low): unpinned runtime dependencies, no lock file (pre-existing).
- Pre-existing and not this change: missing security headers, wildcard CORS, default seed credentials with plaintext passwords, email-as-token, no logging. Recommend `/raise-defect`.

## Issue Summary
| # | ID | Severity | AC/Requirement or SECURITY rule | File | Status |
|---|-----|----------|----------------|------|--------|
| 1 | SEC-ISS-001 | High | SECURITY-08 (Application-Level Access Control) | src/backend/main.py:231 | Waived (REQ-NF-01) |

**Counts**: Blockers: 0 | High: 1 - of which security: 0 Blocker / 1 High (waived) - Advisory (non-blocking): 5

## Approval Status
**Decision**: APPROVED WITH COMMENTS
**Reason**: every acceptance criterion and requirement is Met; the single High security finding is a documented, user-accepted deviation and is not remediable without changing an approved requirement.
