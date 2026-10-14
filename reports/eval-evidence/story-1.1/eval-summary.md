### Eval Scorecard - Story 1.1 - **PASS**

| Gate | Result | Threshold | Status |
|---|---|---|---|
| D1 Lint | 0 new findings (3 pre-existing) | <= 0 delta | PASS |
| D2 Type check | 0 errors | 0 | PASS |
| D3 Static security | 0C / 0H / 0M new (1 pre-existing) - SonarQube not configured | 0C / 0H / <=5M | PASS |
| D4 Dependencies | 0C / 0H | 0C / 0H | PASS |
| D5 Licences | 0 violations | none disallowed | PASS |
| D6 Complexity | max 3 on changed functions | <= 12 | PASS |
| D7 Secrets | 0 findings | 0 | PASS |
| Unit coverage | 100.0% changed lines (34/34) | >= 90.0% | PASS |
| Behavioural B1 (this story) | 5/5 scenarios - 5/5 ACs - native, podman not installed | 100% | PASS |
| Behavioural B2 (cumulative) | N/A - no other active feature file (1.2-1.5 not started) | when another feature exists | N/A |
| Behavioural B3 (epic scope) | N/A - not the last story (1.2, 1.3, 1.4, 1.5 have no merged PR) | last unit only | N/A |
| API & contract | 1/1 endpoints | all applicable | PASS |
| Playwright UI automation | N/A - no Frontend Components Generation step in the plan | UI stories only | N/A |
| Playwright E2E regression | N/A - tests/e2e held no spec at baseline | 0 new | N/A |
| Regression | 0 new failures (baseline 0 tests, now 42 passing) | 0 | PASS |
| J1 Architecture | 1.0 | >= 0.85 | PASS |
| J2 Security (OWASP 2025) | 0.9 | >= 0.85 | PASS |

**Verdict**: PASS - judge `claude-sonnet-5-5` - rubric v1.0.0 (from `architecture.md` v1.0.0)
**Self-healing**: SH-LOOP-1 1/3 - SH-LOOP-4 2/3 - all other loops 0/3
**Bootstrapped**: src/backend/ruff.toml, src/backend/mypy.ini, .gitleaks.toml, tests/.evals/behavior/ (runner)
**Accepted deviation**: REQ-NF-01 - POST /api/billing/upgrade has no token check (user decision Q1 A); reported by the security review, not scored in J2 SEC-01.
**J2 note**: SEC-07 scored 0.0 (no global exception handler for the new endpoint, `src/backend/main.py:231`); Story 1.2 AC-4 adds it.
