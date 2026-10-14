# Evidence Manifest - Static eval gate D1-D7 - story-1.1

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
| 1 | `ruff check --output-format json main.py ../../tests` | src/backend | 1 (3 baseline findings only) |
| 2 | `mypy main.py ../../tests` | src/backend | 0 |
| 3 | `semgrep --config auto --json src/backend/main.py tests` | repo root | 0 |
| 4 | `pip-audit -r requirements-dev.txt` | src/backend | 0 |
| 5 | `pip-licenses --format=json` | src/backend | 0 |
| 6 | `radon cc -s -j main.py` | src/backend | 0 |
| 7 | `gitleaks detect --no-git --config .gitleaks.toml` | repo root | 0 |

## Tools
| Tool | Version |
|---|---|
| ruff | 0.17.0 |
| mypy | 2.4.0 |
| semgrep | 1.180.0 |
| pip-audit | 2.10.1 |
| pip-licenses | 5.5.5 |
| radon | 6.0.1 |
| gitleaks | 8.30.1 |
## Result
| Gate | Tool | Baseline findings | Post-change findings | NEW on changed files | Threshold | Status |
|---|---|---|---|---|---|---|
| D1 Lint | ruff 0.17.0 | 3 (I001, 2x DTZ002, pre-existing) | 3 (same) | 0 | <= 0 delta | PASS |
| D2 Type check | mypy 2.4.0 | 0 | 0 | 0 | 0 | PASS |
| D3 SAST | semgrep 1.180.0 (--config auto) | 1 (wildcard-cors, pre-existing) | 1 (same) | 0 | 0C/0H/<=5M | PASS |
| D4 Dependencies | pip-audit 2.10.1 | 0 | 0 | 0 | 0C/0H | PASS |
| D5 Licences | pip-licenses 5.5.5 | 0 | 0 | 0 | none disallowed | PASS |
| D6 Complexity | radon 6.0.1 | max 5 (login) | max 5 (login); changed functions max 3 | 0 | <= 12 | PASS |
| D7 Secrets | gitleaks 8.30.1 | 0 | 0 | 0 | 0 | PASS |

## Artifacts
| File | What it is |
|---|---|
| ruff.json, mypy.log, semgrep.json, pip-audit.json, license-report.json, radon.json, gitleaks.json | post-change tool output |
| baseline/ | the same seven tools before the change |
## Exceptions and notes
Bootstrap created src/backend/ruff.toml (default rules), src/backend/mypy.ini, .gitleaks.toml (default ruleset). SH-LOOP-4 used 2 attempts: (1) mypy flagged `object` arguments in the upgrade handler, fixed with `str(user[...])`; (2) ruff SIM115 in two helper scripts, fixed with context managers. Findings were matched on rule id, file and message, never on line number. semgrep runs from an isolated venv outside the repo so its pinned dependencies do not conflict with the app.
