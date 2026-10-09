# WORKFLOW: `dev-implement` (Implementation Phase — Code Generation)

## READ FIRST — THE NON-NEGOTIABLES OF EVERY `dev-implement` RUN

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
3. **The pre-commit guard is installed and never bypassed.** Right after the story branch is cut (Step 1.5 item 4.4), run
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
6. **The run ends with its exact end message.** A successful run's final output is the Section F Next-Action Handoff block,
   verbatim, every placeholder substituted, and nothing else in that message — no free-form summary
   before it, no gap list, no suggestions after it. Progress lines earlier in the run are fine; the last
   message is the block. A halted run ends with the Self-Heal Limit message instead, also verbatim.

---

## THIS WORKFLOW IS FULLY AUTOMATIC — IT ASKS NOTHING AFTER THE STORY KEY

**Typing `dev-implement` and naming the story is the ONLY user decision in the entire run.**
Everything after it — the implementation plan, code generation, the unit-test/coverage gate, the
API & Contract Testing gate (when the story touches an API layer), the regression gates, the
automated Code Review, **the remediation of any findings it reports**, the
commit, the push, the PR and the PR review — happens **without a single approval prompt**.

- There is **NO GATE 2** (plan approval). The plan is written, announced, and executed.
- There is **NO GATE 3** (review decision). A review with findings is **remediated automatically**,
  then re-reviewed, **looping until the review comes back clean** — the user is never asked to choose
  between "Approve & continue" and "Remediate".
- 🔴 **Never write the word "GATE" into an audit heading from this workflow.** Plan and review
  outcomes are logged as auto-approved decisions, not gated ones.
- The machine checkpoints that DO still stop the run are **not** approvals and remain fully in force:
  the **Doability Gate** and the **Story Branch dependency-merge check**. The Doability Gate **never
  merges a prerequisite's PR itself, not even one a human has already approved** — merging is always
  a manual action the user performs outside this workflow. It simply stops — naming the reason — for
  any prerequisite that isn't merged yet, whether it's unapproved, draft, conflicted, blocked by
  required checks, or already approved and just waiting on the user to merge it.
- A user who volunteers a correction at any point (plan, code, review finding) is an **interrupt** —
  apply it and continue. Never convert it into a standing gate.
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
| **SH-LOOP-7** | Behavioural B1 + B2 (Gherkin) | Step 6.1 | This unit's scenarios pass with every AC tag executed, AND every other feature file in the repo stays green |
| **SH-LOOP-8** | Behavioural B3 (epic scope) | Step 6.1 | On the LAST work unit only: the whole cycle suite + the `spec/behavior.feature` cross-unit journeys pass |
| **SH-LOOP-2** | API & Contract Testing | Step 6.2 | Every applicable checklist item passes on every touched endpoint |
| **SH-LOOP-12** | Test Placement Verification | Step 6.3 | Zero violations — every new/changed unit test under `tests/unit/<mirror-of-src>/`, every new/changed API test under `tests/api/`, none under `src/` |
| **SH-LOOP-3** | Full Regression | Step 6.5 | Zero NEW failures versus `baseline-regression.log` |
| **SH-LOOP-4** | Static Eval D1–D7 | Step 6.6 | Zero NEW findings above the `tests/.evals/config.json` thresholds on changed files |
| **SH-LOOP-11** | Playwright UI Automation | Step 6.7 | Every generated Playwright spec passes (zero `test.fixme()` outcomes), when the story touches UI |
| **SH-LOOP-13** | Playwright E2E Regression | Step 6.8 | Zero NEW failing Playwright specs versus the Step 1.5 Item 4.7 baseline — runs for EVERY story, UI or not |
| **SH-LOOP-6** | Judge Gates J1 + J2 | Section A Step 2.5 | `J1 ≥ llmJudgeArchitectureScoreMin` **and** `J2 ≥ llmJudgeSecurityScoreMin` (`N/A` passes) |
| **SH-LOOP-5** | Auto-Remediate (code review + security findings) | Section C | Review verdict clean — zero 🔴 and zero 🟠 |
| **SH-LOOP-9** | CI Preflight (provisioning + manifest executability) — **N/A when `## CI/CD Configuration` `Enabled: No`** | Section D Step 2.5 | Every CI entrypoint runs in a clean room with zero missing tools, zero undeclared dependencies, zero Manifest defects, and no gate `N/A`/qualified-pass on a root this unit touched |
| **SH-LOOP-10** | CI Attestation (post-PR provisioning agreement) — **N/A when `## CI/CD Configuration` `Enabled: No`** | Section D Step 8 | CI's `gates` block agrees with this story's own local gate results on every root the diff touched — no gate the diff touched is absent, `N/A`, or provisioning-errored in CI when it passed locally |
| **SH-LOOP-16** | Artifact Completeness | Section D Step 1.2 | Every evidence file `common/work-unit-artifacts.md` Section 1 requires for this unit exists, has its set format, agrees with `eval.json` / `eval-summary.md`, and no folder exists for an `N/A` gate |

**SH-1 — Attempt budget.** Each loop is allowed a **maximum of 3 remediation attempts**. One attempt
is one complete `fix → re-verify` cycle. The initial verification run that first detects the failure
is **not** an attempt (it is attempt 0). Attempts are numbered 1, 2, 3.

**SH-2 — Counters are per-loop, independent, and never silently reset.** Maintain a separate counter
per SH-LOOP ID. A counter is never shared between loops, never reset by another loop's success, and
never reset by advancing to a later gate. When a later loop's remediation forces re-entry into an
earlier loop (for example Section C re-running the Step 6.5 regression diff), that re-entry **continues the earlier loop's existing
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
   external tracker. The story stays `In Development` on its story branch. The attempted fixes stay in the working tree for inspection.
3. Record the halt in the work unit's `## Progress` (`HALTED — …`, `common/self-heal-limit-guidance.md`
   Section 1) and emit the **Self-Heal Limit message** (the Retry-Limit Report —
   `common/self-heal-limit-guidance.md` Section 2, with the "HOW TO FIX IT YOURSELF" steps taken from the
   Section 3 playbook row for this loop) as the run's final output.
4. Append the same content to `runtime-artifacts/audit.md` under the heading
   `## Self-Healing Retry Limit Reached — [SH-LOOP-ID] (Story N.M)`, carrying the standard
   `**TRACKER ITEM**:` and `**Epic Link**:` fields.
5. **HALT and wait for the developer's manual fix.** Do not resume, re-attempt, reroute, or skip the gate on your own
   initiative. The developer fixes the problem manually and types `dev-implement` again; that hand-back
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
- **Work unit** = this story, **Branch** = the branch it stays on (on its story branch);
- **HOW TO FIX IT YOURSELF** steps 1, 2, 4, 5 and **Please do NOT** taken from the Section 3 playbook row
  for the exhausted SH-LOOP, with real commands resolved from `tests/.evals/config.json` and real
  evidence paths;
- **resume keyword** = `dev-implement`.

It tells the developer exactly what is failing, why the framework stopped, what the three attempts
changed (left in the working tree), how to reproduce and fix it themselves, what the gates will reject,
and how to hand the work back. It asks the developer to fix it manually and offers no options. The
hand-back grants a fresh budget for the halted loop only; every other loop keeps the counter it already
held.

---

## MANDATORY: Rule Details Loading

This workflow may be invoked standalone (the user just types `dev-implement`, possibly in a fresh session). Before doing anything else, resolve the rule details directory (check  `aire-workflow/`) and load:
- `common/process-overview.md`, `common/session-continuity.md`, `common/content-validation.md`
- The REQ-ID thread rules from `common/requirements-traceability.md` (plan-level trace + fallback coverage verification)
- The eval rules from `common/eval-framework.md` (the Static Eval Gate D1–D7 at Step 1.5 Item 4.6 + Step 6.6, and the J1/J2 judge scores inside Section A)
- `common/work-unit-artifacts.md` — the complete evidence set this run must leave behind (paths, the `evidence-manifest.md` format, the N/A-means-no-folder rule, keyed security-review names) and the Artifact Completeness Check before the commit
- `common/self-heal-limit-guidance.md` — the Self-Heal Limit message, the per-gate manual-fix playbook and the hand-back (resume) protocol used when a self-healing loop exhausts its budget or a tool cannot be installed
- The branching model from `common/branching-strategy.md` (epic branch → story branches)
- **CI/CD is opt-in** — before touching any CI-specific step, read `## CI/CD Configuration` in `runtime-artifacts/aire-state.md` (recorded at `CLAUDE.md`'s MANDATORY STOP Step 1.2). `Enabled: No` means Section D's Manifest Reconciliation (Step 1.5), CI Preflight Gate (Step 2.5) and CI Attestation Gate (Step 8) are ALL skipped — go straight from the commit to the push + PR, then Section E. `Enabled: Yes` (the default when CI/CD was set up) means the CI contract from `common/ci-pipeline-generation.md` — **Section 4.0d** (working directory is a manifest fact), **Section 4.0f** (manifest reconciliation, Section D Step 1.5), **Section 4.0i** (the CI Preflight Gate, Section D Step 2.5) and **Section 6.6** (which repair agent owns which failure once the PR exists) — applies in full. Load it at the latest when Section D is reached — the preflight and attestation gates are unexecutable without it.
- Story selection steps from `implementation/story-selection.md`
- The detailed code generation steps from `implementation/code-generation.md`. 🔴 **Follow the Guardrail defined there (Generation Phase Rules)** for any generated code.
- 🔴 **Do NOT pre-load** `extensions/testing/playwright-automation/playwright-automation.md` or `implementation/test-plan.md` — Step 6.7 reaches them by **invoking the `ve-implement` and `playwright-implement` skills in WORKFLOW MODE**, and each skill loads its own rule files.
  🔴 **BUT: those files carry the anti-shortcut rules, and you will not have read them if you skip the skill — a circular trap that has caused a real violation.** So the three non-negotiables are restated HERE, where they are always in context:
  1. **The ONLY permitted producer of `tests/e2e/**` and `spec/playwright-specs/**` is the `playwright-implement` skill's own Planner/Generator subagents.** If you are about to `Write`/`Edit` a `.spec.*` file and no `Skill(playwright-implement)` call has happened this run, you are violating the gate.
  2. **"The Playwright agents aren't installed" is an instruction to INSTALL them** (`npx playwright init-agents --loop=claude`), then HALT for a session restart. It is never permission to hand-author.
  3. **Disclosing the shortcut does not make it allowed**, and a prior story that did it is a defect to backfill, not precedent.
- The reviewer steps from `workflows/code-review.md` (auto-run after code generation) and the fixer steps from `workflows/remediate.md` (on the Remediate path)

🔴 **GUARDRAIL — `code-review` and `remediate` are WORKFLOW RULE FILES, NOT Claude skills.** Whenever this workflow "runs Code Review" or "runs Remediate", you MUST `Read` and follow `workflows/code-review.md` / `workflows/remediate.md` (which pull their detailed steps from `implementation/code-review.md` / `implementation/remediate.md`) as instructions. There is **NO** Claude skill named `code-review` or `remediate` — **NEVER** invoke one via the Skill tool.

🔴 **The converse guardrail — these four ARE real Claude skills, and are INVOKED via the Skill tool, never re-implemented inline**: **`ve-implement`** and **`playwright-implement`** (Step 6.7, both in **WORKFLOW MODE** with the story passed in), **`pr-generator`** (Section D, workflow mode), and **`pr-review`** (Section E, AUTO MODE). Copying their steps into this workflow instead of invoking them is a defect — it forks the mechanics and lets the manual and automatic paths drift apart.

This workflow also uses the **`pr-generator`** Claude skill (`.claude/skills/pr-generator/`) to push the branch and raise the PR — always pass it the **target branch** explicitly (story PRs target the **Epic Branch** from `runtime-artifacts/aire-state.md` `## Branching`). Passing a target means it runs in **workflow mode**, where its Phase 5 confirmation is **skipped** and the push + PR happen **automatically** (the user's `dev-implement` invocation is the authorization). **NEVER edit that skill — invoke it as-is.**

After the PR is raised (the story STAYS `In Development` — it is promoted to `Ready for Testing` only when the PR MERGES), this workflow also auto-invokes the **`pr-review`** Claude skill (`.claude/skills/pr-review/`) against that same PR in its **AUTO MODE** — it posts a plain COMMENT review (summary + inline comments) automatically, with no user prompt and no formal GitHub approve/request-changes. **NEVER edit that skill — invoke it as-is.**

This workflow does **NOT** itself flip any story's tracker status to `Ready for Testing` — that promotion is performed ONLY by the **`ve-list-work`** skill (`.claude/skills/ve-list-work/`), which ve runs separately on the epic branch after it has tested the merged stories. Instead, when the user picks a story that `requires` another story, the **Doability Gate** (`implementation/story-selection.md` Step 4) checks that specific prerequisite's PR merge state LIVE, right there — if it's already merged the pick proceeds; **if it is not merged for any reason — including an already-approved PR just waiting to be merged — the gate blocks with a clear message and the run stops.** The gate never merges anything itself. See Step 1.5 below.

All paths below are relative to the resolved rule details directory.

---

## MANDATORY: Audit Entry Format for this Workflow — TRACKER ITEM on EVERY entry

**EVERY runtime-artifacts/audit.md entry written during a `dev-implement` run — from Story Selection, through the Story Branch checkpoint, code-generation planning, code generation done, Unit Test & Coverage, automated Code Review, Remediate, and Approve/PR — MUST include the `**User Email**:`, `**TRACKER ITEM**:`, `**Epic Link**:` and `**AIRE VERSION**:` fields.** No dev-implement audit entry may omit them.

```markdown
## [Stage Name or Interaction Type]
**Timestamp**: [ISO timestamp]
**User Email**: [current session email — read live from the session context]
**User Input**: "[Complete raw user input - never summarized]"
**TRACKER ITEM**: "[Complete tracker item (Jira ticket / ADO work item / GitHub issue / local Story ID) that was implemented]"
**Epic Link**: "[Full Parent Epic URL as a clickable link, from ## Tracker in runtime-artifacts/aire-state.md — or "none"]"
**AIRE VERSION**: "[Framework version [N] read from the "AIRE Framework Version" line in CLAUDE.md — do not hardcode]"
**AI Response**: "[AI's response or action taken]"
**Context**: [Stage, action, or decision made]

---
```

- **AIRE VERSION**: read at runtime from the canonical "AIRE Framework Version" line in `CLAUDE.md` — this records which framework version the work unit was developed with. Never omit it and never hardcode a literal version.
- **Epic Link**: the FULL Parent Epic URL read from `## Tracker` in `runtime-artifacts/aire-state.md` (Epic URL line), written as a clickable Markdown link `[EPIC-ID](<site-base-url>/browse/EPIC-ID)` for JIRA/ADO/GITHUB. If `## Tracker` records `Parent Epic: none` (or `Type: LOCAL` with no Epic), write `none` — the field itself is never dropped.
- For a tracker-linked story, write the item as a clickable Markdown link (`[PROJ-XXX](<site-base-url>/browse/PROJ-XXX)` for JIRA, the work-item/issue URL for ADO/GITHUB) — never bare text.
- For local-only stories (`Tracker ID = —`/`LOCAL`), put the local Story ID (e.g., `Story 1.2 (local — no external tracker)`) in the same field — the field itself is never dropped.
- This applies to every step's entries: selection prompt/response, automatic In-Development transition, branch creation (or Case B stop), plan approval, per-step generation logs, coverage evidence, review outcome, remediate outcome, and the commit/push/PR result.

## 🔴 PARALLEL-SAFE STATE — THIS STORY WRITES ONLY ITS OWN FRAGMENT (`common/parallel-work-state.md`)

Several developers run `dev-implement` on different stories at once, each on its own story branch. So
that their PRs never conflict on the framework's bookkeeping, **this workflow never writes the shared
`runtime-artifacts/audit.md` or `runtime-artifacts/aire-state.md`**:

- **Every audit entry this file tells you to append to `runtime-artifacts/audit.md` goes to
  `runtime-artifacts/stories/story-<N.M>/audit.md`** (same entry format, plus `**Unit**: "story-<N.M>"`).
  Entries logged before the story is chosen (the selection prompt) are held and written there, with
  their original timestamps, as soon as the story is known.
- **Every write this file makes to this story's `## Story Tracker` row, its progress or its SH counters
  goes to `runtime-artifacts/stories/story-<N.M>/state.md`** — the claim (`Ready for Development → In Development`, Start, assignee),
  the PR URL, `Merged = no`, `Recorded`.
- This **overrides every mention of those two shared paths below**. Reads (Doability Gate, "last unit"
  detection, the Epic "first story" check, resume) use the **resolved view** — shared files plus every
  fragment on the branch (`common/parallel-work-state.md` Section 4).
- 🔴 **State Isolation Check before every commit** (Section D Step 2, and any `fix(ci)` commit):
  every changed path under `runtime-artifacts/` must be inside `runtime-artifacts/stories/story-<N.M>/`;
  anything else is moved into the fragment and the shared file restored to the merge-base
  (`common/parallel-work-state.md` Section 5.5).

---

## Step 1 — Keyword Behavior (on invocation)

1. **Read `## Branching`** from `runtime-artifacts/aire-state.md` (Base Branch + Epic Branch). If missing, run `common/branching-strategy.md` Section 1 now (create the epic branch) before proceeding.
1.5. ** No bulk STATUS reconciliation here (by design)**: dev-implement does NOT promote any story's **status** at the start of a run — it never moves a story to `Ready for Testing` in the Story Tracker or the external tracker, for any story, ever (that is `ve-list-work`'s job alone). It never merges a PR either — merging is always the user's own manual action. Dependency readiness is then verified **live, per prerequisite**, inside the **Doability Gate** (Step 2 below → `implementation/story-selection.md` Step 4) at the moment a story with `requires` is picked:
   - Each prerequisite's PR is checked directly (`gh pr view <PR> --json state,mergedAt,baseRefName,isDraft,reviewDecision,mergeable,mergeStateStatus,author,reviews`) unless its Story Tracker `Status` already reads `Ready for Testing`.
   - **Merged (or already `Ready for Testing`)** → that prerequisite is doable; proceed.
   - **Anything else — OPEN (approved or not), draft, conflicted, blocked by checks, CLOSED (not merged), or no PR yet** →  the Doability Gate BLOCKS with a clear message naming the unmerged prerequisite and its PR, and the run STOPS — no story/tracker status is changed by dev-implement itself. 🔴 **`dev-implement` never merges the prerequisite's PR itself, not even an already-approved one** — merging is always the user's own manual action; when the PR is already approved the stop message says so, so the user knows merging it is all that's left.
   The Story Tracker/tracker **status** is moved to `Ready for Testing` only when ve runs the **`ve-list-work`** skill on the epic branch — it lists the stories whose PRs have merged and promotes the ones ve confirms it has finished testing.
1.7. **🔴 SINGLE-SESSION EXECUTION (MANDATORY — on EVERY invocation, before Story Selection)**: `dev-implement` runs **from start to finish in the session where the user typed it**. It never forks itself and never delegates any part of the run to another execution context.
   - **Never delegate** the workflow or any step of it — story selection, branching, baselines, planning, code generation, any gate, the Code Review pass, the J1/J2 judging, remediation, manifest reconciliation, the commit, the preflight, the push, the PR, the attestation or the PR review — to an Agent-tool fork, a general-purpose / Explore / Plan subagent, the Workflow tool, a background or remote agent, a second Claude Code session, or a `claude -p` subprocess. Every one of those steps is performed **by this session's own tool calls**.
   - The `agents/*.md` files this workflow loads (`code-security-review-agent.md`, `ve-implement-agent.md`, `playwright-implement-agent.md`) are **procedures executed inline in this session**, never spawned as subagents. The Code Review pass (Section A) is kept read-only **by discipline** — no `Edit`/`Write` on `src/**` or `tests/**` during that pass — never by spawning a read-only subagent. The skills this workflow invokes (`ve-implement`, `playwright-implement`, `pr-generator`, `pr-review`) run **inline** via the Skill tool.
   - Long-running suites run through this session's own shell. A command may run in the background only if this session waits for it to finish and reads its result before advancing — no gate ever advances on a result it has not read.
   - 🔴 **The ONE permitted Agent-tool use** is Playwright's own official **Planner / Generator / Healer** test agents, invoked by the `playwright-implement` skill inside Step 6.7, **one call at a time, synchronously**, with this session waiting on each. They are Playwright's installed test agents, not a fork of this workflow, and nothing else in the run may be handed to them.
   - **If this run is itself executing inside a fork or a subagent** (its own instructions say it is a fork or a subagent, tell it to "execute directly" / not to spawn agents, or the Agent tool is unavailable to it) → **HALT NOW, before Story Selection**, for every story — backend-only included. Change nothing (no tracker move, no branch, no baseline) and output:
     ```
      dev-implement MUST RUN IN YOUR OWN SESSION
        This run is executing inside a [fork | subagent]. dev-implement never runs delegated —
        every step, from story selection to the PR, happens in the session you typed it in.
        Nothing was changed: no story was claimed, no branch was created, nothing was committed.
     Type dev-implement in your main Claude Code session.
     ```
     Record the halt in `runtime-artifacts/audit.md`.
   🔴 **A fork is NEVER a reason to hand-author Playwright specs** (`implementation/code-generation.md` Step 11d, Part B catch-all). Observed in a real run: `dev-implement` inside a fork silently hand-authored five `.spec.ts` files instead of halting, producing a "passing" gate that never exercised a browser — which is why a fork now halts the whole run up front instead of only the UI gate.
1.75. ** Sequential-development banner (MANDATORY — show on EVERY invocation, before Story Selection)**: display this note to the user verbatim, then continue:
   ```
    Note: stories are NOT to be developed in parallel in this session — dev-implement builds ONE story at a time, sequentially (each story branch is cut from the epic branch).
   To develop stories in parallel, open a NEW folder/clone of this same repo, check the Dependency Graph, and run dev-implement there on an INDEPENDENT story.
   ```
1.8. **▶ RESUME AFTER A HALT OR PAUSE (MANDATORY — before Story Selection)**: a `PAUSED —` record (a Playwright agent install needing a session restart — from Playwright Readiness, Step 4.3, or the Step 6.7 safety net) → continue the story at the step it names, skipping everything already done — no change check is needed. Otherwise, if a story in this clone has a `HALTED —` record in its `## Progress` (`runtime-artifacts/stories/story-<N.M>/state.md`) — a self-healing limit (SH-4 / SH-5) or a tool-installation halt from an earlier run — and its story branch is checked out (or it is the only halted story), this invocation is the developer **handing the work back**: follow the resume protocol in `common/self-heal-limit-guidance.md` Section 4 — announce the resume, check what the developer changed (nothing changed → re-show the Self-Heal Limit message and stop; a forbidden shortcut → list it and stop; otherwise continue), skip Story Selection, branch creation and the baselines, grant the halted loop a fresh 3-attempt budget, never revert the developer's changes, and re-run from the first code gate (Step 6) — or from the halted gate for declaration-only changes — through every later gate to Section F. More than one halted story and none checked out → list them and ask which one to resume (a halt, not a gate). No halted story → continue to Step 2.
2. **Story Selection + Doability Gate**: execute `implementation/story-selection.md` in full — it asks which story (Story ID / number, title, or Tracker ID), reads it from the local Story Tracker / `stories.md` (or resolves the Tracker ID), runs the Doability Gate (**which only ever reads PR state — it never merges a prerequisite's PR itself, not even an already-approved one**), and moves the story from `Ready for Development` to `In Development` **automatically** (picking the story is the claim — the tracker and the Story Tracker are both updated without asking, the transition verified for non-LOCAL, and the issue is **assigned to the operator who invoked `dev-implement`** per `common/tracker-sync.md` Section 5, verified, non-blocking on failure). Do NOT re-implement the prompt or the gate here.
3. ** Story Branch checkpoint (MANDATORY — immediately after story selection)**: In the SAME interaction where the story is chosen, create the story branch per **Step 1.5** below. Do NOT begin Code Generation until the story branch is created and active.
4. Only once the Doability Gate passes **and** the story branch is active **and** the BASELINE regression has been captured (Step 1.5 Item 4.5), proceed with **Code Generation** (Part 1 Planning → Part 2 Generation → unit tests to `unitTestCoverageMin` coverage → FULL regression vs baseline).

---

## Step 1.5 —  Story Branch checkpoint (MANDATORY)

Runs **after** Story Selection resolves the story (Doability Gate passed, story marked `In Development` on BOTH the external tracker and the fragment, assignee set, and the fragment's `## Claim` block written from the verified calls — `implementation/story-selection.md` Steps 5–6; 🔴 no `## Claim` block, no branch) and **before** Code Generation Part 1. Execute **`common/branching-strategy.md` Section 3 — Story Branch Creation** in full. Summary (the strategy file is authoritative):

1. **Log the prompt** in `runtime-artifacts/audit.md` (ISO 8601 timestamp) before asking anything.
2. Derive the branch name automatically — `story/<N.M>-<kebab-case-story-title>` (Tracker ID prefixed when present and non-LOCAL) — and **create it without asking**.  **No confirmation, no override prompt**: the name is fully determined by the story ID + title. Announce it (` Story branch: <name> (cut from <epic-branch>)`). On a name collision, append a short disambiguating suffix automatically and announce that too.
3. **Refresh the epic branch** (`git fetch origin && git checkout <epic-branch> && git pull --ff-only`), then run the **dependency-merge check** on the story's `requires`:
   - All prerequisites merged into the epic branch (or none) → cut the story branch **from the epic branch** (NEVER from main/the base branch).
   - Any prerequisite NOT merged →  **WARN AND STOP** with the Case B message from branching-strategy.md Section 3: tell the user to merge the prerequisite's PR into the epic branch first, do NOT create a story branch (there is no alternative base), revert the story to `Ready for Development` (external tracker, verified), delete the uncommitted fragment `runtime-artifacts/stories/story-<N.M>/` (nothing of it was committed), print the held audit entries in the stop message (`common/parallel-work-state.md` Section 5.1 — never into the shared `audit.md` from this checkout), and END this `dev-implement` run — the user re-invokes it after merging.
4. **Record in runtime-artifacts/audit.md**: the story branch name, the base it was cut from, and the user's raw responses.
4.5. **🧪 BASELINE Regression Run (MANDATORY, AUTOMATIC — BEFORE any code is generated)**: on the freshly cut story branch, run the **ENTIRE repo test suite** (not just this story's area) and save the raw runner output to `reports/unit-test-evidence/story-[N.M]/baseline-regression.log`. Record the pass/fail counts and the full list of failing tests in runtime-artifacts/audit.md. This is the reference point the post-implementation regression gate is diffed against. **No user prompt — capture it and continue.**
   - Any failures here were already present on the epic branch (introduced by a PREVIOUSLY MERGED story, not this one). **Logging them in `baseline-regression.log` is all that is required — do not try to fix them, and do not block on them.** They exist only to define what "already broken" means, so the post-implementation gate can tell this story's breakage apart from everyone else's.
   - If the repo has no test suite at all, record that explicitly in runtime-artifacts/audit.md — the post-implementation gate then covers only this story's new tests.
4.6. ** BASELINE STATIC EVAL RUN (MANDATORY, AUTOMATIC — same moment, BEFORE any code is generated)**: on the same freshly cut story branch, run the **Static Eval Gate checks D1–D7** per `common/eval-framework.md` Section 2 (lint, type check, SAST, dependency vulnerabilities, licences, complexity, secrets) and save the raw output to `reports/eval-evidence/story-[N.M]/static/baseline/`. **No user prompt — capture it and continue.**
   - Exactly like the baseline regression: **every finding here is pre-existing debt on the epic branch, NOT this story's.** Record it and move on — do NOT fix it and do NOT block on it. It exists only to define "already broken" so Step 6.6 can tell this story's findings apart.
   - ** BOOTSTRAP FIRST (eval-framework.md Section 2.3, MANDATORY — same step, immediately BEFORE the baseline run)**: for every check with **no config in the repo**, create the minimal *recommended* config (eslint/ruff/golangci, tsconfig/mypy, `.gitleaks.toml`, the linter's complexity rule at the `tests/.evals/config.json` threshold) so the check is actually runnable. **A check whose config exists is used AS-IS** — the repo's own standards win, never overridden or "upgraded". Announce every file created and log it in runtime-artifacts/audit.md (`bootstrap` block of `eval.json`) — it adds files to the user's repo, so it is never silent; those files commit with this story. 🔴 **AND INSTALL THE TOOLS — retried, never skipped (Section 2.4.1)**: for every gate, work the chain *already present → package manager → alternative installer → **OCI image via Podman***, 3 attempts per rung, verifying each install with a version command. Recording a gate `N/A` for a missing tool **before the Podman rung has been tried** is a bootstrap failure, not an `N/A`. If the whole chain is exhausted, **HALT with the per-rung report** — never continue with an unmeasured gate, and never phrase deferred setup as `N/A` ("not wired yet", "not installed", "not enabled yet" — all ERROR, Section 2.5.2).

🔴 **A MISSING TOOL IS NEVER A QUESTION.** Observed in a real run: the workflow reached D1/D5/D6 with no linter, licence scanner or complexity tool configured for the stack, and **asked the user** *"How should I handle the remaining static-eval gaps?"* with a recommended option. That is a double violation — this workflow asks nothing after the story key, and a tooling gap already has a defined answer: **run the Section 2.4.1 bootstrap chain** (already present -> package manager -> alternative installer -> **OCI image via Podman**), 3 attempts per rung. If the whole chain is exhausted, **HALT with the per-rung report** — which is a halt, not a question, and never a proposal to skip the gate. Emit it as the **"A check can't run" message in `common/self-heal-limit-guidance.md` Section 5** (what was tried per rung, the install command to run by hand, how to hand the work back) and record the halt in `## Progress` so the resume protocol picks it up. 🔴 Never ask the user to choose between closing a gate and deferring it; deferring is not on the menu (Section 2.5.2).
     - 🔴 **ORDER MATTERS**: bootstrap → baseline → generate code → Step 6.6 → diff. A config created AFTER the baseline would make the baseline and the post-change run measure under **different rules**, so every finding it surfaces on pre-existing code would be blamed on this story. Never bootstrap later than this point.
     - 🔴 Recommended presets, never strict/all, and **never a config that pre-suppresses findings** (no seeded rule-offs, no source-tree excludes) — bootstrap makes the check runnable, never makes it pass.
   - 🔴 A check is recorded `N/A` **only after the full Section 2.4.1 install chain — including the Podman image rung — has been attempted and recorded**, and only for a reason on the Section 2.5.1 closed list (inapplicable to this stack / to this work unit / no such tool exists). If the chain is exhausted, that is an **ERROR: HALT** with the per-rung report — never `N/A`, never silently skipped, and never phrased as deferred work ("not wired yet", "not installed", "not enabled yet").
4.7. **🧪 BASELINE PLAYWRIGHT E2E REGRESSION RUN (MANDATORY, AUTOMATIC — same moment, BEFORE any code is generated)**: on the same freshly cut story branch, run the **ENTIRE existing `tests/e2e/` Playwright suite** — every spec earlier stories already shipped (this story has none yet) — and save the raw output to `reports/playwright-test-evidence/story-[N.M]/regression/playwright-baseline-regression.log` plus the **mandatory machine-readable** `playwright-baseline-report.json`. **No user prompt — capture it and continue.**
   - **Why this exists**: it is the UI counterpart of Item 4.5. Step 6.7 only ever proves **this story's own** new specs pass; nothing else in the run proves this story did not break a browser flow an earlier story already shipped. Without a pre-change photograph there is no way to tell "this story broke it" from "it was already red".
   - 🔴 **Applies to EVERY story, UI or not — do NOT skip it because this story touches no UI.** A backend handler, a changed API response shape, a renamed field, a migration or a dependency bump is exactly what silently breaks an existing browser flow, and that is the case this baseline exists to attribute correctly.
   - **Start the app the same way Step 6.7 does** — the `startCommand`/`readinessUrl` recorded in `tests/.evals/config.json` `ci.playwright` (plus `backendStartCommand`/`backendReadinessUrl` when the local gate needed two processes), resolved from the project's own scripts, **never invented**. Poll readiness first; tear the server(s) down on every exit path.
   - **Run headless.** 🔴 A deliberate, narrow carve-out from the `--headed` rule that governs Step 6.7: that rule exists so the developer can *watch* the specs being authored for the story in hand. This is a bulk sweep of already-approved specs nobody watches, so headless is the default here, for speed. Record `"headed": false, "reason": "bulk regression sweep, not the authoring gate"` in the evidence manifest.
   - **Failures here are pre-existing** — logged, never fixed, never blocking, exactly like Item 4.5's. They exist only to define "already red" so Step 6.8 can attribute correctly.
   - **`N/A` only when there is genuinely nothing to regress**: `tests/e2e/` holds no spec files at all (no earlier work unit generated any). Record the reason explicitly — 🔴 never a silent skip, and 🔴 never `N/A` merely because *this* story has no UI.
   - **Specs exist but Playwright is not installed on this machine** (a fresh clone, a new developer): install it now — the project's dependencies (`npm ci` or equivalent, which brings `@playwright/test` when it is a dev dependency) and the browsers (`npx playwright install`) — announced, never asked, then run the sweep. 🔴 A missing runner or browser is never a reason for `N/A`; only an empty `tests/e2e/` is. The official test agents are not needed for this sweep.
4.4. **Install the work-unit guard (MANDATORY, automatic)** on the freshly cut story branch: `sh aire-workflow/templates/hooks/check-work-unit.sh --install story-[N.M]` (`common/work-unit-artifacts.md` Section 6.2). Log the result.
5. Carry the story branch forward — it is the target branch for the commit/push/PR step after review. **Do NOT proceed to Code Generation until the branch is created and confirmed active** (`git branch --show-current` matches).

> **Multiple developers**: Each dev independently runs `dev-implement` and selects a different ready story. The Dependency Graph (`requires` on each story) plus the Doability Gate ensure no two devs pick stories with unresolved dependencies.

> **Design context**: The system-level design artifacts (functional/NFR/infrastructure) live under `spec/plans/` and apply to every story. Code for the story is written into the application structure defined in Application Design (or code-generation.md's structure rules).

---

# Code Generation (per-story)

**Runs once per story selected via `dev-implement`.**

**Two parts, preceded by Story Selection + Story Branch checkpoint:**
1. **Part 1 - Planning**: Create a detailed code-generation plan (implement layers, then the mandatory Unit Test & Coverage step).
2. **Part 2 - Generation**: Execute the approved plan to generate code and artifacts, then generate + run unit tests until coverage is ≥90% (same run).

🔴 **WORKING DIRECTORY IS A MANIFEST FACT (`common/ci-pipeline-generation.md` Section 4.0d/`common/eval-framework.md`
Section 1.1) — applies to EVERY install/build/lint/test/coverage command this stage runs, at Step 4.6,
Step 6, Step 6.6, and `code-generation.md`'s own Steps 11a/11a.5/11b/11c.** Before running any such
command:

1. Read `tests/.evals/config.json`'s `ci.roots[]`. A single-root repo has one entry (`root: "."`); a
   monorepo has one per package, matching `## Code Root` (`common/directory-structure.md`).
2. For the root that owns the file(s) this command targets, resolve
   `REPO_ROOT="$(git rev-parse --show-toplevel)"` **fresh** (never cached — this session may be one of
   several parallel clones opened per Step 1.75), then `cd "${REPO_ROOT}/<root>"` and verify the
   declared `markerFile` is present there before running the bare command (assumes `cwd == root`; never
   bake the subfolder back into the command's own flags).
3. A `cd` target that does not exist, or exists but is missing its `markerFile`, is a **Manifest
   defect** (Section 6.4's triage class) — stop and fix `tests/.evals/config.json`, never patch around it
   by inventing a different path.

**This is what makes CI's later re-run of the SAME manifest command trustworthy** (Section 7: *"CI
re-verifies in a clean environment what was verified on the developer's machine"*) — both sides read the
exact same `root` from the exact same file, never two independent guesses that happen to usually agree.
On a single-root repo this is a no-op `cd "."` plus a marker check; the discipline costs nothing there
and is what actually matters the moment a second root exists.

**Execution**:
1. **MANDATORY**: Log any user input during this stage in runtime-artifacts/audit.md.
2. Load all steps from `implementation/code-generation.md`.
3. **STEP 0 — Story Selection (MANDATORY)**: Execute `implementation/story-selection.md` in full — it is dependency-aware and self-contained. It asks which story (ID / number, title, or Tracker ID), shows the currently ready stories, runs the **Doability Gate** (proceed only if every `requires` is confirmed MERGED — already `Ready for Testing`, or live-verified via `gh pr view`; else  STOP the run with a clear message naming the unmerged prerequisite — the gate never merges it itself, even if already approved), and — **automatically, no confirmation** — moves the chosen story from `Ready for Development` to `In Development` in the Story Tracker + configured tracker (transition verified for non-LOCAL, announced), **assigns the issue to the operator who typed `dev-implement`** per `common/tracker-sync.md` Section 5 (session email → account lookup, verified, non-blocking on failure), setting `Start`/`Recorded`. If the story is already `In Development`, warn that it may be claimed by another dev. Do NOT re-implement the selection prompt or gate logic here.
3.5. **STEP 0.5 — Story Branch checkpoint (MANDATORY)**: Execute **Step 1.5** — create the story branch from the epic branch (dependency-merge check; on any unmerged prerequisite, warn and STOP per Case B — merge first) and record it in runtime-artifacts/audit.md. This branch is the target for the commit/push/PR step after review. Do NOT start Part 1 until the branch is active.
4. **PART 1 - Planning**: Create the code-generation plan with checkboxes — implementation steps per layer, ending with the mandatory **Unit Test & Coverage** step. ** GROUND THE PLAN in the previously generated docs**: every plan step MUST trace back to the story's acceptance criteria, `epic-brief.md`, `requirements.md`, and the design artifacts under `spec/plans/` + Application Design — never invent scope, files, or behavior not backed by those documents. ** DESIGN REFERENCE GROUNDING (`common/design-reference-grounding.md` Rule DR-5 — automatic, adds NO question and NO gate)**: execute `code-generation.md` **Step 1.5** silently — read the `### Reconciliations` table first (**DR-8**: points already decided against a reference by an earlier design stage are settled — follow the framework's design docs there and never reintroduce an excluded capability), then re-open every registered design reference in `runtime-artifacts/aire-state.md`'s `## Design References` that covers a component this story builds (a fresh read for THIS story's scope; "read in an earlier stage" does NOT count) and ground only the **unreconciled** points, and state per component either `Design reference: <path> — grounded (...)` or `Design reference: none covers this component`. On an unreconciled prototype/AC mismatch, apply **DR-6**: follow the design, say plainly in the plan what differed, amend the AC to stay truthful, record the reconciliation, and continue — it is stated plainly in the announced plan and in runtime-artifacts/audit.md; do NOT halt or ask. ** REQ-ID THREAD (`common/requirements-traceability.md` Rule 5)**: resolve the story's `Covers` REQ-IDs and read their text in `requirements.md` (the requirement, not just the AC restatement, is planning input), tag every plan step with the REQ-ID(s)/AC(s) it implements, and pass the trace completeness self-check (every covered REQ-ID and every AC in ≥1 step — blocking, fixed silently) BEFORE announcing the plan.

4.1. ** WRITE THE PLAN TO DISK (MANDATORY — `code-generation.md` Step 4, NOT optional, NOT satisfied by narrating the plan in chat or in audit.md)**: save the complete, finalized plan as its own file at **`spec/spec-generation/story-N.M-code-generation.md`** — numbered steps, checkboxes, story context/dependencies, and the REQ/AC trace summary. 🔴 **A plan that exists only as chat output or as an audit.md log entry does NOT satisfy this step** — the file on disk is the single source of truth Step 10 (Part 2) reads from and the one every step's `[x]` checkbox is marked against. **Verify the file exists on disk (re-`Read` it back) before proceeding to 4.2 — do not proceed on the assumption that "announcing" the plan wrote it.**

4.2. **Announce the plan and execute it immediately — there is NO approval gate.** Log it in runtime-artifacts/audit.md under a plain heading (e.g. `## Code Generation Part 1 — Plan Finalized (auto-approved, no gate)`) with the **path to the saved plan file** (`spec/spec-generation/story-N.M-code-generation.md`), the step count and the REQ/AC trace summary, per `code-generation.md` Steps 4 and 6. Never ask "Approve this plan?" and never write "GATE" into the heading.
4.3. **🎭 PLAYWRIGHT READINESS (MANDATORY WHEN the plan is frontend — automatic, before any code)**

**Applies only when this story's code-generation plan (Step 4.1) contains a _Frontend Components Generation_
step** — the plan is the single place that decides whether a work unit is frontend. No such step →
record `Playwright readiness: N/A — no Frontend Components Generation step in the plan` and continue.
Otherwise, before any code is written, make Playwright fully ready — **automatically, announced, never
asked**:

1. **Runner**: `@playwright/test` is in the project's dev dependencies — if not, add it with the project's
   own package manager (`npm i -D @playwright/test`, `pnpm add -D @playwright/test`, `yarn add -D
   @playwright/test`). A missing `playwright.config.*` is fine here — the Generator creates or extends
   it at the UI gate (`extensions/testing/playwright-automation/playwright-automation.md` Step 0a;
   root = workspace root, `testDir: tests/e2e`).
2. **Browsers**: `npx playwright install` (add `--with-deps` on Linux) when the browsers are not already
   present on this machine.
3. **Playwright's official test agents**: `.claude/agents/playwright-test-planner.md`,
   `playwright-test-generator.md`, `playwright-test-healer.md` and the `playwright-test` entry in
   `.mcp.json`. Missing → back up `.mcp.json`, run `npx playwright init-agents --loop=claude`, then merge
   the other MCP servers back (`init-agents` overwrites the file — playwright-automation.md Step 0a) and
   announce the merged server list. No confirmation is asked: the announced code-generation plan's
   Playwright Readiness step is the authorisation (the extension's confirm-first applies to standalone
   `/playwright-implement` only).
4. **Verify**: `npx playwright --version` succeeds, the three agent files exist, the `.mcp.json` entry
   exists. Record what was installed in the audit trail and in the plan's Playwright step.
5. **Session restart — only if step 3 ran.** Claude Code loads MCP servers when a session starts, so newly
   installed agents cannot be used until the session restarts. Record
   `PAUSED — Playwright agents installed — resume at Step 4.5 — <timestamp>` in the work unit's
   `## Progress` and emit, as the run's last output:
   ```
   Playwright is now set up for this frontend story.
      Installed:  <what was installed>
      One step is needed: restart Claude Code so it loads Playwright's test agents, then type dev-implement.
      (When epic-enhance or epic-bugfix run this step, the keyword shown here and used to resume is theirs.)
      I will continue from Step 4.5. The plan and the baselines are kept, and no code has been
      written yet.
   ```
   Typing `dev-implement` in the new session finds the `PAUSED —` record and continues at Step 4.5, skipping
   everything already done. Everything already installed → no pause.
6. **Install fails** after the full install chain → emit the "A check can't run" message
   (`common/self-heal-limit-guidance.md` Section 5) for Playwright, record `HALTED —`, nothing changed.

Because this runs here, the Playwright UI gate (Step 6.7) finds Playwright ready; its own install
handling remains only as a safety net.

4.5. ** VERIFY THE STORY'S BEHAVIOUR SPEC (MANDATORY — before any code)**: `spec/behavior/story-[N.M].feature` was **already written and approved at the STOP CHECKPOINT** (`CLAUDE.md` Step 1.7 / `implementation/specs-and-test-plans.md`) — this step READS it, it does not author it. Confirm the file exists, parses, and carries one `@AC-n`-tagged scenario per acceptance criterion of this story. **Present → backfill only if genuinely absent**: if the file is missing (legacy project, or a story added after the checkpoint), write it now per `common/behavior-spec.md` Section 2 and **announce the backfill explicitly** (`Behaviour spec for Story [N.M] was missing from the approved set — generated now at spec/behavior/story-[N.M].feature`). 🔴 **NEVER rewrite an approved scenario to match the code you are about to generate** — the spec is the contract, and code that cannot satisfy it is the thing that changes. A genuine spec defect is raised with the user, amended, and logged; it is never silently edited. 🔴 **That is still the ONLY spec file this story gets.** No per-story requirements, architecture, constraints or deep-dive document — the agent reads the tracker item + `stories.md` for ACs, `requirements.md` for the `Covers` REQ-IDs, `spec/plans/architecture.md` for design constraints, and `tests/.evals/config.json` for thresholds. Announce the file path and the scenario/AC counts; log the verification (or backfill) in runtime-artifacts/audit.md.
5. **PART 2 - Generation**: Execute the announced plan for this story, writing **all application code into `src/`** (or the recorded `## Code Root` for a brownfield repo — `common/directory-structure.md`) and nothing into `spec/`. 🔴 **TESTS GO IN THE REPO-ROOT `tests/` TREE — NEVER UNDER `src/` AND NEVER UNDER THE CODE ROOT**: unit tests -> **`tests/unit/`**, Gherkin step definitions -> **`tests/behavior/steps/`** (the tree `tests/.evals/behavior/run.sh` executes inside Podman), Playwright -> `tests/e2e/`. The `## Code Root` remapping above applies to **application code ONLY** — a brownfield repo whose code lives in `app/` or `packages/api/src` still writes its tests to the repo-root `tests/`, never `app/tests/` or `packages/api/src/tests/`. This is also what the manifest's `testPaths` records (`common/eval-framework.md` Section 1.1) and what the Podman mount and the coverage gate look at, so a test written anywhere else is invisible to both gates. ** PLAN FIDELITY**: implement EXACTLY the plan — no unplanned files, features, refactors, or scope drift; keep the generated code consistent with the design docs the plan was grounded in. If mid-coding you discover the plan must change, **revise the plan document, announce the revision (what changed and why) in your output and in runtime-artifacts/audit.md, and continue** — do not ask for approval, and never apply a deviation without recording it.
6. **UNIT TEST & COVERAGE GATE (threshold from `tests/.evals/config.json`) — MANDATORY, same run**: After the story's implementation is complete, execute the Unit Test & Coverage step defined in `code-generation.md` (Step 11a): generate unit tests for all new/changed code, RUN them, measure coverage, and if coverage is below `unitTestCoverageMin` add/adjust tests (and fix any defects the tests expose) within the SAME run until ≥90% is reached.  **This is SH-LOOP-1 — capped at 3 remediation attempts (SH-1). On exhaustion apply SH-4: HALT, emit the Retry-Limit Report, and do NOT proceed below the threshold.** While the story is still `In Development`, **capture the PROOF artifacts of this run** to `reports/unit-test-evidence/story-[N.M]/` — the raw runner output (`unit-test-run.log`), the coverage tool's **mandatory machine-readable report** (`coverage-report.*` — lcov/xml/json/HTML, produced by running the tool with the report-emitting flags such as `--cov-report=xml` / `--coverageReporters=lcov`; a terminal summary alone does NOT satisfy the gate), and an `evidence-manifest.md` (command run, tests X/X, measured coverage %, artifact links). These stored artifacts — not a hand-written claim — are the evidence carried into Code Review and the PR/tracker comment; every figure reported downstream MUST match them.
6.1. ** BEHAVIOURAL TEST GATE — GHERKIN, THREE TIERS (MANDATORY, AUTOMATIC — after the Unit Test & Coverage gate, same run)**: execute the tiered behavioural gate defined in `common/behavior-spec.md` Section 4.4. Implement the step definitions in `tests/behavior/steps/` bound to the application's **public surface** (endpoint / service method / CLI) — never to internals — then run the tiers **in order**:

1. **B1 — Unit scope**: this work unit's own `spec/behavior/story-[N.M].feature`. **Verification**: every scenario passes AND every `@AC-n` tag is executed.
2. **B2 — Cumulative scope**: every **other** feature file already in the repo — earlier work units in this cycle plus everything from prior cycles. **Verification**: all green. 🔴 A B2 failure is THIS unit's problem — it turned that scenario red, so it fixes it. "That scenario belongs to another story" is not a defence.
3. **B3 — Epic scope** (🔴 **last work unit of the cycle ONLY**): B1 ∪ B2 **plus** the cross-unit journeys in `spec/behavior.feature`, tagged `@REQ-<id>`. 🔴 Detect "last" from **PR MERGE STATE, never the tracker status label** (`common/behavior-spec.md` Section 6.1): for every OTHER work unit read its PR from the Story Tracker and verify live with `gh pr view <n> --json state`. **All others merged → this is the last unit → RUN B3** — including the normal case where those units are still `In Development` awaiting Verification Engineer sign-off, because the label lags the merge. Defer ONLY when a unit has no merged PR, recording `B3: N/A — not the last work unit: <n> units with unmerged PRs (<list with PR state>)`. 🔴 Never defer on a status label alone, and never report a deferred B3 as a pass.

**Execution** — 🔴 **every tier runs in a Podman pod** (`common/behavior-spec.md` Section 5): the image built from `tests/.evals/behavior/Containerfile`, plus a fresh ephemeral **test database** where the repo needs one, invoked through `tests/.evals/behavior/run.sh <tier>` with **`AIRE_STORY_KEY` exported to THIS work unit's key** (e.g. `story-1.10`, the stem of its own `spec/behavior/<key>.feature`) — `podman run -e AIRE_STORY_KEY=<key> …`. 🔴 Without it B1 cannot identify which unit is under test and refuses to guess; it used to take the lexicographically last feature file, which returns `story-1.9` when `story-1.10` is the unit being built — passing B1 without ever testing it — the same image and command a developer runs locally, so a CI-only failure is impossible by construction. 🔴 **The ONLY permitted native run is Podman not being installed** (proven by `command -v podman`), recorded as `"containerised": false, "reason": "podman not installed"`. 🔴 "No browser needed", "backend only", "no new dependency" and "faster natively" are **forbidden justifications** — a tier recorded that way is a gate violation, not a pass. Never fall back to the Docker CLI. A tier runs only once the previous is green.

**Evidence** — per tier that runs, to `reports/behavior-test-evidence/story-[N.M]/<b1|b2|b3>/` (🔴 `b3/` is created **only on the last work unit, when B3 actually runs**; a deferred B3 creates no folder — its `N/A` and reason live only in `eval.json` / `eval-summary.md`, `common/work-unit-artifacts.md` Section 1.1): `behavior-test-run.log`, the **mandatory machine-readable** `behavior-test-report.*`, and an `evidence-manifest.md` recording the image ref + digest, the exact command, whether it ran containerised, the tier's feature-file set, and every scenario with its tag and result. A raw log alone does NOT satisfy the gate.

**Self-healing** —  **B1/B2 failures → SH-LOOP-7; B3 failures → SH-LOOP-8, its own separate 3-attempt budget** (an epic-scope failure is usually an integration gap between units, not a bug inside one, so arriving at the epic gate with the story budget already spent must not halt the cycle). Both capped at 3 attempts; on exhaustion apply SH-4 — HALT and emit the Retry-Limit Report.

🔴 **Fix the code, never the scenario.** A scenario changes only when the AC or requirement it encodes genuinely changed — and then the AC, `requirements.md` and the tracker item are amended together and the reconciliation is logged. Deleting, skipping or `@ignore`-ing a scenario to go green is forbidden (SH-6).

**N/A** — B1 is N/A only for a work unit with no externally observable behaviour (pure build-config or docs change); a unit with acceptance criteria is never N/A. B2 is N/A only when the repo genuinely contains no other feature file. Record the reason explicitly.

6.2. ** API & CONTRACT TESTING GATE (MANDATORY WHEN APPLICABLE — same run)**: **Applicability is plan-derived and automatic — never asked**: if this story's code-generation plan includes an API Layer Generation step (a new/changed endpoint), execute the **API & Contract Testing Gate** defined in `code-generation.md` (Step 11a.5) — generate automated tests, written to **`tests/api/`** at the repo root (never `tests/unit/`, never colocated with the endpoint's unit tests — `common/directory-structure.md` rule 4b), against the actual endpoint(s) covering: functional/happy path, response-code validation, role-based authorization (401 unauthenticated vs 403 insufficient role), error-response validation (standard format + codes), request validation (required fields, data types, enums), and response contract/schema validation. RUN them and iterate within the SAME run until every applicable checklist item passes.  **This is SH-LOOP-2 — capped at 3 remediation attempts (SH-1). On exhaustion apply SH-4: HALT and emit the Retry-Limit Report.** Within that budget the gate is never deferred to Verification Engineer or to a later session. Capture PROOF artifacts to `reports/api-contract-test-evidence/story-[N.M]/` (`api-contract-test-run.log`, the **mandatory machine-readable** `api-contract-test-report.*` — invoke the runner with its report-emitting flag/plugin, e.g. `pytest --junitxml=...` / `jest --json --outputFile=...`; a raw log alone does NOT satisfy the gate unless the runner genuinely has no such capability (documented, surfaced exception) — and `evidence-manifest.md` with the per-endpoint checklist). **If the story's plan has NO API Layer Generation step, this gate is N/A** — record that explicitly (with reason) and proceed straight to 6.5. This gate is separate from and does not replace ve's `/ve-implement` MANUAL API/Contract test steps.
6.3. **🔴 TEST PLACEMENT VERIFICATION GATE (MANDATORY, AUTOMATIC — after the Unit Test & Coverage gate and the API & Contract Testing gate when applicable, same run, BEFORE the Full Regression gate)**: execute the **Test Placement Verification Gate** defined in `code-generation.md` (Step 11a.6) — this is a **mechanical, deterministic check**, not a re-reading of the placement rule: diff this story's changed files against the baseline SHA, run `tests/.evals/scripts/check-test-placement.*` against that diff when the project has one (otherwise apply the same rules to the diff and write the same log — `common/work-unit-artifacts.md` Section 2.3), and require **zero violations** — no unit/UI-component test under the resolved code root (`src/`/`## Code Root`) unless the stack's own co-location convention applies, no unit test under `tests/` outside `tests/unit/<mirror-of-src>/`, no API/contract test under `tests/unit/` instead of `tests/api/` (`common/directory-structure.md` rules 4a/4b). On any violation, move the file to its correct mirrored path, fix imports, re-run it, and re-run the check.  **This is SH-LOOP-12 — capped at 3 remediation attempts (SH-1). On exhaustion apply SH-4: HALT and emit the Retry-Limit Report.** Capture the script's raw output to `reports/unit-test-evidence/story-[N.M]/test-placement-check.log` and record the verdict in `evidence-manifest.md`. **N/A only when this story changed no test files at all** — a story with any new/changed test file is never N/A.
6.5. **🧪 FULL REGRESSION GATE (MANDATORY, AUTOMATIC — after the Unit Test & Coverage gate, the API & Contract Testing gate when applicable, and the Test Placement Verification gate, same run)**: re-run the **ENTIRE repo test suite** (all pre-existing tests + this story's new tests, including any new API & Contract tests from Step 6.2), save the raw output to `reports/unit-test-evidence/story-[N.M]/full-regression.log`, and diff it against `baseline-regression.log` from Step 1.5 Item 4.5. **No user prompt — fix and continue.**
   - **NEW failures (green at baseline, red now)** → **this story broke them, so this story fixes them.** Fix them within THIS SAME run, then re-run and re-diff, iterating until the diff is clean.  **This is SH-LOOP-3 — capped at 3 remediation attempts (SH-1). On exhaustion apply SH-4: HALT and emit the Retry-Limit Report.** Within that budget, never hand a new failure back to the user. Fix each according to what actually broke, and a failing test is NEVER "fixed" by deleting or skipping it to make the suite green:
     - **Obsolete expectation** — behaviour legitimately changed, the assertion encodes the old contract → **update the assertion** (keep the test; it still guards real behaviour)
     - **Genuinely dead** — exercises a code path this story removed → **delete it** and confirm this story's new tests cover the replacement path
     - **Real regression** — the test is correct and the implementation broke it → **fix the implementation, never the test**
   - **Failures already red at baseline** → not this story's doing. Already logged in `baseline-regression.log`; ignore them and do not block on them.
   - Proceed to Code Review only once the diff is clean (zero NEW failures).
   - Record in `evidence-manifest.md`: baseline vs post-change pass/fail counts, and each NEW failure with what broke and how it was fixed. **Audit the diff in runtime-artifacts/audit.md.**
6.6. ** STATIC EVAL GATE — D1–D7 (MANDATORY, AUTOMATIC — after the Full Regression Gate, before Code Review)**: re-run the D1–D7 checks per `common/eval-framework.md` Section 2, save to `reports/eval-evidence/story-[N.M]/static/`, and **diff against the Step 1.5 Item 4.6 baseline**. Only findings that are **NEW versus the baseline, on files this story changed**, count. **No user prompt — fix and continue.**
   - **NEW findings above the `tests/.evals/config.json` thresholds** → **this story introduced them, so this story fixes them** in THIS SAME run, then re-run and re-diff, iterating until the diff is clean.  **This is SH-LOOP-4 — capped at 3 remediation attempts (SH-1). On exhaustion apply SH-4: HALT and emit the Retry-Limit Report.** Within that budget, never handed back to the user.
   - 🔴 **NEVER suppress a finding to pass the gate** — no blanket `eslint-disable`, no `# nosec`, no `# type: ignore`, no ignore-list entry, no widening the disallowed-licence list. That is the exact analogue of deleting a failing test to go green and is equally forbidden. Fix the code.
   - **Findings already present at baseline** → not this story's doing. Already logged under `static/baseline/`; ignore them and do not block on them.
   - Write `eval.json` + `eval-summary.md` (eval-framework.md Section 6) and **proceed to Step 6.7 only once the diff is clean**. Audit the gate outcome in runtime-artifacts/audit.md.
6.7. ** TEST PLANS + PLAYWRIGHT UI AUTOMATION GATE (MANDATORY — after the Static Eval Gate, before Code Review, same run)**: execute **Step 11d** of `code-generation.md`. 🔴 **It INVOKES two existing skills via the Skill tool, in WORKFLOW MODE — it never re-implements them**, and 🔴 **the two halves have DIFFERENT applicability**: part 1 runs for **every** story; part 2 only when the story's plan includes a Frontend Components Generation step (plan-derived and automatic — never asked).
   1. **`ve-implement` — VERIFY FIRST, invoke only to backfill.** This story's manual test plan at `spec/test-plans/<TICKET-ID>-<title>/` was **already generated and approved at the STOP CHECKPOINT** (`CLAUDE.md` Step 1.7 / `implementation/specs-and-test-plans.md`) and is already committed on the epic branch — so the normal case here is a **check, not a run**: confirm the folder exists and covers this story's ACs, record `Manual test plan: present (approved at STOP CHECKPOINT)`, and move to part 2. **Only if it is genuinely absent** (legacy project, or a story added after the checkpoint) invoke the skill with this story and `mode: workflow` — which per `agents/ve-implement-agent.md` **Mode Detection** skips its story-picker, its `ve/…` branch, its Approve/Request-Changes checkpoint and its push/PR — announce the backfill explicitly, and let the generated `spec/test-plans/…` files ride THIS story's commit. 🔴 Never regenerate or overwrite an approved test plan to match the code. **Either way, the ve simply executes the plan after the story PR merges instead of having to generate it first.**
   2. **`playwright-implement` — UI stories only** — invoked with the same story and `mode: workflow`, which per `agents/playwright-implement-agent.md` **Mode Detection** skips its story-picker, its both-merges gate (nothing has merged yet by design — the code is in this working tree), its integration-branch checkout, its Planner-plan Approval Gate and its Push Gate; auto-derives the Seed Test Gate; **starts the app locally itself** (and tears it down); invokes the real Planner/Generator/Healer subagents; and **executes `--headed`, exactly as the standalone skill does** (`npx playwright test tests/e2e/<story-slug>/ --headed`) — this is the developer's own machine and the browser is meant to be visible; 🔴 headless belongs to CI alone, because a runner has no display.
   Iterate — fixing the application code, never `test.fixme()`-ing a genuine failure — within the SAME run until every generated spec passes.  **This is SH-LOOP-11 — capped at 3 remediation attempts (SH-1). On exhaustion apply SH-4: HALT and emit the Retry-Limit Report.** Capture PROOF artifacts to `reports/playwright-test-evidence/story-[N.M]/` (`playwright-test-run.log`, the **mandatory machine-readable** `playwright-test-report.json`, and `evidence-manifest.md`), write the result into `eval.json`'s `gates.playwright`, record the resolved `startCommand`/`readinessUrl` into the `ci.playwright` manifest fragment, and **commit the generated artifacts as part of this story's own commit** (no separate branch/PR — see Section D). **If the story's plan has NO Frontend Components Generation step, only part 2 is N/A** — record that explicitly (with reason); part 1's test plans are still generated, and the run proceeds to Step 6.8. 🔴 CI later re-executes these SAME specs as a **trust gate, never the first execution** (headless there only because a runner has no display) — its cross-check rides the existing CI Attestation gate (Section D Step 8, SH-LOOP-10) automatically, since `playwright` is just another id in `eval.json`'s `gates` block, **when `## CI/CD Configuration` `Enabled: Yes`**; when `Enabled: No` there is no CI run to cross-check against, so this story's local Playwright pass is the only evidence. 🔴 WORKFLOW MODE skips **approvals and git mechanics only** — never a verification: the real subagents still run and the tests are really executed. This gate does not replace Verification Engineer's own standalone `/ve-implement` run, which remains the authoritative, independently-scheduled black-box test-plan track and the only sign-off path.
6.8. **🧪 PLAYWRIGHT E2E REGRESSION GATE (MANDATORY, AUTOMATIC — after the Playwright UI Automation Gate, before Code Review, same run)**: execute **Step 11e** of `code-generation.md` — re-run the **ENTIRE** `tests/e2e/` suite (every earlier story's specs **plus** anything this story just generated in Step 6.7) headless against a locally started instance of the app, save the raw output to `reports/playwright-test-evidence/story-[N.M]/regression/playwright-full-regression.log` plus the **mandatory machine-readable** `playwright-regression-report.json`, and **diff it against the Step 1.5 Item 4.7 baseline**. **No user prompt — fix and continue.**
   - **NEW failures (green at baseline, red now)** → **this story broke them, so this story fixes them** within THIS SAME run; then re-run and re-diff until the diff is clean.  **This is SH-LOOP-13 — capped at 3 remediation attempts (SH-1). On exhaustion apply SH-4: HALT and emit the Retry-Limit Report**, naming each newly-red spec.
   - 🔴 **Fix the application code, never the spec.** A generated Playwright spec encodes an acceptance criterion an earlier story shipped and a human approved — deleting it, marking it `test.fixme()` or `.skip`, loosening a locator, widening a timeout or narrowing an assertion to force it green is the exact analogue of deleting a failing unit test and is equally forbidden (SH-6). A spec changes only when the AC it encodes genuinely changed, and then the AC, `requirements.md` and the tracker item are amended together and the reconciliation is logged.
   - **Failures already red at baseline** → not this story's doing. Already logged in `playwright-baseline-regression.log`; ignore them and do not block on them.
   - 🔴 **This gate runs for EVERY story, UI or not — deliberately unlike Step 6.7, which is UI-only.** A backend or contract change that breaks a browser flow is precisely what it catches, and it is the only gate positioned to catch it.
   - Write the result into `eval.json`'s `gates` block under id **`"playwrightRegression"`** (`PASS`/`FAIL`/`N/A` with the new-failure count). 🔴 Like `regression` and `apiContract`, this is a **LOCAL-ONLY gate** — CI has no baseline to diff against, so it is **never** added to `ci.gates` (`common/eval-framework.md` Section 5). CI's own `playwright` job stays a trust gate with no attribution.
   - **`N/A`** when the Item 4.7 baseline was `N/A` (nothing existed to regress) — record the same reason. 🔴 Never reported as a pass.
   - Record in `evidence-manifest.md`: baseline vs post-change pass/fail counts, the exact commands, `headed` + reason, and each NEW failure with what broke and how it was fixed. **Audit the diff in runtime-artifacts/audit.md.**
7. **POST-IMPLEMENTATION — status stays `In Development` until the PR has merged and the ve signs it off with `ve-list-work`**: Do NOT change the tracker status here, and do NOT prompt for a board status. The story **remains `In Development`** through the automated Code Review (Section A), any Remediate loop (Section C), the commit/push/**PR raise** (Section D), and the automated PR Review (Section E). Raising the PR does **NOT** promote it. The story moves to `Ready for Testing` **only when its PR is MERGED into the epic branch** — and ve has signed it off with the `ve-list-work` skill (dev-implement itself only ever live-checks a specific prerequisite's merge state at its own Doability Gate — it never promotes tracker status). The developed ticket is recorded as a full tracker hyperlink in `runtime-artifacts/audit.md`:
   - **MANDATORY — record the developed ticket as a full tracker hyperlink in `runtime-artifacts/audit.md`**: for a tracker-linked story, resolve the site base URL (`getAccessibleAtlassianResources` for JIRA, or reuse the base already recorded in `spec/`; the work-item/issue URL directly for ADO/GITHUB) and write the ticket as a clickable Markdown link (`[PROJ-XXX](<site-base-url>/browse/PROJ-XXX)` for JIRA, the direct URL for ADO/GITHUB) in the audit entry for this implementation — never bare text. When the PR is raised (Section D) record the PR URL and that the story stays `In Development` (Merged=no); when the PR later merges, record the promotion to `Ready for Testing` with evidence (tests passing + measured coverage % ≥90%). For local-only stories (`Tracker ID = —`/`LOCAL`), record the local Story ID instead. Example entry:
      ```markdown
        ## [Stage Name or Interaction Type]
         **Timestamp**: [ISO timestamp]
         **User Email**: [current session email — read live from the session context]
         **User Input**: "[Complete raw user input - never summarized]"
        **TRACKER ITEM**: "[Complete tracker item that was implemented]"
        **Epic Link**: "[Full Parent Epic URL as a clickable link, from ## Tracker in runtime-artifacts/aire-state.md — or "none"]"
        **AIRE VERSION**: "[Framework version [N] read from the "AIRE Framework Version" line in CLAUDE.md — do not hardcode]"
       **AI Response**: "[AI's response or action taken]"
       **Context**: [Stage, action, or decision made]
   
      ```
8. **Update Dependency Graph**: After a story's PR merges, recompute the ready set — stories whose `requires` are all merged (or already `Ready for Testing`) become selectable.
9. **MANDATORY**: Present the code-generation completion announcement as defined in `code-generation.md` Step 14 (Code Generation Complete + file summary). This announces completion only — it does NOT ask the user to choose between review and continue anymore.
10. **AUTO-TRIGGER Code Review (MANDATORY — no longer user-selected)**: As soon as code generation for the story is done, automatically proceed into the **Post-Code-Generation Automation** section below. Code Review runs on its own; the user is NOT asked whether to run it.
11. **MANDATORY**: Log every user response in this stage in runtime-artifacts/audit.md with complete raw input.

---

# Post-Code-Generation Automation — Auto Code Review → (Remediate) → Commit / Push / PR

**Runs automatically once Code Generation Part 2 completes for the story. The user is NOT asked whether to review — Code Review is triggered automatically.** The target branch for the commit/push/PR is the branch resolved in Step 1.5 (newly created, or the current branch).

## A. Auto Code Review (MANDATORY, automatic)
1. **Log** in runtime-artifacts/audit.md that automated Code Review is starting for Story [N.M] (ISO 8601 timestamp).
2. **Run Code Review for this story**: load and execute `workflows/code-review.md` scoped to **this specific story** (target = "story [N.M]"), as a **read-only** review (it MUST NOT edit source). 🔴 It runs **inline in this session** (Step 1.7) — read-only is enforced by making no `Edit`/`Write` calls on `src/**` or `tests/**` during the pass, never by spawning a read-only subagent, and the J1/J2 scores in Step 2.5 are judged by this session itself, never by a subprocess or subagent. It produces the versioned report at `reports/reviews/story-[N.M]-code-review-v[X].md`. Code Review does **NOT** change the tracker status — the story stays `In Development`.
   - ** NO TEST RE-RUN**: the Unit Test & Coverage gate (Step 6) measured coverage on this story's new/changed code to `unitTestCoverageMin`, the API & Contract Testing Gate (Step 6.2, when applicable) ran automated tests against every new/changed endpoint to a full pass, the Playwright UI Automation Gate (Step 6.7, when applicable) ran every generated Playwright spec `--headed` to a full pass, and the Full Regression Gate (Step 6.5) ran the ENTIRE repo suite and diffed it against the Step 1.5 baseline — all in THIS same run, with proof artifacts saved under `reports/unit-test-evidence/story-[N.M]/` (`unit-test-run.log`, `coverage-report.*`, `baseline-regression.log`, `full-regression.log`, `evidence-manifest.md`), when Step 6.2 applied `reports/api-contract-test-evidence/story-[N.M]/` (`api-contract-test-run.log`, `api-contract-test-report.*`, `evidence-manifest.md`), and when Step 6.7 applied `reports/playwright-test-evidence/story-[N.M]/` (`playwright-test-run.log`, `playwright-test-report.json`, `evidence-manifest.md`). Pass that captured evidence into the review — Code Review MUST NOT re-execute the unit tests, re-measure coverage, re-run the API & Contract tests, or re-run the Playwright specs; it verifies test existence/AC coverage statically and **cites the stored proof artifacts** in its report, rather than restating unverified numbers.
2.4. ** AUTOMATED SECURITY REVIEW (MANDATORY, automatic — inside this review pass)**: the review's **Phase 2.5** runs the `agents/code-security-review-agent.md` procedure against this story's diff, checking all 16 Security Baseline rules on the changed files and the attack surface they reach, and writes `reports/code-security-reviews/story-[N.M]-security-review-v[X].md` (keyed by this work unit and the review version — never the dated name, which parallel stories would collide on). Its **🔴 Critical / 🟠 High findings on the changed surface become real `SEC-ISS-XXX` findings in the review's issue list** — so they route through Section B exactly like AC findings and are **auto-remediated by Section C (SH-LOOP-5) until clean, within its 3-round budget**. 🟡/🔵 findings and any pre-existing violation on lines this story didn't touch are **advisory only** (reported, never remediated here, recommend `/raise-defect`). 🔴 Never suppress a finding instead of fixing it; never let the security pass go repo-wide.
2.5. ** JUDGE GATES J1 + J2 — 🔴 BLOCKING (MANDATORY, automatic — computed HERE and nowhere else)**: as part of this review pass, compute the two judge scores per `common/eval-framework.md` Section 4 — **J1 Architecture conformance** against `tests/.evals/rubrics/architecture-rubric.json` (derived mechanically from `spec/plans/architecture.md` Section 10; apply the Section 3 fallback chain, `N/A` if it bottoms out) and **J2 Security (OWASP)** against `security-rubric.json` — from this story's diff. Write them with their **per-criterion breakdown** to `reports/eval-evidence/story-[N.M]/judge/`, merge them into the **`gates`** block of `eval.json`, refresh `eval-summary.md`, and report both in the review report.
   - **Scoring discipline** (eval-framework.md Section 4.1): score **once** per review pass — never re-roll for a better number; score each criterion independently then weight; **every criterion below 1.0 MUST cite `file:line`** and say what violates it; score only what the diff shows; a criterion this diff cannot exercise is `N/A` and is excluded with the remaining weights renormalised to 1.0 — never scored 0.
   - ** Gate**: `J1 ≥ llmJudgeArchitectureScoreMin` **and** `J2 ≥ llmJudgeSecurityScoreMin`, both read from `tests/.evals/config.json`. A `J1` of `N/A` passes. **Below minimum → SH-LOOP-6**: remediate the specific criteria that scored below 1.0, worst weighted-loss first, using their citations; re-run whatever gates the fix touched; re-score on the next review pass. **Capped at 3 attempts (SH-1); on exhaustion apply SH-4 — HALT and emit the Retry-Limit Report** naming each failing criterion, its weight, its citation, and what the three attempts changed.
   - 🔴 **Forbidden ways to pass this gate** (SH-6 violations, all of them): editing `spec/plans/architecture.md` Section 10 to weaken or delete a constraint; editing the rubric JSON directly; lowering either minimum in `tests/.evals/config.json`; re-scoring until a run clears the bar; marking an applicable criterion `N/A`. The architecture document changes only when the **design decision** changed — never because a score did not clear.
   - Record the pinned judge model and the `rubricVersion` alongside every score.
3. **MANDATORY — audit the complete review log**: append to `runtime-artifacts/audit.md` the full Code Review outcome — the `**TRACKER ITEM**:` and `**Epic Link**:` fields, report path, review verdict, and the complete list of findings by severity (🔴 Blocker / 🟠 High — the only severities; findings map strictly to unmet/partially-met ACs and requirements), plus any tracker status change. Do not summarize away findings; record the complete log of this automated review.
4. Proceed to **B. Review Decision Gate**.

## B. Review Verdict Routing ( AUTOMATIC — no question, no gate)

The review's own verdict decides what happens next. **Do NOT present an A/B choice and do NOT wait
for the user.** Announce the verdict, then route:

```
 Automated Code Review complete for Story [N.M].
   Report: reports/reviews/story-[N.M]-code-review-v[X].md
   Verdict: [clean — all ACs Met / findings: Blocker X, High Y]
[Proceeding to commit + PR. | Findings found — remediating them automatically now (round [n]).]
```

1. **Verdict clean — zero 🔴, zero 🟠, AND both judge gates PASS (or J1 `N/A`)** → go straight to **D. Commit, Push & Raise PR**.
1.5. **Judge gate below minimum** → handled by **SH-LOOP-6** inside Section A Step 2.5 before this routing is reached. A run never arrives at Section D with a failing J1 or J2.
2. **Any 🔴 Blocker or 🟠 High finding** → go to **C. Auto-Remediate Loop (SH-LOOP-5)**. The framework
   fixes its own findings within a budget of **3 remediation rounds**; it hands them back to the user
   only when that budget is exhausted (SH-4), and then it HALTS instead of raising the PR.
3. **MANDATORY**: log the routing decision in runtime-artifacts/audit.md under a plain heading
   (`## Review Verdict — Clean, Proceeding to PR (Story N.M)` or
   `## Review Verdict — Findings, Auto-Remediating (Story N.M)`), with the full findings list by
   severity. **No "GATE" in the heading, and no user response to record.**

## C. Auto-Remediate Loop — SH-LOOP-5 ( AUTOMATIC — max 3 rounds)

**Entered whenever the review verdict reports findings. Every round is automatic — no prompts at any
point. The loop is bounded by the Self-Healing Retry Policy: one round = one attempt, maximum 3.**

1. **Check the SH-LOOP-5 counter BEFORE starting a round.** If 3 attempts have already been spent,
   do not start another — go directly to Step 8 (Exhaustion) below.
2. **Log** in `runtime-artifacts/audit.md` that automatic remediation round `[n] of 3` is starting for Story [N.M],
   naming the review report being remediated, the findings in scope, and the identified root cause of
   each (SH-3, SH-7).
3. **Run Remediate**: load and execute `workflows/remediate.md` scoped to **this story's** review
   report (`story-[N.M]-code-review-v[X].md`). It fixes findings (fix → unit test → green, running
   ONLY this story's unit tests) and annotates the report in place.  **Its scope-confirmation prompt
   is SKIPPED in this mode** — every 🔴 and 🟠 finding is in scope by definition, and nothing is
   deferred. Remediate does **NOT** change the tracker status — the story stays `In Development`
   throughout.
4. **Re-run the FULL regression** (Step 6.5's diff vs `baseline-regression.log`) if the remediation
   touched non-test code, fixing any NEW failure in the same round. If the remediation touched
   API-layer code that Step 6.2 covered, also re-run the affected endpoint(s)' API & Contract tests
   and keep them green. Per SH-2, this re-entry **continues** the SH-LOOP-3 / SH-LOOP-2 counters — it
   does not reset them.
5. **MANDATORY — audit the complete remediate log**: append to `runtime-artifacts/audit.md` the full outcome
   of the round — the `**TRACKER ITEM**:` and `**Epic Link**:` fields, the round number (`[n] of 3`),
   which findings were fixed (by severity), the files changed, unit-test evidence, and the regression
   comparison. Record the complete log, not a summary.
6. **Re-review automatically**: return to **A. Auto Code Review**, producing the next report version
   `v[X+1]`, then **B. Review Verdict Routing** again.
7. **Loop control**:
   - **Verdict clean** → the loop exits successfully → **D. Commit, Push & Raise PR**.
   - **Findings remain AND attempts spent < 3** → increment the counter and return to step 1.
   - **Findings remain AND attempts spent = 3** → **exhausted** → step 8.
   - **Stall (SH-5)** — a round produced **no code change at all** AND the next review returned an
     **identical** finding set → the loop cannot progress. Treat as exhausted immediately, regardless
     of attempts remaining → step 8, noting the early end.
8. ** Exhaustion (SH-4) — HALT, do not raise a PR.** When the budget is exhausted (3 rounds, or an
   SH-5 stall):
   - Do **not** run a 4th round, do **not** commit, do **not** push, do **not** raise a PR, and do
     **not** change the local Story Tracker or the external tracker. The story stays
     `In Development` and the remediation work stays in the working tree.
   - Emit the **Retry-Limit Report** (Self-Healing Retry Policy, above) with `[loop name]` =
     `Auto-Remediate (code review + security findings)` and `[SH-LOOP-ID]` = `SH-LOOP-5`, listing every
     unresolved finding with its ID, severity, file:line, and the reason automatic remediation failed
     on it.
   - Append the same content to `runtime-artifacts/audit.md` under
     `## Self-Healing Retry Limit Reached — SH-LOOP-5 (Story N.M)`.
   - **HALT and wait for the developer to fix it manually and hand it back.** 🔴 Never silence a finding by deleting it from the
     report, never weaken the review scope to manufacture a clean verdict, and never let an exhausted
     loop pass unreported.

## D. Commit, Push & Raise PR (on a clean review verdict) —  FULLY AUTOMATIC

🔴 **A clean review verdict is the ONLY thing that triggers this section.** An exhausted SH-LOOP-5
(Section C.8) does NOT reach it — that path HALTS at the gate and waits for the user.
Everything below — the commit, the branch push, the PR creation, the labels, the tracker update,
and the auto PR review (Section E) — runs **automatically, with no prompts of any kind**.
Do NOT ask about pushing, opening the PR, the PR title/body, or the labels. Announce what you
are doing; never ask whether to do it.

1. **Log** in runtime-artifacts/audit.md that the review verdict came back **clean** and the commit/push/PR step is starting, naming the target branch. 🔴 If SH-LOOP-5 was exhausted instead (Section C.8), this section is NOT reached — the run has already halted.
1.2. **🔴 ARTIFACT COMPLETENESS CHECK — SH-LOOP-16 (MANDATORY, AUTOMATIC — after the clean review verdict, BEFORE manifest reconciliation and the commit)**: run `common/work-unit-artifacts.md` Section 5 for `story-[N.M]`. Build the expected evidence list from Section 1 (the always-required files plus the folders of every gate that ran, read from `eval.json`), then verify each file exists, is non-empty, has its set format (the Section 2 `evidence-manifest.md` skeleton; `eval.json` / `eval-summary.md` per `common/eval-framework.md` Section 6; the review and security report templates) and agrees with the others (Section 4) — including that **no folder exists for an `N/A` gate** (so `b3/` only on the last unit). A file whose underlying output exists is written or reformatted from that real output; a missing underlying output means the gate never produced evidence, so that gate's step is **re-run** — never hand-written. Record the result in `reports/eval-evidence/story-[N.M]/artifact-check.md`. Capped at 3 attempts; on exhaustion HALT with the Self-Heal Limit message. **Nothing is committed until this check is clean.**
1.5. **🔴 MANIFEST RECONCILIATION — CONDITIONAL on `## CI/CD Configuration` `Enabled: Yes` (MANDATORY, AUTOMATIC when it applies — after local gates pass, BEFORE the commit)**: **if `Enabled: No`, SKIP this step entirely** — there is no CI manifest to reconcile when no pipeline was generated — and go straight to Step 2 (Commit). Otherwise:
   per `common/ci-pipeline-generation.md` Section 4.0f, write ONE NEW file,
   `tests/.evals/ci-manifest.d/story-[N.M].json` — a JSON array of `ci.roots[]`-shaped entries for every
   root this story's own run established or extended, populated from what Steps 4.6/6/6.6/11a–11c
   **already executed for real** (never re-derived, never guessed): the resolved `root` (matching
   `## Code Root`), `stack`, `runtimeVersion`, `markerFile`, the install/build/coverage commands that
   actually ran, `coverageReportPath`/`coverageFormat`, `noTestsExitCode`, `tools` **paired with**
   `toolInstallCommands`, `dependsOn` (roots this one consumes — read from the repo's own dependency
   declaration), `toolchainSetup` (only for a stack outside the built-in five), and the
   `sourcePaths`/`testPaths` this story's own diff touched. 🔴 **The COMPLETE entry, per Section 4.0f's
   field table** — `tools` without `toolInstallCommands` is a hard Manifest defect, and an omitted
   `dependsOn` silently disables monorepo diff-scoping. **Append-only** — extend an existing root's
   arrays (tools/sourcePaths/testPaths/installCommands), never remove another root's or another
   fragment's entry, and **never edit `tests/.evals/config.json` or any other work unit's fragment file**
   directly (Section 4.0f.1 — this is what keeps two parallel `dev-implement` sessions, Step 1.75,
   conflict-free on CI configuration specifically). If this story's stack tools conflict with an existing
   pin on the same root from an earlier fragment (e.g. two different `semgrep==` versions), surface the
   conflict to the user and confirm which pin wins before writing — never silently union or "last wins".
   Re-run `tests/.evals/scripts/validate-pipeline.{sh,ps1}` after writing the fragment (it re-derives the
   merged view) and confirm it still passes before proceeding to the commit below. Include the fragment
   in the same commit as the story's code.
2. **Commit the story's changes to the target branch**:
   - Verify the active branch is the target branch from Step 1.5 (`git branch --show-current`). If it is not, switch to it automatically and announce the switch (no confirmation — the target branch was determined by this run).
   - Stage and commit the generated/remediated application code, **the Step 6.7 Playwright artifacts when that gate applied** (`tests/e2e/<story-slug>/`, `spec/playwright-specs/<story-slug>.md`, any confirmed `seed.spec.ts` addition, `spec/test-plans/<TICKET-ID>-<title>/automation-summary.md`), **plus the Step 1.5 manifest fragment** (`tests/.evals/ci-manifest.d/story-[N.M].json`, if one was written), **plus this story's state fragment** (`runtime-artifacts/stories/story-[N.M]/`), **plus any files Playwright Readiness added** (the package manifest and lockfile, `playwright.config.*`, `.claude/agents/playwright-test-*.md`, `.mcp.json`), — do NOT commit unrelated changes, and 🔴 **never the shared `runtime-artifacts/audit.md` / `aire-state.md`**: run the **State Isolation Check** (`common/parallel-work-state.md` Section 5.5) on the staged set first and commit only when it is clean. The commit message MUST carry an `AIRE-Version:` trailer as the framework signature, where `[N]` is read at runtime from the "AIRE Framework Version" line in `CLAUDE.md` (do not hardcode a number). Use a clear message, e.g.:
     ```
     git add <story files>
     sh aire-workflow/templates/hooks/check-work-unit.sh story-[N.M]
     git commit -m "[Story N.M / TRACKER-ID] <concise summary of the implemented story>" -m "AIRE-Version: [N]"
     ```
     🔴 The guard must print `every gate PASS or legitimate N/A, evidence complete` before `git commit` runs
     (and the hook repeats it on the commit). A refusal means a gate or its evidence is missing: go back
     and run it (Section D Step 1.2's loop). Never `--no-verify`.
     The `AIRE-Version: [N]` trailer goes on its own line at the end of the message body (alongside any existing trailers), with `[N]` substituted from the CLAUDE.md canonical line.
   - Record the commit hash in runtime-artifacts/audit.md.
2.5. **🔴 CI PREFLIGHT GATE — SH-LOOP-9 — CONDITIONAL on `## CI/CD Configuration` `Enabled: Yes` (MANDATORY, AUTOMATIC when it applies — after the commit, BEFORE the push and the PR)**: **if `Enabled: No`, SKIP this gate entirely** — there is no CI pipeline to preflight — and go straight to Step 3 (Push & raise the PR). Otherwise:
   `common/ci-pipeline-generation.md` **Section 4.0i** is the authoritative contract; execute it in full.
   This gate exists because every local gate above ran in **this agent's ambient environment**, where the
   Step 1.5 Item 4.6 bootstrap had already installed the eval tools and the test dependencies were already
   importable — while CI starts from a bare runner and provisions **only** what the manifest declares.
   A gate CI cannot run measures nothing, and a story whose PR fails on `tool 'ruff' … is not installed on
   this runner` or `RuntimeError: … requires the httpx package` has spent a full CI run, a full self-repair
   triage and a round-trip back to this workflow without a single line of its code being examined.
   **Fix it here, on this machine, where it costs one clean-room run.**
   1. **P1 — Declaration completeness (static, first, cheap)**: against the **merged** manifest
      (`tests/.evals/_run/merged-manifest.json`, or re-derived exactly as `run-static-evals.*` derives it),
      for every root this story's diff touches: every gate in `ci.gates` resolves to a binary named in some
      root's `tools` **with** a matching `toolInstallCommands` entry; `semgrep` (D3) and `gitleaks` (D7) are
      declared; and the full Section 4.0f field table is present — `installCommands`, `coverageCommand` +
      `coverageReportPath` + `coverageFormat`, `markerFile`, `runtimeVersion`, `noTestsExitCode` (or a
      no-tests-safe runner flag), `dependsOn`, `toolchainSetup` where the stack needs it, and
      `sourcePaths`/`testPaths` that actually match this story's changed files.
   2. **P2 — Clean-room execution of the REAL CI entrypoints**: in a disposable environment built per
      `common/ci-pipeline-generation.md` Section 4.0.1a (fresh venv / empty `node_modules` / throwaway
      Podman container from the runner's base image) — 🔴 **never this agent's ambient shell, and never with
      an install the manifest does not declare** — run, with
      `BASE_SHA="$(git merge-base origin/<epic-branch> HEAD)"`:
      `ci-manifest-runner.sh install` → `build` → `run-static-evals.sh` → `ci-manifest-runner.sh coverage`.
      🔴 **The commit in Step 2 above is why this runs here and not before it**: every entrypoint is
      diff-scoped (Section 4.0g), so with the story's changes uncommitted every root scopes out and the
      whole preflight reports `N/A` — clean-looking and worthless.
   3. **P3 — Behavioural provisioning**: if Step 6.1's tiers genuinely ran **containerised** from the
      committed `Containerfile`, that already IS clean-room evidence — **cite that run's evidence manifest
      (image ref + digest) and do NOT re-run it.** Re-run only if that gate fell back to its one permitted
      native exception, or if this story changed the `Containerfile`, `run.sh`, the step-definition
      dependencies, or anything the image installs.
   4. **FAIL on any of** (Section 4.0i.2): `is not installed on this runner` · `command not found` ·
      `ModuleNotFoundError` / `ImportError` / `requires the <pkg> package` / `Cannot find module` ·
      a dependency-resolution failure or non-clean `pip check` · a marker in
      `tests/.evals/_run/manifest-defects.txt` · a missing `cd` target or `markerFile` · a gate reporting
      `N/A` or zero analysed files on a root this diff touched · a gate reporting the **qualified pass**
      ("zero output at BOTH ends") on a root this diff touched.
      **Not a preflight failure**: a gate reporting a real finding, or a test legitimately failing — those
      return to SH-LOOP-1…4 **on those loops' existing counters** (SH-2), never onto this one.
   5. **Repair the DECLARATION, never the gate** (Section 4.0i.3): a missing eval tool → this story's own
      fragment `tests/.evals/ci-manifest.d/story-[N.M].json` (`tools` **and** `toolInstallCommands`, pinned;
      never another unit's fragment, never `config.json`); a missing runtime/test dependency → the **repo's
      own dependency declaration** (its real test/dev group) plus `installCommands` if that group is not
      already installed — 🔴 never a bare `pip install`/`npm i -g` inside the workflow YAML or a script.
      Re-run `validate-pipeline.{sh,ps1}`, commit the fix (`fix(ci): preflight — <what>` with the
      `AIRE-Version: [N]` trailer), and re-run P1–P3 from the top.
      🔴 **Forbidden ways to pass this gate (SH-6)**: removing the gate from `ci.gates`, deleting a tool
      from `tools`, marking an applicable gate `N/A`, excluding the failing root from `sourcePaths`,
      skipping the failing test, or adding an ignore-list entry. **Preflight makes the pipeline runnable;
      it never makes it pass.**
   6. **Loop control — SH-LOOP-9, capped at 3 attempts (SH-1)**. Log each attempt per SH-3 (root cause,
      planned fix, files changed, exact command re-run, result). On exhaustion or an SH-5 stall apply
      **SH-4: HALT** — do **not** push, do **not** raise the PR, do **not** change any tracker — and emit
      the Retry-Limit Report with `[loop name]` = `CI Preflight` and `[SH-LOOP-ID]` = `SH-LOOP-9`, naming
      each unrunnable gate, its root, and the missing binary or package.
   7. **On a clean preflight**: record in `runtime-artifacts/audit.md` — the clean-room type (venv /
      container image + digest), the exact commands run, each gate's outcome, and which behavioural
      evidence was reused rather than re-run — then proceed to the push below. Save the raw output to
      `reports/eval-evidence/story-[N.M]/preflight/`.
3. **Push & raise the PR via the `pr-generator` skill (used as-is — DO NOT edit it)**:
   - Invoke the **`pr-generator`** Claude skill **in WORKFLOW mode**, passing **target branch = the Epic Branch** from `runtime-artifacts/aire-state.md` `## Branching` — story PRs merge into the epic branch, NEVER into main/the base branch. The skill diffs the story branch against the target, reads `runtime-artifacts/aire-state.md` + `runtime-artifacts/audit.md` for context, drafts the PR title/body (the title MUST carry the **`[STORY]`** prefix — this is a story → epic-branch PR), then pushes the branch, ensures the `ai-generated` and `aire-v[N]` labels, and opens the PR.
   - **pr-generator's Phase 5 confirmation is SKIPPED in workflow mode** — the `dev-implement` invocation authorized the whole run, including the push and the PR. The skill announces the drafted title/body/labels/target and proceeds. **Never ask the user whether to push or open the PR.**
   - **Pass the eval scorecard** to pr-generator: give it the PATH `reports/eval-evidence/story-[N.M]/eval-summary.md`; it pastes the file's CONTENTS verbatim into the PR body's `## Eval Scorecard` section.
   - 🔴 **VERIFY IT LANDED — do not assume.** After the PR is created, read the PR body back (`gh pr view <n> --json body`) and confirm the scorecard table is present. If it is missing, edit the PR to add it, then re-verify. **Never write "the PR carries the scorecard" into runtime-artifacts/audit.md on the basis of having passed the path** — record only what reading the body actually showed. A claim in the audit trail that does not match the artifact is a defect in the audit trail.
4. **MANDATORY**: Record in runtime-artifacts/audit.md the PR outcome returned by pr-generator (branch pushed, PR URL, labels applied — `ai-generated` + `aire-v[N]`), including the `**TRACKER ITEM**:` and `**Epic Link**:` fields.
5. **STORE THE PR AND KEEP THE STORY `In Development` (do NOT promote on PR raise)**:
   - In this story's fragment `runtime-artifacts/stories/story-[N.M]/state.md` `## Story Tracker Row` (never the shared table — `common/parallel-work-state.md`), set **PR** → the PR URL returned by pr-generator, **Merged** → `no`, **Recorded** → current timestamp. 🔴 Do **not** push a commit just for this — a state-only push would start a full CI run on a new head SHA and invalidate the CI Attestation below. The fragment was committed with `PR: pending` in Step 2; this update rides the next commit the story gets (an attestation fix, a `pr-fix` round), and until then every reader resolves `pending` live from the head branch (`common/parallel-work-state.md` Section 4.6). **Do NOT change Status** — the story **remains `In Development`**. Raising the PR is NOT the promotion trigger; **merging** it is.
   - **Do NOT transition the tracker here** and do NOT set `End`. The story moves to `Ready for Testing` — in the local tracker AND on the external tracker — ONLY when its PR is confirmed MERGED, handled by the `ve-list-work` skill (dev-implement's own Doability Gate live-checks a prerequisite's merge state when needed, but never promotes this story's tracker status itself).
   - **MANDATORY** — record in `runtime-artifacts/audit.md` (per Step 7 above) the developed ticket as a full tracker hyperlink, the PR URL, and that the story stays `In Development` pending merge (Merged=no).
6. **Ready set unchanged**: because this story's PR is not merged yet, it does NOT yet unblock dependents. Dependents become selectable as soon as this story's PR merges (the Doability Gate checks the merge live; ve sign-off is not required for that). (This aligns with the branch-cut dependency-merge check in `common/branching-strategy.md` — a dependent needs its prerequisite's code MERGED into the epic branch.)
7. **🔷 EPIC → Ready for Testing (only when ALL PRs are MERGED)**: The epic moves to Ready for Testing only when EVERY story is `Ready for Testing` (i.e. every PR merged). Since the just-raised PR is not merged yet, this typically does NOT fire here — it fires from the `ve-list-work` skill once the last PR merges and ve has signed every story off. **If this is the last story and one or more PRs are still open**, do NOT move the epic — instead report:
   ```
    Story [N.M] PR raised (kept In Development until merged).
    As checked, these story PRs are still OPEN — hence keeping their status as In Development,
      and the Parent Epic stays In Development until every PR is merged:
        • Story [X.Y] — [TRACKER-ID] — <PR URL>
        • ...
   Merge those PRs, then Verification Engineer (on the epic branch) uses the skill `ve-list-work` — it lists the
      merged stories, and promotes the ones Verification Engineer has tested to Ready for Testing; when ALL are
      signed off, the Epic is offered a move to Ready for Testing. The exact instructions are repeated in the Section F handoff below.
   ```
   Only when `ve-list-work` later leaves EVERY story `Ready for Testing` is the Parent Epic (from `## Tracker`) offered a confirm-first transition to "Ready for Testing" (verified, logged). Skip the epic transition silently if `## Tracker` records `Parent Epic: none`, or if `Type: LOCAL`.
8. **🔴 CI ATTESTATION GATE — CONDITIONAL on `## CI/CD Configuration` `Enabled: Yes` (MANDATORY, AUTOMATIC when it applies — after the PR is raised, before Section E)**: **if `Enabled: No`, SKIP this gate entirely and proceed straight to Section E** — there is no CI pipeline run to attest against, so there is nothing to check. Otherwise, this is
   the one place "CI does not know about the code this workflow just wrote" is mechanically detectable —
   never skip it because the PR was "just raised and CI hasn't had time yet."
   🔴 **SCOPE — THIS GATE REPAIRS CI CONFIGURATION ONLY** (`common/ci-pipeline-generation.md` **Section 6.6**):
   once the PR exists, this workflow owns the **manifest fragment, the repo's dependency declarations, the
   pipeline scripts and tool pins**; **CI self-repair owns application code and tests**. A CI failure
   triaged as **Code** class (Section 6.4) is **not fixed here** — self-repair owns it, on its own
   `retryLimitForSelfRepair` budget; this gate records it and does not spend an attempt on it. A
   **Manifest/provisioning** failure is the reverse: `auto-fix-agent.*` reports it without burning an
   attempt, and it is fixed HERE. 🔴 **And never push into an in-flight repair**: before pushing anything
   to this PR head, check for a self-repair run `queued`/`in_progress` on it
   (`gh run list --branch <head> --json status,name`) and for any `fix(ci): self-repair attempt <n>` commit
   newer than local `HEAD`; if either exists, **wait for that run to conclude, then `git fetch` + rebase
   onto it** and re-read the result before deciding anything. Never force-push, and never revert
   self-repair's commit to apply your own. Both agents pushing to one head is what turned a provisioning
   bug into two wasted repair budgets.
   1. Confirm a run of `agentic-eval-pipeline.yml` exists for this PR's head SHA
      (`gh pr checks <n>` / `gh run list --commit <sha>`). 🔴 **No run at all is a blocking finding, not
      a note** — it means the trigger filter, the branch, or the workflow file itself is wrong.
   2. **Watch it to conclusion** (`gh run watch <id>`); download `eval.json` from the `eval-results`
      artifact once it finishes.
   3. **Cross-check CI's `gates` block against this story's own local gate results** (the same
      `eval.json`/`static-results.json.gates` this run already produced locally). A gate that passed
      **locally** but is **absent or `N/A` in CI** is a **manifest defect** — the story's code exists in a
      place the pipeline does not know to look (most often: Step 1.5's fragment missed a `sourcePaths`
      entry the story's diff actually touches). A gate that **ERRORed in CI on a missing tool or an
      undeclared dependency** is the same class (provisioning) — and since Step 2.5's preflight is supposed
      to make it impossible, also record **why preflight missed it** (an ambient-environment shortcut? a
      root scoped out? a fix that never reached the fragment?), so the escape is fixed and not just the
      symptom.
   4. **Check the SH-LOOP-10 counter BEFORE starting an attempt.** If 3 attempts have already been
      spent, do not start another — go directly to item 7 (Exhaustion) below.
   5. **On a mismatch**: go back to Step 1.5, correct the fragment (extend it — never remove another
      unit's entry), **re-run the Step 2.5 preflight for the affected root** so the fix is proven in a
      clean room rather than on CI's clock, then commit, push, and re-verify from Step 1 of this gate.
      This is **SH-LOOP-10 — capped at 3 remediation attempts (SH-1)**. Log each attempt per SH-3 (root
      cause, planned fix, files changed, exact command re-run, result). 🔴 Every push here obeys the
      no-in-flight-repair rule in this gate's SCOPE note above.
   6. **On a clean match**: log the attestation (PR URL, run URL, gate-by-gate agreement) in
      `runtime-artifacts/audit.md` and proceed.
   7. **Exhaustion (SH-4)**: on the 3rd failed attempt, or an SH-5 stall, apply SH-4 exactly — HALT, do
      not push further, do not raise/update the PR beyond what already exists, do not change any
      tracker status, and emit the standard Retry-Limit Report with `[loop name]` = `CI Attestation`
      and `[SH-LOOP-ID]` = `SH-LOOP-10`, naming each gate CI never saw agreement on. Append the same
      content to `runtime-artifacts/audit.md` under
      `## Self-Healing Retry Limit Reached — SH-LOOP-10 (Story N.M)`.
   8. **A CI failure in the Code class** (a real finding, a failing test, a judge criterion — Section 6.4)
      is **left to CI self-repair**: record it in `runtime-artifacts/audit.md` with its triage class and
      the run URL, do not edit `src/**` or `tests/**` from here, and do not spend an attestation attempt on
      it. Attestation asks one question only — *did CI see and measure this story's code?* — never *is the
      code correct?*, which the local gates and Section A already answered before the PR existed.
   This is what makes Step 1.5 self-correcting rather than best-effort: reconciliation writes the
   manifest, Step 2.5's preflight proves it is runnable, attestation proves CI agreed with it.
9. Proceed to **E. Auto PR Review**.

## E. Auto PR Review (MANDATORY, automatic — runs right after the PR is raised; story is still `In Development`)
1. **Log** in runtime-artifacts/audit.md that automated PR Review is starting for Story [N.M], naming the PR URL/number from Section D.
2. **Invoke the `pr-review` Claude skill** (`.claude/skills/pr-review/`, used as-is — DO NOT edit it) in its **AUTO MODE**, passing the PR just raised in Section D so it does not need to ask which PR (its Phase 0 is satisfied automatically). It reads the diff, grounds itself in `runtime-artifacts/aire-state.md` + `runtime-artifacts/audit.md`, and drafts inline comments + a summary review.
3. **AUTO MODE — post automatically, comments only, no prompt**: the skill posts the review **without asking the user** (its Phase 5 confirmation is skipped by design in this mode) and **only as a plain COMMENT review** (summary + inline comments) — NEVER a formal GitHub `APPROVE`/`REQUEST_CHANGES`. The same GitHub identity that just raised the PR is posting the review, so a formal self-review is impossible; there is no decision for the user to make here. Do not re-introduce a prompt around the skill.
4. **MANDATORY**: Record in runtime-artifacts/audit.md the outcome — review posted automatically (AUTO MODE, comment-only), the posted review URL, findings summary, and the `**TRACKER ITEM**:` and `**Epic Link**:` fields.
5. Proceed to **F. Next-Action Handoff** — this run is NOT complete until that message is shown.

## F.  Next-Action Handoff (MANDATORY — the LAST thing this run outputs)

**This message closes every `dev-implement` run that raised a PR.** It is professional, short and exact:
it states that the PR is ready, that it is **reviewed by the Developer and the Verification Engineer
together**, that **approval and merge are manual** — the framework never approves or merges a pull
request — and the ONE keyword to type next. The story is `In Development` with an unmerged PR. Do not
tell the user to check out or switch branches — the next workflow does that itself.

1. **Determine the remaining work first** — count the stories in the resolved `## Story Tracker` that are
   still `Ready for Development` (call it `[K]`), and whether this story was the **last** one (no story is
   `Ready for Development` and no other story is `In Development` with an unmerged PR).
2. **Present EXACTLY ONE of the two blocks below, verbatim, every placeholder substituted** (`<PR URL>`,
   `<epic-branch>`, `[N.M]`, `[story title]`, `[EPIC-ID]`). Never ship an unsubstituted placeholder.

   **Case 1 — more stories remain (`K > 0`)**:
   ```
   Story [N.M] — [story title] is ready for review.

      Pull request   <PR URL>   ([STORY] → <epic-branch>)
      Status         In Development — it moves forward only after this PR is merged and signed off.
      Evidence       The eval scorecard and review summary are in the PR description; the full evidence
                     is under reports/…/story-[N.M]/ on the branch.

   NEXT STEPS
      1. Review the pull request together — Developer and Verification Engineer.
      2. Approve and merge the pull request — both are manual steps.
         The framework never approves or merges a pull request on anyone's behalf.
         Changes needed? Leave review comments on the PR, then type:  pr-fix <PR URL>
      3. Continue with the next story. Type:  dev-implement

   Please type the keyword exactly as shown — other phrasing does not start a framework workflow.
   ```

   **Case 2 — this was the LAST story of the epic**:
   ```
   Story [N.M] — [story title] is ready for review. This is the last story of epic [EPIC-ID].

      Pull request   <PR URL>   ([STORY] → <epic-branch>)
      Status         In Development — it moves forward only after this PR is merged and signed off.
      Evidence       The eval scorecard and review summary are in the PR description; the full evidence
                     is under reports/…/story-[N.M]/ on the branch.

   NEXT STEPS
      1. Review the pull request together — Developer and Verification Engineer.
      2. Approve and merge the pull request — both are manual steps.
         The framework never approves or merges a pull request on anyone's behalf.
         Changes needed? Leave review comments on the PR, then type:  pr-fix <PR URL>
      3. Verification Engineer sign-off, once every story PR is merged. Type:  ve-list-work
         (on <epic-branch>, then Option B). Each story you have tested moves to Ready for Testing;
         when all are signed off, you are offered the Parent Epic move and pointed to pr-generator
         for the Epic pull request.

   Please type the keyword exactly as shown — other phrasing does not start a framework workflow.
   ```
3. **Say nothing after this block, and put nothing before it in the same message** — no free-form
   "Summary", no "disclosed gaps" list, no options menu, no extra suggestions. The handoff block IS the
   final message of the run. (A gap is never reported here: a run with a gap never reaches Section F — it
   halted with the Self-Heal Limit message.)
4. **MANDATORY**: log in the story's audit trail which case was presented (more-stories vs last-story) and
   the keyword the user was told to type.

---

## Tracker Sync Rule (reminder)

This workflow changes story status (`Ready for Development` → `In Development` at story selection, then `In Development` → `Ready for Testing` **only through the `ve-list-work` skill, after the PR has merged and the ve has tested it** — never by this workflow). The **Tracker Sync Rule** in `CLAUDE.md` (mechanics in `common/tracker-sync.md` Section 4/Section 5) applies at every status change:
- If **Tracker ID = `—`/`LOCAL`** (local story, or `## Tracker` records `Type: LOCAL`): update only the local tracker. No external call.
- If **Tracker ID is a real JIRA/ADO/GITHUB identifier**: also transition the tracker issue via the mechanism for that type (Atlassian MCP / `az boards` / `gh`) and verify the transition. Never silently update only one side.
- **Exception — the claim is automatic**: the `Ready for Development → In Development` transition at story pick is applied to the tracker AND the local Story Tracker WITHOUT asking (picking the story is the claim), verified (non-LOCAL) and announced. The later `In Development → Ready for Testing` move is never made by this workflow — only `ve-list-work` Option B makes it. Non-story transitions (e.g., the Parent Epic moves) remain **confirm-first**.
- **Assignee on claim**: when the story moves to `In Development`, the tracker issue is ALSO **assigned to the operator who typed `dev-implement`**, per `common/tracker-sync.md` Section 5 — resolve the session email (the same one stamped as `**User Email**:` in runtime-artifacts/audit.md) and set the assignee via the type-appropriate mechanism (JIRA: `lookupJiraAccountId` + `editJiraIssue`; ADO: `az boards work-item update --assigned-to`; GITHUB: a cached GitHub username + `gh issue edit --add-assignee`), verify, announce, log in runtime-artifacts/audit.md. Automatic (part of the same claim, no confirmation). If the identity doesn't resolve, leave the issue unassigned, warn the user, and continue — never block development on assignment. LOCAL has no assignee concept.
- **Ready for Testing = PR merged**: a story moves `In Development` → `Ready for Testing` ONLY when its PR is confirmed MERGED AND ve has named it in the `ve-list-work` skill after testing it (verified + announced + logged). dev-implement never promotes it. Raising the PR stores the PR URL and keeps the story `In Development` (`Merged=no`).
- **Epic status sync**: when the FIRST story moves to `In Development`, the Parent Epic is transitioned to "In Development" **automatically** (Story Selection Step 5); when the LAST story reaches `Ready for Testing` (all PRs merged), the Parent Epic is transitioned to "Ready for Testing" **confirm-first** (from `ve-list-work`). Both are verified (non-LOCAL) and logged in runtime-artifacts/audit.md.

---

## Critical Rules

- **ALL APPLICATION CODE GOES IN `src/`** — greenfield and brownfield alike. On a brownfield repo whose code lives elsewhere, use the root recorded in `runtime-artifacts/aire-state.md` `## Code Root` and never introduce a second location (`common/directory-structure.md`). Test code goes in `tests/`; specs and docs go in `spec/`; **never a source file under `spec/`**.
- **THE BEHAVIOUR SPEC IS WRITTEN BEFORE CODE — AT THE STOP CHECKPOINT, NOT HERE** (`CLAUDE.md` Step 1.7, `implementation/specs-and-test-plans.md`, `common/behavior-spec.md`). One file, `spec/behavior/story-[N.M].feature`, approved alongside every other story's spec before any code existed. Step 4.5 **verifies** it and backfills only a genuinely absent one, announced. 🔴 **Never rewrite an approved scenario to match the code.** 🔴 **That is still the story's ONLY spec file.** No per-story requirements, architecture, constraints or deep-dive document — ACs come from the tracker + `stories.md`, requirements from `requirements.md`, design constraints from `spec/plans/architecture.md`, thresholds from `tests/.evals/config.json`.
- **J1 AND J2 ARE BLOCKING GATES** (Section A Step 2.5, `common/eval-framework.md` Section 4) — they live under `gates` in `eval.json` and decide the verdict like every other gate. Below minimum → SH-LOOP-6, max 3 attempts, then HALT. 🔴 NEVER pass a judge gate by editing `architecture.md`, editing a rubric, lowering a minimum, or re-scoring.

- 🔴 **CI/CD IS OPT-IN — check `## CI/CD Configuration` in `runtime-artifacts/aire-state.md` before ANY CI-specific step.** `Enabled: No` (user declined at `CLAUDE.md` Step 1.2) means Manifest Reconciliation (Section D Step 1.5), the CI Preflight Gate (Step 2.5), and the CI Attestation Gate (Step 8) are ALL skipped for every story in this cycle — the run goes commit → push → PR (`pr-generator`) → Section E (`pr-review`) → Section F handoff, with no CI mention anywhere. This never weakens the LOCAL gates (Steps 6–6.7, Section A) — only the generated-pipeline re-verification is skipped.
- 🔴 **WHEN CI/CD IS ENABLED, NEVER PUSH A STORY WHOSE CI CANNOT RUN — the CI PREFLIGHT GATE (Section D Step 2.5, SH-LOOP-9) is MANDATORY between the commit and the push** (`common/ci-pipeline-generation.md` Section 4.0i). Every local gate above ran in this agent's ambient environment; CI provisions **only** what the manifest declares. So before the push, run CI's own entrypoints (`ci-manifest-runner.sh install|build|coverage`, `run-static-evals.sh`) in a **clean room** against the **committed** work unit and require zero missing tools, zero undeclared dependencies, zero Manifest defects, and no `N/A`/qualified pass on a root this diff touched. Fix the **declaration** — this story's own fragment for `tools`+`toolInstallCommands`, the repo's own dependency declaration for a test/runtime package — never the gate, never a bare install inside CI YAML. Capped at **3 attempts**; on exhaustion HALT per SH-4 with no push and no PR. Reuse Step 6.1's containerised behavioural evidence instead of re-running it.
- 🔴 **AFTER THE PR EXISTS (WHEN CI/CD IS ENABLED), THE TWO REPAIR AGENTS HAVE EXCLUSIVE TERRITORIES** (`common/ci-pipeline-generation.md` Section 6.6): **this workflow repairs CI configuration and provisioning only** (manifest fragment, dependency declarations, pipeline scripts, tool pins) and **CI self-repair repairs application code and tests only**. A Code-class CI failure is recorded and left to self-repair — never fixed from the attestation gate, never charged to an attestation attempt. Never push into an in-flight self-repair run: wait for it, fetch, rebase onto its commit, re-read; never force-push, never revert its commit. Two agents repairing one PR head is wasted budget on both sides.
- **SELF-HEALING IS CAPPED AT 3 ATTEMPTS PER LOOP.** The **Self-Healing Retry Policy (SH-1 … SH-7)** at the top of this file governs every SH-LOOP in its table without exception. Track one counter per loop, log every attempt, and on exhaustion HALT at that gate, emit the Self-Heal Limit message (`common/self-heal-limit-guidance.md` — what is failing, why, how to fix it by hand, how to hand it back), and wait for the user. NEVER start a 4th attempt, never skip or weaken a failing gate to move on, and never continue to a later stage with an exhausted loop outstanding.
- 🔴 EVERY runtime-artifacts/audit.md entry in this workflow — selection, branching, planning, generation, coverage, review, remediate, PR — MUST carry the `**User Email**:` (current session email), `**TRACKER ITEM**:`, `**Epic Link**:` (full Parent Epic URL from `## Tracker` in runtime-artifacts/aire-state.md, or `none`) AND `**AIRE VERSION**:` fields (version read at runtime from the "AIRE Framework Version" line in `CLAUDE.md` — never hardcoded). See the Audit Entry Format section above.
- 🔴 EVERY story commit MUST carry the `AIRE-Version: [N]` trailer (framework signature, read live from `CLAUDE.md`) — see Section D Step 2.
- 🔴 ALWAYS show the sequential-development banner (Step 1.75) on every invocation, BEFORE Story Selection — one story at a time per session; parallel development happens in a separate folder/clone on an independent story.
- 🔴 **PARALLEL-SAFE STATE — NEVER COMMIT THE SHARED BOOKKEEPING FILES** (`common/parallel-work-state.md`): this story's audit entries go to `runtime-artifacts/stories/story-<N.M>/audit.md` and its Story Tracker row, progress and SH counters to `runtime-artifacts/stories/story-<N.M>/state.md`; reads use the resolved view; every commit passes the State Isolation Check. A story PR therefore never conflicts with another story's PR, or with ve's epic-branch sign-offs, on `audit.md` / `aire-state.md`.
- 🔴 **SINGLE-SESSION EXECUTION — NEVER FORK** (Step 1.7): the whole run happens in the session where `dev-implement` was typed. Never hand any step to a fork, subagent, Workflow-tool run, background/remote agent, second session or `claude -p` subprocess; agent procedure files and skills execute inline; the Code Review pass is read-only by discipline, not by delegation. The only Agent-tool use is Playwright's own Planner/Generator/Healer inside Step 6.7, synchronously, one at a time. A run that finds itself inside a fork or subagent HALTS before Story Selection, for every story, changing nothing.
- 🔴 **A CHANGE TO WORK THE EPIC ALREADY BUILT IS NOT A `dev-implement` RUN** — new or changed behaviour, or a bug in an earlier story, found mid-cycle is delivered with `epic-enhance` (`workflows/epic-enhance.md`) or `epic-bugfix` (`workflows/epic-bugfix.md`, which also detects AI-origin automatically): one document, one approval, a new change story on the epic branch that also updates the affected stories' ACs, scenarios, test plans and tests under a Test Change Authorization list, then this workflow's full gate chain. `dev-implement` never edits an earlier story's tests or specs to fit new behaviour.
- 🔴 **A REJECTED STORY PR IS FIXED WITH `pr-fix`, NOT BY RE-RUNNING `dev-implement`** (`workflows/pr-fix.md`): when the developer or the ve comments on / requests changes on an open `[STORY]` PR, `pr-fix <PR>` fixes it on the same branch, re-runs this workflow's complete gate chain and updates the same PR. Re-running `dev-implement` on an already-claimed story would cut a second branch and a second PR.
- 🔴 NEVER guess which story to implement — always ask and wait.
- 🔴 NO GATES: this workflow asks for NO approval — no plan approval (GATE 2 removed) and no review decision (GATE 3 removed). Never present an approve/reject or Approve-&-continue/Remediate prompt, and never write "GATE" into an audit heading here. The Doability Gate and the branch-cut dependency-merge check are machine checks that STOP the run — they are not approvals and remain in force.
- 🔴 PLAN GUARDRAIL: the code-generation plan MUST be grounded in the previously generated docs (story acceptance criteria, epic-brief, requirements, design artifacts), and coding MUST follow the announced plan exactly — any needed deviation is applied only after the plan document is revised and the change announced + logged, never silently.
- 🔴 REQ-ID THREAD: `requirements.md` + the story's `Covers` REQ-IDs are MANDATORY planning inputs; every plan step is tagged with the REQ/AC it implements and the trace completeness self-check (every covered REQ-ID and every AC in ≥1 step) MUST pass before the plan is executed. If `runtime-artifacts/aire-state.md` has no `Requirements coverage verified post-design` record, run the Rule 4 fallback verification (silent, blocking) before planning. See `common/requirements-traceability.md`.
- 🔴 ALWAYS create the story branch (Step 1.5) right after Story Selection — cut from the refreshed EPIC branch per `common/branching-strategy.md`, NEVER from main/the base branch or a dependency branch — and run the dependency-merge check BEFORE any code is generated: if any prerequisite is unmerged into the epic branch, WARN AND STOP and tell the user to merge it first.
- 🔴 NEVER bypass the Doability Gate — a story is doable only when ALL its `requires` are confirmed MERGED: already `Ready for Testing` in the tracker, or live-verified via `gh pr view` at gate time (`implementation/story-selection.md` Step 4). Any prerequisite still unmerged →  STOP the run with a clear message naming it; do NOT loop back and do NOT let the user bypass it.
- 🔴 **THE GATE NEVER MERGES A PR — PERIOD.** Not automatically, not with a confirmation prompt, not even when the PR is already approved by a human. PR approval is always a manual action a human performs outside this workflow, and merging is likewise always the user's own action. The Doability Gate only ever reads live PR state (`gh pr view`) — it has no merge step of any kind. If the blocking prerequisite is already approved, say so in the stop message so the user knows merging it is all that remains.
- 🔴 The ONLY valid Story Tracker statuses are `Ready for Development`, `In Development`, and `Ready for Testing`. The story stays `In Development` through code generation, Code Review, Remediate, the PR raise, AND the auto PR Review; it becomes `Ready for Testing` ONLY when its PR is confirmed **MERGED** into the epic branch, promoted exclusively by the `ve-list-work` skill, on ve's explicit say-so. Raising the PR NEVER promotes the story, and NEITHER does a later `dev-implement` run — it only ever live-checks a specific prerequisite's PR at its own Doability Gate.
- 🔴 At Section D, when the PR is raised, STORE the PR URL in the Story Tracker (`PR` column, `Merged=no`) and keep the story `In Development` — do NOT transition the tracker or set `End` here.
- 🔴 dev-implement does NOT bulk-reconcile or promote prior `In Development` stories at the start of a run (Step 1.5) — that promotion is exclusively the `ve-list-work` skill's job. dev-implement only ever live-checks the PR-merge state of a SPECIFIC prerequisite, at the Doability Gate, when a story that `requires` it is being selected — and STOPS the run with a clear message if that prerequisite isn't merged yet.
- 🔴 ALWAYS enforce the Unit Test & Coverage gate: after implementation, generate unit tests, RUN them, and iterate within the same run until coverage on the story's new/changed code meets `unitTestCoverageMin`. This is **SH-LOOP-1**, capped at **3 remediation attempts**; on exhaustion apply SH-4 — HALT, emit the Retry-Limit Report, and never mark the story done below the threshold.
- 🔴 ALWAYS enforce the API & Contract Testing Gate (Step 6.2) WHEN this story's plan includes an API Layer Generation step: generate automated tests against the real endpoints, RUN them, and iterate within the same run until EVERY applicable checklist item (functional, response-code validation, role-based authorization 401/403, error-response validation, request validation, response contract/schema validation) passes. This is **SH-LOOP-2**, capped at **3 remediation attempts**; on exhaustion apply SH-4 (HALT + Retry-Limit Report). Applicability is decided from the plan alone — never asked. When the plan has no API layer step, mark it N/A with a reason and proceed. Capture proof artifacts to `reports/api-contract-test-evidence/story-[N.M]/` — never a hand-written claim. This gate runs BEFORE the Full Regression Gate (Step 6.5) and does NOT replace ve's `/ve-implement` MANUAL API/Contract test steps.
- 🔴 **Step 6.7 has TWO halves with DIFFERENT applicability — never skip the whole step because the story has no UI.** **Part 1 — the story's manual test plan — is VERIFIED for EVERY story, UI or not**: it was authored and approved at the STOP CHECKPOINT (`CLAUDE.md` Step 1.7), so the normal case is a presence check; `ve-implement` is invoked in WORKFLOW MODE only to backfill a genuinely absent plan, announced. Either way the Verification Engineer simply executes the plan once the story PR merges instead of generating it first. **Part 2 — `playwright-implement` → browser automation — runs ONLY when the story's plan includes a Frontend Components Generation step**; on a backend-only story record `Playwright UI Automation: N/A — no UI touched by this story` and move on, **with part 1 still done**. Both halves run **by INVOKING those skills in WORKFLOW MODE with the story passed in**, never by re-implementing their steps inline. WORKFLOW MODE skips their story-pickers, Verification Engineer's branch/approval/PR, the both-merges gate, the integration-branch checkout, the Planner-plan Approval Gate and the Push Gate — and nothing else. The skill starts the app locally, runs the real Planner/Generator/Healer subagents, executes **`--headed`** (same as standalone — headless is CI's alone, since a runner has no display), and iterates — fixing application code, never `test.fixme()`-ing a real failure — within the same run until every generated spec passes. This is **SH-LOOP-11**, capped at **3 remediation attempts**; on exhaustion apply SH-4 (HALT + Retry-Limit Report). Applicability is decided from the plan alone — never asked. When the plan has no Frontend Components Generation step, mark it N/A with a reason and proceed. Capture proof artifacts to `reports/playwright-test-evidence/story-[N.M]/` and write the result into `eval.json`'s `gates.playwright` — never a hand-written claim. This gate runs BEFORE Code Review; CI later re-executes it headless as a **trust gate, never the first execution**, cross-checked automatically by the CI Attestation gate (SH-LOOP-10). It does NOT replace ve's own independently-scheduled `/ve-implement` run.
- 🔴 **ALWAYS run the BASELINE Playwright E2E regression (Step 1.5 Item 4.7) and the FULL Playwright E2E regression (Step 6.8), then diff them — for EVERY story, UI or not.** This is the UI counterpart of the unit-test regression pair (Item 4.5 / Step 6.5) and exists for the same reason: Step 6.7 only proves *this* story's own specs pass, so nothing else proves this story did not break a browser flow an earlier story already shipped. 🔴 **Do NOT skip it because the story touches no UI** — a backend, API, schema, config or dependency change is exactly what breaks an existing flow silently. Both runs are **automatic — never prompt the user for either**. Only specs green at baseline and red now count; this story fixes them in the same run under **SH-LOOP-13** (capped at **3 remediation attempts**; on exhaustion apply SH-4 — HALT + Retry-Limit Report). 🔴 **NEVER delete, `test.fixme()`, `.skip`, loosen a locator, widen a timeout or narrow an assertion to make an existing spec green** — the analogue of deleting a failing unit test, equally forbidden (SH-6); fix the application code. Baseline failures are pre-existing debt: logged and ignored. Evidence goes to `reports/playwright-test-evidence/story-[N.M]/regression/` and the result into `eval.json`'s `gates.playwrightRegression` — a **local-only** gate, never added to `ci.gates`. Headless is the default for this sweep (a reasoned carve-out from Step 6.7's `--headed` rule, recorded with its reason).
- 🔴 ALWAYS BOOTSTRAP missing tool configs BEFORE the baseline static run (Step 1.5 Item 4.6, `common/eval-framework.md` Section 2.2) — a check with no config is **set up**, not marked N/A; a check whose config exists is used **as-is**. Bootstrap → baseline → code → gate → diff, in that order: a config created after the baseline makes the two runs measure under different rules and blames this story for pre-existing findings. Announce every file created; only a genuinely unavailable tool is `N/A`.
- 🔴 ALWAYS run the BASELINE static eval checks D1–D7 alongside the baseline regression (Step 1.5 Item 4.6) and the STATIC EVAL GATE after the Full Regression Gate (Step 6.6), then diff them. Both runs are **automatic — never prompt the user for either**. Only findings NEW vs the baseline on files this story changed count, and this story **fixes them in the same run**. **NEVER suppress a finding to pass the gate** (`eslint-disable`, `# nosec`, `# type: ignore`, ignore lists, widening the licence list) — that is the analogue of deleting a failing test and is equally forbidden. Baseline findings are pre-existing debt: logged and ignored. See `common/eval-framework.md`.
- 🔴 The J1/J2 judge scores are computed ONCE per review pass inside Section A and are **blocking gates** (see the Critical Rule above and `common/eval-framework.md` Section 4): below minimum → SH-LOOP-6. They are never re-rolled within a pass.
- 🔴 The auto-remediate loop (**SH-LOOP-5**) is **capped at 3 rounds** by the Self-Healing Retry Policy. It fixes review and security findings; a judge score below minimum is fixed by its own loop, SH-LOOP-6.
- 🔴 ALWAYS run the BASELINE regression (entire repo suite) on the story branch BEFORE any code is generated (Step 1.5 Item 4.5) and the FULL regression AFTER the Unit Test & Coverage gate and the API & Contract Testing Gate (Step 6.5), then diff them. Both runs are **automatic — never prompt the user for either**. Failures NEW vs the baseline were broken BY this story, so this story **fixes them in the same run** — iterate until the diff is clean under **SH-LOOP-3** (capped at **3 remediation attempts**; on exhaustion apply SH-4 — HALT + Retry-Limit Report), fixing each according to what broke (update an obsolete expectation / delete a genuinely dead test / fix the implementation for a real regression). **NEVER delete, skip, or weaken a failing test merely to make the suite green, and NEVER hand a new failure back to the user.** Failures already red at baseline are not this story's doing — they are logged in `baseline-regression.log` and ignored. The the `unitTestCoverageMin` threshold gate is scoped to the story's new code and does NOT substitute for this — coverage on new code says nothing about assertions the change invalidated in pre-existing shared test files.
- 🔴 ALWAYS capture the TEST PROOF artifacts from that same run before leaving `In Development` — save the raw runner output (`unit-test-run.log`), the coverage tool's **mandatory machine-readable report** (`coverage-report.*` — lcov/xml/json/HTML), and `evidence-manifest.md` to `reports/unit-test-evidence/story-[N.M]/`. Run the tool with the flags that emit the report file; a terminal summary alone does NOT satisfy the gate — when the stack HAS coverage tooling, no coverage-report file means the gate is not met, STOP and surface it. The only waiver is a stack with genuinely NO coverage-report tooling, and that must be a documented, user-surfaced exception in `evidence-manifest.md` — never a silent skip. Evidence is the actual tool output, never a hand-written claim; every X/X-passing and coverage-% figure in the completion message, Code Review report, and PR/tracker comment MUST match these stored artifacts.
- 🔴 After Code Generation, ALWAYS auto-run Code Review (`workflows/code-review.md`) and audit its complete log in runtime-artifacts/audit.md. The verdict — not the user — decides what happens next (Section B).
- 🔴 **THE FRAMEWORK FIXES ITS OWN FINDINGS, WITHIN A BOUNDED BUDGET.** Any 🔴/🟠 finding triggers the **Auto-Remediate Loop** (Section C, **SH-LOOP-5**): remediate → re-run regression → re-review, looping until the verdict is clean **or the 3-attempt budget is exhausted**. Never ask whether to remediate, and never raise the PR on an unclean verdict. On exhaustion (3 rounds, or an SH-5 stall — no code change + identical findings) the run **HALTS at the gate**: no commit, no push, no PR, no tracker change; the Retry-Limit Report is emitted to the user and to runtime-artifacts/audit.md, and the run waits for the developer to fix it manually and hand it back.
- 🔴 The commit, push and PR are AUTOMATIC once the verdict is clean. Commit to the story branch from Step 1.5, then push + raise the PR ONLY via the `pr-generator` skill (used as-is), passing **target branch = the Epic Branch**. Story PR titles MUST carry the **`[STORY]`** prefix (pr-generator applies it).
- 🔴 **ONE SANCTIONED PAUSE — a Playwright agent install (Step 4.3).** For a frontend work unit, Playwright Readiness (Step 4.3) installs the runner, the browsers and Playwright's official test agents **before any code is written**. If the agents had to be installed, the run records `PAUSED —` and asks the user to restart the Claude Code session — MCP servers load at session start, so the `playwright-test` server is not connected until then. 🔴 **This is a hard stop, not an approval prompt.** Nothing is committed, pushed or transitioned; after the restart the user types `dev-implement` and it continues at **Step 4.5**. The Playwright UI gate (Step 6.7) keeps the same install-then-pause handling only as a safety net, resuming at Step 6.7 if it ever triggers there. Everything already installed → no pause.
- 🔴 **THE RUN HAS NO PROMPTS AFTER THE STORY KEY.** Story selection → branch → baseline (regression + static eval + Playwright e2e, installing the Playwright runner and browsers when specs exist) → plan → Playwright readiness (frontend plans only; the one sanctioned restart pause if agents were installed) → code → coverage → test placement check → regression → static eval gate → playwright UI automation → playwright e2e regression → review → auto-remediate → [manifest reconciliation → commit → **CI preflight (SH-LOOP-9)**] → push → PR (pr-generator **workflow mode, Phase 5 skipped**) → labels → Story Tracker PR/Merged update → [CI attestation] → auto `pr-review` → Section F handoff, all uninterrupted. The bracketed CI-specific steps run only when `## CI/CD Configuration` `Enabled: Yes` (Step 1.2 opt-in) — when `Enabled: No` they are silently skipped, never asked about again, and the chain is simply: review → auto-remediate → commit → push → PR → auto `pr-review` → Section F handoff. Asking anything in that chain (approve the plan, approve the review, whether to push, whether to open the PR, whether the title/body/labels are OK, or whether to run CI) is a defect. Announce each action; never ask mid-run.
- 🔴 The story branch name is derived and created **automatically — never confirmed or offered for override** (Step 1.5 Item 2); it is announced.
- 🔴 EPIC STATUS SYNC: on the FIRST story pick, the Parent Epic moves to "In Development" automatically; when ALL stories are `Ready for Testing` (i.e. ALL PRs merged), offer (confirm-first) to move the Parent Epic to "Ready for Testing". Verify every epic transition and log it. If the last story's PR is raised while other PRs are still open, do NOT move the epic — report the open PRs and keep everything `In Development`.
- 🔴 After the PR is raised (the story STAYS `In Development` — it is NOT yet Ready for Testing), ALWAYS auto-invoke the `pr-review` skill (used as-is) against that PR in **AUTO MODE** — it posts automatically as a plain COMMENT review (summary + inline comments) with NO user prompt and NEVER a formal GitHub APPROVE/REQUEST_CHANGES (the PR author's own identity cannot formally self-review). The skill's Phase 5 confirmation applies only to standalone runs.
- 🔴 EVERY run that raises a PR MUST end with the **Section F Next-Action Handoff** — the PR ready for review, reviewed by the Developer and the Verification Engineer together, approval and merge stated as manual steps, and the ONE keyword to type (`dev-implement` when stories remain, `ve-list-work` when this was the last story). 🔴 Do NOT tell the user to switch branches — `dev-implement` refreshes the epic branch itself (`common/branching-strategy.md` Section 3) and `ve-list-work` resolves and switches on its own. 🔴 The framework never merges a PR for you, approved or not — say so plainly, and never imply the next run will merge it automatically. Never end a run with a bare "PR raised" summary, and never leave the next step to the user's own words. Nothing is output after the handoff block.
- 🔴 On every auto-remediate round, ALWAYS audit the complete remediate log, then re-review automatically — never offer "Approve & continue" or "Re-review" as a choice.
- 🔴 The ONLY story tracker transition this workflow makes is the **automatic** claim (`In Development` at story pick). `Ready for Testing` is set only by `ve-list-work` Option B after the PR has merged. Any OTHER tracker transition (e.g., the Parent Epic moves) requires explicit user confirmation. ALWAYS verify every transition landed (non-LOCAL) and log it in runtime-artifacts/audit.md.
- 🔴 At story pick, ALWAYS set the assignee to the operator who invoked `dev-implement` per `common/tracker-sync.md` Section 5 (automatic, verified where applicable, logged). Unresolvable identity → leave unassigned, warn, continue — assignment failure never blocks development. LOCAL has no assignee concept.
- 🔴 ALWAYS update the Story Tracker (and `Recorded` timestamp) on every status change.

---
