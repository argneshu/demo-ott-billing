# Evidence Manifest - API and contract tests - story-1.1

| Field | Value |
|---|---|
| Work unit | Story 1.1 - Backend prorated upgrade to Premium |
| Branch / head | story/1.1-backend-prorated-upgrade-to-premium @ 9eb1a1f (work tree) - base 9eb1a1f |
| Generated | 2026-10-14T11:15:56Z |
| AIRE version | 1.0 |
| Status | PASS |

## Commands run
| # | Command | Working directory | Exit code |
|---|---|---|---|
| 1 | `pytest ../../tests/api --junitxml=...` | src/backend | 0 |

## Tools
| Tool | Version |
|---|---|
| pytest | 9.1.1 |
| httpx | 0.28.1 |
## Result
| Endpoint | Functional | Status codes | Auth 401/403 | Error shape | Request validation | Response schema |
|---|---|---|---|---|---|---|
| POST /api/billing/upgrade | Pass | Pass (200, 400, 401, 405, 422) | 401 Pass; 403 N/A - the API has no role model (documented deviation REQ-NF-01) | Pass | Pass | Pass |

11/11 tests passed.

## Artifacts
| File | What it is |
|---|---|
| api-contract-test-run.log | raw output |
| api-contract-test-report.xml | JUnit XML |
## Exceptions and notes
Tests live in tests/api/test_upgrade_contract.py. Token or role authorization is not implemented by design (accepted deviation REQ-NF-01).
