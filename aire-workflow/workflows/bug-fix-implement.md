# WORKFLOW: `bug-fix-implement` (Bug/Defect — Code Fix)

**Purpose**: Implement the fix for the defect prepared by `bug-fix`. Normally entered from `bug-fix` Step 9's **Verification Engineer Handoff Break** — the user answers `yes` there and this workflow runs in the same session (the keyword is only typed to resume a session that answered `no` or ended after analysis). Sibling of `dev-implement`, but: it works **directly on the existing bug branch** (no story selection, no doability gate, no story branch), it runs a **baseline regression pass before touching code**, a **full-repo regression gate after the fix**, and its PR targets the **base branch** with the **`[BUG]`** prefix — after which the operator runs the cycle archive manually (Step 12).

## READ FIRST — THE NON-NEGOTIABLES OF EVERY `bug-fix-implement` RUN

Observed in a real run: the story shipped a PR with D3/D5/D6/D7, B1/B2 and J1/J2 never run and the
tracker claim made only locally, "disclosed" as a scope call to keep the session moving, and ended on a
free-form summary. Every one of those is forbidden:

1. **Every gate runs.** No gate is skipped, deferred or "scoped out" to finish sooner. A gate ends only as
   `PASS`, or `N/A` for a reason on the closed list (`common/eval-framework.md` Section 2.5.1). A missing
   tool is installed through the full chain; a gate that truly cannot run is an `ERROR` that HALTS the
   run. "Not run this session", "scope call", "to keep the session moving" and every reason in Section
   2.5.2 are forbidden.
2. **The Gate Ledger is complete before the commit** (`common/work-unit-artifacts.md` Section 6). Any
   gate that is not `PASS` or a legitimate `N/A` means no commit and no PR: HALT with the Self-Heal Limit
   message.
3. **The pre-commit guard is installed and never bypassed.** At the start of the fix, on the bug branch (unit key `bug-<TICKET-ID>`), run
   `sh aire-workflow/templates/hooks/check-work-unit.sh --install <unit-key>`. Right before the commit, run
   `sh aire-workflow/templates/hooks/check-work-unit.sh <unit-key>`; the git hook runs it again on the
   commit. A refusal is fixed by doing the missing work — `git commit --no-verify` is forbidden.
4. **The claim happens on the external tracker too, before any branch or code.** For a non-LOCAL
   Tracker ID: transition to In Development AND assign the operator (`common/tracker-sync.md` Sections 4
   and 5), verify both by re-fetching, and write the results into the fragment's `## Claim` block.
   Updating only the local fragment is a defect, and the work-unit guard refuses a commit without the
   block.
5. **Disclosing a gap does not make it acceptable.** The moment you notice a gate unrun, a transition
   unmade or a file missing is the moment to do the work — or to HALT with the Self-Heal Limit message.
   Never raise a PR with "disclosed gaps", and never ask the user whether to skip.
6. **The run ends with its exact end message.** A successful run's final output is the Step 12 Archive Handoff block,
   verbatim, every placeholder substituted, and nothing else in that message — no free-form summary
   before it, no gap list, no suggestions after it. Progress lines earlier in the run are fine; the last
   message is the block. A halted run ends with the Self-Heal Limit message instead, also verbatim.

---

## MANDATORY: Rule Details Loading

May be invoked standalone in a fresh session. Resolve `aire-workflow/` and load:
- `common/process-overview.md`, `common/session-continuity.md`, `common/content-validation.md`
- `common/branching-strategy.md` — **Bug Branch Model** section
- `common/work-unit-artifacts.md` — the complete evidence set this run must leave behind (paths, the `evidence-manifest.md` format, the N/A-means-no-folder rule, keyed security-review names) and the Artifact Completeness Check before the commit
- `common/self-heal-limit-guidance.md` — the Self-Heal Limit message, the per-gate manual-fix playbook and the hand-back (resume) protocol used when a self-healing loop exhausts its budget or a tool cannot be installed
- `implementation/code-generation.md` (planning/generation/coverage mechanics — story selection and story-branch steps do NOT apply here). 🔴 **Follow the Guardrail defined there (Generation Phase Rules)** for any generated code.
- 🔴 **Do NOT pre-load** `extensions/testing/playwright-automation/playwright-automation.md` or `implementation/test-plan.md` — Step 7.7 reaches them by **invoking the `ve-implement` and `playwright-implement` skills in WORKFLOW MODE**, and each skill loads its own rule files.
  🔴 **BUT: those files carry the anti-shortcut rules, and you will not have read them if you skip the skill — a circular trap that has caused a real violation.** The three non-negotiables, restated HERE where they are always in context:
  1. **The ONLY permitted producer of `tests/e2e/**` and `spec/playwright-specs/**` is the `playwright-implement` skill's own Planner/Generator subagents.** About to `Write`/`Edit` a `.spec.*` file with no `Skill(playwright-implement)` call this run? That is the violation.
  2. **"The Playwright agents aren't installed" means INSTALL them** (`npx playwright init-agents --loop=claude`), then HALT for a session restart — never hand-author.
  3. **Disclosing the shortcut does not make it allowed**, and a prior work unit that did it is a defect to backfill, not precedent.
- `workflows/code-review.md` (auto-run after the fix) and `workflows/remediate.md` (on the Remediate path)
- `common/eval-framework.md` — the Static Eval Gate D1–D7 (baseline at Step 3, gate at Step 7.5) and the J1/J2 judge scores (Step 8a). Evidence key for this flow: `bug-[TICKET-ID]`

🔴 **GUARDRAIL — `code-review` and `remediate` are WORKFLOW RULE FILES, NOT Claude skills.** Whenever this workflow "runs Code Review" or "runs Remediate", you MUST `Read` and follow `workflows/code-review.md` / `workflows/remediate.md` (which pull their detailed steps from `implementation/code-review.md` / `implementation/remediate.md`) as instructions. There is **NO** Claude skill named `code-review` or `remediate` — **NEVER** invoke one via the Skill tool.

🔴 **The converse guardrail — these ARE real Claude skills, INVOKED via the Skill tool, never re-implemented inline**: **`ve-implement`** and **`playwright-implement`** (Step 7.7, both in **WORKFLOW MODE** with the ticket passed in), **`pr-generator`** (Step 9, workflow mode), and **`pr-review`** (Step 11, AUTO MODE).

Skills used **as-is — NEVER edit them**: **`pr-generator`** (pass target branch = the **Base Branch**; PR type `[BUG]`), **`pr-review`** (AUTO MODE after the PR), and **`archive-epic`** in **bug mode** (🔴 **NEVER auto-invoked by this workflow — the operator runs it manually** after all ve work has landed on the bug branch; see Step 12).

## MANDATORY: Audit Entry Format

Every runtime-artifacts/audit.md entry in this workflow carries the `**TRACKER ITEM**:` field (the defect ticket as a tracker hyperlink, or the local ID for LOCAL) — same format as `bug-fix.md` — AND the `**AIRE VERSION**:` field, exactly as `dev-implement` does:

```markdown
**AIRE VERSION**: "[Framework version [N] read from the "AIRE Framework Version" line in CLAUDE.md — do not hardcode]"
```

The version is read **at runtime** from the canonical "AIRE Framework Version" line in `CLAUDE.md` — it records which framework version the bug fix was developed with. Never omit it and never hardcode a literal number. Append-only, ISO 8601 timestamps, complete raw user input.

## 🔴 PARALLEL-SAFE STATE — THIS WORKFLOW WRITES ONLY ITS OWN FRAGMENT (`common/parallel-work-state.md`)

The ve works in parallel on `ve/…` branches whose PRs merge into this same integration branch, and
`pr-fix` may later add commits to this PR. So that none of them conflict on the framework's bookkeeping,
**this workflow never writes the shared `runtime-artifacts/audit.md` or `runtime-artifacts/aire-state.md`**:

- Every audit entry this file tells you to append to `runtime-artifacts/audit.md` goes to
  **`runtime-artifacts/stories/bug-<TICKET-ID>/audit.md`** (same format, plus `**Unit**: "bug-<TICKET-ID>"`).
- Every write to the ticket's Story Tracker row, its progress or its SH counters goes to
  **`runtime-artifacts/stories/bug-<TICKET-ID>/state.md`** (`## Story Tracker Row`, `## Progress`,
  `## Self-Healing Counters`).
- This overrides every mention of those two shared paths below. Reads use the **resolved view**
  (`common/parallel-work-state.md` Section 4); a `PR: pending` is resolved live from the branch.
- 🔴 **State Isolation Check before every commit** (Step 9, and any `fix(ci)` commit): every changed
  path under `runtime-artifacts/` must be inside `runtime-artifacts/stories/bug-<TICKET-ID>/`; anything else is
  moved into the fragment and the shared file restored to the merge-base (Section 5.5).
- Do not push a commit only to record the PR URL — it rides the next commit (Section 4.6).

## THIS WORKFLOW IS FULLY AUTOMATIC — IT HAS NO APPROVAL GATES

**Entering this workflow (the `yes` at `bug-fix` Step 9's ve Handoff Break, or typing
`bug-fix-implement` to resume) is the ONLY user decision.** Everything after it — the fix plan, the
code, the unit-test/coverage gate, the regression gates, the automated Code Review, **the
remediation of any findings it reports**, the commit, the push, the `[BUG]` PR and the PR review —
runs **without a single approval prompt**.

- There is **NO GATE 2** (fix-plan approval). The plan is built, announced and executed.
- There is **NO GATE 3** (review decision). A review with findings is **remediated automatically**,
  then re-reviewed, **looping until the verdict is clean** — never an Approve/Remediate question.
- There is **NO GATE 1** either — that was the epic flow's story-set approval, which no longer
  exists anywhere in the framework.
- 🔴 **Never write the word "GATE" into an audit heading from this workflow.** Plan and review
  outcomes are logged as auto-approved decisions under plain headings.
- The stage approvals inside `bug-fix.md` (requirements, the single story) belong to that file and
  are unchanged.
- **Automatic does not mean unbounded.** Every self-healing loop in this workflow is capped at
  **3 remediation attempts** by the **Self-Healing Retry Policy (SH-1 … SH-7)** below. When a loop
  exhausts its budget the run **HALTS at that gate**, emits the Self-Heal Limit message
  (`common/self-heal-limit-guidance.md`) and waits for the developer's manual fix. A failing gate is never passed, skipped, weakened, or carried forward.

---

## SELF-HEALING RETRY POLICY (SH-1 … SH-7) — BINDING ON EVERY AUTOMATIC LOOP IN THIS WORKFLOW

Any gate in this workflow that detects a failure and fixes it without user input is a **self-healing
loop**. Every such loop is bounded by the rules below. **These rules override any wording elsewhere in
this file that describes a loop as uncapped, unbounded, or repeating "until clean" with no limit.**

**Governed loops — each has its own independent attempt counter:**

| ID | Loop | Defined in | Verification that must pass to exit the loop |
|---|---|---|---|
| **SH-LOOP-1** | Unit Test & Coverage | Step 6 | All unit tests green **and** coverage on new/changed code ≥ 90% |
| **SH-LOOP-7** | Behavioural B1 + B2 (Gherkin) | Step 6.2 | The fix's scenarios pass with every AC tag executed, AND the entire existing behaviour suite stays green |
| **SH-LOOP-8** | Behavioural B3 (epic scope) | Step 6.2 | The full suite + the ticket's end-to-end journey pass |
| **SH-LOOP-2** | API & Contract Testing | Step 6.5 | Every applicable checklist item passes on every touched endpoint |
| **SH-LOOP-3** | Full Regression | Step 7 | Zero NEW failures versus the Step 3 baseline |
| **SH-LOOP-4** | Static Eval D1–D7 | Step 7.5 | Zero NEW findings above the `tests/.evals/config.json` thresholds on changed files |
| **SH-LOOP-11** | Playwright UI Automation | Step 7.7 | Every generated Playwright spec passes (zero `test.fixme()` outcomes), when the fix touches UI |
| **SH-LOOP-13** | Playwright E2E Regression | Step 7.8 | Zero NEW failing Playwright specs versus the Step 3 Item 6 baseline — runs for EVERY fix, UI or not |
| **SH-LOOP-6** | Judge Gates J1 + J2 | Step 8a Item 2.5 | `J1 ≥ llmJudgeArchitectureScoreMin` **and** `J2 ≥ llmJudgeSecurityScoreMin` (`N/A` passes) |
| **SH-LOOP-5** | Auto-Remediate (code review + security findings) | Step 8c | Review verdict clean — zero 🔴 and zero 🟠 |
| **SH-LOOP-9** | CI Preflight (provisioning + manifest executability) — **N/A when `## CI/CD Configuration` `Enabled: No`** | Step 9 Item 1.5 | Every CI entrypoint runs in a clean room with zero missing tools, zero undeclared dependencies, zero Manifest defects, and no gate `N/A`/qualified pass on a root this fix touched |
| **SH-LOOP-10** | CI Attestation (post-PR provisioning agreement) — **N/A when `## CI/CD Configuration` `Enabled: No`** | Step 10.5 | CI's `gates` block agrees with this fix's own local gate results on every root the diff touched — no gate the diff touched is absent, `N/A`, or provisioning-errored in CI when it passed locally |
| **SH-LOOP-16** | Artifact Completeness | Step 8.4 | Every evidence file `common/work-unit-artifacts.md` Section 1 requires for this unit exists, has its set format, agrees with `eval.json` / `eval-summary.md`, and no folder exists for an `N/A` gate |

**SH-1 — Attempt budget.** Each loop is allowed a **maximum of 3 remediation attempts**. One attempt
is one complete `fix → re-verify` cycle. The initial verification run that first detects the failure
is **not** an attempt (it is attempt 0). Attempts are numbered 1, 2, 3.

**SH-2 — Counters are per-loop, independent, and never silently reset.** Maintain a separate counter
per SH-LOOP ID. A counter is never shared between loops, never reset by another loop's success, and
never reset by advancing to a later gate. When a later loop's remediation forces re-entry into an
earlier loop (for example Step 8c re-running the Step 7 regression comparison), that re-entry **continues the earlier loop's existing
counter** — it does not grant a fresh budget of 3. The only reset is the one the user grants
explicitly under SH-4 step 5.

**SH-3 — Every attempt is recorded.** Before an attempt, log to `runtime-artifacts/audit.md` and to that loop's evidence
manifest: the loop ID, the attempt number (`n of 3`), the exact failures being addressed, the
identified root cause, and the planned fix. After the attempt, log the files changed, the exact
verification command re-run, and its result. An unrecorded attempt is a process violation.

**SH-4 — Exhaustion halts the workflow.** When attempt 3 completes and the loop's verification still
fails, the loop is **exhausted**. Immediately:
1. Stop the loop. Do **not** begin a 4th attempt.
2. Stop the workflow at this gate. Do **not** advance to the next gate, do **not** commit, do **not**
   push, do **not** raise or update a PR, and do **not** change the local Story Tracker or the
   external tracker. The ticket stays `In Development` on its bug branch. The attempted fixes stay in the working tree for inspection.
3. Record the halt in the work unit's `## Progress` (`HALTED — …`, `common/self-heal-limit-guidance.md`
   Section 1) and emit the **Self-Heal Limit message** (the Retry-Limit Report —
   `common/self-heal-limit-guidance.md` Section 2, with the "HOW TO FIX IT YOURSELF" steps taken from the
   Section 3 playbook row for this loop) as the run's final output.
4. Append the same content to `runtime-artifacts/audit.md` under the heading
   `## Self-Healing Retry Limit Reached — [SH-LOOP-ID] (Bug [TICKET-ID])`, carrying the standard
   `**TRACKER ITEM**:` and `**Epic Link**:` fields.
5. **HALT and wait for the developer's manual fix.** Do not resume, re-attempt, reroute, or skip the gate on your own
   initiative. The developer fixes the problem manually and types `bug-fix-implement` again; that hand-back
   is the only way the run resumes, and it grants a fresh 3-attempt budget for the halted loop only, via
   the resume protocol in
   `common/self-heal-limit-guidance.md` Section 4 — which checks the manual change, rejects
   forbidden shortcuts, never reverts the developer's code, and re-runs every gate from the right place.

**SH-5 — A stall ends the budget early.** If an attempt produces **no code change at all** AND
re-verification returns output **identical** to the previous verification, the loop cannot make
progress. Treat it as exhausted under SH-4 immediately, regardless of attempts remaining, and state in
the report that the budget ended early on a stall rather than on attempt 3.

**SH-6 — Forbidden shortcuts, on every attempt.** No attempt may produce a pass by weakening the
check. Explicitly forbidden: deleting, skipping, `xfail`-ing or weakening a failing test; suppressing a
finding (`eslint-disable`, `# nosec`, `# type: ignore`, ignore-list entries); lowering a threshold or
widening an allow-list in `tests/.evals/config.json`; deleting a finding from a review report; narrowing a
gate's declared scope. Reaching SH-4 honestly is the required outcome; passing the gate dishonestly is
not an outcome at all.

**SH-7 — Diagnose before spending an attempt.** An attempt that repeats a previous attempt's change,
or applies a speculative fix with no stated root cause, wastes budget. State the root cause in the
attempt log before making the change. If the root cause cannot be established from the available
evidence, stop and report under SH-4 rather than spending an attempt on a guess.

### Self-Heal Limit message (Retry-Limit Report) — `common/self-heal-limit-guidance.md`

At SH-4 emit the message in **`common/self-heal-limit-guidance.md` Section 2 verbatim**, every bracket
substituted from this run's evidence, with:
- **Work unit** = this ticket, **Branch** = the branch it stays on (on its bug branch);
- **HOW TO FIX IT YOURSELF** steps 1, 2, 4, 5 and **Please do NOT** taken from the Section 3 playbook row
  for the exhausted SH-LOOP, with real commands resolved from `tests/.evals/config.json` and real
  evidence paths;
- **resume keyword** = `bug-fix-implement`.

It tells the developer exactly what is failing, why the framework stopped, what the three attempts
changed (left in the working tree), how to reproduce and fix it themselves, what the gates will reject,
and how to hand the work back. It asks the developer to fix it manually and offers no options. The
hand-back grants a fresh budget for the halted loop only; every other loop keeps the counter it already
held.

---

## Step 0 — 🔴 Execution-Context Check (MANDATORY, before anything else)

Step 7.7's Playwright gate invokes Playwright's own Planner/Generator/Healer via the **Agent tool**. **A fork, or any subagent instructed "do NOT spawn subagents / you ARE the fork, execute directly", cannot call it** — the gate is then structurally impossible regardless of what is installed. Determine whether this run can call the Agent tool: if it **cannot**, announce it now (` This run cannot call the Agent tool — a UI fix will HALT at Step 7.7; run it from a normal session instead.`), log it in `runtime-artifacts/audit.md`, and continue. 🔴 **It is NEVER a reason to hand-author Playwright specs** (`implementation/code-generation.md` Step 11d Part B catch-all) — a UI fix halts and is re-run from a context that can invoke subagents.

## Step 1 — Preconditions

1. Read `runtime-artifacts/aire-state.md`. Require `## Tracker` with `Workflow Type: bug` + `Parent Ticket`, and `## Branching` with `Bug Branch`. If missing, STOP: tell the user to run `ticket-implement <TICKET-ID>` first — this workflow only implements a prepared fix.
2. Verify the state records `Design complete — awaiting bug-fix-implement` (or later). If Planning is incomplete, STOP and say which stage is pending.
3. **Switch to the bug branch**: `git fetch origin`, checkout the recorded Bug Branch, `git pull --ff-only` if it has an upstream. Confirm with `git branch --show-current`. 🔴 All work happens on this ONE branch — never cut another branch.
4. Read `spec/plans/impact-analysis.md` and `spec/plans/bug-brief.md` — they drive the plan.
5. **▶ Resume after a pause or halt**: a `PAUSED —` record (Playwright agent install restart — Step 4.4 readiness or the Step 7.7 safety net) → continue at the step it names, skipping everything already done. If `runtime-artifacts/stories/bug-<TICKET-ID>/state.md` `## Progress` holds a `HALTED —` record (a self-healing limit or a tool-installation halt from an earlier run), this invocation is the developer **handing the work back** — follow `common/self-heal-limit-guidance.md` Section 4 (check the manual change, reject forbidden shortcuts, keep the developer's code, fresh budget for the halted loop only), skip Steps 2–4 (the ticket is already claimed, the baselines and the fix plan already exist), and re-run from the first code gate (Step 6) — or from the halted gate for declaration-only changes — through Step 12.

## Step 2 — Ticket → In Development (automatic)

Running `bug-fix-implement` IS the claim. Without asking, dispatch on `## Tracker` → `Type` per `common/tracker-sync.md` Section 4/Section 5/Section 9:
1. Story Tracker (single row): Status → `In Development`, Start + Recorded timestamps set.
2. Transition the ticket to the tracker's "In Development" state/label (non-LOCAL): **JIRA** — resolve the actual transition via `getTransitionsForJiraIssue` → `transitionJiraIssue` (Bug and Story issue types can have different workflows; never hardcode the state name); **ADO** — `az boards work-item update --state "Active"`; **GITHUB** — swap the status label to `status:in-development`. **Verify it landed**, announce it, log in runtime-artifacts/audit.md. **LOCAL**: no external call — this step is a no-op beyond the Story Tracker update above.
2.2. **Assign the ticket to the operator (automatic — same claim)** — then write the fragment's `## Claim` block (`common/parallel-work-state.md` Section 3.2) from the verified transition and assignment results; the guard refuses the commit without it: the developer who typed `bug-fix-implement` claims the fix, so set them as the assignee without asking, per `common/tracker-sync.md` Section 5 — read the session **email** LIVE from the session context (the same one stamped as `**User Email**:` in runtime-artifacts/audit.md), then **JIRA**: resolve via `lookupJiraAccountId` + `editJiraIssue`; **ADO**: `az boards work-item update --assigned-to "<session-email>"` directly; **GITHUB**: a cached GitHub username (ask once per session if not yet recorded) + `gh issue edit --add-assignee`; **LOCAL**: no assignee concept, skip. **Verify** (non-LOCAL) by fetching the issue back. If the identity resolves to no (or ambiguous) account, leave the assignee unchanged, warn the user, and continue — assignment failure is NON-blocking. Announce and log in runtime-artifacts/audit.md.
2.5. **Add the AIRE version label to the ticket** (mirrors dev-implement's version stamping — the defect ticket was raised by ve, not by the framework, so it doesn't carry the label yet), dispatching on `## Tracker` → `Type` per `common/tracker-sync.md` Section 9: **JIRA** — label `aire-v[N]` via the Atlassian MCP; **ADO** — add `aire-v[N]` to `System.Tags`; **GITHUB** — `gh issue edit --add-label aire-v[N]`; **LOCAL** — note the version directly on the local bug entry, no external call. `[N]` is the FULL framework version (including the minor, e.g. `1.0` → `aire-v1.0` — never the major only, never `aire-v1`), read **at runtime** from the "AIRE Framework Version" line in `CLAUDE.md` (never hardcoded). If the label is already present, skip. Verify (non-LOCAL), announce, log in runtime-artifacts/audit.md.
3. 🔴 Skip all Parent-Epic sync steps — `## Tracker` records `Parent Epic: none` in the bug flow.

## Step 3 — 🧪 BASELINE Regression Run (BEFORE any change)

**Purpose**: know what was already broken so post-fix failures are attributed correctly — a fix must never be blamed for (or silently hide) pre-existing failures.

1. Discover and run the **entire repo's unit test suite** (all modules) with no code changes made yet.
2. Save the raw runner output to `reports/unit-test-evidence/bug-<TICKET-ID>/baseline-regression.log` (`common/work-unit-artifacts.md` E1), and record the baseline in `reports/ticket-summary/bug-<TICKET-ID>-summary.md`:
   ```markdown
   ## Baseline Regression (pre-fix)
   - Command(s): [exact commands]
   - Result: [X passed / Y failed / Z skipped]
   - Pre-existing failures: [list each failing test, or "none"]
   ```
3. Pre-existing failures are **logged, not fixed** — they are out of scope UNLESS a failing test is itself the defect under fix (note it if so). Log the baseline in runtime-artifacts/audit.md.
4. If the repo has no test suite at all, record that explicitly — the post-fix regression gate then covers only the new tests.
5. ** BASELINE STATIC EVAL RUN (MANDATORY, AUTOMATIC — same moment, before any change)**: run the **Static Eval Gate checks D1–D7** per `common/eval-framework.md` Section 2 (lint, type check, SAST, dependency vulnerabilities, licences, complexity, secrets) and save the raw output to `reports/eval-evidence/bug-<TICKET-ID>/static/baseline/`. Exactly like the regression baseline: **every finding is pre-existing debt, not this fix's** — logged, not fixed, never blocking. It exists only so Step 7.5 can tell this fix's findings apart. Log the baseline in runtime-artifacts/audit.md.
   - ** BOOTSTRAP FIRST (eval-framework.md Section 2.3, MANDATORY — same step, immediately BEFORE the baseline run)**: for every check with **no config in the repo**, create the minimal *recommended* config (eslint/ruff/golangci, tsconfig/mypy, `.gitleaks.toml`, the linter's complexity rule at the `tests/.evals/config.json` threshold) so the check is actually runnable. **A check whose config exists is used AS-IS** — the repo's own standards win, never overridden. Announce every file created and log it (`bootstrap` block of `eval.json`) — it adds files to the user's repo, so it is never silent; those files commit with the fix. 🔴 **AND INSTALL THE TOOLS — retried, never skipped (Section 2.4.1)**: for every gate, work the chain *already present → package manager → alternative installer → **OCI image via Podman***, 3 attempts per rung, verifying each install with a version command. Recording a gate `N/A` for a missing tool **before the Podman rung has been tried** is a bootstrap failure, not an `N/A`. If the whole chain is exhausted, **HALT with the per-rung report** — never continue with an unmeasured gate, and never phrase deferred setup as `N/A` ("not wired yet", "not installed", "not enabled yet" — all ERROR, Section 2.5.2).

🔴 **A MISSING TOOL IS NEVER A QUESTION.** Observed in a real run: the workflow reached D1/D5/D6 with no linter, licence scanner or complexity tool configured for the stack, and **asked the user** *"How should I handle the remaining static-eval gaps?"* with a recommended option. That is a double violation — this workflow asks nothing after the story key, and a tooling gap already has a defined answer: **run the Section 2.4.1 bootstrap chain** (already present -> package manager -> alternative installer -> **OCI image via Podman**), 3 attempts per rung. If the whole chain is exhausted, **HALT with the per-rung report** — which is a halt, not a question, and never a proposal to skip the gate. Emit it as the **"A check can't run" message in `common/self-heal-limit-guidance.md` Section 5** (what was tried per rung, the install command to run by hand, how to hand the work back) and record the halt in `## Progress` so the resume protocol picks it up. 🔴 Never ask the user to choose between closing a gate and deferring it; deferring is not on the menu (Section 2.5.2).
     - 🔴 **ORDER MATTERS**: bootstrap → baseline → fix → Step 7.5 → diff. A config created AFTER the baseline would make both runs measure under **different rules**, blaming this fix for findings on pre-existing code.
     - 🔴 Recommended presets, never strict/all, and **never a config that pre-suppresses findings**.
   - 🔴 A check is recorded `N/A` **only after the full Section 2.4.1 install chain — including the Podman image rung — has been attempted and recorded**, and only for a reason on the Section 2.5.1 closed list (inapplicable to this stack / to this work unit / no such tool exists). If the chain is exhausted, that is an **ERROR: HALT** with the per-rung report — never `N/A`, never silently skipped, and never phrased as deferred work ("not wired yet", "not installed", "not enabled yet").
6. **🧪 BASELINE PLAYWRIGHT E2E REGRESSION RUN (MANDATORY, AUTOMATIC — same moment, before any change)**: run the **ENTIRE existing `tests/e2e/` Playwright suite** with no code changes made yet, and save the raw output to `reports/playwright-test-evidence/bug-<TICKET-ID>/regression/playwright-baseline-regression.log` plus the **mandatory machine-readable** `playwright-baseline-report.json`. **No user prompt — capture it and continue.**
   - **Why**: this is the UI counterpart of the unit baseline above. Step 7.7 only proves **this fix's own** new specs pass; nothing else proves the fix did not break a browser flow an earlier work unit already shipped. Without a pre-change photograph there is no way to tell "this fix broke it" from "it was already red".
   - 🔴 **Applies to EVERY fix, UI or not — do NOT skip it because the fix touches no UI.** A backend handler, a changed response shape, a renamed field or a migration is exactly what silently breaks an existing browser flow, and that is the case this baseline exists to attribute correctly.
   - **Start the app the same way Step 7.7 does** — the `startCommand`/`readinessUrl` in `tests/.evals/config.json` `ci.playwright` (plus the backend pair when two processes are needed), resolved from the project's own scripts, **never invented**; tear it down on every exit path.
   - **Run headless** — a deliberate carve-out from Step 7.7's `--headed` rule, which exists so the developer can watch newly authored specs. This is a bulk sweep of already-approved specs; record `"headed": false, "reason": "bulk regression sweep, not the authoring gate"`.
   - **Failures here are pre-existing** — logged, never fixed, never blocking. They define "already red" so Step 7.8 can attribute correctly.
   - **`N/A` only when there is nothing to regress**: `tests/e2e/` holds no specs at all (no earlier work unit generated any). Record the reason — 🔴 never a silent skip, and never `N/A` merely because *this* fix has no UI.
   - **Specs exist but Playwright is not installed on this machine** (a fresh clone, a new developer): install it now — the project's dependencies (`npm ci` or equivalent, which brings `@playwright/test` when it is a dev dependency) and the browsers (`npx playwright install`) — announced, never asked, then run the sweep. 🔴 A missing runner or browser is never a reason for `N/A`; only an empty `tests/e2e/` is. The official test agents are not needed for this sweep.

## Step 4 — Fix Plan ( announced, not gated)

1. Build the fix plan from `spec/plans/impact-analysis.md` + the design artifacts, using `code-generation.md`'s Part 1 planning format (checkboxed steps), ending with the mandatory Unit Test & Coverage step, the API & Contract Testing Gate (Step 6.5, when the fix touches an API endpoint), and the Full Regression Gate (Step 7). ** TRACE THREAD (bug variant, `common/requirements-traceability.md` Rule 7)**: tag every plan step with the `spec/plans/bug-brief.md` expected-behavior statement(s) and `spec/plans/impact-analysis.md` entry it addresses, and self-check that every expected-behavior statement and every impact-analysis touch point appears in ≥1 step before presenting the plan.
2. **Re-validate the impact analysis against current code.** If the plan must touch files NOT in the impact analysis: add them to `spec/plans/impact-analysis.md` and **re-run the Defect Provenance Analyst (`agents/defect-provenance-analyst.md`, per bug-fix Step 5b) on the newly implicated defective lines** — same line-level procedure (trace each defective line to its introducing commit); if any is AI-generated and the ticket isn't labeled yet, apply the `ai-generated-defect` label automatically, exactly as bug-fix Step 5b does (positive evidence only, verified, announced, logged). Also run **bug-fix Step 5c** on any newly resolved originating ticket keys — create the "is caused by" link automatically (no confirmation), skipping keys already linked, verified and logged.
3. ** Announce the plan and proceed — NO approval gate**:
   1. **Log the finalized plan** in `runtime-artifacts/audit.md` (ISO 8601 timestamp) under a **plain heading** — e.g. `## Fix Plan — Finalized (auto-approved, no gate) (Bug [JIRA-ID])` — with the plan path, the step count and the trace summary. **The word "GATE" must NOT appear in the heading.**
   2. Present the plan as an **announcement** (NOT a question):
      ```
       Fix plan ready for Bug [JIRA-ID] — [N] steps.
      Plan: spec/spec-generation/Bug-generation.md
      Generating the fix now (Step 5).
      ```
   3. **Do NOT wait for a response** — go straight to Step 5. If the user volunteers a change to the plan, apply it, update the plan document, announce the revision, log it, and continue (an interrupt, not a gate).

## Step 4.4 — 🎭 Playwright Readiness (MANDATORY WHEN the fix plan is frontend — automatic, before any code)

**Applies only when this fix's code-generation plan (Step 4) contains a _Frontend Components Generation_
step** — the plan is the single place that decides whether a work unit is frontend. No such step →
record `Playwright readiness: N/A — no Frontend Components Generation step in the plan` and continue.
Otherwise, before any code is written, make Playwright fully ready — **automatically, announced, never
asked**:

1. **Runner**: `@playwright/test` is in the project's dev dependencies — if not, add it with the project's
   own package manager (`npm i -D @playwright/test`, `pnpm add -D @playwright/test`, `yarn add -D
   @playwright/test`); a `playwright.config.*` exists at the workspace root — if not, create it per
   `extensions/testing/playwright-automation/playwright-automation.md` Step 0a (root = workspace root,
   `testDir: tests/e2e`).
2. **Browsers**: `npx playwright install` (add `--with-deps` on Linux) when the browsers are not already
   present on this machine.
3. **Playwright's official test agents**: `.claude/agents/playwright-test-planner.md`,
   `playwright-test-generator.md`, `playwright-test-healer.md` and the `playwright-test` entry in
   `.mcp.json`. Missing → back up `.mcp.json`, run `npx playwright init-agents --loop=claude`, then merge
   the other MCP servers back (`init-agents` overwrites the file — playwright-automation.md Step 0a).
4. **Verify**: `npx playwright --version` succeeds, the three agent files exist, the `.mcp.json` entry
   exists. Record what was installed in the audit trail and in the plan's Playwright step.
5. **Session restart — only if step 3 ran.** Claude Code loads MCP servers when a session starts, so newly
   installed agents cannot be used until the session restarts. Record
   `PAUSED — Playwright agents installed — resume at Step 4.5 — <timestamp>` in the work unit's
   `## Progress` and emit, as the run's last output:
   ```
   Playwright is now set up for this frontend fix.
      Installed:  <what was installed>
      One step is needed: restart Claude Code so it loads Playwright's test agents, then type bug-fix-implement.
      I will continue from Step 4.5. The plan and the baselines are kept, and no code has been
      written yet.
   ```
   Typing `bug-fix-implement` in the new session finds the `PAUSED —` record and continues at Step 4.5, skipping
   everything already done. Everything already installed → no pause.
6. **Install fails** after the full install chain → emit the "A check can't run" message
   (`common/self-heal-limit-guidance.md` Section 5) for Playwright, record `HALTED —`, nothing changed.

Because this runs here, the Playwright UI gate (Step 7.7) finds Playwright ready; its own install
handling remains only as a safety net.

## Step 4.5 —  Verify the Behaviour Spec (MANDATORY — before any code)

`spec/behavior/bug-<TICKET-ID>.feature` was **already written and approved** at `bug-fix.md` Step 8.5 Item 4.5 (`implementation/specs-and-test-plans.md`) and is already committed on the bug branch. This step **READS** it — it does not author it. Confirm the file exists, parses, and carries one `@AC-n`-tagged scenario per acceptance criterion **plus the scenario that reproduces the defect**.

**Backfill only if genuinely absent** (legacy project, or a ticket that skipped the checkpoint): write it now per `common/behavior-spec.md` Section 2 and **announce the backfill explicitly** (`Behaviour spec for <TICKET-ID> was missing from the approved set — generated now at spec/behavior/bug-<TICKET-ID>.feature`).

🔴 **NEVER rewrite an approved scenario to match the fix you are about to generate** — the spec is the contract, and code that cannot satisfy it is the thing that changes. A genuine spec defect is raised with the user, amended and logged; it is never silently edited.

🔴 **That is still the ONLY spec file this work unit gets.** No per-unit requirements, architecture, constraints or deep-dive document. The agent reads the tracker item for acceptance criteria, `requirements.md` for the covered REQ-IDs, `spec/plans/architecture.md` for design constraints, and `tests/.evals/config.json` for thresholds — copying any of that per unit only creates something that can drift.

Announce the file path and the scenario/AC counts. Log the verification (or backfill) in runtime-artifacts/audit.md.

## Step 5 — Generate the Fix

Execute the announced plan step by step on the bug branch, marking each checkbox `[x]` in the same interaction it completes. ** All application code goes into `src/`** (or the recorded `## Code Root` — `common/directory-structure.md`) and nothing into `spec/`. 🔴 **TESTS GO IN THE REPO-ROOT `tests/` TREE — NEVER UNDER `src/` AND NEVER UNDER THE CODE ROOT**: unit tests -> **`tests/unit/`**, Gherkin step definitions -> **`tests/behavior/steps/`** (the tree `tests/.evals/behavior/run.sh` executes inside Podman), Playwright -> `tests/e2e/`. The `## Code Root` remapping above applies to **application code ONLY** — a brownfield repo whose code lives in `app/` or `packages/api/src` still writes its tests to the repo-root `tests/`, never `app/tests/` or `packages/api/src/tests/`. This is also what the manifest's `testPaths` records (`common/eval-framework.md` Section 1.1) and what the Podman mount and the coverage gate look at, so a test written anywhere else is invisible to both gates. ** PLAN FIDELITY**: implement EXACTLY the announced plan — no unplanned files, features, refactors, or scope drift; keep the fix consistent with the impact analysis and design docs the plan was grounded in. If mid-coding you discover the plan must change, **revise the plan document, announce the revision (what changed and why) in your output and in runtime-artifacts/audit.md, and continue** — never apply a deviation silently, and never ask for approval. Write code to the workspace root per the existing project structure. Log progress in runtime-artifacts/audit.md.

## Step 6 — Unit Tests + Coverage Gate (threshold from `tests/.evals/config.json`)

1. Write unit test(s) that **reproduce the defect** — they must exercise the exact failure scenario from the bug-brief (ideally shown to fail against the pre-fix logic) — plus tests covering all new/changed code.
2. RUN them; fix failures; measure coverage on the new/changed code; iterate in the SAME run until **≥90%**.  **This is SH-LOOP-1 — capped at 3 remediation attempts (SH-1). On exhaustion apply SH-4: HALT, emit the Retry-Limit Report, and do NOT proceed below the threshold.**
3. Capture the evidence in `reports/unit-test-evidence/bug-<TICKET-ID>/` exactly as `common/work-unit-artifacts.md` E1 defines — `unit-test-run.log`, `coverage/` (the tool's machine-readable report plus `changed-lines-coverage.json`) and `evidence-manifest.md` — and record tests X/X passing + the measured changed-lines coverage in `bug-<TICKET-ID>-summary.md` and the audit trail.

## Step 6.2 —  Behavioural Test Gate (Gherkin — three tiers)

Execute the tiered behavioural gate defined in `common/behavior-spec.md` Section 4.4. Implement the step definitions in `tests/behavior/steps/`, bound to the application's **public surface** (endpoint / service method / CLI) — never to internals — then run the tiers **in order**:

1. **B1 — Unit scope**: this work unit's own `spec/behavior/bug-<TICKET-ID>.feature`. **Verification**: every scenario passes AND every `@AC-n` tag is executed.
2. **B2 — Cumulative scope**: every **other** feature file already in the repo — earlier work units in this cycle plus everything from prior cycles. **Verification**: all green. 🔴 A B2 failure is THIS unit's problem — it turned that scenario red, so it fixes it. "That scenario belongs to another story" is not a defence.
3. **B3 — Epic scope** (🔴 **last work unit of the cycle ONLY**): B1 ∪ B2 **plus** the cross-unit journeys in `spec/behavior.feature`, tagged `@REQ-<id>`. 🔴 Detect "last" from **PR MERGE STATE, never the tracker status label** (`common/behavior-spec.md` Section 6.1): for every OTHER work unit read its PR from the Story Tracker and verify live with `gh pr view <n> --json state`. **All others merged → this is the last unit → RUN B3** — including the normal case where those units are still `In Development` awaiting Verification Engineer sign-off, because the label lags the merge. Defer ONLY when a unit has no merged PR, recording `B3: N/A — not the last work unit: <n> units with unmerged PRs (<list with PR state>)`. 🔴 Never defer on a status label alone, and never report a deferred B3 as a pass.

**Execution** — 🔴 **every tier runs in a Podman pod** (`common/behavior-spec.md` Section 5): the image built from `tests/.evals/behavior/Containerfile`, plus a fresh ephemeral **test database** where the repo needs one, invoked through `tests/.evals/behavior/run.sh <tier>` with **`AIRE_STORY_KEY` exported to THIS work unit's key** (e.g. `story-1.10`, the stem of its own `spec/behavior/<key>.feature`) — `podman run -e AIRE_STORY_KEY=<key> …`. 🔴 Without it B1 cannot identify which unit is under test and refuses to guess; it used to take the lexicographically last feature file, which returns `story-1.9` when `story-1.10` is the unit being built — passing B1 without ever testing it — the same image and command a developer runs locally, so a CI-only failure is impossible by construction. 🔴 **The ONLY permitted native run is Podman not being installed** (proven by `command -v podman`), recorded as `"containerised": false, "reason": "podman not installed"`. 🔴 "No browser needed", "backend only", "no new dependency" and "faster natively" are **forbidden justifications** — a tier recorded that way is a gate violation, not a pass. Never fall back to the Docker CLI. A tier runs only once the previous is green.

**Evidence** — per tier that runs, to `reports/behavior-test-evidence/bug-<TICKET-ID>/<b1|b2|b3>/` (🔴 `b3/` is created **only on the last work unit, when B3 actually runs**; a deferred B3 creates no folder — its `N/A` and reason live only in `eval.json` / `eval-summary.md`, `common/work-unit-artifacts.md` Section 1.1): `behavior-test-run.log`, the **mandatory machine-readable** `behavior-test-report.*`, and an `evidence-manifest.md` recording the image ref + digest, the exact command, whether it ran containerised, the tier's feature-file set, and every scenario with its tag and result. A raw log alone does NOT satisfy the gate.

**Self-healing** —  **B1/B2 failures → SH-LOOP-7; B3 failures → SH-LOOP-8, its own separate 3-attempt budget** (an epic-scope failure is usually an integration gap between units, not a bug inside one, so arriving at the epic gate with the story budget already spent must not halt the cycle). Both capped at 3 attempts; on exhaustion apply SH-4 — HALT and emit the Retry-Limit Report.

🔴 **Fix the code, never the scenario.** A scenario changes only when the AC or requirement it encodes genuinely changed — and then the AC, `requirements.md` and the tracker item are amended together and the reconciliation is logged. Deleting, skipping or `@ignore`-ing a scenario to go green is forbidden (SH-6).

**N/A** — B1 is N/A only for a work unit with no externally observable behaviour (pure build-config or docs change); a unit with acceptance criteria is never N/A. B2 is N/A only when the repo genuinely contains no other feature file. Record the reason explicitly.

## Step 6.5 —  API & Contract Testing Gate (MANDATORY WHEN APPLICABLE)

**Applicability (automatic, no question asked)**: applies when the fix plan (Step 4) touches an API endpoint/route/controller/handler — i.e. the defect is in, or the fix changes, API-visible behavior. **If the fix plan touches no API layer, this gate is N/A** — record that explicitly in `bug-<TICKET-ID>-summary.md` and proceed to Step 7.

1. Generate automated tests against the actual affected endpoint(s) — via the stack's standard integration-test mechanism (in-process test client or a spun-up test server) — that reproduce the defect at the API level where applicable, plus the full checklist for every endpoint the fix touches:
   - **Functional / happy path** — the documented correct behavior once fixed
   - **Response Code Validation** — correct HTTP status code for every documented success and failure path
   - **Authorization Testing (role-based access)** — unauthenticated → `401`; authenticated with insufficient role → `403`; correct role → success (N/A only for a genuinely public endpoint)
   - **Error Response Validation** — standard error envelope/format and correct error code for each documented error condition
   - **Request Validation** — required fields, data types, and enum constraints on the request payload are enforced (N/A only for an endpoint with no request body)
   - **Response Contract Validation** — the response payload matches its declared schema/contract (required fields, types, enum values)
2. RUN them; fix failures; iterate in the SAME run until every applicable checklist item passes.  **This is SH-LOOP-2 — capped at 3 remediation attempts (SH-1). On exhaustion apply SH-4: HALT and emit the Retry-Limit Report.**
3. Capture evidence to `reports/api-contract-test-evidence/bug-<TICKET-ID>/` (`api-contract-test-run.log`, the **mandatory machine-readable** `api-contract-test-report.*` — invoke the runner with its report-emitting flag/plugin, e.g. `pytest --junitxml=...` / `jest --json --outputFile=...`; a raw log alone does NOT satisfy the gate unless the runner genuinely has no such capability (documented, surfaced exception) — and `evidence-manifest.md` with the per-endpoint checklist) and reference it in `bug-<TICKET-ID>-summary.md` + runtime-artifacts/audit.md. This gate is separate from and does not replace ve's `/ve-implement` MANUAL API/Contract test steps.

## Step 7 — 🧪 FULL Regression Gate (after the fix)

1. Re-run the **entire repo's unit test suite** (all existing tests + the new bug tests, including any new API & Contract tests from Step 6.5).
2. **Compare against the Step 3 baseline**:
   - **New failures** (passing at baseline, failing now) → caused by the fix. 🔴 BLOCKING: fix them and re-run until zero new failures.  **This is SH-LOOP-3 — capped at 3 remediation attempts (SH-1). On exhaustion apply SH-4: HALT and emit the Retry-Limit Report.**
   - **Pre-existing failures** (already failing at baseline) → not blocking; list them as pre-existing.
3. Save the raw output to `reports/unit-test-evidence/bug-<TICKET-ID>/full-regression.log` and add the baseline vs post-change counts to that folder's `evidence-manifest.md` (E1); append the complete outcome to `bug-<TICKET-ID>-summary.md`:
   ```markdown
   ## Full Regression (post-fix)
   - Command(s): [exact commands]
   - Result: [X passed / Y failed / Z skipped]
   - New failures caused by the fix: [none — required to proceed]
   - Pre-existing failures (unchanged from baseline): [list or "none"]
   - New bug tests: [N] — all passing | Coverage on changed code: [NN]%
   ```
4. Log the full comparison in runtime-artifacts/audit.md. Do NOT proceed with new failures outstanding.

## Step 7.5 —  STATIC EVAL GATE — D1–D7 (MANDATORY, AUTOMATIC — after Step 7, before Code Review)

Re-run D1–D7 per `common/eval-framework.md` Section 2, save to `reports/eval-evidence/bug-<TICKET-ID>/static/`, and **diff against the Step 3 Item 5 baseline**. Only findings **NEW versus the baseline, on files this fix changed**, count. **No user prompt — fix and continue.**

1. **NEW findings above the `tests/.evals/config.json` thresholds** → caused by this fix, so **this fix resolves them in THIS SAME run**, then re-run and re-diff until the diff is clean. 🔴 BLOCKING.  **This is SH-LOOP-4 — capped at 3 remediation attempts (SH-1). On exhaustion apply SH-4: HALT and emit the Retry-Limit Report.**
2. 🔴 **NEVER suppress a finding to pass the gate** — no blanket `eslint-disable`, no `# nosec`, no `# type: ignore`, no ignore-list entry, no widening `disallowedLicenses`. That is the exact analogue of deleting a failing test to go green and is equally forbidden. **Fix the code.**
3. **Findings already present at baseline** → pre-existing, listed not blocking.
4. Write `eval.json` + `eval-summary.md` (eval-framework.md Section 6) and append the gate outcome to `bug-<TICKET-ID>-summary.md`. Log in runtime-artifacts/audit.md. Do NOT proceed with new findings outstanding.

## Step 7.7 —  Test Plans (ALWAYS) + Playwright UI Automation Gate (UI fixes only)

**Applicability (automatic, no question asked) — the two halves differ**: 🔴 **part 1 (the ticket's manual test plans) ALWAYS runs**, so the ve can simply execute the plan once the `[BUG]` PR merges instead of generating it first. **Part 2 (Playwright)** applies only when the fix plan (Step 4) touches UI (a Frontend Components step) — otherwise record `Playwright UI Automation: N/A — no UI touched by this fix` in `bug-<TICKET-ID>-summary.md` and proceed to Step 8 with part 1 still done.

🔴 **This gate INVOKES two existing skills via the Skill tool, in WORKFLOW MODE — it never re-implements them.** Full mechanics: `implementation/code-generation.md` Step 11d.

1. **Manual test plan — VERIFY FIRST, invoke `ve-implement` only to backfill.** `spec/test-plans/<TICKET-ID>-<title>/` was **already generated and approved** at `bug-fix.md` Step 8.5 Item 4.5 and is already committed on the bug branch, so the normal case here is a **check, not a run**: confirm the folder exists and covers this ticket's ACs, record `Manual test plan: present (approved at STOP CHECKPOINT)`, and move to part 2. **Only if it is genuinely absent** invoke the skill with this ticket and **`mode: workflow`** — per `agents/ve-implement-agent.md` **Mode Detection** it skips its story-picker, its `ve/…` branch, its Approve/Request-Changes checkpoint and its push/PR, and the generated `spec/test-plans/…` files stay in the working tree to ride THIS fix's commit — and announce the backfill explicitly. 🔴 Never regenerate or overwrite an approved test plan to match the code. 🔴 Either way this is scope derivation, not Verification Engineer's sign-off — Verification Engineer's own standalone `/ve-implement` run remains the only sign-off path.
2. **Invoke the `playwright-implement` skill — UI fixes only** — with the same ticket and **`mode: workflow`**: per `agents/playwright-implement-agent.md` **Mode Detection** it skips its story-picker, its both-merges gate (nothing has merged yet by design — the fix is in this working tree), its integration-branch checkout, its Planner-plan Approval Gate and its Push Gate; auto-derives the Seed Test Gate; **starts the app locally itself** (and tears it down); invokes the real Planner/Generator/Healer subagents; and **executes `--headed`, exactly as the standalone skill does** (`npx playwright test tests/e2e/… --headed`) — this is the developer's own machine and the browser is meant to be visible; 🔴 headless belongs to CI alone, because a runner has no display.
3. **Iterate** — fixing the application code (never `test.fixme()`-ing a genuine failure) within the SAME run until every generated spec passes.  **This is SH-LOOP-11 — capped at 3 remediation attempts (SH-1). On exhaustion apply SH-4: HALT and emit the Retry-Limit Report.** 🔴 WORKFLOW MODE skips **approvals and git mechanics only** — never a verification.
4. **Capture evidence** to `reports/playwright-test-evidence/bug-<TICKET-ID>/` (`playwright-test-run.log`, the **mandatory machine-readable** `playwright-test-report.json`, `evidence-manifest.md`) and reference it in `bug-<TICKET-ID>-summary.md` + runtime-artifacts/audit.md. Write the result into `eval.json`'s `gates.playwright`, and record the resolved `startCommand`/`readinessUrl` into the `ci.playwright` manifest fragment (Step 8.5) so CI's trust-gate run reuses the identical commands.
5. **Commit the generated Playwright artifacts** (`tests/e2e/...`, `spec/playwright-specs/...`, any confirmed `seed.spec.ts` addition, `spec/test-plans/<TICKET-ID>-<title>/automation-summary.md`) together with the rest of the fix — no separate branch/PR.
6. 🔴 CI later re-executes these SAME specs as a **trust gate, never the first execution** (headless there only because a runner has no display) — cross-checked automatically by the CI Attestation gate (Step 10.5, SH-LOOP-10) **when `## CI/CD Configuration` `Enabled: Yes`**; when `Enabled: No` there is no CI run to cross-check against, so this run's local Playwright pass is the only evidence for this fix.

## Step 7.8 — 🧪 Playwright E2E Regression Gate (MANDATORY — after Step 7.7, before Code Review, same run)

Execute **Step 11e** of `implementation/code-generation.md`. 🔴 **Runs for EVERY fix, UI or not — deliberately unlike Step 7.7, which is UI-only.**

1. **Re-run the ENTIRE `tests/e2e/` suite** (every earlier work unit's specs **plus** anything Step 7.7 just generated), headless against a locally started instance of the app, and save the raw output to `reports/playwright-test-evidence/bug-<TICKET-ID>/regression/playwright-full-regression.log` plus the **mandatory machine-readable** `playwright-regression-report.json`.
2. **Diff against the Step 3 Item 6 baseline.** Only specs **green at baseline and red now** count.
3. **NEW failures → this fix broke them, so this fix fixes them** within THIS SAME run; re-run and re-diff until the diff is clean.  **This is SH-LOOP-13 — capped at 3 remediation attempts (SH-1). On exhaustion apply SH-4: HALT and emit the Retry-Limit Report**, naming each newly-red spec.
4. 🔴 **Fix the application code, never the spec.** Deleting a spec, marking it `test.fixme()` or `.skip`, loosening a locator, widening a timeout or narrowing an assertion to force it green is the exact analogue of deleting a failing unit test and is equally forbidden (SH-6). An approved spec changes only when the acceptance criterion it encodes genuinely changed — amended together with the AC, `requirements.md` and the tracker item, and logged.
5. **Failures already red at baseline** → not this fix's doing; already logged in the baseline. Ignore them and do not block on them.
6. **Capture evidence** in that same `regression/` folder (`evidence-manifest.md` with baseline vs post-change counts, the exact commands, `headed` + reason, and each NEW failure with what broke and how it was fixed), reference it in `bug-<TICKET-ID>-summary.md` + runtime-artifacts/audit.md, and write the result into `eval.json`'s `gates` block under id **`"playwrightRegression"`**.
7. 🔴 **LOCAL-ONLY gate** — like `regression` and `apiContract`, CI has no baseline to diff against, so `playwrightRegression` is **never** added to `ci.gates` (`common/eval-framework.md` Section 5). CI's own `playwright` job stays a trust gate with no attribution.
8. **`N/A`** when the Step 3 Item 6 baseline was `N/A` (nothing existed to regress) — record the same reason. 🔴 Never reported as a pass.

## Step 8 — AUTO Code Review →  Verdict Routing + Auto-Remediate Loop

Mirrors dev-implement Sections A–C, bug-scoped. The Code Review runs **automatically**, and so does everything that follows from it — the user is asked nothing.

### 8a. AUTO Code Review (MANDATORY, automatic)
1. **Log** in runtime-artifacts/audit.md that automated Code Review is starting for Bug [TICKET-ID] (ISO 8601 timestamp).
2. Auto-run `workflows/code-review.md` scoped to this fix (read-only — it MUST NOT edit source) → versioned report `reports/reviews/bug-<TICKET-ID>-code-review-v[X].md`. Pass in the Step 6/7/7.5/7.7 evidence — the review MUST NOT re-run the tests, re-measure coverage, re-run the D1–D7 checks, or re-run the Playwright specs; it cites the stored evidence.
2.4. ** AUTOMATED SECURITY REVIEW (MANDATORY, automatic — inside this review pass)**: the review's **Phase 2.5** runs the `agents/code-security-review-agent.md` procedure against this fix's diff (all 16 Security Baseline rules, scoped to the changed files + the attack surface they reach) and writes `reports/code-security-reviews/bug-<TICKET-ID>-security-review-v[X].md` (keyed by this work unit and the review version — never the dated name, which parallel stories would collide on). Its **🔴/🟠 findings on the changed surface become real `SEC-ISS-XXX` findings** — routed by 8b and **auto-remediated by 8c (SH-LOOP-5) until clean, within its 3-round budget**, exactly like AC findings. 🟡/🔵 and pre-existing violations on untouched lines are **advisory only** (`/raise-defect` for those). 🔴 Never suppress instead of fixing; never widen the scan to the whole repo.
2.5. ** JUDGE GATES J1 + J2 — 🔴 BLOCKING (MANDATORY, automatic — computed HERE and nowhere else)**: compute the two judge scores per `common/eval-framework.md` Section 4 from this work unit's diff — **J1** against `tests/.evals/rubrics/architecture-rubric.json` (derived from `spec/plans/architecture.md` Section 10; apply the Section 3 **fallback chain**: this cycle's rubric → a prior cycle's committed rubric → derived from Atlas / the reverse-engineering artifacts → **`N/A` with the reason**; this flow skips most design stages, so `N/A` is a normal outcome and is never scored against a borrowed rubric) and **J2** against `security-rubric.json`. Write them with their **per-criterion breakdown** to `reports/eval-evidence/bug-<TICKET-ID>/judge/`, merge into the **`gates`** block of `eval.json`, refresh `eval-summary.md`, report both in the review report.
   - **Scoring discipline** (Section 4.1): score **once** per review pass — never re-roll for a better number; every criterion below 1.0 **MUST cite `file:line`**; score only what the diff shows; a criterion this diff cannot exercise is `N/A`, excluded, remaining weights renormalised to 1.0 — never scored 0.
   - ** Gate**: `J1 ≥ llmJudgeArchitectureScoreMin` **and** `J2 ≥ llmJudgeSecurityScoreMin` from `tests/.evals/config.json`. `J1 = N/A` passes. **Below minimum → SH-LOOP-6**: remediate the cited criteria worst-weighted-loss first, re-run whatever gates the fix touched, re-score on the next review pass. **Capped at 3 attempts; on exhaustion apply SH-4 — HALT and emit the Retry-Limit Report.**
   - 🔴 **Forbidden ways to pass** (SH-6): editing `architecture.md` Section 10, editing the rubric JSON, lowering either minimum, re-scoring until it clears, or marking an applicable criterion `N/A`.
3. **MANDATORY — audit the complete review log**: the `**TRACKER ITEM**:` field, report path, verdict, and the complete list of findings by severity (🔴 Blocker / 🟠 High). Do not summarize away findings.
4. Proceed to **8b**.

### 8b.  Review Verdict Routing (AUTOMATIC — no question, no gate)

The review's own verdict decides what happens next. **Do NOT present an A/B choice and do NOT wait for the user.** Announce the verdict, then route:
   ```
    Automated Code Review complete for Bug [JIRA-ID].
      Report: reports/reviews/bug-[JIRA-ID]-code-review-v[X].md
      Verdict: [clean — all ACs Met / findings: Blocker X, High Y]
   [Proceeding to commit + [BUG] PR. | Findings found — remediating them automatically now (round [n]).]
   ```
1. **Verdict clean (zero 🔴 and zero 🟠)** → go to **Step 8.5 (Manifest Reconciliation)**, then Step 9.
2. **Any 🔴 or 🟠 finding** → go to **8c (SH-LOOP-5)**. The framework fixes its own findings within a budget of **3 remediation rounds**; it hands them back to the user only when that budget is exhausted (SH-4), and then it HALTS instead of raising the `[BUG]` PR.
3. **MANDATORY**: log the routing decision in runtime-artifacts/audit.md under a plain heading (`## Review Verdict — Clean, Proceeding to PR (Bug [JIRA-ID])` or `## Review Verdict — Findings, Auto-Remediating (Bug [JIRA-ID])`) with the full findings list by severity. **No "GATE" in the heading, and no user response to record.**

### 8c.  Auto-Remediate Loop — SH-LOOP-5 (AUTOMATIC — max 3 rounds)

**Entered whenever the review verdict reports findings. Every round is automatic — no prompts at any point. The loop is bounded by the Self-Healing Retry Policy: one round = one attempt, maximum 3.**
1. **Check the SH-LOOP-5 counter BEFORE starting a round.** If 3 attempts have already been spent, do not start another — go directly to step 7 (Exhaustion).
2. **Log** in runtime-artifacts/audit.md that automatic remediation round `[n] of 3` is starting for Bug [TICKET-ID], naming the review report being remediated, the findings in scope, and the identified root cause of each (SH-3, SH-7).
3. Run `workflows/remediate.md` scoped to that report (fix → unit test → green).  **Its scope-confirmation prompt is SKIPPED** — every 🔴/🟠 finding is in scope and nothing is deferred. **Re-run the FULL repo suite if the remediation touched non-test code**, comparing against the Step 3 baseline again — only NEW failures block, and they are fixed in the same round. If the remediation touched API-layer code that Step 6.5 covered, also re-run the affected endpoint(s)' API & Contract tests and keep them green. Per SH-2, these re-entries **continue** the SH-LOOP-3 / SH-LOOP-2 counters — they do not reset them.
4. **MANDATORY — audit the complete remediate log**: the round number (`[n] of 3`), which findings were fixed (by severity), files changed, unit-test evidence, regression comparison. Record the complete log, not a summary.
5. **Re-review automatically**: return to **8a** (produces the next report version `v[X+1]`), then **8b** again.
6. **Loop control**:
   - **Verdict clean** → the loop exits successfully → **Step 8.5 (Manifest Reconciliation)**, then Step 9.
   - **Findings remain AND attempts spent < 3** → increment the counter and return to step 1.
   - **Findings remain AND attempts spent = 3** → **exhausted** → step 7.
   - **Stall (SH-5)** — a round produced **no code change at all** AND the next review returned an **identical** finding set → the loop cannot progress. Treat as exhausted immediately, regardless of attempts remaining → step 7, noting the early end.
7. ** Exhaustion (SH-4) — HALT, do not raise the `[BUG]` PR.** When the budget is exhausted (3 rounds, or an SH-5 stall):
   - Do **not** run a 4th round, do **not** commit, do **not** push, do **not** raise a PR, and do **not** change the local Story Tracker or the external tracker. The ticket stays `In Development` and the remediation work stays in the working tree.
   - Emit the **Retry-Limit Report** (Self-Healing Retry Policy, above) with `[loop name]` = `Auto-Remediate (code review + security findings)` and `[SH-LOOP-ID]` = `SH-LOOP-5`, listing every unresolved finding with its ID, severity, file:line, and the reason automatic remediation failed on it.
   - Append the same content to runtime-artifacts/audit.md under `## Self-Healing Retry Limit Reached — SH-LOOP-5 (Bug [TICKET-ID])`.
   - **HALT and wait for the developer to fix it manually and hand it back.** 🔴 Never silence a finding by deleting it from the report, never weaken the review scope to manufacture a clean verdict, and never let an exhausted loop pass unreported.

### 8d. Status
The ticket stays `In Development` throughout review and remediation.

## Step 8.4 — Artifact Completeness Check (MANDATORY)

**🔴 ARTIFACT COMPLETENESS CHECK — SH-LOOP-16 (MANDATORY, AUTOMATIC — after the clean review verdict, BEFORE Step 8.5 and the Step 9 commit)**: run `common/work-unit-artifacts.md` Section 5 for `bug-<TICKET-ID>`. Build the expected evidence list from Section 1 (the always-required files plus the folders of every gate that ran, read from `eval.json`), then verify each file exists, is non-empty, has its set format (the Section 2 `evidence-manifest.md` skeleton; `eval.json` / `eval-summary.md` per `common/eval-framework.md` Section 6; the review and security report templates) and agrees with the others (Section 4) — including that **no folder exists for an `N/A` gate** (so `b3/` only on the last unit). A file whose underlying output exists is written or reformatted from that real output; a missing underlying output means the gate never produced evidence, so that gate's step is **re-run** — never hand-written. Record the result in `reports/eval-evidence/bug-<TICKET-ID>/artifact-check.md`. Capped at 3 attempts; on exhaustion HALT with the Self-Heal Limit message. **Nothing is committed until this check is clean.**

## Step 8.5 — Manifest Reconciliation — CONDITIONAL on `## CI/CD Configuration` `Enabled: Yes` (MANDATORY, AUTOMATIC when it applies — after local gates pass, BEFORE the commit)

**If `## CI/CD Configuration` records `Enabled: No` (`## CI Setup Status` = "declined"), SKIP this step entirely** — there is no CI manifest to reconcile without a pipeline — and go straight to Step 9. Otherwise:

Identical mechanism to `dev-implement.md` Section D Step 1.5 — see
`common/ci-pipeline-generation.md` Section 4.0f for the full contract. Write ONE NEW file,
`tests/.evals/ci-manifest.d/bug-[TICKET-ID].json`, from what Steps 6/6.5/7.5 **already executed for
real** for every root this fix touched — never re-derived, never guessed. Append-only; never edit
`tests/.evals/config.json` or another work unit's fragment. Re-run `validate-pipeline.{sh,ps1}` and
confirm it passes before proceeding to Step 9. Include the fragment in the same commit as the fix. 🔴 **Write the COMPLETE entry per Section 4.0f's field table** — including `runtimeVersion`,
`coverageReportPath`/`coverageFormat`, `noTestsExitCode`, `dependsOn`, `toolchainSetup`, and `tools`
**paired with** `toolInstallCommands`. A name in `tools` with no matching `toolInstallCommands` entry is a
hard Manifest defect, and an omitted `dependsOn` silently disables monorepo diff-scoping.

## Step 9 — Commit, Push & Raise the `[BUG]` PR —  FULLY AUTOMATIC

🔴 **A clean review verdict is the ONLY thing that triggers this step.** An exhausted SH-LOOP-5 (8c.7) does NOT reach it — that path HALTS at the gate and waits for the user. The commit, push,
PR creation, labels, tracker update (Step 10) and auto PR review (Step 11) run **automatically with
no prompts**. Announce each action; never ask whether to do it.

1. Verify the active branch is the Bug Branch (switch automatically and announce if not). Run the **State Isolation Check** (`common/parallel-work-state.md` Section 5.5), then stage and commit — together with the fragment `runtime-artifacts/stories/bug-<TICKET-ID>/` and never the shared `audit.md` / `aire-state.md` — the fix (code + tests + updated docs), **the Step 7.7 Playwright artifacts when that gate applied**, **plus any files Playwright Readiness added** (the package manifest and lockfile, `playwright.config.*`, `.claude/agents/playwright-test-*.md`, `.mcp.json`), **plus the Step 8.5 manifest fragment, if one was written**. The commit message MUST carry an `AIRE-Version:` trailer as the framework signature — exactly as dev-implement Section D does — where `[N]` is read at runtime from the "AIRE Framework Version" line in `CLAUDE.md` (do not hardcode a number):
   ```
   git add <fix files>
   git commit -m "[BUG][TICKET-ID] <concise fix summary>" -m "AIRE-Version: [N]"
   ```
   The `AIRE-Version: [N]` trailer goes on its own line at the end of the message body (alongside any existing trailers). Record the hash in the fragment `runtime-artifacts/stories/bug-<TICKET-ID>/audit.md`.
1.5. **🔴 CI PREFLIGHT GATE — CONDITIONAL on `## CI/CD Configuration` `Enabled: Yes` (MANDATORY, AUTOMATIC when it applies — after this commit, BEFORE the push)**: **if `Enabled: No`, SKIP this gate entirely** — there is no CI pipeline to preflight — and go straight to Step 2 (invoke `pr-generator`). Otherwise, identical
   mechanism to `dev-implement.md` Section D Step 2.5; `common/ci-pipeline-generation.md` **Section 4.0i**
   is the contract. In a **clean room** (fresh venv / empty `node_modules` / throwaway Podman container —
   never this agent's ambient shell, never an install the manifest does not declare), against the
   **committed** fix with `BASE_SHA="$(git merge-base origin/<base-branch> HEAD)"`, run CI's own
   entrypoints — `ci-manifest-runner.sh install` → `build` → `run-static-evals.sh` →
   `ci-manifest-runner.sh coverage` — plus the P1 declaration check over the merged manifest. **FAIL** on a
   missing tool, an undeclared dependency (`ModuleNotFoundError` / `requires the <pkg> package`), a
   Manifest defect, or a gate reporting `N/A`/a qualified pass on a root this diff touched. Fix the
   **declaration** (this fix's own fragment for `tools`+`toolInstallCommands`; the repo's own dependency
   declaration for a test/runtime package) — never the gate, never a bare install inside CI YAML. This is
   **SH-LOOP-9**, capped at **3 attempts** (SH-1); on exhaustion apply SH-4 — HALT with the Retry-Limit
   Report, no push and no PR. Reuse the behavioural gate's containerised evidence rather than re-running it.
2. Invoke **`pr-generator`** (as-is) **in WORKFLOW mode**, passing **target branch = the Base Branch** from `## Branching`. The PR title carries the **`[BUG]`** prefix; the skill applies the `ai-generated` and `aire-v[N]` labels (plus the `AIRE Framework: v[N]` line in the PR body).  **Its Phase 5 confirmation is SKIPPED — this workflow has no gates; invoking it is the authorization.** It announces the draft and raises the PR without asking. Never re-ask about pushing or opening the `[BUG]` PR.
3. Record the PR URL in the ticket's state fragment (`runtime-artifacts/stories/bug-<TICKET-ID>/state.md`, `## Story Tracker Row` → PR — never the shared `## Branching`; readers resolve it from there or live from the bug branch) and the full outcome in the audit trail — including the labels applied (`ai-generated` + `aire-v[N]`).

## Step 10 — Tracker Update (NO Ready-for-Testing transition)

1. Story Tracker: keep Status = `In Development`; set **End** = today and **Recorded** = now; note the PR URL.
2. 🔴 **Do NOT transition the ticket to "Ready for Testing"** (or any further state) — the ticket stays In Development after the PR. Add a **comment** on the ticket (automatic) linking the PR with evidence (tests passing, coverage %, regression clean vs baseline), dispatching on `## Tracker` → `Type` per `common/tracker-sync.md` Section 10: JIRA `addCommentToJiraIssue`, ADO `az boards work-item update --discussion`, GITHUB `gh issue comment`, LOCAL a note appended to the local bug entry (no external call).
3. Log in runtime-artifacts/audit.md (with the TRACKER ITEM field).

## Step 10.5 — CI Attestation Gate — CONDITIONAL on `## CI/CD Configuration` `Enabled: Yes` (MANDATORY, AUTOMATIC when it applies — after the PR is raised, before Step 11)

**If `## CI/CD Configuration` records `Enabled: No`, SKIP this gate entirely and proceed straight to Step 11** — there is no CI pipeline run to attest against. Otherwise, identical mechanism to `dev-implement.md` Section D Step 8. Confirm a run of
`agentic-eval-pipeline.yml` exists for this PR's head SHA (`gh pr checks` / `gh run list`) — no run is a
blocking finding. Watch it to conclusion, download `eval.json`, and cross-check CI's `gates` block
against this fix's own local gate results.

**Check the SH-LOOP-10 counter BEFORE starting an attempt.** If 3 attempts have already been spent, do
not start another — go directly to Exhaustion below.

A gate that passed locally but is absent/`N/A` in CI is a **manifest defect** — go back to Step 8.5,
extend the fragment (never remove another unit's entry), re-run the Step 9.1.5 preflight for that root,
commit, push, re-verify. This is **SH-LOOP-10 — capped at 3 remediation attempts (SH-1)**. Log each
attempt per SH-3 (root cause, planned fix, files changed, exact command re-run, result).

**Exhaustion (SH-4)**: on the 3rd failed attempt, or an SH-5 stall, apply SH-4 exactly — HALT, do not
push further, do not raise/update the PR beyond what already exists, do not change any tracker status,
and emit the standard Retry-Limit Report with `[loop name]` = `CI Attestation` and `[SH-LOOP-ID]` =
`SH-LOOP-10`, naming each gate CI never saw agreement on. Append the same content to
`runtime-artifacts/audit.md` under `## Self-Healing Retry Limit Reached — SH-LOOP-10 (Bug [TICKET-ID])`.

On a clean match, log the attestation and proceed.

🔴 **SCOPE — this gate repairs CI configuration only** (`common/ci-pipeline-generation.md` **Section 6.6**):
this workflow owns the manifest fragment, the repo's dependency declarations, the pipeline scripts and
tool pins; **CI self-repair owns application code and tests**. A Code-class CI failure (Section 6.4) is
recorded here and left to self-repair — never fixed from this gate and never charged to an attestation
attempt. Never push into an in-flight self-repair run: wait for it, fetch, rebase onto its commit, re-read;
never force-push and never revert its commit.

## Step 11 — AUTO PR Review

Invoke the **`pr-review`** skill (as-is) in **AUTO MODE** against the just-raised PR: it posts a plain COMMENT review (summary + inline comments) automatically — no prompt, never a formal APPROVE/REQUEST_CHANGES. Record the outcome in runtime-artifacts/audit.md.

## Step 12 — Archive Handoff (MANUAL)

🔴 **RE-READ FIRST.** Before writing any part of this step's output, `Read` this Step 12 section from the file again. Do NOT reconstruct it from memory or from earlier in this session's context — "I already read this file at Step 1" does not satisfy this.

### The ordering invariant

| # | Action | Relative to the archive |
|---|--------|-------------------------|
| 1 | `ve/...` PR(s), if the Verification Engineer raised any, merge into `<bug-branch>` | BEFORE |
| 2 | `ve-list-work` Option C amendments pushed to `<bug-branch>` | BEFORE |
| 3 | `ve-list-work` Option B sign-off → ticket `Ready for Testing` | BEFORE |
| 4 | **`archive-epic`** (bug mode) | ⬅ **THE ARCHIVE** |
| 5 | **`[BUG]` PR merges into `<base-branch>`** | AFTER — completes the cycle |

🔴 **`archive-epic` runs at row 4 — BEFORE the `[BUG]` PR merges (row 5).** Its cycle-close archive commit must reside in the still-OPEN `[BUG]` PR so the archive rides that PR onto `<base-branch>`. Merging the `[BUG]` PR completes the cycle; the next cycle pulls fresh current-system truth from Atlas via the Helix MCP.

**TWO DIFFERENT PRs appear here — never write "the PR" unqualified:**
- the **`ve/...` PR** → merges into `<bug-branch>`. The archive **waits for this one**.
- the **`[BUG]` PR** → merges into `<base-branch>`. The archive **must precede this one**.

"Wait until all ve work has landed" means rows 1–3 **only** — never row 5.

**🔴 BANNED OUTPUT — each inverts the invariant. Never emit them, in any wording:**
- "archive runs post-merge" / "it runs post-merge only"
- "when the `[BUG]` PR merges, run `archive-epic`"
- "DO NOT invoke `archive-epic` manually now"
- any instruction for the developer to transition the tracker ticket in this step

Do NOT invoke `archive-epic`, do NOT ask whether to invoke it, and do NOT add an options menu or any competing next-steps block. The block below is the entire output of this step.

### Emit this message VERBATIM (placeholders substituted)

The ONLY permitted modification is substituting `<url>`, `<bug-branch>`, `<base-branch>`, `[TICKET-ID]`, `<slug>` with real values from `## Branching` / the Step 9 PR. **Never ship an unsubstituted placeholder**; never add, remove, reorder, reword, or summarise a line:

```
Bug fix for [TICKET-ID] is ready for review.
   Pull request   <url>   ([BUG] → <base-branch>)
   Status         In Development — it moves forward only after sign-off, the cycle archive and the merge.
   Note           The cycle archive was deliberately NOT run — it is yours to run, at step 4 below.

REVIEW THE PULL REQUEST TOGETHER — FIRST
   The [BUG] PR is reviewed by the Developer and the Verification Engineer together.
   Approval and merge are manual steps — the framework never approves or merges a pull request.
   Changes needed? Leave review comments on the PR, then type:  pr-fix <url>

NEXT ACTIONS (in this order):
   1.  If the Verification Engineer raised any `ve/...` PR(s) for [TICKET-ID], wait until they have MERGED into `<bug-branch>`
       (the Verification Engineer PR into the bug branch — NOT the [BUG] PR into `<base-branch>`)
   2.  On `<bug-branch>`: `git checkout <bug-branch> && git pull --ff-only`
       (pulls the merged `spec/test-plans/<TICKET-ID>-.../` docs in so the archive captures them)
   3.  Verification Engineer: use the skill ve-list-work — on `<bug-branch>`, NOT on `<base-branch>`
       • Option C to amend a test plan (commit + push to `<bug-branch>` so the archive captures it)
       • Option B to sign off — promotes ticket [TICKET-ID] In Development → Ready for Testing
       (Sign-off happens HERE, before the archive.)
        For frontend work, this workflow already generated and ran the Playwright tests
          (Step 7.7); ve-list-work's output shows their status.
       Rejected? If the Verification Engineer rejects in Option B, or anyone leaves review comments / requests
          changes on the [BUG] PR, type: pr-fix <url> — it fixes the bug on `<bug-branch>`,
          re-runs every gate, updates the same [BUG] PR, then come back to step 3.
   4.  Use the skill archive-epic  on bug branch (bug mode → `aire-archives/bugs/<TICKET-ID>-<slug>/`)
       MUST happen while the [BUG] PR is still OPEN — its cycle-close archive commit rides that
          open PR onto `<base-branch>`. It writes this cycle's RE delta to
          `spec/plans/delta/<TICKET-ID>-<slug>/`, archives it, and then REMOVES the live spec/,
          reports/ and runtime-artifacts/ trees — it never stitches.
   5.  ONLY NOW merge the [BUG] PR into `<base-branch>`: <url>
   6.  On `<base-branch>`, after that merge, type: /stitch-delta
       It reads the delta from the cycle archive and publishes it to the deep dive on Atlas via the
       Helix MCP; its own PR is a single ledger row. The cycle is NOT closed until this lands —
       skipping it leaves Atlas a cycle stale.

ORDER IS LOAD-BEARING: archive-epic (step 4) runs BEFORE the [BUG] PR merges (step 5).
   Merging first strands the cycle archive off the PR and forces a manual recovery.
Use the skill names EXACTLY as shown — do not describe what you want in your own words.
   Any other phrasing is not a framework trigger and the workflow will not advance.
```
---

## Critical Rules
- EVERY audit entry carries the `**TRACKER ITEM**:` field AND the `**AIRE VERSION**:` field (version read at runtime from the "AIRE Framework Version" line in `CLAUDE.md` — never hardcoded).
- 🔴 **A REJECTED `[BUG]` PR IS FIXED WITH `pr-fix`** (`workflows/pr-fix.md`): review comments or a ve rejection (`ve-list-work` Option B) while the `[BUG]` PR is open are fixed by `pr-fix <PR>` on the same bug branch — it re-runs this workflow's complete gate chain (Steps 3–11) and updates the same PR. Never re-run `bug-fix-implement` to raise a second PR.
- 🔴 **ONE SANCTIONED PAUSE — a Playwright agent install (Step 4.4).** For a frontend work unit, Playwright Readiness (Step 4.4) installs the runner, the browsers and Playwright's official test agents **before any code is written**. If the agents had to be installed, the run records `PAUSED —` and asks the user to restart the Claude Code session — MCP servers load at session start, so the `playwright-test` server is not connected until then. 🔴 **This is a hard stop, not an approval prompt.** Nothing is committed, pushed or transitioned; after the restart the user types `bug-fix-implement` and it continues at **Step 4.5**. The Playwright UI gate (Step 7.7) keeps the same install-then-pause handling only as a safety net, resuming at Step 7.7 if it ever triggers there. Everything already installed → no pause.
- 🔴 **NO GATES AT ALL** — the fix plan is announced and executed (no GATE 2), and the review verdict routes the run automatically (no GATE 3). Never present a plan-approval or Approve-&-continue/Remediate prompt, and never write "GATE" into an audit heading from this workflow.
- 🔴 **THE FRAMEWORK FIXES ITS OWN FINDINGS, WITHIN A BOUNDED BUDGET** — any 🔴/🟠 finding triggers the auto-remediate loop (8c, **SH-LOOP-5**): remediate → regression → re-review, looping until the verdict is clean **or the 3-attempt budget is exhausted**. On exhaustion (3 rounds, or an SH-5 stall — no code change + identical findings) the run **HALTS at the gate**: no commit, no push, no `[BUG]` PR, no tracker change; the Retry-Limit Report is emitted to the user and to runtime-artifacts/audit.md, and the run waits for the developer to fix it manually and hand it back.
- 🔴 Mid-coding plan deviations are applied only after the plan document is revised and the change announced + logged — never silently, and never via an approval prompt.
- Version stamping mirrors dev-implement: the `aire-v[N]` label on the Jira ticket (Step 2.5), the `AIRE-Version: [N]` trailer on the fix commit (Step 9), and the `aire-v[N]` label on the `[BUG]` PR (via pr-generator) — all substituted live from CLAUDE.md.
- ONE branch — work on the recorded Bug Branch only; never create story branches; never commit to the base branch.
- ALWAYS run the BASELINE regression BEFORE any change, and the FULL regression AFTER the fix; only NEW failures (vs baseline) block; log both runs' complete output in `bug-<TICKET-ID>-summary.md`.
- 🔴 ALWAYS BOOTSTRAP missing tool configs BEFORE the baseline static run (Step 3 Item 5, `common/eval-framework.md` Section 2.2) — a check with no config is **set up**, not marked N/A; an existing config is used **as-is**. Bootstrap → baseline → fix → gate → diff: a config created after the baseline blames this fix for pre-existing findings. Announce every file created.
- 🔴 ALWAYS run the BASELINE static eval checks D1–D7 before any change (Step 3 Item 5) and the STATIC EVAL GATE after the regression gate (Step 7.5); only findings NEW vs baseline on changed files block, and this fix resolves them in the same run. **NEVER suppress a finding to pass the gate** — that is the analogue of deleting a failing test. Baseline findings are pre-existing debt: logged, ignored. See `common/eval-framework.md`.
- 🔴 The J1/J2 judge scores are computed ONCE per review pass in Step 8a and are **blocking gates** (below minimum → SH-LOOP-6); J1 = `N/A` passes and is a normal outcome for a bug fix that skipped the design stages.
- 🔴 The 8c auto-remediate loop (**SH-LOOP-5**) is **capped at 3 rounds** by the Self-Healing Retry Policy. It fixes review and security findings; a judge score below minimum is fixed by its own loop, SH-LOOP-6.
- Unit tests must include at least one test reproducing the defect; coverage on new/changed code ≥90%.
- 🔴 **API & Contract Testing Gate (Step 6.5) is MANDATORY WHEN the fix touches an API endpoint** — applicability is plan-derived and automatic, never asked. Generate automated tests against the real endpoint(s), RUN them, and iterate until every applicable checklist item (functional, response-code validation, role-based authorization 401/403, error-response validation, request validation, response contract/schema validation) passes, in the SAME run, BEFORE the Full Regression Gate (Step 7). This is **SH-LOOP-2**, capped at **3 remediation attempts**; on exhaustion apply SH-4 (HALT + Retry-Limit Report). N/A (with a stated reason) when the fix touches no API layer. Capture proof artifacts to `reports/api-contract-test-evidence/bug-<TICKET-ID>/`. This gate does NOT replace ve's `/ve-implement` MANUAL API/Contract test steps.
- 🔴 **Step 7.7 has TWO halves with DIFFERENT applicability — never skip the whole step because the fix has no UI.** **Part 1 — the ticket's manual test plan — is VERIFIED ALWAYS**: it was authored and approved at `bug-fix.md` Step 8.5 Item 4.5, so the normal case is a presence check; `ve-implement` is invoked in WORKFLOW MODE only to backfill a genuinely absent plan, announced. Either way the Verification Engineer simply executes the plan once the `[BUG]` PR merges instead of generating it first. **Part 2 — `playwright-implement` → browser automation — runs ONLY when the fix plan touches UI**; otherwise record `Playwright UI Automation: N/A — no UI touched by this fix` and move on, **with part 1 still done**. Applicability is plan-derived and automatic, never asked. Both halves run **by INVOKING those skills in WORKFLOW MODE with the ticket passed in**, never by re-implementing their steps inline. WORKFLOW MODE skips their story-pickers, Verification Engineer's branch/approval/PR, the both-merges gate, the integration-branch checkout, the Planner-plan Approval Gate and the Push Gate — and nothing else. The skill starts the app locally, runs the real Planner/Generator/Healer subagents, executes **`--headed`** (same as standalone — headless is CI's alone, since a runner has no display), and iterates — fixing the application code, never `test.fixme()`-ing a real failure — in the SAME run, BEFORE Step 8 Code Review. This is **SH-LOOP-11**, capped at **3 remediation attempts**; on exhaustion apply SH-4 (HALT + Retry-Limit Report). N/A (with a stated reason) when the fix touches no UI. Capture proof artifacts to `reports/playwright-test-evidence/bug-<TICKET-ID>/` and write the result into `eval.json`'s `gates.playwright`. CI later re-executes it headless as a **trust gate, never the first execution**, cross-checked by the CI Attestation gate (SH-LOOP-10). This gate does NOT replace ve's own independently-scheduled `/ve-implement` run.
- 🔴 **ALWAYS run the BASELINE Playwright E2E regression (Step 3 Item 6) and the FULL Playwright E2E regression (Step 7.8), then diff them — for EVERY fix, UI or not.** This is the UI counterpart of the unit-test regression pair (Step 3 / Step 7) and exists for the same reason: Step 7.7 only proves *this* fix's own specs pass, so nothing else proves the fix did not break a browser flow an earlier work unit already shipped. 🔴 **Do NOT skip it because the fix touches no UI** — a backend, API, schema, config or dependency change is exactly what breaks an existing flow silently. Both runs are **automatic — never prompt the user for either**. Only specs green at baseline and red now count; the fix resolves them in the same run under **SH-LOOP-13** (capped at **3 remediation attempts**; on exhaustion apply SH-4 — HALT + Retry-Limit Report). 🔴 **NEVER delete, `test.fixme()`, `.skip`, loosen a locator, widen a timeout or narrow an assertion to make an existing spec green** (SH-6) — fix the application code. Baseline failures are pre-existing debt: logged and ignored. Evidence goes to `reports/playwright-test-evidence/bug-<TICKET-ID>/regression/` and the result into `eval.json`'s `gates.playwrightRegression` — a **local-only** gate, never added to `ci.gates`.
- NEVER commit/push/raise the PR while the review verdict is unclean. An exhausted SH-LOOP-5 (8c.7) HALTS the run — it does NOT proceed to the PR. PR via `pr-generator` only, target = Base Branch, `[BUG]` prefix, `ai-generated` label. **The whole chain is automatic and prompt-free** — pr-generator runs in workflow mode with Phase 5 skipped; asking whether to push or open the PR is a defect.
- The ticket stays `In Development` after the PR — NEVER transition it to Ready for Testing yourself; that is ve's, via `ve-list-work` Option B run **on the bug branch, before `archive-epic` and before the `[BUG]` PR merges** (not post-merge on the base branch — after the archive's workspace reset there is no Story Tracker left to promote). No Parent-Epic sync exists in this flow.
- **Test Plan sign-off remains ve's, and only ve's.** ve still runs `/ve-implement` independently, on its own schedule, and only `ve-list-work` can approve/reject a test plan or move the ticket to Ready for Testing. 🔴 **The ONE narrow exception**: Step 7.7 above may auto-generate `implementation/test-plan.md` Steps 1–5 (never Step 6, the ve approval checkpoint) purely as UI-scenario scope for the Playwright gate, when ve hasn't produced that content yet — this is scope derivation for an automated test, not a substitute for ve's sign-off. Never write anything under `spec/build-and-test/`, and never treat Step 7.7's auto-generated content as an approved test plan.
- At Step 2, ALWAYS assign the ticket to the operator who invoked `bug-fix-implement` per `common/tracker-sync.md` Section 5 (automatic, verified where applicable, logged). Unresolvable identity → leave unassigned, warn, continue — assignment failure never blocks the fix. LOCAL has no assignee concept.
- 🔴 After the PR: AUTO `pr-review` (comment-only), then **STOP — the archive is MANUAL**. NEVER invoke `archive-epic` from this workflow. **Re-read Step 12 before emitting its handoff, and emit that block VERBATIM with placeholders substituted** — do not paraphrase it. The operator runs `archive-epic` once the Verification Engineer `ve/...` PR(s) (and any `ve-list-work` Option C amendments) have merged **into the bug branch**, and **BEFORE the `[BUG]` PR merges into the base branch**, so the cycle archive rides the open PR. archive-epic writes the cycle's RE delta, archives it and then removes the live `spec/`, `reports/` and `runtime-artifacts/` (the archive is the only copy), but never stitches. After the `[BUG]` PR merges, the operator runs **`/stitch-delta`** on the base branch; it reads the delta from the archive and publishes it to Atlas (it touches no `spec/`) — the cycle is not closed until that lands. Never tell the user the archive runs post-merge (that inverts the invariant), and never tell them the stitch runs pre-merge (that inverts the other one).
