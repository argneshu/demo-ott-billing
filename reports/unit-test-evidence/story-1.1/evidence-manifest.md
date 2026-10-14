# Evidence Manifest - Unit tests and coverage - story-1.1

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
| 1 | `pytest ../../tests/unit --cov=main --cov-branch --cov-report=xml,json,html` | src/backend | 0 |
| 2 | `python tests/.evals/scripts/changed-lines-coverage.py story-1.1 9eb1a1f 90.0 ...` | repo root | 0 |
| 3 | `pytest ../../tests` (baseline: 0 tests; post-change full regression) | src/backend | 0 |

## Tools
| Tool | Version |
|---|---|
| pytest | 9.1.1 |
| pytest-cov | 7.1.0 |
| hypothesis | 6.169.1 |
| python | 3.14.6 |
## Result
| Measure | Value |
|---|---|
| Tests passed | 22/22 (unit); 42/42 full suite |
| Changed executable lines covered | 34/34 (100.0%) |
| Changed branches covered | 4/4 (100.0%) |
| Threshold (unitTestCoverageMin) | 90.0% |
| Whole-file coverage (transparency, not the gate) | 75.9% (main.py includes untouched login/register/me code) |
| Baseline pass/fail | 0 passed / 0 failed (no test suite existed) |
| Post-change pass/fail | 42 passed / 0 failed |
| New failures | none |
| Test placement verdict | PASS (0 violations) |

## Artifacts
| File | What it is |
|---|---|
| unit-test-run.log | final unit run with coverage |
| coverage/coverage.xml | Cobertura report |
| coverage/coverage-summary.json | coverage.py JSON summary |
| coverage/htmlcov/ | HTML report |
| coverage/changed-lines-coverage.json | gate metric |
| baseline-regression.log | baseline (no suite) |
| full-regression.log | post-change full suite |
| test-placement-check.log | placement verdict |
## Exceptions and notes
SH-LOOP-1 used 1 attempt: the first coverage measurement read 64.71% because the behaviour-steps plugin imported `main` before coverage started; the plugin now imports it lazily and the re-measurement is above. Test packages are dev-only (requirements-dev.txt).
