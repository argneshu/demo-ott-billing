# Work-Unit Artifacts — the Evidence Every Implement Run Must Leave Behind

**Purpose**: every `dev-implement`, `bug-fix-implement` and `enhancement-implement` run (and, through them,
`epic-enhance`, `epic-bugfix` and `pr-fix`) must leave the **same complete set of evidence files, in the
same layout and format**, so reviewers, the Verification Engineer and CI can rely on them. Real runs have
skipped pieces — a UI story with generated Playwright specs but no `playwright-test-evidence/` folder, a
later story with no Playwright regression evidence, a static baseline holding one tool's output out of
seven, a coverage folder without the changed-lines measurement. This file is the single checklist, and
**Section 5 is the check that makes skipping impossible**: nothing is committed until every required file
exists, has its format, and agrees with the others.

`<key>` = the work unit's evidence key: `story-<N.M>` (epic stories, including change and bugfix
stories), `bug-<TICKET-ID>`, or `enhancement-<TICKET-ID>`. `<slug>` = `<key>-<kebab-case-title>`.

---

## 1. The evidence set

### E1 — Unit tests + coverage — `reports/unit-test-evidence/<key>/` — **always**

| File | Content |
|---|---|
| `baseline-regression.log` | the whole repo suite on the freshly cut branch, before any change |
| `unit-test-run.log` | raw output of the final passing unit-test run |
| `coverage/` | the coverage tool's own output: the **machine-readable report** (`lcov.info`, `coverage.xml`, `jacoco.xml`, `coverage.out` … — this is what "`coverage-report.*`" means everywhere else), `coverage-summary.json` (or the stack's summary), and the HTML report when the tool emits one (`lcov-report/`) |
| `coverage/changed-lines-coverage.json` | 🔴 **the gate metric**: coverage of the lines and branches this unit added or changed (Section 2.2) |
| `full-regression.log` | the whole repo suite after the change, diffed against the baseline |
| `test-placement-check.log` | `dev-implement` runs only (Step 6.3), whenever the unit changed any test file (Section 2.3); the bug and enhancement flows have no test-placement gate |
| `evidence-manifest.md` | Section 2 format |

### E2 — Behavioural tiers — `reports/behavior-test-evidence/<key>/`

| Folder | When | Files |
|---|---|---|
| `b1/` | **always** (a unit with ACs is never B1 N/A) | `behavior-test-run.log` · `behavior-test-report.json` (or the runner's machine-readable format) · `evidence-manifest.md` |
| `b2/` | **always**, unless the repo holds no other feature file (then N/A) | same three files |
| `b3/` | 🔴 **only on the LAST work unit of the cycle, when B3 actually runs** | same three files |

Every other unit creates **no `b3/` folder** — its B3 is `N/A` in `eval.json` / `eval-summary.md` with the
reason (e.g. `not the last story — 1.4, 1.5 still open`).

### E3 — API & contract — `reports/api-contract-test-evidence/<key>/` — when the plan has an API Layer Generation step

`api-contract-test-run.log` · `api-contract-test-report.json` (or JUnit XML / trx) · `evidence-manifest.md`.
The tests themselves live in **`tests/api/`** (Section 1.3).

### E4 — Playwright UI automation — `reports/playwright-test-evidence/<key>/` — when the plan has a Frontend Components Generation step

`playwright-test-run.log` · `playwright-test-report.json` · `evidence-manifest.md` — plus, outside
`reports/`: the generated specs in `tests/e2e/<slug>/`, the Planner's plan in
`spec/playwright-specs/<slug>.md`, and `spec/test-plans/<TICKET-ID>-<title>/automation-summary.md`.

### E5 — Playwright E2E regression — `reports/playwright-test-evidence/<key>/regression/` — whenever `tests/e2e/` held at least one spec at baseline

`playwright-baseline-regression.log` · `playwright-baseline-report.json` · `playwright-full-regression.log` ·
`playwright-regression-report.json` · `evidence-manifest.md`. 🔴 This runs for **every** unit, UI or not,
once any earlier unit has shipped a spec — a backend story that follows a UI story must still produce it.

### E6 — Evals — `reports/eval-evidence/<key>/` — **always**

| File / folder | Content |
|---|---|
| `eval.json` | `common/eval-framework.md` Section 6.1 |
| `eval-summary.md` | `common/eval-framework.md` Section 6.2 |
| `static/` | the post-change raw output of **every D-gate that is not N/A** (e.g. `eslint.json`, `tsc.log`, `semgrep.json`, `npm-audit.json`, `license-report.json`, the complexity output, `gitleaks.json`), the deltas `run-static-evals` writes (`semgrep-delta.json`, `gitleaks-delta.json`, `delta-summary.json`, `static-results.json.gates`), and `evidence-manifest.md` (Section 2) |
| `static/baseline/` | 🔴 the pre-change output of the **same tool set** — one baseline output per D-gate that is not N/A. A baseline with fewer tools than the post-change run makes the diff meaningless |
| `judge/architecture-score.json` · `judge/security-score.json` | per-criterion breakdown, with citations for every criterion below 1.0 |
| `preflight/` | when `## CI/CD Configuration` is `Enabled: Yes` |
| `test-impact-reconciliation.md` | change and bugfix stories (`epic-enhance` / `epic-bugfix`) |
| `artifact-check.md` | the Section 5 result |

### E7 — Code review — `reports/reviews/<key>-code-review-v<X>.md` — **always**, every version kept

### E8 — Security review — `reports/code-security-reviews/<key>-security-review-v<X>.md` — **always**

`<X>` = the code-review version this pass belongs to. 🔴 Never the dated `security-review-YYYY-MM-DD.md`
from a workflow run — two stories reviewed on the same day would both create it (an add/add merge
conflict, and a report nobody can trace to its story). The dated name belongs only to the standalone
full-repository `code-security-review` skill.

### E9 — Manifest fragment — `tests/.evals/ci-manifest.d/<key>.json` — when `Enabled: Yes`

### E10 — State and audit — `runtime-artifacts/stories/<key>/audit.md` + `state.md` — **always** (`common/parallel-work-state.md`)

### E11 — Ticket summary — `reports/ticket-summary/<key>-summary.md` — bug and enhancement units (the summary those workflows already write)

### 1.1 The N/A rule — no folder for a gate that did not run

🔴 **A gate that is `N/A` creates no evidence folder and no empty files.** Its `N/A` status and reason live
in `eval.json` (`gates.<id>.status = "N/A"`, `reason`) and its `eval-summary.md` row — nowhere else. This
covers B3 on every unit but the last, API & contract without an API step, Playwright UI without a
Frontend step, and the regression sweep when `tests/e2e/` holds no spec. Conversely, **a gate that ran
always has its complete folder** — a PASS without its manifest is not a PASS.

### 1.2 Applicability is decided once, and the evidence must match it

| Gate | Runs when | Decided from |
|---|---|---|
| B3 | this unit is the last of the cycle (every other unit's PR merged, live check) | `gh pr view` per unit |
| API & contract | the plan has an **API Layer Generation** step | the code-generation plan |
| Playwright UI | the plan has a **Frontend Components Generation** step | the code-generation plan |
| Playwright regression | `tests/e2e/` holds ≥1 spec at baseline | the baseline run |

A gate is never `N/A` because a tool is not installed — the tool is installed (Section 5 of
`common/self-heal-limit-guidance.md` covers the case it truly cannot be).

### 1.3 Where the test code goes (so the evidence and the tests line up)

| Tests | Location |
|---|---|
| Unit | `tests/unit/<mirror-of-src>/` |
| API & contract | `tests/api/` (never `tests/unit/`, never a per-story folder such as `tests/api-contract/<key>/`) |
| Gherkin step definitions / support | `tests/behavior/steps/` · `tests/behavior/support/` |
| Playwright | `tests/e2e/seed.spec.ts` (shared) · `tests/e2e/<slug>/*.spec.ts` — written only by the `playwright-implement` subagents |

---

## 2. `evidence-manifest.md` — one format for every evidence folder

Every `evidence-manifest.md` (E1, each E2 tier, E3, E4, E5, `static/`) uses this skeleton; only the
**Result** section is gate-specific.

```markdown
# Evidence Manifest — <gate name> — <key>

| Field | Value |
|---|---|
| Work unit | <Story N.M — title | BUG-ID — title | ENH-ID — title> |
| Branch / head | <branch> @ <short sha> · base <short sha> |
| Generated | <ISO 8601 timestamp, one real clock command> |
| AIRE version | <N, read live from CLAUDE.md> |
| Status | PASS | FAIL        (identical to `eval.json` → `gates.<id>.status`) |

## Commands run
| # | Command | Working directory | Exit code |
|---|---|---|---|

## Tools
| Tool | Version |
|---|---|

## Result
<gate-specific table — Section 2.1>

## Artifacts
| File | What it is |
|---|---|

## Exceptions and notes
<repo configuration used as-is, documented exceptions, self-healing attempts that changed this gate's
result, or "None">
```

### 2.1 Gate-specific Result tables

| Manifest | Result table |
|---|---|
| E1 unit + coverage | Tests passed (X/X) · Changed executable lines covered (x/y, %) · Changed branches covered (x/y, %) · Threshold (%) · Whole-file coverage (for transparency, not the gate metric) · Baseline pass/fail · Post-change pass/fail · New failures (each with what broke and how it was fixed) · Test placement verdict |
| E2 behavioural tier | Tier · Feature files in scope · Scenarios passed (X/X) · `@AC` tags executed (X/X) · Containerised (yes/no + reason) · Image ref + digest |
| E3 API & contract | one row per endpoint + method: Functional · Status codes · Auth 401/403 · Error shape · Request validation · Response schema — each `Pass` or `N/A — reason` |
| E4 Playwright UI | Manual TC → generated spec → result · Headed (yes) · `test.fixme()` count (must be 0) |
| E5 Playwright regression | Baseline pass/fail · Post-change pass/fail · New failures (spec + what broke + fix) · Headed (no — bulk regression sweep) |
| `static/` | one row per D-gate: tool · baseline findings · post-change findings · NEW findings on changed files · threshold · status (`N/A — reason` where it applies) |

### 2.2 `coverage/changed-lines-coverage.json`

```json
{
  "key": "story-1.2", "base": "<sha>", "threshold": 90.0,
  "files": [
    { "path": "src/frontend/screens/BoardScreen.tsx",
      "changedExecutableLines": 2, "coveredLines": 2,
      "changedBranches": 14, "coveredBranches": 14 }
  ],
  "lineCoverage": 100.0, "branchCoverage": 100.0, "status": "PASS"
}
```

Computed from `git diff --unified=0 <base>` intersected with the coverage report's line (`DA`) and branch
(`BRDA`) records (or the stack's equivalent). This is the number the coverage gate, `eval.json`
`gates.unitCoverage.value` and `eval-summary.md` report.

### 2.3 `test-placement-check.log`

Written by `tests/.evals/scripts/check-test-placement.*` when the project has it; otherwise the run applies
the same rules (`common/directory-structure.md` rules 4a/4b, `implementation/code-generation.md`
Step 11a.6) to `git diff --name-only --diff-filter=ACMR <base>...HEAD` itself and writes the same log:
every changed test path, its classification (`unit-test` / `api-test` / `other`), the rule it was checked
against, and the verdict. Never skipped because the script is missing.

---

## 3. Formats that already exist — use them exactly

| Artifact | Format source |
|---|---|
| `eval.json` | `common/eval-framework.md` Section 6.1 — every gate id present (`D1_lint`, `D2_types`, `D3_sast`, `D4_deps`, `D5_licenses`, `D6_complexity`, `D7_secrets` — the same ids as `ci.gates` — `unitCoverage`, `behaviorB1`, `behaviorB2`, `behaviorB3`, `apiContract`, `playwright`, `playwrightRegression`, `regression`, `J1_architecture`, `J2_security`, plus `testImpact` for change and bugfix stories), each exactly one of `PASS` / `FAIL` / `ERROR` / `N/A` (+ `reason` for N/A), `selfHealing`, and a `verdict` that is `PASS` only if every gate is `PASS` or `N/A` |
| `eval-summary.md` | `common/eval-framework.md` Section 6.2 — the fixed single table, one row per gate, verdict line, self-healing line |
| Code review report | `implementation/code-review.md` "Code Review Report Template" |
| Security review report | `agents/code-security-review-agent.md` "Report Structure" — scoped to the diff |
| Manifest fragment | `common/ci-pipeline-generation.md` Section 4.0f field table |
| State / audit fragments | `common/parallel-work-state.md` Section 3 |

---

## 4. Consistency rules — the files must agree

1. Every manifest's `Status` equals `eval.json` → `gates.<id>.status`.
2. `eval-summary.md` has exactly one row per `eval.json` gate, with the same status and figures.
3. The figures in the manifests (tests, changed-lines coverage, scenarios, endpoints) equal `eval.json`,
   `eval-summary.md`, and every figure later quoted in the PR body or tracker comment.
4. The latest code-review report names the security report of the **same version**
   (`<key>-security-review-v<X>.md`), and its J1 / J2 values equal `judge/*.json` and `eval.json`.
5. **Folder ⇔ ran**: `b3/`, E3, E4 and E5 exist **if and only if** their gate is not `N/A`.
6. **Applicability ⇔ plan** (Section 1.2): an API Layer Generation step in the plan ⇒ `apiContract` is not
   `N/A`; a Frontend Components Generation step ⇒ `playwright` is not `N/A` and `tests/e2e/<slug>/` exists;
   specs in `tests/e2e/` at baseline ⇒ `playwrightRegression` is not `N/A`; last unit ⇒ `behaviorB3` is not
   `N/A`.
7. `static/baseline/` holds an output for every D-gate that has one in `static/`.

---

## 5. Artifact Completeness Check — before the commit (SH-LOOP-16)

Runs **after the review verdict is clean and before manifest reconciliation / the commit**
(`dev-implement` Section D Step 1.2, `bug-fix-implement` Step 8.4, `enhancement-implement` Step 15.4, and
`pr-fix` Step 14 item 2.5).

1. **Build the expected list** from Section 1: the always-required files, plus each conditional folder
   whose gate ran (read from `eval.json` and the plan, Section 1.2).
2. **Check every expected file**: it exists, is non-empty, and has its format (the Section 2 manifest
   skeleton, `changed-lines-coverage.json` keys, `eval.json` gate ids, one `eval-summary.md` row per gate,
   the review and security report templates).
3. **Check the Section 4 consistency rules**, including that **no folder exists for an `N/A` gate** — an
   empty or placeholder folder is removed.
4. **Fix what is missing or malformed**:
   - the underlying output exists (a manifest, `eval-summary.md`, `changed-lines-coverage.json`, a
     mis-named security report) → write, compute or reformat it **from this run's real outputs**;
   - the underlying output does not exist (no `unit-test-run.log`, no coverage report, an incomplete
     static baseline, no Playwright report, no regression sweep) → that gate never produced its evidence,
     so **re-run that gate's step** (its own loop, counters continuing). An incomplete static baseline is
     recaptured at the merge-base in a scratch worktree, as `workflows/pr-fix.md` Step 8 describes;
   - 🔴 never hand-write a result, a log or a figure.
5. **Record** the result in `reports/eval-evidence/<key>/artifact-check.md` — one row per expected file:
   `File | Required because | Present | Format OK | Consistent | Action taken` — plus the N/A gates and
   their reasons. Log it in the unit's audit trail.
6. **Budget**: one fix-and-recheck cycle is one attempt of **SH-LOOP-16 — Artifact Completeness**, capped
   at 3. Exhaustion → HALT with the Self-Heal Limit message (`common/self-heal-limit-guidance.md`), nothing
   committed.
7. Only a clean check lets the run proceed to the commit. The evidence is committed with the unit
   (`reports/**` travels on the work-unit branch).

---

## 6. The Gate Ledger and the work-unit guard

### 6.1 The Gate Ledger — every gate, one allowed outcome

Before the commit, every gate below has exactly one recorded outcome in `eval.json`, and the only outcomes
that may be committed are `PASS` and `N/A` with a reason on the closed list (`common/eval-framework.md`
Section 2.5.1). "Not run", "skipped", "scope call", "to keep the session moving", "not installed" and
every Section 2.5.2 reason are not outcomes — they mean the gate still has to run.

| Gate | May be N/A? |
|---|---|
| `D1_lint` … `D7_secrets` | only for reasons 1 or 3 (reason 3 only after the full install chain, Podman rung included) |
| `unitCoverage`, `behaviorB1`, `regression`, `J2_security` | never |
| `behaviorB2` | only when the repo holds no other feature file |
| `behaviorB3` | when this is not the last work unit |
| `apiContract` / `playwright` | when the plan has no API Layer / Frontend Components Generation step |
| `playwrightRegression` | when `tests/e2e/` held no spec at baseline |
| `J1_architecture` | when no architecture rubric is derivable (`common/eval-framework.md` Section 3) |
| `testImpact` | never, on change and bugfix stories |

Plus the tracker claim: a non-LOCAL Tracker ID is transitioned to In Development AND assigned to the
operator on the external tracker at the claim, both verified, and recorded in the fragment's `## Claim`
block (`common/parallel-work-state.md` Section 3.2). A gate that cannot reach an allowed outcome is an `ERROR`: HALT with the
Self-Heal Limit message. Nothing is committed, no PR is raised.

### 6.2 The work-unit guard — `aire-workflow/templates/hooks/check-work-unit.sh`

A deterministic script, so the ledger is enforced by a check the run cannot talk its way past:

- **Install** right after the work-unit branch is cut or checked out:
  `sh aire-workflow/templates/hooks/check-work-unit.sh --install <unit-key>`. It records the branch and the
  unit key in `.git/aire-work-unit` and installs a git `pre-commit` hook (an existing hook is kept as
  `pre-commit.local` and still runs first). When `core.hooksPath` is set, the hook is not installed (that
  folder may be versioned) and the explicit run below is the enforcement.
- **Run explicitly** right before `git commit`: `sh aire-workflow/templates/hooks/check-work-unit.sh <unit-key>`.
  The hook runs the same check on the commit itself, on that branch only.
- **What it refuses**: a missing `eval.json` gate; a status other than `PASS` or `N/A`; an `N/A` with no
  reason, a forbidden reason, or on a gate that can never be `N/A`; a verdict other than `PASS`; any
  required E1/E2/E6/E7/E8/E10/E11 file missing, empty or not staged; E3/E4/E5 files missing when their gate
  passed; a folder present for an `N/A` gate; fewer `static/baseline/` outputs than D-gates that ran; a
  unit `state.md` with no `## Claim` block, or a non-LOCAL claim whose `Tracker:` line is not `verified` or
  whose `Assignee:` line is neither `verified` nor `unresolved`.
- 🔴 **Never bypass it** — no `git commit --no-verify`, no editing `eval.json` to satisfy it, no placeholder
  files. A refusal is fixed by running the missing gate and writing its real evidence (Section 5), within
  SH-LOOP-16's budget; exhaustion → HALT with the Self-Heal Limit message.
- Hooks run in Git's bundled `sh` on every platform (Git for Windows included), so one `.sh` script serves
  all; the repository's `.gitattributes` keeps `*.sh` at LF endings.
