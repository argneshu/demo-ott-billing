# WORKFLOW: `enhancement-implement <TICKET-ID>` (Enhancement — Analysis + Implementation in ONE flow)

## READ FIRST — THE NON-NEGOTIABLES OF EVERY `enhancement-implement` RUN

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
3. **The pre-commit guard is installed and never bypassed.** At the start of Phase B, on the enhancement branch (unit key `enhancement-<TICKET-ID>`), run
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
6. **The run ends with its exact end message.** A successful run's final output is the Step 19 handoff block,
   verbatim, every placeholder substituted, and nothing else in that message — no free-form summary
   before it, no gap list, no suggestions after it. Progress lines earlier in the run are fine; the last
   message is the block. A halted run ends with the Self-Heal Limit message instead, also verbatim.

---

## MANDATORY: Rule Details Loading

May be invoked standalone in a fresh session. Resolve `aire-workflow/` and load:
- `common/process-overview.md`, `common/session-continuity.md`, `common/content-validation.md`, `common/question-format-guide.md`
- `common/work-unit-artifacts.md` — the complete evidence set this run must leave behind (paths, the `evidence-manifest.md` format, the N/A-means-no-folder rule, keyed security-review names) and the Artifact Completeness Check before the commit
- `common/self-heal-limit-guidance.md` — the Self-Heal Limit message, the per-gate manual-fix playbook and the hand-back (resume) protocol used when a self-healing loop exhausts its budget or a tool cannot be installed
- `common/branching-strategy.md` — **Bug Branch Model** section (the enhancement branch follows the same single-branch model, with the `enhancement/` prefix)
- `planning/workspace-detection.md`, `planning/reverse-engineering.md` (if RE runs), `planning/requirements-analysis.md`, `planning/workflow-planning.md`
- `implementation/code-generation.md` (planning/generation/coverage mechanics — story selection and story-branch steps do NOT apply here). 🔴 **Follow the Guardrail defined there (Generation Phase Rules)** for any generated code.
- 🔴 **Do NOT pre-load** `extensions/testing/playwright-automation/playwright-automation.md` or `implementation/test-plan.md` — Step 14.7 reaches them by **invoking the `ve-implement` and `playwright-implement` skills in WORKFLOW MODE**, and each skill loads its own rule files.
  🔴 **BUT: those files carry the anti-shortcut rules, and you will not have read them if you skip the skill — a circular trap that has caused a real violation.** The three non-negotiables, restated HERE where they are always in context:
  1. **The ONLY permitted producer of `tests/e2e/**` and `spec/playwright-specs/**` is the `playwright-implement` skill's own Planner/Generator subagents.** About to `Write`/`Edit` a `.spec.*` file with no `Skill(playwright-implement)` call this run? That is the violation.
  2. **"The Playwright agents aren't installed" means INSTALL them** (`npx playwright init-agents --loop=claude`), then HALT for a session restart — never hand-author.
  3. **Disclosing the shortcut does not make it allowed**, and a prior work unit that did it is a defect to backfill, not precedent.
- `workflows/code-review.md` (auto-run after the implementation) and `workflows/remediate.md` (on the Remediate path)
- `common/eval-framework.md` — the Static Eval Gate D1–D7 (baseline at Step 10, gate at Step 14.5), the J1/J2 judge scores (Step 15a), and rubric derivation at Step 8.5. Evidence key for this flow: `enhancement-[TICKET-ID]`

**Loaded on demand (not at start):** `common/behavior-spec.md`, `implementation/architecture-doc.md`,
`common/ci-pipeline-generation.md` — loaded together at Step 8.5 (the STOP CHECKPOINT), exactly like
the epic flow loads them at its own STOP CHECKPOINT.

🔴 **GUARDRAIL — `code-review` and `remediate` are WORKFLOW RULE FILES, NOT Claude skills.** Whenever this workflow "runs Code Review" or "runs Remediate", you MUST `Read` and follow `workflows/code-review.md` / `workflows/remediate.md` (which pull their detailed steps from `implementation/code-review.md` / `implementation/remediate.md`) as instructions. There is **NO** Claude skill named `code-review` or `remediate` — **NEVER** invoke one via the Skill tool.

🔴 **The converse guardrail — these ARE real Claude skills, INVOKED via the Skill tool, never re-implemented inline**: **`ve-implement`** and **`playwright-implement`** (Step 14.7, both in **WORKFLOW MODE** with the ticket passed in), **`pr-generator`** (Step 16, workflow mode), and **`pr-review`** (Step 18, AUTO MODE).
- Extensions per CLAUDE.md's Extensions Loading rules (Security Baseline is ALWAYS mandatory)

Skills used **as-is — NEVER edit them**: **`pr-generator`** (pass target branch = the **Base Branch**; PR type `[ENH]`), **`pr-review`** (AUTO MODE after the PR), and **`archive-epic`** in **cycle mode** (🔴 **NEVER auto-invoked by this workflow — the operator runs it manually** after all Verification Engineer work has landed on the enhancement branch; archives under `aire-archives/enhancements/`; see Step 19).

Display the welcome message (`common/welcome-message.md`) once at start. All CLAUDE.md audit-logging rules apply: log EVERY user input verbatim in `runtime-artifacts/audit.md` (append-only, ISO 8601 timestamps).

## MANDATORY: Audit Entry Format — TRACKER ITEM on EVERY entry

Every runtime-artifacts/audit.md entry in this workflow carries the `**User Email**:` field (current session email, read live), the `**TRACKER ITEM**:` field (the enhancement ticket as a clickable link for JIRA/ADO/GITHUB, or the local ID for LOCAL), and — from Phase B onward — the `**AIRE VERSION**:` field (read at runtime from the "AIRE Framework Version" line in `CLAUDE.md` — never hardcoded), exactly as `dev-implement` does.

## THIS WORKFLOW IS FULLY AUTOMATIC — IT HAS NO APPROVAL GATES

**The Implementation Checkpoint ("Ready to implement now? yes / no", between Phase A and Phase B) is
the ONLY user decision in Phase B.** Everything after that `yes` — the implementation plan, the code,
the unit-test/coverage gate, the regression gates, the automated Code Review, **the remediation of any
findings it reports**, the commit, the push, the `[ENH]` PR and the PR review — runs **without a
single approval prompt**.

- There is **NO GATE 2** (implementation-plan approval). The plan is built, announced and executed.
- There is **NO GATE 3** (review decision). A review with findings is **remediated automatically**,
  then re-reviewed, **looping until the verdict is clean** — never an Approve/Remediate question.
- There is **NO GATE 1** either — that was the epic flow's story-set approval, which no longer
  exists anywhere in the framework.
- The **Implementation Checkpoint remains** — it is deliberately unnumbered flow control (it also
  marks the ve handoff), not a numbered approval gate.
- 🔴 **Never write the word "GATE" into an audit heading from this workflow.** Plan and review
  outcomes are logged as auto-approved decisions under plain headings.
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
| **SH-LOOP-1** | Unit Test & Coverage | Step 13 | All unit tests green **and** coverage on new/changed code ≥ 90% |
| **SH-LOOP-7** | Behavioural B1 + B2 (Gherkin) | Step 13.2 | The enhancement's scenarios pass with every AC tag executed, AND the entire existing behaviour suite stays green |
| **SH-LOOP-8** | Behavioural B3 (epic scope) | Step 13.2 | The full suite + the ticket's end-to-end journey pass |
| **SH-LOOP-2** | API & Contract Testing | Step 13.5 | Every applicable checklist item passes on every touched endpoint |
| **SH-LOOP-3** | Full Regression | Step 14 | Zero NEW failures versus the Step 10 baseline |
| **SH-LOOP-4** | Static Eval D1–D7 | Step 14.5 | Zero NEW findings above the `tests/.evals/config.json` thresholds on changed files |
| **SH-LOOP-11** | Playwright UI Automation | Step 14.7 | Every generated Playwright spec passes (zero `test.fixme()` outcomes), when the enhancement touches UI |
| **SH-LOOP-13** | Playwright E2E Regression | Step 14.8 | Zero NEW failing Playwright specs versus the Step 10 baseline — runs for EVERY enhancement, UI or not |
| **SH-LOOP-6** | Judge Gates J1 + J2 | Step 15a Item 2.5 | `J1 ≥ llmJudgeArchitectureScoreMin` **and** `J2 ≥ llmJudgeSecurityScoreMin` (`N/A` passes) |
| **SH-LOOP-5** | Auto-Remediate (code review + security findings) | Step 15c | Review verdict clean — zero 🔴 and zero 🟠 |
| **SH-LOOP-9** | CI Preflight (provisioning + manifest executability) — **N/A when `## CI/CD Configuration` `Enabled: No`** | Step 16 Item 1.5 | Every CI entrypoint runs in a clean room with zero missing tools, zero undeclared dependencies, zero Manifest defects, and no gate `N/A`/qualified pass on a root this change touched |
| **SH-LOOP-10** | CI Attestation (post-PR provisioning agreement) — **N/A when `## CI/CD Configuration` `Enabled: No`** | Step 17.5 | CI's `gates` block agrees with this enhancement's own local gate results on every root the diff touched — no gate the diff touched is absent, `N/A`, or provisioning-errored in CI when it passed locally |
| **SH-LOOP-16** | Artifact Completeness | Step 15.4 | Every evidence file `common/work-unit-artifacts.md` Section 1 requires for this unit exists, has its set format, agrees with `eval.json` / `eval-summary.md`, and no folder exists for an `N/A` gate |

**SH-1 — Attempt budget.** Each loop is allowed a **maximum of 3 remediation attempts**. One attempt
is one complete `fix → re-verify` cycle. The initial verification run that first detects the failure
is **not** an attempt (it is attempt 0). Attempts are numbered 1, 2, 3.

**SH-2 — Counters are per-loop, independent, and never silently reset.** Maintain a separate counter
per SH-LOOP ID. A counter is never shared between loops, never reset by another loop's success, and
never reset by advancing to a later gate. When a later loop's remediation forces re-entry into an
earlier loop (for example Step 15c re-running the Step 14 regression comparison), that re-entry **continues the earlier loop's existing
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
   external tracker. The ticket stays `In Development` on its enhancement branch. The attempted fixes stay in the working tree for inspection.
3. Record the halt in the work unit's `## Progress` (`HALTED — …`, `common/self-heal-limit-guidance.md`
   Section 1) and emit the **Self-Heal Limit message** (the Retry-Limit Report —
   `common/self-heal-limit-guidance.md` Section 2, with the "HOW TO FIX IT YOURSELF" steps taken from the
   Section 3 playbook row for this loop) as the run's final output.
4. Append the same content to `runtime-artifacts/audit.md` under the heading
   `## Self-Healing Retry Limit Reached — [SH-LOOP-ID] (Enhancement [TICKET-ID])`, carrying the standard
   `**TRACKER ITEM**:` and `**Epic Link**:` fields.
5. **HALT and wait for the developer's manual fix.** Do not resume, re-attempt, reroute, or skip the gate on your own
   initiative. The developer fixes the problem manually and types `ticket-implement <TICKET-ID>` again; that hand-back
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
- **Work unit** = this ticket, **Branch** = the branch it stays on (on its enhancement branch);
- **HOW TO FIX IT YOURSELF** steps 1, 2, 4, 5 and **Please do NOT** taken from the Section 3 playbook row
  for the exhausted SH-LOOP, with real commands resolved from `tests/.evals/config.json` and real
  evidence paths;
- **resume keyword** = `ticket-implement <TICKET-ID>`.

It tells the developer exactly what is failing, why the framework stopped, what the three attempts
changed (left in the working tree), how to reproduce and fix it themselves, what the gates will reject,
and how to hand the work back. It asks the developer to fix it manually and offers no options. The
hand-back grants a fresh budget for the halted loop only; every other loop keeps the counter it already
held.

---

# PHASE A — Analysis (trimmed Planning + design)

## Step 0 — 🔴 Execution-Context Check (MANDATORY, before anything else)

Step 14.7's Playwright gate invokes Playwright's own Planner/Generator/Healer via the **Agent tool**. **A fork, or any subagent instructed "do NOT spawn subagents / you ARE the fork, execute directly", cannot call it** — the gate is then structurally impossible regardless of what is installed. Determine whether this run can call the Agent tool: if it **cannot**, announce it now (` This run cannot call the Agent tool — a UI enhancement will HALT at Step 14.7; run it from a normal session instead.`), log it in `runtime-artifacts/audit.md`, and continue. 🔴 **It is NEVER a reason to hand-author Playwright specs** (`implementation/code-generation.md` Step 11d Part B catch-all) — a UI enhancement halts and is re-run from a context that can invoke subagents.

## Step 1 — Ticket Capture

1. **Resume check first**: if `runtime-artifacts/aire-state.md` exists, read it. If `## Tracker` records a DIFFERENT ticket/epic, ask the user which to keep — NEVER silently overwrite. If it records this same ticket with `Workflow Type: enhancement`, resume from the recorded stage per `common/session-continuity.md`. If `## Tracker` doesn't exist yet, ask the Tracker Selection question (`common/tracker-sync.md` Section 1) first.
2. Dispatch on `## Tracker` → `Type`, per `common/tracker-sync.md` Section 8:
   - **JIRA/ADO/GITHUB**: parse the `<TICKET-ID>` from the invocation (key/ID/number or URL). If missing, ask for it and wait. Fetch the ticket (`getJiraIssue` / `az boards work-item show` / `gh issue view`) — issue type **Story or Task** (a Bug should go through `bug-fix` instead — warn if it's a Bug and confirm before continuing). Save summary, description, and acceptance criteria to `spec/plans/enhancement-brief.md`.
   - **LOCAL**: no ID expected. Ask ` Describe the enhancement (what should change, and why):`, capture the answer, and mint a local ID `ENH-LOCAL-N` (next unused N found by scanning `runtime-artifacts/aire-state.md`) to use as `<TICKET-ID>` for the rest of this flow. Write the captured description directly to `spec/plans/enhancement-brief.md`.
   The enhancement-brief is the intake brief: it defines WHAT to enhance and is the primary input to every later stage.
3. Record in `runtime-artifacts/aire-state.md`:
   ```markdown
   ## Tracker
   - Type: JIRA
   - Workflow Type: enhancement
   - Parent Ticket: PROJ-456        (the enhancement being built — issue type: [Story/Task]; or ENH-LOCAL-N for LOCAL)
   - Ticket URL: https://<site>.atlassian.net/browse/PROJ-456   (— for LOCAL)
   - Project Key / Repo / Org: PROJ (derived from the key — confirm before first use; — for LOCAL)
   - Parent Epic: none              (enhancement flow — all Parent-Epic sync steps are skipped)
   ```
   `Workflow Type: enhancement` is the marker every resumed session reads FIRST — it routes execution to this workflow's rules.
4. **MANDATORY**: Log the invocation (complete raw input) and the ticket fetch/capture in runtime-artifacts/audit.md.

## Step 2 — Workspace Detection + Enhancement Branch (branch FIRST, before requirements)

1. Execute `planning/workspace-detection.md` Steps 1–4 as written (workspace scan, brownfield/greenfield, RE-artifact search anywhere in the repo, state file creation). An enhancement is expected to be **brownfield**; if the workspace is empty, STOP and suggest the full epic flow instead.
2. **Create the ENHANCEMENT branch (automatic)** — same single-branch model as the bug flow (`common/branching-strategy.md` Bug Branch Model), with the `enhancement/` prefix:
   - Record the **base branch** (`git branch --show-current` — never assume `main`).
   - Create `enhancement/<TICKET-ID>-<kebab-case-ticket-title>` (whole name ≤ 60 chars; working tree must be clean, else show `git status` and ask).
   - Record in `runtime-artifacts/aire-state.md`:
     ```markdown
     ## Branching
     - Base Branch: main
     - Enhancement Branch: enhancement/PROJ-456-export-to-csv
     - Enhancement PR: (pending — raised at the end after code review approval)
     ```
   - **ALL work — docs and code — happens on this ONE branch.** No story branches are ever cut.
3. Log the branch creation (name, base) in runtime-artifacts/audit.md; present the Workspace Detection completion message and proceed automatically.

## Step 3 — Reverse Engineering (CONDITIONAL — as-is)

Exactly per the epic flow: if RE artifacts exist anywhere in the repo (or restorable from `aire-archives/`), reuse them and skip. Otherwise run `planning/reverse-engineering.md` in full, with its approval gate. Log everything in runtime-artifacts/audit.md.

## Step 4 — Requirements Analysis (as-is, enhancement-scoped)

1. Execute `planning/requirements-analysis.md` with `spec/plans/enhancement-brief.md` as the primary input. Depth will usually be **minimal/standard** (the ticket defines the enhancement); use comprehensive only if it is genuinely complex or high-risk. Its Step 1.5 reads the `## Context Project` answer captured by `ticket-implement` (Step 3.5) and, if `Existing Knowledge: Yes`, uses **only** the recorded path as background context about the existing system — do NOT re-ask.
2. Extension opt-ins are presented as usual; Security Baseline is always enforced.
3. **Wait for explicit approval** of requirements.md.
4. On approval: commit the planning artifacts on the **enhancement branch**. 🔴 **Do NOT raise a PR here** — the single `[ENH]` PR is raised at the end, after code review approval.
5. **MANDATORY**: Log the user's response verbatim in runtime-artifacts/audit.md.

## Step 5 — Impact Analysis (NO AI-Origin Detection)

**Purpose**: Find WHERE the enhancement lands — the files/components to change and the blast radius — for an accurate implementation plan.

1. Using the RE artifacts, the enhancement-brief, and code search (grep/glob/read), identify the **affected files/components**: where the new behavior plugs in, what must change, and the blast radius (callers, consumers, shared files, tests). Cite explicit **`file:line-range`** evidence per touch point.
2. Write `spec/plans/impact-analysis.md`:
   ```markdown
   # Impact Analysis — [TICKET-ID]
   ## Change Approach
   [Where the enhancement plugs in and why, with file:line evidence]
   ## Affected Files
   | File | Why it must change |
   |------|--------------------|
   ## Blast Radius
   [Callers/consumers/tests that could be impacted by the change]
   ```
3. ** AUTOMATIC — no approval gate.** Present the Impact Analysis summary as an **announcement** and proceed straight to Step 6 — do NOT ask for approval and do NOT block. The analysis is evidence-based (`file:line` citations), is re-validated against current code at Step 11.2, and is re-surfaced inside the announced implementation plan (Step 11). Log in runtime-artifacts/audit.md that it was completed and auto-approved, with the affected-file list. If the user volunteers a correction, update `spec/plans/impact-analysis.md`, re-announce, and continue (an interrupt, not a gate). This document is the primary planning input for the implementation phase.

## Step 6 — Single Story (replaces User Stories + Dependency Graph)

1. Write **exactly ONE story** to `spec/plans/stories.md`, derived from the ticket + requirements + impact analysis: story ID `1.1`, title = the enhancement, acceptance criteria from the ticket (plus regression-safe), and a `**Covers**: REQ-F-xx, …` line naming the REQ-IDs assigned in the enhancement-scoped `requirements.md` (`common/requirements-traceability.md` Rules 2 & 7) — coverage must be complete: every REQ-ID from that requirements.md maps to this one story. Do NOT ask team size, do NOT generate extra personas, do NOT ask about pushing to the tracker (the ticket already exists, or for LOCAL never existed externally — no new issue is ever created), do NOT create `dependency-graph.yml`.
2. Populate the Story Tracker in `runtime-artifacts/aire-state.md` with the single row (Tracker ID column = the existing enhancement ticket — the Tracker Sync Rule applies to it at every status change):
   | Story | Title | Requires | Tracker ID | Status | Start | End | Recorded |
   |-------|-------|----------|------------|--------|-------|-----|----------|
   | 1.1 | [Enhancement title] | none | PROJ-456 (or ENH-LOCAL-N for LOCAL) | Ready for Development | | | [timestamp] |
3. **Wait for explicit approval** of the story; log the response verbatim.

## Step 7 — Workflow Planning (as-is)

Execute `planning/workflow-planning.md`: determine which Implementation design stages EXECUTE/SKIP for this enhancement (small enhancements skip most design stages), generate the execution plan + visualization (validate Mermaid), **announce it, and proceed automatically** — that file's Step 9/10 are an announcement, not an approval gate. Each design stage the plan selects still runs its own approval when it executes.

## Step 8 — Implementation Design Stages (CONDITIONAL, as-is)

Run the system-level design stages the plan selected (Functional Design → NFR Requirements → NFR Design → Infrastructure Design), each per its rule file with its standardized 2-option completion message and approval gate. Scope each to the enhancement-brief + impact analysis.

**Rubric derivation, `architecture.md`, and CI pipeline generation now happen at Step 8.5 (STOP CHECKPOINT), immediately below, once the last design stage completes (or all were skipped).**

## Step 8.5 —  STOP CHECKPOINT: `architecture.md`, `behavior.feature`, rubrics, the enhancement's behaviour spec + manual test plan, CI Pipeline (CONDITIONAL)

**Purpose**: this enhancement gets the SAME project-level bootstrap the epic flow gets at its own STOP
CHECKPOINT (CLAUDE.md) — scoped to ONE enhancement instead of a whole epic. **CI setup is now conditional** on
`## CI Setup Status` (detected, and — when missing — asked, at `ticket-implement` Step 1.5):

- **If CI Setup EXISTS** (established AIRE project): Skip full CI setup + smoke test (Section 5 below). Architecture and rubrics proceed normally.
- **If CI Setup MISSING** (new repo, user opted IN at the Step 1.5 question): Run full CI setup with smoke test (current behavior).
- **If CI Setup DECLINED** (new repo, user opted OUT at the Step 1.5 question): Skip full CI setup + smoke test — same as EXISTS, but announced as declined. Architecture and rubrics still proceed normally. `## CI/CD Configuration` records `Enabled: No`, which this workflow also reads to skip its own CI Preflight and CI Attestation gates.

**Load `common/behavior-spec.md`, `implementation/architecture-doc.md`, `implementation/specs-and-test-plans.md`.** Load `common/ci-pipeline-generation.md`
**only if `## CI Setup Status` is "missing"** (i.e. the user opted in) — never for `exists` or `declined`.

Every artifact below is **create-if-missing, never regenerate** (`common/directory-structure.md`
Artifact Ownership): if it already exists in the repo — inherited from a prior epic/bug/enhancement
cycle — reuse it AS-IS and say so; only a genuinely absent artifact gets created here.

1. **MANDATORY**: Log reaching this checkpoint in audit.md.
2. ** `spec/behavior.feature`** — if absent, create it per `common/behavior-spec.md` Section 3 (the
   cross-story journeys that belong to no single unit, tagged `@REQ-<id>`). This enhancement's OWN
   behaviour contract is the separate `spec/behavior/enhancement-<TICKET-ID>.feature` written at Item 4.5
   below — never conflate the two. A single-work-unit cycle will typically have no genuine cross-unit journey
   yet; record that explicitly rather than leaving the file empty or copying this enhancement's own
   scenario into it.
3. ** `spec/plans/architecture.md`** — if absent, write it per `implementation/architecture-doc.md`,
   consolidating whichever Step 8 design stages ran (small enhancements skip most of them — say so
   explicitly, never invent a decision) plus the reverse-engineering/Atlas artifacts as the
   existing-system baseline. Section 10 Verifiable Constraints is mandatory: 3–8 constraints, weights
   summing to 1.0, each traceable to an approved design artifact or Atlas truth. Version it and log it
   in audit.md.
4. ** Rubrics** — derive `tests/.evals/rubrics/architecture-rubric.json` **mechanically from
   `architecture.md` Section 10** (one constraint, one criterion, `rubricVersion` equal to the
   `architecture.md` version) per `implementation/architecture-doc.md` Section 4 and
   `common/eval-framework.md` Section 3. Only when Section 10 ends up genuinely empty (no design stage
   ran and no Atlas truth exists) does the Section 3 **fallback chain** apply (the latest
   archived rubric → the reverse-engineering artifacts → J1 recorded `N/A`) — record which link was
   used. 🔴 Never hand-write a generic rubric, never score J1 against a borrowed/unrelated one. Create
   `tests/.evals/rubrics/security-rubric.json` (OWASP-based, `implementation/architecture-doc.md` Section
   4.1) and `tests/.evals/config.json` (eval-framework.md Section 1 template) if absent. Log in runtime-artifacts/audit.md.

4.5. ** THE ENHANCEMENT'S BEHAVIOUR SPEC + MANUAL TEST PLAN (MANDATORY — ONE approval gate, before any
   code)** per `implementation/specs-and-test-plans.md`. These are the LAST design artifacts of the
   cycle and the last thing written before any code exists. For this one ticket:
   - **(a)** `spec/behavior/enhancement-<TICKET-ID>.feature` per `common/behavior-spec.md` Section 2 — one
     Gherkin scenario per acceptance criterion, `@AC-n` tagged, failure paths included. Authored
     BEFORE the implementation because it is the contract, not a description of what was built.
     🔴 That is the ONLY spec file this work unit gets.
   - **(b)** `spec/test-plans/<TICKET-ID>-<title>/` by **invoking the `ve-implement` skill in WORKFLOW
     MODE** with this ticket (`agents/ve-implement-agent.md` Mode Detection — no story-picker, no
     `ve/…` branch, no approval checkpoint, no push/PR). Never re-implement its steps inline. The
     generated files ride the ve HANDOFF BREAK commit (Item 1 there).
   - **Blocking coverage check**: every acceptance criterion has ≥ 1 Gherkin scenario AND ≥ 1 manual
     test case. A gap is fixed here, not deferred.
   - **Then present the standardized 2-option completion message and WAIT** for `Request Changes` /
     `Continue to Next Stage` — DO NOT proceed to Section 5 or the ve HANDOFF BREAK until the user
     confirms. Log the prompt and the complete raw response in runtime-artifacts/audit.md.
   🔴 This is scope derivation, NOT ve's sign-off — ve still runs `/ve-implement` and `ve-list-work`
   independently, and only `ve-list-work` can approve a test plan or move the ticket to Ready for Testing.

### 8.5 Section 5 — CI Pipeline Setup (CONDITIONAL on CI Setup Status)

**IF `## CI Setup Status` = "missing"** (new repo, no AIRE-Helix CI yet, user opted IN):

Run the full CI setup with smoke test:

🔴 **No scope question before or during this generation.** Load and generate per
`common/ci-pipeline-generation.md` exactly as it specifies, unconditionally — never pause to ask the
user to characterize this as "minimal"/"full"/"defer" or present any menu/confirmation about it. The
job's size (many files, a long template, many checks) is not a reason to gate it. The **only**
sanctioned halt in this entire step is the Section 4.1.2 SonarQube setup gate below, presented
verbatim — nothing else in Item 5/6 blocks on the user.

5. ** CI Pipeline** — if `.github/workflows/agentic-eval-pipeline.yml` is absent, generate it per
   `common/ci-pipeline-generation.md`: every command from the repo's real build files, every threshold
   from `tests/.evals/config.json`. **🔴 VALIDATE BEFORE COMMITTING (Section 4.0)**: YAML parses, `actionlint`
   clean, every referenced script exists. An invalid workflow is NEVER committed. **SonarQube**:
   generate `sonar-project.properties`, present the Section 4.1.2 setup gate, and **HALT for `proceed`
   or `skip`** — never write a token into any file. Also generate (if absent)
   `tests/.evals/scripts/run-static-evals.*`, `run-evals.*`, `auto-fix-agent.*`, `validate-pipeline.*`,
   `smoke-test-epic.*`, and `tests/.evals/behavior/{Containerfile,run.sh}`. 🔴 Everything commits on the
   **enhancement branch** — never pushed to base, never a separate `[CI]` PR; it reaches base when the
   `[ENH]` PR merges.
6. **🧪 Run the pre-handoff smoke test** per `common/ci-pipeline-generation.md` Section 4.0.6 (automatic, with auto-merge).

**IF `## CI Setup Status` = "exists"** (established AIRE project with CI already set up):

Skip Section 5 entirely. Announce: "CI infrastructure already exists — skipping full setup. Proceeding with analysis + design artifacts only."

**IF `## CI Setup Status` = "declined"** (user opted out of CI/CD at the `ticket-implement` Step 1.5 question):

Skip Section 5 entirely. Announce: "CI/CD setup was declined for this ticket — skipping pipeline generation. Proceeding with analysis + design artifacts only." No `.github/workflows/agentic-eval-pipeline.yml`, `sonar-project.properties`, or `tests/.evals/scripts/*` are generated.

---

# ve HANDOFF BREAK →  Implementation Checkpoint (ask, don't stop)

After the design stages complete (or are all skipped), mark in `runtime-artifacts/aire-state.md`: `Analysis complete — awaiting implementation approval`, log in runtime-artifacts/audit.md.

**This is a deliberate BREAK in the flow.** The analysis + design artifacts are everything the ve needs, and the ve must not have to wait for the code. So before Phase B:

1. **Commit + push the analysis, design and STOP CHECKPOINT artifacts on the enhancement branch (automatic — this is what unblocks ve)**: stage `spec/**` (enhancement-brief, requirements, impact analysis, the single story, `architecture.md`, `behavior.feature`, **Item 4.5's `spec/behavior/enhancement-<TICKET-ID>.feature` and `spec/test-plans/<TICKET-ID>-<title>/`**), `spec/plans/**`, `tests/.evals/**` (rubrics, config, scripts, `behavior/`), PLUS `.github/workflows/agentic-eval-pipeline.yml` and `sonar-project.properties` **only when `## CI Setup Status` is `exists` or `missing` (opted in)** — never when `declined`, since neither file exists — the updated `runtime-artifacts/aire-state.md` and `runtime-artifacts/audit.md`; commit on the enhancement branch with an `AIRE-Version: [N]` trailer (`[N]` read live from `CLAUDE.md`); push to origin. Announce the commit hash + pushed branch and log both in audit.md. 🔴 If the push fails, say so explicitly and tell the user to push manually — **the Verification Engineer cannot start until this branch is on origin**. Still no `[ENH]` PR here. This step ALWAYS runs, regardless of `## CI Setup Status` — it is what unblocks ve and is unrelated to whether CI infrastructure already exists.
2. **🧪 Pre-handoff smoke test — CONDITIONAL on `## CI Setup Status` (recorded by `ticket-implement` Step 1.5 / `common/ci-setup-detection.md`)**:
   - **IF `## CI Setup Status` = "missing"** (automatic; HARD HALT on exhaustion): per `common/ci-pipeline-generation.md` Section 4.0.6, run `tests/.evals/scripts/smoke-test-epic.{sh,ps1}` against the enhancement branch + `[TICKET-ID]` just pushed (the script takes any integration branch and ticket ID — "epic" is just its filename). This proves the environment is viable (installs cleanly, the existing test suite runs, self-repair itself works) via a zero-diff scratch PR — it is NOT proof this enhancement's own gates are correct, only that the environment they run in is. On a pass, the scratch PR merges and deletes automatically, logged in audit.md. On exhaustion, the scratch PR is left open and **the break message below does NOT get presented** until the user resolves it — report with the standard Retry-Limit Report format. This runs exactly once per enhancement cycle, here — never again for this ticket.
   - **IF `## CI Setup Status` = "exists"** (established AIRE project — CI infrastructure, including `smoke-test-epic.*` itself, was already validated in a prior cycle): **SKIP this smoke test entirely — do not run it, do not ask about it.** Announce: "CI infrastructure already exists — skipping the pre-handoff smoke test." Log the skip (with the CI Setup Status detection timestamp/files it was based on) in audit.md, and proceed straight to the break message. 🔴 Skipping the smoke test does NOT skip or shortcut anything else in Step 8.5 or this section — `architecture.md`, `behavior.feature`, the rubrics, and this step's own commit/push (Item 1) still happen exactly as written.
   - **IF `## CI Setup Status` = "declined"** (user opted out at the Step 1.5 question): **SKIP this smoke test entirely — there is no pipeline to validate.** Announce: "No CI/CD pipeline for this cycle (declined) — skipping the pre-handoff smoke test." Log the skip in audit.md and proceed straight to the break message. `architecture.md`, `behavior.feature`, the rubrics, and Item 1's commit/push still happen exactly as written.
3. Present the break message below and **block on its yes/no**.

```markdown
# Enhancement Analysis Done — Design Artifacts Pushed

 **Ticket**: [TICKET-ID] — [title]
 **Impact**: [N] files identified in spec/plans/impact-analysis.md
 Design stages: [list which ran vs were skipped]
 Behaviour spec + manual test plan: `spec/behavior/enhancement-[TICKET-ID].feature` and `spec/test-plans/[TICKET-ID]-[title]/`,
   approved at this checkpoint, so the contract and the test plan exist before a line of the code does.
 Branch: enhancement/[TICKET-ID]-[title] (cut from [base branch]) — analysis + design **committed and pushed** ([commit hash])

> **<u>Verification Engineer — the manual test plan is already on the enhancement branch.</u>**
> `spec/test-plans/[TICKET-ID]-[title]/` was generated and approved at this checkpoint. Once the
> enhancement code is generated and on the enhancement branch, verify it by executing this test plan,
> then use `ve-list-work` to approve or reject the ticket.

> ** <u>**DEV — continue with the implementation plan and code generation**</u>**
> **Ready to implement now? (yes / no)**
> **yes** → everything below runs automatically, with no further questions:
> baseline regression → implementation plan (announced) → code + unit
> tests (the `unitTestCoverageMin` threshold) → FULL regression → auto code review, with any findings
> auto-remediated and re-reviewed until clean (max 3 rounds) → `[ENH]` PR to
> [base branch] → auto PR review → then STOP (the cycle archive is MANUAL — you run
> `archive-epic` after the Verification Engineer has signed the enhancement off on the enhancement branch).
> **no**→ I halt here; the state is saved. Resume any time with `ticket-implement [TICKET-ID]`
> (or `enhancement-implement [TICKET-ID]`) and it picks up at this gate.

Use the keywords EXACTLY as shown — do not describe what you want in your own words. Any other
   phrasing is not a framework trigger and the workflow will not advance.
```

**Block until the user answers.** On **no**, halt here (state is saved — re-invoking `enhancement-implement <TICKET-ID>` or `ticket-implement <TICKET-ID>` resumes at this gate). On **yes**, log the response verbatim and continue to Phase B. Substitute every placeholder (`[TICKET-ID]`, `[base branch]`, `[commit hash]`) with real values — never ship a placeholder to the user.

---

# PHASE B — Implementation (same flow, after "yes")

> **▶ Resume after a pause or halt**: a `PAUSED —` record (Playwright agent install restart — Step 11.4 readiness or the Step 14.7 safety net) → continue at the
> step it names, skipping everything already done. When `ticket-implement <TICKET-ID>` resumes this flow and
> `runtime-artifacts/stories/enhancement-<TICKET-ID>/state.md` `## Progress` holds a `HALTED —` record (a
> self-healing limit or a tool-installation halt), the developer is **handing the work back**: follow
> `common/self-heal-limit-guidance.md` Section 4 — check the manual change, reject forbidden shortcuts,
> keep the developer's code, fresh budget for the halted loop only — skip Steps 9–11 (already claimed,
> baselined and planned), and re-run from the first code gate (Step 13) — or from the halted gate for
> declaration-only changes — through Step 19.


## 🔴 PARALLEL-SAFE STATE — THIS PHASE WRITES ONLY ITS OWN FRAGMENT (`common/parallel-work-state.md`)

The ve works in parallel on `ve/…` branches whose PRs merge into this same integration branch, and
`pr-fix` may later add commits to this PR. So that none of them conflict on the framework's bookkeeping,
**Phase B never writes the shared `runtime-artifacts/audit.md` or `runtime-artifacts/aire-state.md`**:

- Every audit entry this file tells you to append to `runtime-artifacts/audit.md` goes to
  **`runtime-artifacts/stories/enhancement-<TICKET-ID>/audit.md`** (same format, plus `**Unit**: "enhancement-<TICKET-ID>"`).
- Every write to the ticket's Story Tracker row, its progress or its SH counters goes to
  **`runtime-artifacts/stories/enhancement-<TICKET-ID>/state.md`** (`## Story Tracker Row`, `## Progress`,
  `## Self-Healing Counters`).
- This overrides every mention of those two shared paths below. Reads use the **resolved view**
  (`common/parallel-work-state.md` Section 4); a `PR: pending` is resolved live from the branch.
- 🔴 **State Isolation Check before every commit** (Step 16, and any `fix(ci)` commit): every changed
  path under `runtime-artifacts/` must be inside `runtime-artifacts/stories/enhancement-<TICKET-ID>/`; anything else is
  moved into the fragment and the shared file restored to the merge-base (Section 5.5).
- Do not push a commit only to record the PR URL — it rides the next commit (Section 4.6).

(Phase A above ran before the ve handoff, as the only writer on the enhancement branch, and wrote the
shared files; from Step 9 onward the fragment rule applies.)

## Step 9 — Ticket → In Development (automatic)

The user's "yes" IS the claim. Without asking, dispatch on `## Tracker` → `Type` per `common/tracker-sync.md` Section 4/Section 5/Section 9:
1. Story Tracker (single row): Status → `In Development`, Start + Recorded timestamps set.
2. Transition the ticket to the tracker's "In Development" state/label (non-LOCAL): **JIRA** — resolve the actual transition via `getTransitionsForJiraIssue` → `transitionJiraIssue` (never hardcode the state name); **ADO** — `az boards work-item update --state "Active"`; **GITHUB** — swap the status label to `status:in-development`. **Verify it landed**, announce it, log in runtime-artifacts/audit.md. **LOCAL**: no external call.
3. **Assign the ticket to the operator (automatic — same claim)** — then write the fragment's `## Claim` block (`common/parallel-work-state.md` Section 3.2) from the verified transition and assignment results; the guard refuses the commit without it: read the session **email** LIVE from the session context, then **JIRA**: resolve via `lookupJiraAccountId` + `editJiraIssue`; **ADO**: `az boards work-item update --assigned-to "<session-email>"`; **GITHUB**: a cached GitHub username + `gh issue edit --add-assignee`; **LOCAL**: no assignee concept, skip. **Verify** (non-LOCAL) by fetching the issue back. Unresolvable/ambiguous identity → leave unassigned, warn, continue (non-blocking). Announce and log in runtime-artifacts/audit.md.
4. **Add the AIRE version label/tag** `aire-v[N]` to the ticket per `common/tracker-sync.md` Section 9 (JIRA label / ADO `System.Tags` / GitHub label / LOCAL a note on the local entry), `[N]` read at runtime from the "AIRE Framework Version" line in `CLAUDE.md` — never hardcoded. Skip if already present. Verify (non-LOCAL), announce, log.
5. 🔴 Skip all Parent-Epic sync steps — `## Tracker` records `Parent Epic: none`.

## Step 10 — 🧪 BASELINE Regression Run (BEFORE any change)

Same as the bug flow: discover and run the **entire repo's unit test suite** with no code changes yet; save the raw output to `reports/unit-test-evidence/enhancement-<TICKET-ID>/baseline-regression.log` (`common/work-unit-artifacts.md` E1) and record the baseline (commands, results, pre-existing failures) in `reports/ticket-summary/enhancement-<TICKET-ID>-summary.md`; pre-existing failures are logged, not fixed. Log in runtime-artifacts/audit.md. If the repo has no test suite, record that explicitly.

** BASELINE STATIC EVAL RUN (MANDATORY, AUTOMATIC — same moment, before any change)**: also run the **Static Eval Gate checks D1–D7** per `common/eval-framework.md` Section 2 (lint, type check, SAST, dependency vulnerabilities, licences, complexity, secrets) and save the raw output to `reports/eval-evidence/enhancement-<TICKET-ID>/static/baseline/`. Exactly like the regression baseline: **every finding is pre-existing debt, not this enhancement's** — logged, not fixed, never blocking; it exists only so Step 14.5 can tell this change's findings apart.

** BOOTSTRAP FIRST (eval-framework.md Section 2.3, MANDATORY — same step, immediately BEFORE the baseline run)**: for every check with **no config in the repo**, create the minimal *recommended* config (eslint/ruff/golangci, tsconfig/mypy, `.gitleaks.toml`, the linter's complexity rule at the `tests/.evals/config.json` threshold) so the check is actually runnable. **A check whose config exists is used AS-IS** — the repo's own standards win, never overridden. Announce every file created and log it (`bootstrap` block of `eval.json`) — it adds files to the user's repo, so it is never silent; those files commit with the enhancement. 🔴 **AND INSTALL THE TOOLS — retried, never skipped (Section 2.4.1)**: for every gate, work the chain *already present → package manager → alternative installer → **OCI image via Podman***, 3 attempts per rung, verifying each install with a version command. Recording a gate `N/A` for a missing tool **before the Podman rung has been tried** is a bootstrap failure, not an `N/A`. If the whole chain is exhausted, **HALT with the per-rung report** — never continue with an unmeasured gate, and never phrase deferred setup as `N/A` ("not wired yet", "not installed", "not enabled yet" — all ERROR, Section 2.5.2).

🔴 **A MISSING TOOL IS NEVER A QUESTION.** Observed in a real run: the workflow reached D1/D5/D6 with no linter, licence scanner or complexity tool configured for the stack, and **asked the user** *"How should I handle the remaining static-eval gaps?"* with a recommended option. That is a double violation — this workflow asks nothing after the story key, and a tooling gap already has a defined answer: **run the Section 2.4.1 bootstrap chain** (already present -> package manager -> alternative installer -> **OCI image via Podman**), 3 attempts per rung. If the whole chain is exhausted, **HALT with the per-rung report** — which is a halt, not a question, and never a proposal to skip the gate. Emit it as the **"A check can't run" message in `common/self-heal-limit-guidance.md` Section 5** (what was tried per rung, the install command to run by hand, how to hand the work back) and record the halt in `## Progress` so the resume protocol picks it up. 🔴 Never ask the user to choose between closing a gate and deferring it; deferring is not on the menu (Section 2.5.2).
- 🔴 **ORDER MATTERS**: bootstrap → baseline → implement → Step 14.5 → diff. A config created AFTER the baseline would make both runs measure under **different rules**, blaming this change for findings on pre-existing code.
- 🔴 Recommended presets, never strict/all, and **never a config that pre-suppresses findings**.
- 🔴 A check is recorded `N/A` **only after the full Section 2.4.1 install chain — including the Podman image rung — has been attempted and recorded**, and only for a reason on the Section 2.5.1 closed list (inapplicable to this stack / to this work unit / no such tool exists). If the chain is exhausted, that is an **ERROR: HALT** with the per-rung report — never `N/A`, never silently skipped, and never phrased as deferred work ("not wired yet", "not installed", "not enabled yet").

**🧪 BASELINE PLAYWRIGHT E2E REGRESSION RUN (MANDATORY, AUTOMATIC — same moment, before any change)**: also run the **ENTIRE existing `tests/e2e/` Playwright suite** with no code changes yet, saving the raw output to `reports/playwright-test-evidence/enhancement-<TICKET-ID>/regression/playwright-baseline-regression.log` plus the **mandatory machine-readable** `playwright-baseline-report.json`. **No user prompt — capture it and continue.**

- **Why**: this is the UI counterpart of the unit baseline above. Step 14.7 only proves **this enhancement's own** new specs pass; nothing else proves the change did not break a browser flow an earlier work unit already shipped. Without a pre-change photograph there is no way to tell "this change broke it" from "it was already red".
- 🔴 **Applies to EVERY enhancement, UI or not — do NOT skip it because the change touches no UI.** A backend handler, a changed response shape, a renamed field or a migration is exactly what silently breaks an existing browser flow, and that is the case this baseline exists to attribute correctly.
- **Start the app the same way Step 14.7 does** — the `startCommand`/`readinessUrl` in `tests/.evals/config.json` `ci.playwright` (plus the backend pair when two processes are needed), resolved from the project's own scripts, **never invented**; tear it down on every exit path.
- **Run headless** — a deliberate carve-out from Step 14.7's `--headed` rule, which exists so the developer can watch newly authored specs. This is a bulk sweep of already-approved specs; record `"headed": false, "reason": "bulk regression sweep, not the authoring gate"`.
- **Failures here are pre-existing** — logged, never fixed, never blocking. They define "already red" so Step 14.8 can attribute correctly.
- **`N/A` only when there is nothing to regress**: `tests/e2e/` holds no specs at all (no earlier work unit generated any). Record the reason — 🔴 never a silent skip, and never `N/A` merely because *this* enhancement has no UI.
- **Specs exist but Playwright is not installed on this machine** (a fresh clone, a new developer): install it now — the project's dependencies (`npm ci` or equivalent, which brings `@playwright/test` when it is a dev dependency) and the browsers (`npx playwright install`) — announced, never asked, then run the sweep. 🔴 A missing runner or browser is never a reason for `N/A`; only an empty `tests/e2e/` is. The official test agents are not needed for this sweep.
- 🔴 **ORDER MATTERS here too**: baseline → implement → Step 14.7 → Step 14.8 → diff. A baseline captured after the change measures the changed system and can attribute nothing.

## Step 11 — Implementation Plan ( announced, not gated)

1. Build the plan from `spec/plans/impact-analysis.md` + the design artifacts, using `code-generation.md`'s Part 1 planning format (checkboxed steps), ending with the mandatory Unit Test & Coverage step, the API & Contract Testing Gate (Step 13.5, when the enhancement touches an API endpoint), and the Full Regression Gate (Step 14). ** GROUND THE PLAN in the previously generated docs** — every step MUST trace back to the ticket's acceptance criteria, `spec/plans/enhancement-brief.md`, `requirements.md`, the impact analysis, and any design artifacts; never invent scope, files, or behavior not backed by them. ** REQ-ID THREAD**: tag every plan step with the REQ-ID(s)/AC(s) it implements and self-check that every REQ-ID from `requirements.md` and every AC of the single story appears in ≥1 step before presenting the plan (`common/requirements-traceability.md` Rules 5 & 7).
2. **Re-validate the impact analysis against current code.** If the plan must touch files NOT in the impact analysis, add them to `spec/plans/impact-analysis.md` first .
3. ** Announce the plan and proceed — NO approval gate**:
   1. **Log the finalized plan** in `runtime-artifacts/audit.md` (ISO 8601 timestamp) under a **plain heading** — e.g. `## Implementation Plan — Finalized (auto-approved, no gate) (Enhancement [TICKET-ID])` — with the plan path, the step count and the REQ/AC trace summary. **The word "GATE" must NOT appear in the heading.**
   2. Present the plan as an **announcement** (NOT a question):
      ```
       Implementation plan ready for Enhancement [TICKET-ID] — [N] steps.
      Plan: spec/spec-generation/enhancement-generation.md
      Generating the enhancement now (Step 12).
      ```
   3. **Do NOT wait for a response** — go straight to Step 12. If the user volunteers a change to the plan, apply it, update the plan document, announce the revision, log it, and continue (an interrupt, not a gate).

## Step 11.4 — 🎭 Playwright Readiness (MANDATORY WHEN the implementation plan is frontend — automatic, before any code)

**Applies only when this enhancement's code-generation plan (Step 11) contains a _Frontend Components Generation_
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
   `PAUSED — Playwright agents installed — resume at Step 11.5 — <timestamp>` in the work unit's
   `## Progress` and emit, as the run's last output:
   ```
   Playwright is now set up for this frontend enhancement.
      Installed:  <what was installed>
      One step is needed: restart Claude Code so it loads Playwright's test agents, then type ticket-implement <TICKET-ID>.
      I will continue from Step 11.5. The plan and the baselines are kept, and no code has been
      written yet.
   ```
   Typing `ticket-implement <TICKET-ID>` in the new session finds the `PAUSED —` record and continues at Step 11.5, skipping
   everything already done. Everything already installed → no pause.
6. **Install fails** after the full install chain → emit the "A check can't run" message
   (`common/self-heal-limit-guidance.md` Section 5) for Playwright, record `HALTED —`, nothing changed.

Because this runs here, the Playwright UI gate (Step 14.7) finds Playwright ready; its own install
handling remains only as a safety net.

## Step 11.5 —  Verify the Behaviour Spec (MANDATORY — before any code)

`spec/behavior/enhancement-<TICKET-ID>.feature` was **already written and approved** at Step 8.5 Item 4.5 (`implementation/specs-and-test-plans.md`) and is already committed on the enhancement branch. This step **READS** it — it does not author it. Confirm the file exists, parses, and carries one `@AC-n`-tagged scenario per acceptance criterion.

**Backfill only if genuinely absent** (legacy project, or a ticket that skipped the checkpoint): write it now per `common/behavior-spec.md` Section 2 and **announce the backfill explicitly** (`Behaviour spec for <TICKET-ID> was missing from the approved set — generated now at spec/behavior/enhancement-<TICKET-ID>.feature`).

🔴 **NEVER rewrite an approved scenario to match the code you are about to generate** — the spec is the contract, and code that cannot satisfy it is the thing that changes. A genuine spec defect is raised with the user, amended and logged; it is never silently edited.

🔴 **That is still the ONLY spec file this work unit gets.** No per-unit requirements, architecture, constraints or deep-dive document. The agent reads the tracker item for acceptance criteria, `requirements.md` for the covered REQ-IDs, `spec/plans/architecture.md` for design constraints, and `tests/.evals/config.json` for thresholds — copying any of that per unit only creates something that can drift.

Announce the file path and the scenario/AC counts. Log the verification (or backfill) in runtime-artifacts/audit.md.

## Step 12 — Generate the Enhancement

Execute the approved plan step by step on the enhancement branch, marking each checkbox `[x]` in the same interaction it completes. ** All application code goes into `src/`** (or the recorded `## Code Root` — `common/directory-structure.md`) and nothing into `spec/`. 🔴 **TESTS GO IN THE REPO-ROOT `tests/` TREE — NEVER UNDER `src/` AND NEVER UNDER THE CODE ROOT**: unit tests -> **`tests/unit/`**, Gherkin step definitions -> **`tests/behavior/steps/`** (the tree `tests/.evals/behavior/run.sh` executes inside Podman), Playwright -> `tests/e2e/`. The `## Code Root` remapping above applies to **application code ONLY** — a brownfield repo whose code lives in `app/` or `packages/api/src` still writes its tests to the repo-root `tests/`, never `app/tests/` or `packages/api/src/tests/`. This is also what the manifest's `testPaths` records (`common/eval-framework.md` Section 1.1) and what the Podman mount and the coverage gate look at, so a test written anywhere else is invisible to both gates. ** PLAN FIDELITY**: implement EXACTLY the announced plan — no unplanned files, features, refactors, or scope drift. If a deviation is genuinely needed, **revise the plan document (Step 11), announce the revision (what changed and why) in your output and in runtime-artifacts/audit.md, and continue** — never applied silently, and never via an approval prompt. Write code to the workspace root per the existing project structure. Log progress in runtime-artifacts/audit.md.

## Step 13 — Unit Tests + Coverage Gate (threshold from `tests/.evals/config.json`)

1. Write unit tests covering all new/changed code, exercising the enhancement's acceptance criteria.
2. RUN them; fix failures; measure coverage on the new/changed code; iterate in the SAME run until **≥90%**.  **This is SH-LOOP-1 — capped at 3 remediation attempts (SH-1). On exhaustion apply SH-4: HALT, emit the Retry-Limit Report, and do NOT proceed below the threshold.**
3. Capture evidence (tests X/X passing + measured %) in `enhancement-<TICKET-ID>-summary.md` and runtime-artifacts/audit.md, with the machine-readable coverage report per dev-implement's evidence rules (`reports/unit-test-evidence/enhancement-<TICKET-ID>/` — `unit-test-run.log`, `coverage/` with the tool's machine-readable report plus `changed-lines-coverage.json`, and `evidence-manifest.md`, exactly as `common/work-unit-artifacts.md` E1 defines).

## Step 13.2 —  Behavioural Test Gate (Gherkin — three tiers)

Execute the tiered behavioural gate defined in `common/behavior-spec.md` Section 4.4. Implement the step definitions in `tests/behavior/steps/`, bound to the application's **public surface** (endpoint / service method / CLI) — never to internals — then run the tiers **in order**:

1. **B1 — Unit scope**: this work unit's own `spec/behavior/enhancement-<TICKET-ID>.feature`. **Verification**: every scenario passes AND every `@AC-n` tag is executed.
2. **B2 — Cumulative scope**: every **other** feature file already in the repo — earlier work units in this cycle plus everything from prior cycles. **Verification**: all green. 🔴 A B2 failure is THIS unit's problem — it turned that scenario red, so it fixes it. "That scenario belongs to another story" is not a defence.
3. **B3 — Epic scope** (🔴 **last work unit of the cycle ONLY**): B1 ∪ B2 **plus** the cross-unit journeys in `spec/behavior.feature`, tagged `@REQ-<id>`. 🔴 Detect "last" from **PR MERGE STATE, never the tracker status label** (`common/behavior-spec.md` Section 6.1): for every OTHER work unit read its PR from the Story Tracker and verify live with `gh pr view <n> --json state`. **All others merged → this is the last unit → RUN B3** — including the normal case where those units are still `In Development` awaiting Verification Engineer sign-off, because the label lags the merge. Defer ONLY when a unit has no merged PR, recording `B3: N/A — not the last work unit: <n> units with unmerged PRs (<list with PR state>)`. 🔴 Never defer on a status label alone, and never report a deferred B3 as a pass.

**Execution** — 🔴 **every tier runs in a Podman pod** (`common/behavior-spec.md` Section 5): the image built from `tests/.evals/behavior/Containerfile`, plus a fresh ephemeral **test database** where the repo needs one, invoked through `tests/.evals/behavior/run.sh <tier>` with **`AIRE_STORY_KEY` exported to THIS work unit's key** (e.g. `story-1.10`, the stem of its own `spec/behavior/<key>.feature`) — `podman run -e AIRE_STORY_KEY=<key> …`. 🔴 Without it B1 cannot identify which unit is under test and refuses to guess; it used to take the lexicographically last feature file, which returns `story-1.9` when `story-1.10` is the unit being built — passing B1 without ever testing it — the same image and command a developer runs locally, so a CI-only failure is impossible by construction. 🔴 **The ONLY permitted native run is Podman not being installed** (proven by `command -v podman`), recorded as `"containerised": false, "reason": "podman not installed"`. 🔴 "No browser needed", "backend only", "no new dependency" and "faster natively" are **forbidden justifications** — a tier recorded that way is a gate violation, not a pass. Never fall back to the Docker CLI. A tier runs only once the previous is green.

**Evidence** — per tier that runs, to `reports/behavior-test-evidence/enhancement-<TICKET-ID>/<b1|b2|b3>/` (🔴 `b3/` is created **only on the last work unit, when B3 actually runs**; a deferred B3 creates no folder — its `N/A` and reason live only in `eval.json` / `eval-summary.md`, `common/work-unit-artifacts.md` Section 1.1): `behavior-test-run.log`, the **mandatory machine-readable** `behavior-test-report.*`, and an `evidence-manifest.md` recording the image ref + digest, the exact command, whether it ran containerised, the tier's feature-file set, and every scenario with its tag and result. A raw log alone does NOT satisfy the gate.

**Self-healing** —  **B1/B2 failures → SH-LOOP-7; B3 failures → SH-LOOP-8, its own separate 3-attempt budget** (an epic-scope failure is usually an integration gap between units, not a bug inside one, so arriving at the epic gate with the story budget already spent must not halt the cycle). Both capped at 3 attempts; on exhaustion apply SH-4 — HALT and emit the Retry-Limit Report.

🔴 **Fix the code, never the scenario.** A scenario changes only when the AC or requirement it encodes genuinely changed — and then the AC, `requirements.md` and the tracker item are amended together and the reconciliation is logged. Deleting, skipping or `@ignore`-ing a scenario to go green is forbidden (SH-6).

**N/A** — B1 is N/A only for a work unit with no externally observable behaviour (pure build-config or docs change); a unit with acceptance criteria is never N/A. B2 is N/A only when the repo genuinely contains no other feature file. Record the reason explicitly.

## Step 13.5 —  API & Contract Testing Gate (MANDATORY WHEN APPLICABLE)

**Applicability (automatic, no question asked)**: applies when the implementation plan (Step 11) adds or changes an API endpoint/route/controller/handler. **If the plan touches no API layer, this gate is N/A** — record that explicitly in `enhancement-<TICKET-ID>-summary.md` and proceed to Step 14.

1. Generate automated tests against the actual new/changed endpoint(s) — via the stack's standard integration-test mechanism (in-process test client or a spun-up test server) — covering, for each endpoint:
   - **Functional / happy path** — the documented behavior per acceptance criterion
   - **Response Code Validation** — correct HTTP status code for every documented success and failure path
   - **Authorization Testing (role-based access)** — unauthenticated → `401`; authenticated with insufficient role → `403`; correct role → success (N/A only for a genuinely public endpoint)
   - **Error Response Validation** — standard error envelope/format and correct error code for each documented error condition
   - **Request Validation** — required fields, data types, and enum constraints on the request payload are enforced (N/A only for an endpoint with no request body)
   - **Response Contract Validation** — the response payload matches its declared schema/contract (required fields, types, enum values)
2. RUN them; fix failures; iterate in the SAME run until every applicable checklist item passes.  **This is SH-LOOP-2 — capped at 3 remediation attempts (SH-1). On exhaustion apply SH-4: HALT and emit the Retry-Limit Report.**
3. Capture evidence (per-endpoint checklist + tests X/X passing) in `enhancement-<TICKET-ID>-summary.md` and runtime-artifacts/audit.md, with proof artifacts saved to `reports/api-contract-test-evidence/enhancement-<TICKET-ID>/` (`api-contract-test-run.log`, the **mandatory machine-readable** `api-contract-test-report.*` — invoke the runner with its report-emitting flag/plugin, e.g. `pytest --junitxml=...` / `jest --json --outputFile=...`; a raw log alone does NOT satisfy the gate unless the runner genuinely has no such capability (documented, surfaced exception) — and `evidence-manifest.md`). This gate is separate from and does not replace ve's `/ve-implement` MANUAL API/Contract test steps.

## Step 14 — 🧪 FULL Regression Gate (after the change)

Re-run the **entire repo's unit test suite** (including any new API & Contract tests from Step 13.5) and compare against the Step 10 baseline — exactly as the bug flow: **new failures** (passing at baseline, failing now) are 🔴 BLOCKING (fix and re-run until zero); pre-existing failures are listed, not blocking. Save the raw output to `reports/unit-test-evidence/enhancement-<TICKET-ID>/full-regression.log` and add the baseline vs post-change counts to that folder's `evidence-manifest.md` (E1).  **This is SH-LOOP-3 — capped at 3 remediation attempts (SH-1). On exhaustion apply SH-4: HALT and emit the Retry-Limit Report.** Append the complete outcome to `enhancement-<TICKET-ID>-summary.md` and log the comparison in runtime-artifacts/audit.md.

## Step 14.5 —  STATIC EVAL GATE — D1–D7 (MANDATORY, AUTOMATIC — after Step 14, before Code Review)

Re-run D1–D7 per `common/eval-framework.md` Section 2, save to `reports/eval-evidence/enhancement-<TICKET-ID>/static/`, and **diff against the Step 10 baseline**. Only findings **NEW versus the baseline, on files this enhancement changed**, count. **No user prompt — fix and continue.**

1. **NEW findings above the `tests/.evals/config.json` thresholds** → introduced by this change, so **this change resolves them in THIS SAME run**, then re-run and re-diff until the diff is clean. 🔴 BLOCKING.  **This is SH-LOOP-4 — capped at 3 remediation attempts (SH-1). On exhaustion apply SH-4: HALT and emit the Retry-Limit Report.**
2. 🔴 **NEVER suppress a finding to pass the gate** — no blanket `eslint-disable`, no `# nosec`, no `# type: ignore`, no ignore-list entry, no widening `disallowedLicenses`. That is the exact analogue of deleting a failing test to go green and is equally forbidden. **Fix the code.**
3. **Findings already present at baseline** → pre-existing, listed not blocking.
4. Write `eval.json` + `eval-summary.md` (eval-framework.md Section 6) and append the gate outcome to `enhancement-<TICKET-ID>-summary.md`. Log in runtime-artifacts/audit.md. Do NOT proceed with new findings outstanding.

## Step 14.7 —  Test Plans (ALWAYS) + Playwright UI Automation Gate (UI enhancements only)

**Applicability (automatic, no question asked) — the two halves differ**: 🔴 **part 1 (the ticket's manual test plans) ALWAYS runs**, so the ve can simply execute the plan once the `[ENH]` PR merges instead of generating it first. **Part 2 (Playwright)** applies only when the implementation plan (Step 11) touches UI (a Frontend Components step) — otherwise record `Playwright UI Automation: N/A — no UI touched by this enhancement` in `enhancement-<TICKET-ID>-summary.md` and proceed to Step 15 with part 1 still done.

🔴 **This gate INVOKES two existing skills via the Skill tool, in WORKFLOW MODE — it never re-implements them.** Full mechanics: `implementation/code-generation.md` Step 11d.

1. **Manual test plan — VERIFY FIRST, invoke `ve-implement` only to backfill.** `spec/test-plans/<TICKET-ID>-<title>/` was **already generated and approved** at Step 8.5 Item 4.5 and is already committed on the enhancement branch, so the normal case here is a **check, not a run**: confirm the folder exists and covers this ticket's ACs, record `Manual test plan: present (approved at STOP CHECKPOINT)`, and move to part 2. **Only if it is genuinely absent** invoke the skill with this ticket and **`mode: workflow`** — per `agents/ve-implement-agent.md` **Mode Detection** it skips its story-picker, its `ve/…` branch, its Approve/Request-Changes checkpoint and its push/PR, and the generated `spec/test-plans/…` files stay in the working tree to ride THIS enhancement's commit — and announce the backfill explicitly. 🔴 Never regenerate or overwrite an approved test plan to match the code. 🔴 Either way this is scope derivation, not Verification Engineer's sign-off — Verification Engineer's own standalone `/ve-implement` run remains the only sign-off path.
2. **Invoke the `playwright-implement` skill — UI enhancements only** — with the same ticket and **`mode: workflow`**: per `agents/playwright-implement-agent.md` **Mode Detection** it skips its story-picker, its both-merges gate (nothing has merged yet by design — the code is in this working tree), its integration-branch checkout, its Planner-plan Approval Gate and its Push Gate; auto-derives the Seed Test Gate; **starts the app locally itself** (and tears it down); invokes the real Planner/Generator/Healer subagents; and **executes `--headed`, exactly as the standalone skill does** (`npx playwright test tests/e2e/… --headed`) — this is the developer's own machine and the browser is meant to be visible; 🔴 headless belongs to CI alone, because a runner has no display.
3. **Iterate** — fixing the application code (never `test.fixme()`-ing a genuine failure) within the SAME run until every generated spec passes.  **This is SH-LOOP-11 — capped at 3 remediation attempts (SH-1). On exhaustion apply SH-4: HALT and emit the Retry-Limit Report.** 🔴 WORKFLOW MODE skips **approvals and git mechanics only** — never a verification.
4. **Capture evidence** to `reports/playwright-test-evidence/enhancement-<TICKET-ID>/` (`playwright-test-run.log`, the **mandatory machine-readable** `playwright-test-report.json`, `evidence-manifest.md`) and reference it in `enhancement-<TICKET-ID>-summary.md` + runtime-artifacts/audit.md. Write the result into `eval.json`'s `gates.playwright`, and record the resolved `startCommand`/`readinessUrl` into the `ci.playwright` manifest fragment (Step 15.5) so CI's trust-gate run reuses the identical commands.
5. **Commit the generated Playwright artifacts** (`tests/e2e/...`, `spec/playwright-specs/...`, any confirmed `seed.spec.ts` addition, `spec/test-plans/<TICKET-ID>-<title>/automation-summary.md`) together with the rest of the change — no separate branch/PR.
6. 🔴 CI later re-executes these SAME specs as a **trust gate, never the first execution** (headless there only because a runner has no display) — cross-checked automatically by the CI Attestation gate (Step 17.5, SH-LOOP-10) **when `## CI/CD Configuration` `Enabled: Yes`**; when `Enabled: No` there is no CI run to cross-check against, so this run's local Playwright pass is the only evidence for this change.

## Step 14.8 — 🧪 Playwright E2E Regression Gate (MANDATORY — after Step 14.7, before Code Review, same run)

Execute **Step 11e** of `implementation/code-generation.md`. 🔴 **Runs for EVERY enhancement, UI or not — deliberately unlike Step 14.7, which is UI-only.**

1. **Re-run the ENTIRE `tests/e2e/` suite** (every earlier work unit's specs **plus** anything Step 14.7 just generated), headless against a locally started instance of the app, and save the raw output to `reports/playwright-test-evidence/enhancement-<TICKET-ID>/regression/playwright-full-regression.log` plus the **mandatory machine-readable** `playwright-regression-report.json`.
2. **Diff against the Step 10 baseline.** Only specs **green at baseline and red now** count.
3. **NEW failures → this enhancement broke them, so this enhancement fixes them** within THIS SAME run; re-run and re-diff until the diff is clean.  **This is SH-LOOP-13 — capped at 3 remediation attempts (SH-1). On exhaustion apply SH-4: HALT and emit the Retry-Limit Report**, naming each newly-red spec.
4. 🔴 **Fix the application code, never the spec.** Deleting a spec, marking it `test.fixme()` or `.skip`, loosening a locator, widening a timeout or narrowing an assertion to force it green is the exact analogue of deleting a failing unit test and is equally forbidden (SH-6). An approved spec changes only when the acceptance criterion it encodes genuinely changed — amended together with the AC, `requirements.md` and the tracker item, and logged.
5. **Failures already red at baseline** → not this enhancement's doing; already logged in the baseline. Ignore them and do not block on them.
6. **Capture evidence** in that same `regression/` folder (`evidence-manifest.md` with baseline vs post-change counts, the exact commands, `headed` + reason, and each NEW failure with what broke and how it was fixed), reference it in `enhancement-<TICKET-ID>-summary.md` + runtime-artifacts/audit.md, and write the result into `eval.json`'s `gates` block under id **`"playwrightRegression"`**.
7. 🔴 **LOCAL-ONLY gate** — like `regression` and `apiContract`, CI has no baseline to diff against, so `playwrightRegression` is **never** added to `ci.gates` (`common/eval-framework.md` Section 5). CI's own `playwright` job stays a trust gate with no attribution.
8. **`N/A`** when the Step 10 baseline was `N/A` (nothing existed to regress) — record the same reason. 🔴 Never reported as a pass.

## Step 15 — AUTO Code Review →  Verdict Routing + Auto-Remediate Loop

Mirrors dev-implement Sections A–C, enhancement-scoped. The Code Review runs **automatically**, and so does everything that follows from it — the user is asked nothing.

### 15a. AUTO Code Review (MANDATORY, automatic)
1. **Log** in runtime-artifacts/audit.md that automated Code Review is starting for Enhancement [TICKET-ID] (ISO 8601 timestamp).
2. Auto-run `workflows/code-review.md` scoped to this change (read-only — it MUST NOT edit source) → versioned report `reports/reviews/enhancement-<TICKET-ID>-code-review-v[X].md`. Pass in the Step 13/14/14.5/14.7 evidence — the review MUST NOT re-run the tests, re-measure coverage, re-run the D1–D7 checks, or re-run the Playwright specs; it cites the stored evidence.
2.4. ** AUTOMATED SECURITY REVIEW (MANDATORY, automatic — inside this review pass)**: the review's **Phase 2.5** runs the `agents/code-security-review-agent.md` procedure against this change's diff (all 16 Security Baseline rules, scoped to the changed files + the attack surface they reach) and writes `reports/code-security-reviews/enhancement-<TICKET-ID>-security-review-v[X].md` (keyed by this work unit and the review version — never the dated name, which parallel stories would collide on). Its **🔴/🟠 findings on the changed surface become real `SEC-ISS-XXX` findings** — routed by 15b and **auto-remediated by 15c (SH-LOOP-5) until clean, within its 3-round budget**, exactly like AC findings. 🟡/🔵 and pre-existing violations on untouched lines are **advisory only** (`/raise-defect` for those). 🔴 Never suppress instead of fixing; never widen the scan to the whole repo.
2.5. ** JUDGE GATES J1 + J2 — 🔴 BLOCKING (MANDATORY, automatic — computed HERE and nowhere else)**: compute the two judge scores per `common/eval-framework.md` Section 4 from this work unit's diff — **J1** against `tests/.evals/rubrics/architecture-rubric.json` (derived from `spec/plans/architecture.md` Section 10; apply the Section 3 **fallback chain**: this cycle's rubric → a prior cycle's committed rubric → derived from Atlas / the reverse-engineering artifacts → **`N/A` with the reason**; this flow skips most design stages, so `N/A` is a normal outcome and is never scored against a borrowed rubric) and **J2** against `security-rubric.json`. Write them with their **per-criterion breakdown** to `reports/eval-evidence/enhancement-<TICKET-ID>/judge/`, merge into the **`gates`** block of `eval.json`, refresh `eval-summary.md`, report both in the review report.
   - **Scoring discipline** (Section 4.1): score **once** per review pass — never re-roll for a better number; every criterion below 1.0 **MUST cite `file:line`**; score only what the diff shows; a criterion this diff cannot exercise is `N/A`, excluded, remaining weights renormalised to 1.0 — never scored 0.
   - ** Gate**: `J1 ≥ llmJudgeArchitectureScoreMin` **and** `J2 ≥ llmJudgeSecurityScoreMin` from `tests/.evals/config.json`. `J1 = N/A` passes. **Below minimum → SH-LOOP-6**: remediate the cited criteria worst-weighted-loss first, re-run whatever gates the fix touched, re-score on the next review pass. **Capped at 3 attempts; on exhaustion apply SH-4 — HALT and emit the Retry-Limit Report.**
   - 🔴 **Forbidden ways to pass** (SH-6): editing `architecture.md` Section 10, editing the rubric JSON, lowering either minimum, re-scoring until it clears, or marking an applicable criterion `N/A`.
3. **MANDATORY — audit the complete review log**: the `**TRACKER ITEM**:` field, report path, verdict, and the complete list of findings by severity (🔴 Blocker / 🟠 High). Do not summarize away findings.
4. Proceed to **15b**.

### 15b.  Review Verdict Routing (AUTOMATIC — no question, no gate)

The review's own verdict decides what happens next. **Do NOT present an A/B choice and do NOT wait for the user.** Announce the verdict, then route:
   ```
    Automated Code Review complete for Enhancement [TICKET-ID].
      Report: reports/reviews/enhancement-[TICKET-ID]-code-review-v[X].md
      Verdict: [clean — all ACs Met / findings: Blocker X, High Y]
   [Proceeding to commit + [ENH] PR. | Findings found — remediating them automatically now (round [n]).]
   ```
1. **Verdict clean (zero 🔴 and zero 🟠)** → go to **Step 15.5 (Manifest Reconciliation)**, then Step 16.
2. **Any 🔴 or 🟠 finding** → go to **15c (SH-LOOP-5)**. The framework fixes its own findings within a budget of **3 remediation rounds**; it hands them back to the user only when that budget is exhausted (SH-4), and then it HALTS instead of raising the `[ENH]` PR.
3. **MANDATORY**: log the routing decision in runtime-artifacts/audit.md under a plain heading (`## Review Verdict — Clean, Proceeding to PR (Enhancement [TICKET-ID])` or `## Review Verdict — Findings, Auto-Remediating (Enhancement [TICKET-ID])`) with the full findings list by severity. **No "GATE" in the heading, and no user response to record.**

### 15c.  Auto-Remediate Loop — SH-LOOP-5 (AUTOMATIC — max 3 rounds)

**Entered whenever the review verdict reports findings. Every round is automatic — no prompts at any point. The loop is bounded by the Self-Healing Retry Policy: one round = one attempt, maximum 3.**
1. **Check the SH-LOOP-5 counter BEFORE starting a round.** If 3 attempts have already been spent, do not start another — go directly to step 7 (Exhaustion).
2. **Log** in runtime-artifacts/audit.md that automatic remediation round `[n] of 3` is starting for Enhancement [TICKET-ID], naming the review report being remediated, the findings in scope, and the identified root cause of each (SH-3, SH-7).
3. Run `workflows/remediate.md` scoped to that report (fix → unit test → green).  **Its scope-confirmation prompt is SKIPPED** — every 🔴/🟠 finding is in scope and nothing is deferred. **Re-run the FULL repo suite if the remediation touched non-test code**, comparing against the Step 10 baseline again — only NEW failures block, and they are fixed in the same round. If the remediation touched API-layer code that Step 13.5 covered, also re-run the affected endpoint(s)' API & Contract tests and keep them green. Per SH-2, these re-entries **continue** the SH-LOOP-3 / SH-LOOP-2 counters — they do not reset them.
4. **MANDATORY — audit the complete remediate log**: the round number (`[n] of 3`), which findings were fixed (by severity), files changed, unit-test evidence, regression comparison. Record the complete log, not a summary.
5. **Re-review automatically**: return to **15a** (produces the next report version `v[X+1]`), then **15b** again.
6. **Loop control**:
   - **Verdict clean** → the loop exits successfully → **Step 15.5 (Manifest Reconciliation)**, then Step 16.
   - **Findings remain AND attempts spent < 3** → increment the counter and return to step 1.
   - **Findings remain AND attempts spent = 3** → **exhausted** → step 7.
   - **Stall (SH-5)** — a round produced **no code change at all** AND the next review returned an **identical** finding set → the loop cannot progress. Treat as exhausted immediately, regardless of attempts remaining → step 7, noting the early end.
7. ** Exhaustion (SH-4) — HALT, do not raise the `[ENH]` PR.** When the budget is exhausted (3 rounds, or an SH-5 stall):
   - Do **not** run a 4th round, do **not** commit, do **not** push, do **not** raise a PR, and do **not** change the local Story Tracker or the external tracker. The ticket stays `In Development` and the remediation work stays in the working tree.
   - Emit the **Retry-Limit Report** (Self-Healing Retry Policy, above) with `[loop name]` = `Auto-Remediate (code review + security findings)` and `[SH-LOOP-ID]` = `SH-LOOP-5`, listing every unresolved finding with its ID, severity, file:line, and the reason automatic remediation failed on it.
   - Append the same content to runtime-artifacts/audit.md under `## Self-Healing Retry Limit Reached — SH-LOOP-5 (Enhancement [TICKET-ID])`.
   - **HALT and wait for the developer to fix it manually and hand it back.** 🔴 Never silence a finding by deleting it from the report, never weaken the review scope to manufacture a clean verdict, and never let an exhausted loop pass unreported.

### 15d. Status
The ticket stays `In Development` throughout review and remediation.

## Step 15.4 — Artifact Completeness Check (MANDATORY)

**🔴 ARTIFACT COMPLETENESS CHECK — SH-LOOP-16 (MANDATORY, AUTOMATIC — after the clean review verdict, BEFORE Step 15.5 and the Step 16 commit)**: run `common/work-unit-artifacts.md` Section 5 for `enhancement-<TICKET-ID>`. Build the expected evidence list from Section 1 (the always-required files plus the folders of every gate that ran, read from `eval.json`), then verify each file exists, is non-empty, has its set format (the Section 2 `evidence-manifest.md` skeleton; `eval.json` / `eval-summary.md` per `common/eval-framework.md` Section 6; the review and security report templates) and agrees with the others (Section 4) — including that **no folder exists for an `N/A` gate** (so `b3/` only on the last unit). A file whose underlying output exists is written or reformatted from that real output; a missing underlying output means the gate never produced evidence, so that gate's step is **re-run** — never hand-written. Record the result in `reports/eval-evidence/enhancement-<TICKET-ID>/artifact-check.md`. Capped at 3 attempts; on exhaustion HALT with the Self-Heal Limit message. **Nothing is committed until this check is clean.**

## Step 15.5 — Manifest Reconciliation — CONDITIONAL on `## CI/CD Configuration` `Enabled: Yes` (MANDATORY, AUTOMATIC when it applies — after local gates pass, BEFORE the commit)

**If `## CI/CD Configuration` records `Enabled: No` (`## CI Setup Status` = "declined"), SKIP this step entirely** — there is no CI manifest to reconcile without a pipeline — and go straight to Step 16. Otherwise:

Identical mechanism to `dev-implement.md` Section D Step 1.5 — see `common/ci-pipeline-generation.md`
Section 4.0f for the full contract. Write ONE NEW file, `tests/.evals/ci-manifest.d/enhancement-[TICKET-ID].json`,
from what Steps 13/13.5/14.5 **already executed for real** for every root this enhancement touched —
never re-derived, never guessed. Append-only; never edit `tests/.evals/config.json` or another work
unit's fragment. Re-run `validate-pipeline.{sh,ps1}` and confirm it passes before proceeding to Step 16.
Include the fragment in the same commit as the change. 🔴 **Write the COMPLETE entry per Section 4.0f's field table** — including `runtimeVersion`,
`coverageReportPath`/`coverageFormat`, `noTestsExitCode`, `dependsOn`, `toolchainSetup`, and `tools`
**paired with** `toolInstallCommands`. A name in `tools` with no matching `toolInstallCommands` entry is a
hard Manifest defect, and an omitted `dependsOn` silently disables monorepo diff-scoping.

## Step 16 — Commit, Push & Raise the `[ENH]` PR —  FULLY AUTOMATIC

🔴 **A clean review verdict is the ONLY thing that triggers this step.** An exhausted SH-LOOP-5 (15c.7) does NOT reach it — that path HALTS at the gate and waits for the user. The commit, push,
PR creation, labels, tracker update (Step 17) and auto PR review (Step 18) run **automatically with
no prompts**. Announce each action; never ask whether to do it.

1. Verify the active branch is the Enhancement Branch (switch automatically and announce if not). Run the **State Isolation Check** (`common/parallel-work-state.md` Section 5.5), then stage and commit — together with the fragment `runtime-artifacts/stories/enhancement-<TICKET-ID>/` and never the shared `audit.md` / `aire-state.md` — (code + tests + updated docs, **plus any files Playwright Readiness added** (the package manifest and lockfile, `playwright.config.*`, `.claude/agents/playwright-test-*.md`, `.mcp.json`), the Step 14.7 Playwright artifacts when that gate applied, plus the Step 15.5 manifest fragment if one was written) with the framework signature trailer, `[N]` read live from CLAUDE.md:
   ```
   git add <files>
   git commit -m "[ENH][TICKET-ID] <concise enhancement summary>" -m "AIRE-Version: [N]"
   ```
   Record the hash in runtime-artifacts/audit.md.
1.5. **🔴 CI PREFLIGHT GATE — CONDITIONAL on `## CI/CD Configuration` `Enabled: Yes` (MANDATORY, AUTOMATIC when it applies — after this commit, BEFORE the push)**: **if `Enabled: No`, SKIP this gate entirely** — there is no CI pipeline to preflight — and go straight to Step 2 (invoke `pr-generator`). Otherwise, identical
   mechanism to `dev-implement.md` Section D Step 2.5; `common/ci-pipeline-generation.md` **Section 4.0i**
   is the contract. In a **clean room** (fresh venv / empty `node_modules` / throwaway Podman container —
   never this agent's ambient shell, never an install the manifest does not declare), against the
   **committed** change with `BASE_SHA="$(git merge-base origin/<base-branch> HEAD)"`, run CI's own
   entrypoints — `ci-manifest-runner.sh install` → `build` → `run-static-evals.sh` →
   `ci-manifest-runner.sh coverage` — plus the P1 declaration check over the merged manifest. **FAIL** on a
   missing tool, an undeclared dependency (`ModuleNotFoundError` / `requires the <pkg> package`), a
   Manifest defect, or a gate reporting `N/A`/a qualified pass on a root this diff touched. Fix the
   **declaration** (this enhancement's own fragment for `tools`+`toolInstallCommands`; the repo's own
   dependency declaration for a test/runtime package) — never the gate, never a bare install inside CI
   YAML. This is **SH-LOOP-9**, capped at **3 attempts** (SH-1); on exhaustion apply SH-4 — HALT with the
   Retry-Limit Report, no push and no PR. Reuse Step 13.2's containerised behavioural evidence rather than
   re-running it.
2. Invoke **`pr-generator`** (as-is) **in WORKFLOW mode**, passing **target branch = the Base Branch** from `## Branching`. The PR title carries the **`[ENH]`** prefix; the skill applies the `ai-generated` and `aire-v[N]` labels (plus the `AIRE Framework: v[N]` line in the PR body).  **Its Phase 5 confirmation is SKIPPED — this workflow has no gates; the Implementation Checkpoint authorized the whole of Phase B.** It announces the draft and raises the PR without asking.
3. Record the PR URL in the ticket's state fragment (`runtime-artifacts/stories/enhancement-<TICKET-ID>/state.md`, `## Story Tracker Row` → PR — never the shared `## Branching`; readers resolve it from there or live from the enhancement branch) and the full outcome in the audit trail.

## Step 17 — Tracker Update (NO Ready-for-Testing transition)

1. Story Tracker: keep Status = `In Development`; set **End** = today and **Recorded** = now; note the PR URL.
2. 🔴 **Do NOT transition the tracker ticket to "Ready for Testing"** — the ticket stays In Development after the PR. Promotion is ve's, via `ve-list-work` Option B, run **on `<enhancement-branch>` while the `[ENH]` PR is still OPEN** — never post-merge on the base branch (see Step 19). Add a **comment** on the ticket (**automatic** — part of the prompt-free post-review sequence, same as the bug flow), dispatched per `common/tracker-sync.md` Section 10 (LOCAL: note on the local entry), linking the PR with evidence (tests passing, coverage %, regression clean vs baseline).
3. Log in runtime-artifacts/audit.md (with the TRACKER ITEM field).

## Step 17.5 — CI Attestation Gate — CONDITIONAL on `## CI/CD Configuration` `Enabled: Yes` (MANDATORY, AUTOMATIC when it applies — after the PR is raised, before Step 18)

**If `## CI/CD Configuration` records `Enabled: No`, SKIP this gate entirely and proceed straight to Step 18** — there is no CI pipeline run to attest against. Otherwise, identical mechanism to `dev-implement.md` Section D Step 8. Confirm a run of
`agentic-eval-pipeline.yml` exists for this PR's head SHA, watch it to conclusion, download `eval.json`,
and cross-check CI's `gates` block against this enhancement's own local gate results.

**Check the SH-LOOP-10 counter BEFORE starting an attempt.** If 3 attempts have already been spent, do
not start another — go directly to Exhaustion below.

A gate that passed locally but is absent/`N/A` in CI is a **manifest defect** — go back to Step 15.5,
extend the fragment (never remove another unit's entry), re-run the Step 16.1.5 preflight for that root,
commit, push, re-verify. This is **SH-LOOP-10 — capped at 3 remediation attempts (SH-1)**. Log each
attempt per SH-3 (root cause, planned fix, files changed, exact command re-run, result).

**Exhaustion (SH-4)**: on the 3rd failed attempt, or an SH-5 stall, apply SH-4 exactly — HALT, do not
push further, do not raise/update the PR beyond what already exists, do not change any tracker status,
and emit the standard Retry-Limit Report with `[loop name]` = `CI Attestation` and `[SH-LOOP-ID]` =
`SH-LOOP-10`, naming each gate CI never saw agreement on. Append the same content to
`runtime-artifacts/audit.md` under `## Self-Healing Retry Limit Reached — SH-LOOP-10 (Enhancement [TICKET-ID])`.

On a clean match, log the attestation and proceed.

🔴 **SCOPE — this gate repairs CI configuration only** (`common/ci-pipeline-generation.md` **Section 6.6**):
this workflow owns the manifest fragment, the repo's dependency declarations, the pipeline scripts and
tool pins; **CI self-repair owns application code and tests**. A Code-class CI failure (Section 6.4) is
recorded here and left to self-repair — never fixed from this gate and never charged to an attestation
attempt. Never push into an in-flight self-repair run: wait for it, fetch, rebase onto its commit, re-read;
never force-push and never revert its commit.

## Step 18 — AUTO PR Review

Invoke the **`pr-review`** skill (as-is) in **AUTO MODE** against the just-raised PR: it posts a plain COMMENT review (summary + inline comments) automatically — no prompt, never a formal APPROVE/REQUEST_CHANGES. Record the outcome in runtime-artifacts/audit.md.

## Step 19 — Archive Handoff (MANUAL)

🔴 **RE-READ FIRST.** Before writing any part of this step's output, `Read` this Step 19 section from the file again. Do NOT reconstruct it from memory or from earlier in this session's context — "I already read this file earlier" does not satisfy this.

### The ordering invariant

| # | Action | Relative to the archive |
|---|--------|-------------------------|
| 1 | `ve/...` PR(s), if the Verification Engineer raised any, merge into `<enhancement-branch>` | BEFORE |
| 2 | `ve-list-work` Option C amendments pushed to `<enhancement-branch>` | BEFORE |
| 3 | `ve-list-work` Option B sign-off → ticket `Ready for Testing` | BEFORE |
| 4 | **`archive-epic`** (enhancement mode) | ⬅ **THE ARCHIVE** |
| 5 | **`[ENH]` PR merges into `<base-branch>`** | AFTER — completes the cycle |

🔴 **`archive-epic` runs at row 4 — BEFORE the `[ENH]` PR merges (row 5).** Its cycle-close archive commit must ride the still-OPEN `[ENH]` PR so the archive reaches `<base-branch>`. Merging the `[ENH]` PR completes the cycle; the next cycle pulls fresh current-system truth from Atlas via the Helix MCP.

**TWO DIFFERENT PRs appear here — never write "the PR" unqualified:**
- the **`ve/...` PR** → merges into `<enhancement-branch>`. The archive **waits for this one**.
- the **`[ENH]` PR** → merges into `<base-branch>`. The archive **must precede this one**.

"Wait until all ve work has landed" means rows 1–3 **only** — never row 5.

**🔴 BANNED OUTPUT — each inverts the invariant. Never emit them, in any wording:**
- "archive runs post-merge" / "it runs post-merge only"
- "when the `[ENH]` PR merges, run `archive-epic`"
- "DO NOT invoke `archive-epic` manually now"
- any instruction for the developer to transition the tracker ticket in this step

Do NOT invoke `archive-epic`, do NOT ask whether to invoke it, and do NOT add an options menu or any competing next-steps block. The block below is the entire output of this step.

### Emit this message VERBATIM (placeholders substituted)

The ONLY permitted modification is substituting `<url>`, `<enhancement-branch>`, `<base-branch>`, `[TICKET-ID]`, `<slug>` with real values from `## Branching` / the Step 16 PR. **Never ship an unsubstituted placeholder**; never add, remove, reorder, reword, or summarise a line:

```
Enhancement for [TICKET-ID] is ready for review.
   Pull request   <url>   ([ENH] → <base-branch>)
   Status         In Development — it moves forward only after sign-off, the cycle archive and the merge.
   Note           The cycle archive was deliberately NOT run — it is yours to run, at step 4 below.

REVIEW THE PULL REQUEST TOGETHER — FIRST
   The [ENH] PR is reviewed by the Developer and the Verification Engineer together.
   Approval and merge are manual steps — the framework never approves or merges a pull request.
   Changes needed? Leave review comments on the PR, then type:  pr-fix <url>

NEXT ACTIONS (in this order):
   1.  If the Verification Engineer raised any `ve/...` PR(s) for [TICKET-ID], wait until they have MERGED into `<enhancement-branch>`
       (the Verification Engineer PR into the enhancement branch — NOT the [ENH] PR into `<base-branch>`)
   2.  On `<enhancement-branch>`: `git checkout <enhancement-branch> && git pull --ff-only`
       (pulls the merged `spec/test-plans/<TICKET-ID>-.../` docs in so the archive captures them)
   3.  Verification Engineer: use the skill ve-list-work — on `<enhancement-branch>`, NOT on `<base-branch>`
       • Option C to amend a test plan (commit + push to `<enhancement-branch>` so the archive captures it)
       • Option B to sign off — promotes ticket [TICKET-ID] In Development → Ready for Testing
       (Sign-off happens HERE, before the archive — so the tracker still exists and the sign-off
        plus test-plan edits are captured in the archive.)
        For frontend work, this workflow already generated and ran the Playwright tests
          (Step 14.7); ve-list-work's output shows their status.
       Rejected? If the Verification Engineer rejects in Option B, or anyone leaves review comments / requests
          changes on the [ENH] PR, type: pr-fix <url> — it fixes the enhancement on
          `<enhancement-branch>`, re-runs every gate, updates the same [ENH] PR, then come back to step 3.
   4.  Use the skill archive-epic  (enhancement mode → `aire-archives/enhancements/<TICKET-ID>-<slug>/`)
       MUST happen while the [ENH] PR is still OPEN — its cycle-close archive commit rides that
          open PR onto `<base-branch>`. It writes this cycle's RE delta to
          `spec/plans/delta/<TICKET-ID>-<slug>/`, archives it, and then REMOVES the live spec/,
          reports/ and runtime-artifacts/ trees — it never stitches.
   5.  ONLY NOW merge the [ENH] PR into `<base-branch>`: <url>
   6.  On `<base-branch>`, after that merge, type: /stitch-delta
       It reads the delta from the cycle archive and publishes it to the deep dive on Atlas via the
       Helix MCP; its own PR is a single ledger row. The cycle is NOT closed until this lands —
       skipping it leaves Atlas a cycle stale.

ORDER IS LOAD-BEARING: archive-epic (step 4) runs BEFORE the [ENH] PR merges (step 5).
   Merging first strands the cycle archive off the PR and forces a manual recovery.
Use the skill names EXACTLY as shown — do not describe what you want in your own words.
   Any other phrasing is not a framework trigger and the workflow will not advance.
```

---

## Critical Rules
- EVERY audit entry carries `**User Email**:` and `**TRACKER ITEM**:`; Phase B entries also carry `**AIRE VERSION**:` (read live from CLAUDE.md — never hardcoded).
- 🔴 **A REJECTED `[ENH]` PR IS FIXED WITH `pr-fix`** (`workflows/pr-fix.md`): review comments or a ve rejection (`ve-list-work` Option B) while the `[ENH]` PR is open are fixed by `pr-fix <PR>` on the same enhancement branch — it re-runs this workflow's complete Phase B gate chain (Steps 10–18) and updates the same PR. Never re-run the enhancement flow to raise a second PR.
- ONE branch (`enhancement/...`) created FIRST — before requirements; ONE story, NO dependency graph, NO new tracker issues (except LOCAL's locally-minted ID, never pushed externally), NO epic branch, NO Parent-Epic sync.
- NO PR at requirements approval — the single `[ENH]` PR is raised at Step 16 after review approval, target = Base Branch, via `pr-generator` only, `ai-generated` + `aire-v[N]` labels.
- 🔴 Step 8.5 (STOP CHECKPOINT) gives this ONE-enhancement cycle the SAME project-level bootstrap the epic flow gets: `architecture.md`, the cycle's `behavior.feature`, the rubrics. **CI setup is now CONDITIONAL** on `## CI Setup Status` (detected, and — when missing — asked, at `ticket-implement` Step 1.5):
  - **CI exists** → skip full CI setup + smoke test; proceed with architecture/rubrics/behavior artifacts only.
  - **CI missing** (opted in) → run full CI setup + smoke test (current behavior).
  - **CI declined** (opted out) → skip full CI setup + smoke test, same as "exists" but announced as a decline; this workflow also skips its own CI Preflight and CI Attestation gates for this ticket.
  Every artifact is **create-if-missing, never regenerate**: a repo that already has them (from a prior epic/bug/enhancement cycle) reuses them AS-IS. Never skip Step 8.5 on the reasoning that "this is only a small enhancement."
- The **ve Handoff Break** runs BEFORE the Implementation Gate question: ALWAYS commit + push the analysis/design/STOP-CHECKPOINT artifacts on the enhancement branch first (the ve's `/ve-implement` needs them on origin), run the pre-handoff smoke test **only if `## CI Setup Status` = "missing"** (skip it, announced, when "exists" or "declined"), and present the ve instructions. The ve's run is independent of the yes/no answer and of the code existing at all.
- The Implementation Gate is a **yes/no question in the same flow** — never auto-continue into Phase B without the user's explicit "yes"; on "no", halt with state saved. It is **deliberately unnumbered** (flow control, not an approval gate) — and it is now the ONLY question this workflow asks.
- 🔴 **ONE SANCTIONED PAUSE — a Playwright agent install (Step 11.4).** For a frontend work unit, Playwright Readiness (Step 11.4) installs the runner, the browsers and Playwright's official test agents **before any code is written**. If the agents had to be installed, the run records `PAUSED —` and asks the user to restart the Claude Code session — MCP servers load at session start, so the `playwright-test` server is not connected until then. 🔴 **This is a hard stop, not an approval prompt.** Nothing is committed, pushed or transitioned; after the restart the user types `ticket-implement <TICKET-ID>` and it continues at **Step 11.5**. The Playwright UI gate (Step 14.7) keeps the same install-then-pause handling only as a safety net, resuming at Step 14.7 if it ever triggers there. Everything already installed → no pause.
- 🔴 **NO GATES AT ALL** — the implementation plan is announced and executed (no GATE 2), and the review verdict routes the run automatically (no GATE 3). Never present a plan-approval or Approve-&-continue/Remediate prompt, and never write "GATE" into an audit heading from this workflow. The Implementation Checkpoint (yes/no) survives as unnumbered flow control.
- 🔴 **THE FRAMEWORK FIXES ITS OWN FINDINGS, WITHIN A BOUNDED BUDGET** — any 🔴/🟠 finding triggers the auto-remediate loop (15c, **SH-LOOP-5**): remediate → regression → re-review, looping until the verdict is clean **or the 3-attempt budget is exhausted**. On exhaustion (3 rounds, or an SH-5 stall — no code change + identical findings) the run **HALTS at the gate**: no commit, no push, no `[ENH]` PR, no tracker change; the Retry-Limit Report is emitted to the user and to runtime-artifacts/audit.md, and the run waits for the developer to fix it manually and hand it back.
- 🔴 Mid-coding plan deviations are applied only after the plan document is revised and the change announced + logged — never silently, and never via an approval prompt.
- At Step 9, ALWAYS assign the ticket to the operator per `common/tracker-sync.md` Section 5 (automatic, verified where applicable, logged; failure non-blocking). LOCAL has no assignee concept.
- ALWAYS run the BASELINE regression BEFORE any change and the FULL regression AFTER; only NEW failures (vs baseline) block; log both runs in `enhancement-<TICKET-ID>-summary.md`.
- 🔴 ALWAYS BOOTSTRAP missing tool configs BEFORE the baseline static run (Step 10, `common/eval-framework.md` Section 2.2) — a check with no config is **set up**, not marked N/A; an existing config is used **as-is**. Bootstrap → baseline → implement → gate → diff: a config created after the baseline blames this change for pre-existing findings. Announce every file created.
- 🔴 ALWAYS run the BASELINE static eval checks D1–D7 before any change (Step 10) and the STATIC EVAL GATE after the regression gate (Step 14.5); only findings NEW vs baseline on changed files block, and this change resolves them in the same run. **NEVER suppress a finding to pass the gate** — that is the analogue of deleting a failing test. Baseline findings are pre-existing debt: logged, ignored. See `common/eval-framework.md`.
- 🔴 The J1/J2 judge scores are computed ONCE per review pass in Step 15a and are **blocking gates** (below minimum → SH-LOOP-6); J1 = `N/A` passes and is a normal outcome when the design stages were skipped.
- 🔴 The 15c auto-remediate loop (**SH-LOOP-5**) is **capped at 3 rounds** by the Self-Healing Retry Policy. It fixes review and security findings; a judge score below minimum is fixed by its own loop, SH-LOOP-6.
- Plan grounded in the previously generated docs; coding follows the announced plan exactly — deviations revised into the plan, announced and logged, never silent. Coverage on new/changed code ≥90%.
- 🔴 **API & Contract Testing Gate (Step 13.5) is MANDATORY WHEN the enhancement touches an API endpoint** — applicability is plan-derived and automatic, never asked. Generate automated tests against the real endpoint(s), RUN them, and iterate until every applicable checklist item (functional, response-code validation, role-based authorization 401/403, error-response validation, request validation, response contract/schema validation) passes, in the SAME run, BEFORE the Full Regression Gate (Step 14). This is **SH-LOOP-2**, capped at **3 remediation attempts**; on exhaustion apply SH-4 (HALT + Retry-Limit Report). N/A (with a stated reason) when the enhancement touches no API layer. Capture proof artifacts to `reports/api-contract-test-evidence/enhancement-<TICKET-ID>/`. This gate does NOT replace ve's `/ve-implement` MANUAL API/Contract test steps.
- 🔴 **Step 14.7 has TWO halves with DIFFERENT applicability — never skip the whole step because the enhancement has no UI.** **Part 1 — the ticket's manual test plan — is VERIFIED ALWAYS**: it was authored and approved at Step 8.5 Item 4.5, so the normal case is a presence check; `ve-implement` is invoked in WORKFLOW MODE only to backfill a genuinely absent plan, announced. Either way the ve simply executes the plan once the `[ENH]` PR merges instead of generating it first. **Part 2 — `playwright-implement` → browser automation — runs ONLY when the implementation plan touches UI**; otherwise record `Playwright UI Automation: N/A — no UI touched by this enhancement` and move on, **with part 1 still done**. Applicability is plan-derived and automatic, never asked. Both halves run **by INVOKING those skills in WORKFLOW MODE with the ticket passed in**, never by re-implementing their steps inline. WORKFLOW MODE skips their story-pickers, Verification Engineer's branch/approval/PR, the both-merges gate, the integration-branch checkout, the Planner-plan Approval Gate and the Push Gate — and nothing else. The skill starts the app locally, runs the real Planner/Generator/Healer subagents, executes **`--headed`** (same as standalone — headless is CI's alone, since a runner has no display), and iterates — fixing the application code, never `test.fixme()`-ing a real failure — in the SAME run, BEFORE Step 15 Code Review. This is **SH-LOOP-11**, capped at **3 remediation attempts**; on exhaustion apply SH-4 (HALT + Retry-Limit Report). N/A (with a stated reason) when the enhancement touches no UI. Capture proof artifacts to `reports/playwright-test-evidence/enhancement-<TICKET-ID>/` and write the result into `eval.json`'s `gates.playwright`. CI later re-executes it headless as a **trust gate, never the first execution**, cross-checked by the CI Attestation gate (SH-LOOP-10). This gate does NOT replace ve's own independently-scheduled `/ve-implement` run.
- 🔴 **ALWAYS run the BASELINE Playwright E2E regression (Step 10) and the FULL Playwright E2E regression (Step 14.8), then diff them — for EVERY enhancement, UI or not.** This is the UI counterpart of the unit-test regression pair (Step 10 / Step 14) and exists for the same reason: Step 14.7 only proves *this* enhancement's own specs pass, so nothing else proves the change did not break a browser flow an earlier work unit already shipped. 🔴 **Do NOT skip it because the enhancement touches no UI** — a backend, API, schema, config or dependency change is exactly what breaks an existing flow silently. Both runs are **automatic — never prompt the user for either**. Only specs green at baseline and red now count; the enhancement resolves them in the same run under **SH-LOOP-13** (capped at **3 remediation attempts**; on exhaustion apply SH-4 — HALT + Retry-Limit Report). 🔴 **NEVER delete, `test.fixme()`, `.skip`, loosen a locator, widen a timeout or narrow an assertion to make an existing spec green** (SH-6) — fix the application code. Baseline failures are pre-existing debt: logged and ignored. Evidence goes to `reports/playwright-test-evidence/enhancement-<TICKET-ID>/regression/` and the result into `eval.json`'s `gates.playwrightRegression` — a **local-only** gate, never added to `ci.gates`.
- The ticket stays `In Development` after the PR — promotion to Ready for Testing is ve's, via `ve-list-work` Option B run **on the enhancement branch, before `archive-epic` and before the `[ENH]` PR merges** (not post-merge on the base branch — after the archive's workspace reset there is no Story Tracker left to promote).
- **Test Plan sign-off remains ve's, and only ve's.** ve still runs `/ve-implement` independently, on its own schedule, and only `ve-list-work` can approve/reject a test plan or move the ticket to Ready for Testing. 🔴 **The ONE narrow exception**: Step 14.7 above may auto-generate `implementation/test-plan.md` Steps 1–5 (never Step 6, the ve approval checkpoint) purely as UI-scenario scope for the Playwright gate, when ve hasn't produced that content yet — this is scope derivation for an automated test, not a substitute for ve's sign-off. Never write anything under `spec/build-and-test/`, and never treat Step 14.7's auto-generated content as an approved test plan.
- 🔴 After the PR: AUTO `pr-review` (comment-only), then **STOP — the archive is MANUAL**. NEVER invoke `archive-epic` from this workflow. **Re-read Step 19 before emitting its handoff, and emit that block VERBATIM with placeholders substituted** — do not paraphrase it. The operator runs `archive-epic` once the Verification Engineer `ve/...` PR(s) (and any `ve-list-work` Option C amendments) have merged **into the enhancement branch**, and **BEFORE the `[ENH]` PR merges into the base branch**, so the cycle archive rides the open PR. archive-epic writes the cycle's RE delta, archives it and then removes the live `spec/`, `reports/` and `runtime-artifacts/` (the archive is the only copy), but never stitches. After the `[ENH]` PR merges, the operator runs **`/stitch-delta`** on the base branch; it reads the delta from the archive and publishes it to Atlas (it touches no `spec/`) — the cycle is not closed until that lands. Never tell the user the archive runs post-merge (that inverts the invariant), and never tell them the stitch runs pre-merge (that inverts the other one).
- Security Baseline extension always applies; other extensions per their recorded opt-ins.
