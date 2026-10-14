# Evidence Manifest - Behavioural tier B1 - story-1.1

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
| 1 | `AIRE_STORY_KEY=story-1.1 sh tests/.evals/behavior/run.sh b1` | repo root | 0 |
| 2 | `python tests/.evals/behavior/report.py b1 story-1.1 ...` | repo root | 0 |

## Tools
| Tool | Version |
|---|---|
| pytest-bdd | 9.0.0 |
| pytest | 9.1.1 |
## Result
| Measure | Value |
|---|---|
| Tier | B1 (this unit) |
| Feature files in scope | spec/behavior/story-1.1.feature |
| Scenarios passed | 5/5 (9 test cases, the outline expands to 5) |
| @AC tags executed | 5/5 |
| Containerised | no - reason: podman not installed |
| Image ref + digest | n/a (native run; Containerfile written but cannot be built without podman) |

| Scenario | Tags | Result |
|---|---|---|
| Prorated charge for the days remaining | @AC-1 | PASS |
| Unparseable renewal date is treated as no days remaining | @AC-2 | PASS |
| Successful upgrade applies the Premium plan | @AC-3 | PASS |
| Renewal date is unchanged by the upgrade | @AC-4 | PASS |
| Premium data is not shared between accounts | @AC-5 | PASS |

## Artifacts
| File | What it is |
|---|---|
| behavior-test-run.log | raw run output |
| behavior-test-junit.xml | JUnit report |
| behavior-test-report.json | machine-readable report with tag coverage |
## Exceptions and notes
`containerised: false, reason: podman not installed` (checked with `command -v podman`). Parity is UNVERIFIED for this tier. The Docker CLI exists on this machine but is never used as a fallback.
