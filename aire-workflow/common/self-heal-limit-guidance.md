# Self-Heal Limit Guidance — What the Developer Sees, and How They Take Over

**Purpose**: when an automatic self-healing loop uses its 3 attempts and the gate still fails (SH-4), or a
stall ends the budget early (SH-5), the developer must be able to **see exactly what is wrong, fix it
themselves, and hand the work back** — without reading the workflow files. This file is the single
source of truth for:

1. the **Self-Heal Limit message** every implement workflow emits at SH-4 (Section 2),
2. the **per-gate manual-fix playbook** that fills its "HOW TO FIX IT YOURSELF" block (Section 3),
3. the **resume protocol** that picks the work up again after a manual fix (Section 4),
4. the **tool-installation blocked** message for the one other halt that needs manual action (Section 5).

It is used by `workflows/dev-implement.md`, `workflows/bug-fix-implement.md`,
`workflows/enhancement-implement.md`, and — through them — `epic-enhance`, `epic-bugfix` and `pr-fix`.

🔴 **The stop signal.** If you catch yourself wanting to wrap up, "keep the session moving", make a
"scope call", or list gaps for the user to accept, that is not a reason to ship — it is the signal to
either do the missing work now or HALT with the message in Section 2 (or Section 5 for a tool that truly
cannot be installed). A PR raised with a gate unrun, a tracker transition unmade or an evidence file
missing is a framework violation, however honestly it is disclosed.

---

## 1. State left behind at the halt

When SH-4 fires, before emitting the message:

- **Nothing is committed, pushed or raised**, no tracker status changes, the work unit stays
  `In Development` on its branch.
- **The 3 attempted fixes stay in the working tree** — the developer inspects them with `git diff`.
- **Record the halt** in the work unit's state (`runtime-artifacts/stories/<unit-key>/state.md`
  `## Progress`, per `common/parallel-work-state.md`):
  ```markdown
  HALTED — <SH-LOOP-ID> <loop name> exhausted at <step / gate> — <ISO timestamp>
  Head at halt: <sha> · Working tree: 3 attempted fixes, uncommitted
  Resume keyword: <dev-implement | bug-fix-implement | ticket-implement <ID> | epic-enhance | epic-bugfix | pr-fix <n>>
  ```
- Log the full message in the work unit's audit trail under
  `## Self-Healing Retry Limit Reached — <SH-LOOP-ID> (<work unit>)`.

---

## 2. The Self-Heal Limit message — emit VERBATIM, every bracketed value substituted

Fill every bracket from the run's own evidence. **Never ship an unsubstituted placeholder**, never write
"unclear" or "complex" as a diagnosis, and take the "HOW TO FIX IT YOURSELF" lines from the Section 3 row
for this SH-LOOP.

```
SELF-HEALING LIMIT REACHED — I could not fix this on my own. Please take a look.

   Gate:       [step number + gate name]   ([SH-LOOP-ID] — 3 of 3 attempts used | ended early: no progress)
   Work unit:  [Story N.M — title | Bug TICKET-ID — title | Enhancement TICKET-ID — title]
   Branch:     [branch]
   Status:     STOPPED at this gate. Nothing was committed, pushed or raised as a PR, and no tracker
               status changed. My 3 attempted fixes are still in your working tree (see step 3 below).

─────────────────────────────────────────────────────────────────────
WHAT IS FAILING
   Measured:   [pass/fail counts | coverage X% vs required Y% | N new findings vs threshold M]
     1. [identifier] — [file:line] — [one-line message]
     2. [identifier] — [file:line] — [one-line message]
     [… every outstanding failure, most important first]

WHY I STOPPED
   [The specific blocker — the constraint, contradiction, missing dependency, environment limitation or
    ambiguous requirement that an automatic fix cannot resolve.]

WHAT I TRIED  (all three changes are in your working tree)
   1. Cause: [diagnosis] → changed: [files] → result: [outcome]
   2. Cause: [diagnosis] → changed: [files] → result: [outcome]
   3. Cause: [diagnosis] → changed: [files] → result: [outcome]

─────────────────────────────────────────────────────────────────────
HOW TO FIX IT YOURSELF
   1. Reproduce it:     [exact command, and the folder to run it from]
   2. Read the detail:  [evidence file paths — logs, reports, screenshots/traces]
   3. Review my tries:  git diff -- [files changed by the 3 attempts]
                        Keep, adjust or revert any of them — they are only suggestions.
   4. Fix it:           [gate-specific guidance from the playbook — where to look, what usually fixes it]
   5. Check your fix:   [same command as step 1] → must show: [the pass criterion]
   6. Hand it back:     type  [resume keyword]
                        I detect this halted [story | ticket], check what you changed, re-run every gate
                        from [first gate to re-run] on your code, and — when all pass — review, commit and
                        raise the PR myself.

   Please do NOT: [gate-specific forbidden shortcuts from the playbook]. The gates detect these and
     will stop again. Also do not commit, push or open the PR yourself — hand it back instead, so every
     gate re-verifies your change.

Please fix this manually yourself, then type [resume keyword] to continue.
```

**The message asks nothing.** It is the last output of the run; the workflow stays halted until the developer
has fixed the problem by hand and typed the resume keyword. That hand-back (Section 4) grants the halted
loop a fresh 3-attempt budget; every other loop keeps the counter it already held (SH-2).

---

## 3. Manual-fix playbook — one row per loop

Use the row for the exhausted loop to fill the message's steps 1, 2, 4, 5 and "Please do NOT". Resolve
commands from `tests/.evals/config.json` (`ci.roots[]`: `coverageCommand`, `installCommands`, `root`) and
the evidence already on disk — never invent a command.

| Loop | 1. Reproduce | 2. Read the detail | 4. Usually fixed by | ⚠ Do NOT | Re-run from |
|---|---|---|---|---|---|
| **SH-LOOP-1** Unit tests + coverage | the root's `coverageCommand`, from `<root>` | `reports/unit-test-evidence/<key>/unit-test-run.log`, `coverage-report.*` (open the HTML report to see the uncovered lines) | a failing test: read its assertion and fix the code it exercises; low coverage: add tests under `tests/unit/<mirror-of-src>/` for the uncovered branches listed in the report | delete, skip or `xfail` a test; lower `unitTestCoverageMin`; exclude files from coverage | Unit tests (the first code gate) |
| **SH-LOOP-7** Gherkin B1 / B2 | `podman run -e AIRE_STORY_KEY=<key> … tests/.evals/behavior/run.sh b1` (then `b2`) | `reports/behavior-test-evidence/<key>/b1/` (or `b2/`) — the failing scenario, its step and the error | fix the application so the scenario's behaviour holds; a missing or wrong step binding in `tests/behavior/steps/` | edit, skip or `@ignore` an approved scenario; run outside Podman to "pass" | Unit tests |
| **SH-LOOP-8** Gherkin B3 (epic scope) | `… run.sh b3` | `reports/behavior-test-evidence/<key>/b3/` | an integration gap between work units — wiring, shared data, the order of calls across stories | edit `spec/behavior.feature` or another unit's scenario to match the code | Unit tests |
| **SH-LOOP-2** API & contract | the API test command on `tests/api/` | `reports/api-contract-test-evidence/<key>/` — per-endpoint checklist | wrong status code, missing 401/403 authorisation, error body shape, request validation, response schema drift | loosen a schema, accept any status, remove an endpoint from the test | Unit tests |
| **SH-LOOP-12** Test placement | the placement rules applied to the diff (or the project's own `check-test-placement.*`) | `reports/unit-test-evidence/<key>/test-placement-check.log` | move each flagged test to `tests/unit/<mirror-of-src>/` or `tests/api/` and fix its imports | disable the check; keep tests under `src/` | Unit tests |
| **SH-LOOP-3** Full regression | the full test suite command | `reports/unit-test-evidence/<key>/full-regression.log` vs `baseline-regression.log` — the tests that were green before and are red now | a real regression → fix the code; a test whose expectation this change legitimately changed → update the assertion (and say why); a test for code this change removed → delete it | delete or skip a failing test just to go green | Unit tests |
| **SH-LOOP-4** Static checks D1–D7 | `tests/.evals/scripts/run-static-evals.*` (or the single tool named in the finding) | `reports/eval-evidence/<key>/static/` vs `static/baseline/` — only NEW findings on changed files count | fix the flagged code: lint error, type error, unsafe pattern, vulnerable/unlicensed dependency (upgrade or replace), function too complex (split it), secret (remove it and use config) | `eslint-disable`, `# nosec`, `# type: ignore`, ignore lists, widening allow-lists or thresholds | Unit tests |
| **SH-LOOP-11** Playwright UI | `npx playwright test tests/e2e/<slug>/ --headed` (app started per `ci.playwright`) | `reports/playwright-test-evidence/<key>/`, then `npx playwright show-report` for the trace and screenshots | fix the application's UI behaviour; a missing test id or wrong seed data | hand-write or edit a `.spec.ts`, add `test.fixme()` / `.skip`, widen timeouts, loosen locators | Unit tests |
| **SH-LOOP-13** Playwright E2E regression | `npx playwright test` (whole `tests/e2e/`, headless) | `reports/playwright-test-evidence/<key>/regression/` vs the baseline report | this change broke a flow an earlier story shipped — usually a changed API response, route, field name or data shape | change an earlier story's spec, skip it, widen its timeout | Unit tests |
| **SH-LOOP-6** Judge J1 / J2 | re-read the scores; they are recomputed on the next review | `reports/eval-evidence/<key>/judge/` — every criterion below 1.0 with its `file:line` citation and weight | fix the cited code against the named `architecture.md` Section 10 constraint (J1) or OWASP category (J2), worst weighted loss first | edit `architecture.md` Section 10 or a rubric, lower a minimum | Unit tests |
| **SH-LOOP-5** Review findings | re-read the latest review report | `reports/reviews/<key>-code-review-v<X>.md` — each 🔴/🟠 finding with `file:line`, plus `reports/code-security-reviews/` | complete the unmet / partially met acceptance criterion, or fix the Critical/High security issue named | delete a finding from the report, narrow the review scope | Unit tests |
| **SH-LOOP-9** CI preflight | `tests/.evals/scripts/preflight-clean-room.*` | `reports/eval-evidence/<key>/preflight/` — the missing tool, undeclared dependency or manifest defect | declare it: the tool in this unit's `tests/.evals/ci-manifest.d/<key>.json` (`tools` + `toolInstallCommands`), a package in the repo's own dependency file | remove a gate from `ci.gates`, mark it N/A, install it only in your own shell | CI preflight (after re-commit) — or Unit tests if you also changed `src/` / `tests/` |
| **SH-LOOP-10** CI attestation | `gh run view <run-id>` and the run's `eval-results` artifact | the CI run's gates block vs the local `eval.json` | a gate CI skipped or could not run → extend this unit's manifest fragment (`sourcePaths`, tools) | edit the workflow YAML to skip the gate | CI preflight |
| **SH-LOOP-16** Artifact completeness | re-read `reports/eval-evidence/<key>/artifact-check.md` | that file — each missing, malformed or inconsistent evidence file and the action attempted | re-run the gate whose evidence is missing so it produces its real log / report / manifest; reformat a manifest to the `common/work-unit-artifacts.md` Section 2 skeleton; remove a folder created for an N/A gate | hand-write a log, a report or a figure; copy another unit's evidence | The gate whose evidence is missing |
| **SH-LOOP-14** pr-fix feedback resolution | re-read each unresolved comment | `reports/pr-feedback/<key>/round-<R>/feedback-ledger.md` | the change the reviewer actually asked for, at the line they commented on | mark an item resolved without the change | Unit tests |
| **SH-LOOP-15** Test impact reconciliation | `git diff --name-status $(git merge-base origin/<epic-branch> HEAD) -- tests/ spec/` | `reports/eval-evidence/<key>/test-impact-reconciliation.md` | restore a test changed without authorisation and fix the code instead; complete an authorised update left undone | change a test that is not on the Test Change Authorization list | Unit tests |

For a loop not listed, fill the steps from its own gate definition and evidence path.

---

## 4. Resume protocol — handing the work back

The developer types the resume keyword the message named. The workflow detects the halt instead of
starting fresh.

1. **Detect**: before story/ticket selection, look for a `HALTED —` record in `## Progress` of the work
   unit on the current branch (and, for `dev-implement`, of any story fragment in this clone whose
   branch is checked out). Found → announce:
   ```
   Resuming [work unit], stopped at [gate] ([SH-LOOP-ID]) on [date].
     Checking what you changed since then…
   ```
   Skip selection, branch creation and the baselines — the baselines from the original run still hold.
   (If `origin/<integration-branch>` has moved on and the branch is behind, merge it in first — no
   rebase — and recapture the baselines, saying so.)
2. **See what changed** since the halt: `git status --porcelain` plus `git diff <head-at-halt>` (and
   any commits the developer made on the branch).
   - **Nothing changed** → say `Nothing has changed since the stop — the gate would fail the same way.`,
     re-show the Section 2 message, and do not spend any attempt.
   - **A forbidden shortcut** (from the playbook's "Do NOT" column, or anything SH-6 lists: a deleted,
     skipped or `xfail`ed test; a new suppression comment; a changed threshold, allow-list, rubric or
     `architecture.md` Section 10; an edited approved `.feature` scenario or test plan) → stop and show
     each one with its `file:line`:
     ```
     These changes would pass the gate by weakening it, so I can't continue with them:
        • [file:line] — [what was changed]
       Please revert them, fix the underlying problem manually, and type [resume keyword] again.
       If you believe the requirement or threshold itself is wrong, raise it with the story owner —
       that change goes through its own review, never through this gate.
     ```
   - **Otherwise** → continue.
3. **Re-verify from the right place** — the playbook's "Re-run from" column:
   - any change under the code root or `tests/` → re-run from the **first code gate** (unit tests +
     coverage) through **every** later gate, because a manual change can affect any of them;
   - declaration-only changes (manifest fragment, dependency file) → re-run from the halted gate.
4. **Budgets**: the halted loop gets a **fresh 3-attempt budget** (the hand-back is the explicit user
   instruction SH-4 requires); every other loop keeps its counter. 🔴 **Never revert the developer's
   changes** — if the gate still fails and self-heals, it builds on their code.
5. **Record**: replace the `HALTED —` record with
   `RESUMED — <timestamp> — changes: <file list> — re-running from <gate>`, and log the hand-back
   (complete raw input, the change list, the re-run start) in the work unit's audit trail.
6. From there the workflow continues exactly as it would have — review, then commit, push, PR and
   handoff.

---

## 5. Tool installation blocked — the other halt that needs the developer

When a static-check tool cannot be installed after the whole bootstrap chain (already present →
package manager → alternative installer → Podman image, 3 tries each — `common/eval-framework.md`
Section 2.4.1), emit:

```
A CHECK CAN'T RUN — I couldn't install [tool] for [D-gate: what it checks] on [root].

   Tried:   [rung → command → error], for every rung
   Status:  STOPPED before any code was written for this [story | ticket] — nothing changed.

HOW TO FIX IT
   1. Install it yourself:   [the most likely command for this OS / stack]
   2. Check it works:        [tool] --version
   3. Hand it back:          type  [resume keyword]   (I re-check the tool and continue from the baseline)

```

Record `HALTED — tool bootstrap: <tool> — <timestamp>` in `## Progress`; the Section 4 resume applies, with
"re-run from" = the baseline static run.

---

## 6. Rules

- 🔴 The message is written for the developer: plain words, exact commands, real paths, every bracket
  filled. It is always the last thing the halted run outputs.
- 🔴 Every "HOW TO FIX IT YOURSELF" line comes from the playbook row and the run's real evidence — never
  a generic "please investigate".
- 🔴 The forbidden shortcuts are always named, so the developer does not spend time on a change the gate
  will reject.
- 🔴 Resuming never skips a gate, never reverts the developer's work, and never commits before every gate
  passes on the final code.
