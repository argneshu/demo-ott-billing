# Artifact Completeness Check - story-1.1

| File | Required because | Present | Format OK | Consistent | Action taken |
|---|---|---|---|---|---|
| reports/unit-test-evidence/story-1.1/baseline-regression.log | E1 always | yes | yes | yes | none |
| reports/unit-test-evidence/story-1.1/unit-test-run.log | E1 | yes | yes | yes | none |
| reports/unit-test-evidence/story-1.1/coverage/coverage.xml | E1 machine-readable report | yes | yes | yes | none |
| reports/unit-test-evidence/story-1.1/coverage/coverage-summary.json | E1 | yes | yes | yes | none |
| reports/unit-test-evidence/story-1.1/coverage/changed-lines-coverage.json | E1 gate metric | yes | yes | yes | none |
| reports/unit-test-evidence/story-1.1/full-regression.log | E1 | yes | yes | yes | none |
| reports/unit-test-evidence/story-1.1/test-placement-check.log | E1 (test files changed) | yes | yes | yes | none |
| reports/unit-test-evidence/story-1.1/evidence-manifest.md | E1 | yes | yes | yes | none |
| reports/behavior-test-evidence/story-1.1/b1/behavior-test-run.log | E2 b1 | yes | yes | yes | none |
| reports/behavior-test-evidence/story-1.1/b1/behavior-test-report.json | E2 b1 | yes | yes | yes | none |
| reports/behavior-test-evidence/story-1.1/b1/evidence-manifest.md | E2 b1 | yes | yes | yes | none |
| reports/api-contract-test-evidence/story-1.1/api-contract-test-run.log | E3 plan has an API layer step | yes | yes | yes | none |
| reports/api-contract-test-evidence/story-1.1/api-contract-test-report.xml | E3 | yes | yes | yes | none |
| reports/api-contract-test-evidence/story-1.1/evidence-manifest.md | E3 | yes | yes | yes | none |
| reports/eval-evidence/story-1.1/eval.json | E6 | yes | yes | yes | none |
| reports/eval-evidence/story-1.1/eval-summary.md | E6 | yes | yes | yes | none |
| reports/eval-evidence/story-1.1/static/evidence-manifest.md | E6 static | yes | yes | yes | none |
| reports/eval-evidence/story-1.1/judge/architecture-score.json | E6 judge | yes | yes | yes | none |
| reports/eval-evidence/story-1.1/judge/security-score.json | E6 judge | yes | yes | yes | none |
| reports/reviews/story-1.1-code-review-v1.md | E7 | yes | yes | yes | none |
| reports/code-security-reviews/story-1.1-security-review-v1.md | E8 | yes | yes | yes | none |
| runtime-artifacts/stories/story-1.1/audit.md | E10 | yes | yes | yes | none |
| runtime-artifacts/stories/story-1.1/state.md | E10 | yes | yes | yes | none |
| reports/eval-evidence/story-1.1/static/ruff.json | E6 static post-change | yes | yes | yes | none |
| reports/eval-evidence/story-1.1/static/baseline/ruff.json | E6 static baseline | yes | yes | yes | none |
| reports/eval-evidence/story-1.1/static/mypy.log | E6 static post-change | yes | yes | yes | none |
| reports/eval-evidence/story-1.1/static/baseline/mypy.log | E6 static baseline | yes | yes | yes | none |
| reports/eval-evidence/story-1.1/static/semgrep.json | E6 static post-change | yes | yes | yes | none |
| reports/eval-evidence/story-1.1/static/baseline/semgrep.json | E6 static baseline | yes | yes | yes | none |
| reports/eval-evidence/story-1.1/static/pip-audit.json | E6 static post-change | yes | yes | yes | none |
| reports/eval-evidence/story-1.1/static/baseline/pip-audit.json | E6 static baseline | yes | yes | yes | none |
| reports/eval-evidence/story-1.1/static/license-report.json | E6 static post-change | yes | yes | yes | none |
| reports/eval-evidence/story-1.1/static/baseline/license-report.json | E6 static baseline | yes | yes | yes | none |
| reports/eval-evidence/story-1.1/static/radon.json | E6 static post-change | yes | yes | yes | none |
| reports/eval-evidence/story-1.1/static/baseline/radon.json | E6 static baseline | yes | yes | yes | none |
| reports/eval-evidence/story-1.1/static/gitleaks.json | E6 static post-change | yes | yes | yes | none |
| reports/eval-evidence/story-1.1/static/baseline/gitleaks.json | E6 static baseline | yes | yes | yes | none |

## N/A gates (no folder exists for any of them)
- behaviorB2: no other active feature file - stories 1.2, 1.3, 1.4, 1.5 are still Ready for Development
- behaviorB3: not the last work unit - stories 1.2, 1.3, 1.4, 1.5 have no merged PR
- playwright: no Frontend Components Generation step in this story's plan
- playwrightRegression: tests/e2e held no spec at baseline

## Consistency
- eval.json verdict PASS; every manifest status equals its eval.json gate status; eval-summary.md has one row per gate.
- Folders for N/A gates present: none.
- Missing files: none.
