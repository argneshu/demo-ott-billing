# WORKFLOW: `epic-enhance <TICKET-ID | description>` (Mid-Epic Enhancement — into the Epic Branch)

> **READ FIRST.** The six non-negotiables at the top of `workflows/dev-implement.md` bind this workflow
> too: every gate runs (no scope calls), the Gate Ledger is complete before the commit, the work-unit
> guard (`sh aire-workflow/templates/hooks/check-work-unit.sh --install <unit-key>` right after the story branch is cut) is installed and
> never bypassed, the claim (In Development + assignee) is made on the external tracker and recorded in the fragment's `## Claim` block — a `pr-fix` run whose unit has no such block makes the claim now —, a disclosed gap is never shipped, and the run
> ends with this workflow's own handoff block verbatim — nothing else in that final message.

## WHAT THIS WORKFLOW IS

A new or changed behaviour that arrives **while an epic cycle is still open**, including behaviour that
earlier stories of the epic already built, is delivered **inside that epic** as ONE new change story
on the epic branch, instead of as a separate base-branch cycle. Earlier stories' specs, test plans and
tests that the change touches are found, updated and re-proven in the same PR.

Bugs found in work the epic already built have their own flow: `epic-bugfix`
(`workflows/epic-bugfix.md`).

| | `ticket-implement` → enhancement cycle | **`epic-enhance` (this workflow)** |
|---|---|---|
| Branch | `enhancement/…` from **base** | `story/…` from the **epic branch** |
| PR | `[ENH]` → base | **`[STORY]` → epic branch** |
| Cycle | Its own: requirements, design stages, STOP checkpoint, archive | **None** — the epic's state, specs, rubrics and CI are reused |
| Documents | brief, requirements, impact analysis, design docs, plan | **ONE** — `spec/plans/change-story-<N.M>.md` |
| Earlier stories' tests | Not its concern | **Found, changed and re-proven** — scenarios, test plans, unit/API tests, step definitions and Playwright specs |
| Questions | Requirements Q&A, approvals per stage | **None — only the plan approval** |

---

## FAST BY DESIGN — LESS CEREMONY, NEVER FEWER GATES

**Cut**: requirements Q&A, design-stage documents, the STOP checkpoint, the smoke test, a separate
code-generation plan file, a separate ve test-plan PR, a separate archive, and every clarifying
question.

**Never cut**: the baselines, every gate of `workflows/dev-implement.md` (unit + coverage, Gherkin
B1/B2/B3, API & contract, test placement, full regression, D1–D7, Playwright UI + E2E regression, Code
Review with the Security Baseline pass and the blocking J1/J2 judges, auto-remediation, CI preflight and
attestation), the 3-attempt retry cap, and the rule that a test is never weakened to go green.

The one addition over `dev-implement` is the **Test Change Authorization** discipline (Steps 5.4 and
12): changing an earlier story's behaviour legitimately invalidates some of its tests, so the approved
change document names **exactly** which ones may change. Every other test is a regression guard and
must stay green by fixing code.

---

## 🔴 THE ONLY QUESTION IS THE PLAN APPROVAL

**The run asks exactly one thing: approve the change document (Step 7).** It never asks a clarifying
question, never offers a menu of options, and never asks for a decision mid-run.

- **Input comes with the keyword.** `epic-enhance PROJ-240` or
  `epic-enhance "let managers export the order list as CSV"`. A bare `epic-enhance` stops with one usage
  line — `Usage: epic-enhance <TICKET-ID | "description of the change">` — and asks nothing.
- **Where a decision is needed, the framework decides, and the document says so.** Every such decision
  is written into the document's **Section 9 — Decisions & assumptions** with its reason and the
  alternative it rejected (defaults in the Edge cases table). The user overrules any of them with
  **Request Changes** at the approval — that is the only channel, and it is enough.
- **Approval authorises everything the document lists**: the new story, the amended acceptance
  criteria, the Test Change Authorization list, the tracker story creation and links, the dependency
  edges, an `architecture.md` amendment, and — when the document says so — moving the Parent Epic back
  to In Development.
- After approval the run is **fully automatic** through to the PR and the handoff. A correction the user
  volunteers is an interrupt: apply it, record it in the document's revision log, continue.
- The sanctioned **halts** stay (they are not questions): SH-4 retry-limit exhaustion, the Playwright
  agent-install restart pause, and the Step 4 blocks.

---

## 🔴 SINGLE-SESSION EXECUTION — NO FORKS

`workflows/dev-implement.md` Step 1.7 applies to this whole workflow, unchanged: every step runs in the
session where the keyword was typed; nothing is delegated to a fork, subagent, Workflow-tool run,
background or remote agent, second session or `claude -p` subprocess; agent procedure files and skills
execute inline; the Code Review pass is read-only by discipline. The only Agent-tool use is Playwright's
own Planner/Generator/Healer inside the Playwright UI gate, one call at a time, synchronously. A run
inside a fork or subagent HALTS at Step 0.

---

## MANDATORY: Rule Details Loading

Resolve `aire-workflow/` and load:
- `common/process-overview.md`, `common/session-continuity.md`, `common/content-validation.md`,
  `common/audit-logging.md`, `common/tracker-sync.md`, `common/branching-strategy.md`,
  `common/requirements-traceability.md`, `common/behavior-spec.md`, `common/eval-framework.md`,
  `common/directory-structure.md`
- `workflows/dev-implement.md` **in full** — its Step 1.5 (branch + baselines) and everything from
  Step 4.5 to Section F is executed **by reference** at Steps 9–14; its Self-Healing Retry Policy and
  Retry-Limit Report bind this workflow.
- `implementation/code-generation.md` (Guardrail — Generation Phase Rules),
  `workflows/code-review.md` + `implementation/code-review.md`, `workflows/remediate.md` +
  `implementation/remediate.md`
- When `## CI/CD Configuration` records `Enabled: Yes`: `common/ci-pipeline-generation.md` Sections
  4.0d, 4.0f, 4.0i and 6.6
- 🔴 The Playwright non-negotiables in `workflows/dev-implement.md` ("MANDATORY: Rule Details
  Loading") apply unchanged — earlier stories' Playwright specs are changed only by the
  `playwright-implement` skill's own subagents, never by hand.

---

## SELF-HEALING RETRY POLICY — INHERITED, PLUS ONE LOOP

SH-1 … SH-7 from `workflows/dev-implement.md` govern every loop here (3 attempts each, independent
counters, logged root cause per attempt, exhaustion HALTS with the Retry-Limit Report, stalls end the
budget early, no weakening).

At SH-4 the run emits the **Self-Heal Limit message** (`common/self-heal-limit-guidance.md` Section 2 —
what is failing, why it stopped, how the developer reproduces and fixes it, what the gates reject) with
**resume keyword = `epic-enhance`**, and records `HALTED —` in the story fragment's `## Progress`. Typing
`epic-enhance` again is a hand-back: the run finds the halted change story and follows the resume protocol
(Section 4) instead of starting a new change — the plan approval is not asked again.

The loops keep their `dev-implement` IDs, plus:

| ID | Loop | Defined in | Verification that must pass to exit |
|---|---|---|---|
| **SH-LOOP-15** | Test Impact Reconciliation | Step 12 | The test/spec diff matches the Test Change Authorization list exactly (every authorised change made, no unauthorised change), and every new or amended AC has ≥1 scenario and ≥1 test case |

---

## MANDATORY: Audit Entry Format

`workflows/dev-implement.md`'s format (`User Email`, `User Input`, `TRACKER ITEM`, `Epic Link`,
`AIRE VERSION`, `AI Response`, `Context`) **plus** one field on every entry:

```markdown
**CHANGE**: "ENHANCE — Story <N.M> — spec/plans/change-story-<N.M>.md"
```

Append only; timestamps from one real clock command.


## 🔴 PARALLEL-SAFE STATE — THIS STORY WRITES ONLY ITS OWN FRAGMENT (`common/parallel-work-state.md`)

Other developers build other stories of the same epic at the same time, and the ve signs stories off on
the epic branch. So that none of their PRs conflict on the framework's bookkeeping, **the build path of
this workflow never writes the shared `runtime-artifacts/audit.md` or `runtime-artifacts/aire-state.md`**:

- Every audit entry goes to **`runtime-artifacts/stories/story-<N.M>/audit.md`** (same format plus
  `**Unit**: "story-<N.M>"`). Entries from Steps 1–5, before the story number exists, are held and written there with their original timestamps as soon as Step 5.2 assigns it.
- The story's Story Tracker row, progress and SH counters go to
  **`runtime-artifacts/stories/story-<N.M>/state.md`**; the change story's dependency-graph node goes to
  its `## Dependency Graph Additions` section (the shared `## Dependency Graph` section is never
  edited).
- This overrides every mention of those two shared paths below. Reads use the **resolved view**
  (`common/parallel-work-state.md` Section 4).
- 🔴 **State Isolation Check before every commit** (Section 5.5). No push only to record a PR URL
  (Section 4.6).
- **The spec-only path is an integration-branch writer** — it commits on the epic branch itself, so it
  writes the shared files, pulling immediately before and pushing immediately after (Section 6).
---

## Step 0 — 🔴 Single-Session Check

Exactly `workflows/dev-implement.md` Step 1.7's fork check. Inside a fork or subagent → HALT with
that step's message (substituting `epic-enhance`), change nothing.

## Step 1 — Preconditions: is there an open epic cycle to change?

0. **▶ Hand-back first**: if the checked-out branch is a change story's branch whose fragment
   (`runtime-artifacts/stories/story-<N.M>/state.md`) holds a `PAUSED —` record (Playwright agent install —
   continue at the step it names) or a `HALTED —` record, this invocation is the
   developer handing the work back after a manual fix — the keyword may be bare and the working tree dirty
   by design. Skip the rest of Steps 1–9 and follow `common/self-heal-limit-guidance.md` Section 4, then
   continue from the first code gate (Step 11) or the halted gate. Otherwise continue with item 1.
1. `runtime-artifacts/aire-state.md` exists with `## Branching` → `Epic Branch` recorded and no
   `Workflow Type: bug` / `Workflow Type: enhancement` in `## Tracker`. Otherwise → stop:
   `No open epic cycle here — use ticket-implement <TICKET-ID> for a base-branch enhancement cycle.`
2. The keyword carries a ticket ID or a description. Otherwise → stop with the usage line.
3. The working tree is clean (`git status --porcelain` empty). Otherwise → stop:
   `Commit or stash your local changes, then re-run epic-enhance.` Never stash or discard for the user.
4. `git fetch origin && git checkout <epic-branch> && git pull --ff-only`.
5. **The cycle is still open**: `spec/`, `spec/plans/stories.md` and the Story Tracker are present, and
   `aire-archives/epics/<EPIC-ID>-*/` does not exist. Archived → stop: the change belongs to a
   base-branch cycle after the Epic PR merges (`ticket-implement`), or the user reverts the archive
   commit first.
6. Read `## CI/CD Configuration`, `## Tracker`, `## Code Root`, `team_size`, and the
   `tests/.evals/config.json` thresholds. Log the preconditions.

## Step 2 — Capture the change

- **Ticket ID**: fetch it per `common/tracker-sync.md` Section 8 — summary, description, acceptance
  criteria, labels, links.
- **Description**: use it verbatim as the change statement.

Where the capture leaves something open (a rule, a limit, a message text), do not ask: choose the
reading most consistent with the approved ACs, `requirements.md`, `architecture.md` and the existing
code, and record it as an assumption in document Section 9. Log the invocation and the capture verbatim.

## Step 3 — Impact analysis (code → stories)

No file is "affected" without a recorded reason.

1. **Code surface**: the files, symbols and `file:line` ranges the change must add to or alter — read
   the code, never infer from names.
2. **Map every touched path to the stories that own it**, from three independent sources (record which
   ones agree):
   - the manifest fragments `tests/.evals/ci-manifest.d/story-*.json` (`sourcePaths` / `testPaths`),
   - epic-branch history — story commits carry `[Story N.M / TRACKER-ID]` subjects
     (`git log --format='%H %s' origin/<base>..<epic-branch> -- <path>`),
   - `git blame -w -M -C -L <range> -- <file>` on the touched line ranges.
3. **Map behaviour to stories**: read the ACs of **every** story in `stories.md` — merged, in flight
   and not yet started — and list each AC whose behaviour the change alters, even where no code exists
   yet.
4. **Map tests to stories**: for each affected story, list its tests that exercise the touched code or
   the altered ACs — `tests/unit/**`, `tests/api/**`, `tests/behavior/steps/**`,
   `tests/e2e/<story-slug>/**` — plus its scenarios in `spec/behavior/story-<N.M>.feature`, its cases in
   `spec/test-plans/<ID>-*/`, and any journey in `spec/behavior.feature`.
5. **Concurrency scan**: every other work unit `In Development` without a merged PR, and every open
   `ve/…` test-plan PR, whose diff touches a path in the change surface (`gh pr diff <n> --name-only`).

## Step 4 — Route on the state of each affected story

| Affected story's state | What the change does to it | Outcome |
|---|---|---|
| `Ready for Development` — no code yet | Amend its ACs, scenarios and test cases only (**spec-only**); add a `requires` edge onto the change story when its code will build on the change | Proceed |
| `In Development`, **no PR yet** — being built right now | Cannot change a spec or code under an in-flight build | **HALT — blocked** (E2) |
| `In Development`, **PR OPEN, unmerged** | Its code is not on the epic branch yet | **HALT — blocked** (E3): comment the change on that PR and run `pr-fix <PR>`, or merge the PR and re-run |
| `In Development`, **PR MERGED** (awaiting ve sign-off) | Code change on the epic branch through the change story; its tests/specs amended in place | Proceed (E4) |
| `Ready for Testing` — ve already signed off | Code change through the change story; its tests/specs amended in place; **status not demoted** — the change story's test plan carries the re-verification | Proceed (E5) |

- **All affected stories are `Ready for Development`** → the **spec-only path**: Steps 5–7 and 9.3 run, no change story is
  created, nothing is built; Step 9.3 ends with a direct commit on the epic branch, and the document is
  saved as `spec/plans/change-spec-<X.Y>.md`.
- **Any block** → HALT before writing anything, listing every blocking story, its state, its PR and the
  exact way forward. Log it. (A halt, not a question.)

## Step 5 — Test impact analysis and sizing

### 5.1 Classify every affected AC

| Class | Meaning | Artifacts that move |
|---|---|---|
| **UNCHANGED** | Behaviour stays as approved | None — its tests are regression guards and must stay green |
| **AMENDED** | Behaviour changes | AC text, its scenario(s), its test case(s), the tests asserting the old behaviour, its Playwright spec(s) if it has UI |
| **SUPERSEDED** | Behaviour is removed | AC marked superseded (never deleted); scenario(s) and test case(s) retired; tests deleted as genuinely dead; dead code removed |

### 5.2 Define the change story

- **Number**: the next free `N.M`, read from `origin/<epic-branch>`'s `stories.md` and Story Tracker
  **immediately before assigning** (two clones may run this at once — E13).
- **Title**: `Change: <summary>`.
- **ACs**: the behaviour **as it must now be** — net-new behaviour plus the new form of every AMENDED
  behaviour, so B1 proves the change end to end.
- **Covers**: existing REQ-IDs it implements; a genuinely new requirement gets a new REQ-ID appended to
  `requirements.md` (`REQ-F-NN — added mid-cycle by Story <N.M>`).
- **Requires**: every affected story whose code it changes (all merged, per Step 4).
- **Enables**: every `Ready for Development` story that must now wait for it.

### 5.3 Artifact inventory

Every artifact that will be edited or created: `stories.md` (new story + annotated amendments),
`requirements.md`, `dependency-graph.yml` + Story Tracker row, feature files (the change story's new
`spec/behavior/story-<N.M>.feature`, amended scenarios in earlier stories' files, `spec/behavior.feature`
journeys), test plans (the change story's new folder, amended cases in earlier stories' folders), tests
(5.4), and `architecture.md` Section 10 only if a design decision changes.

### 5.4 Test Change Authorization list

The exact tests that may be **modified or deleted** because an AC they assert was AMENDED or
SUPERSEDED — one row each: `file` + test name + action (`update assertion` / `delete — dead` /
`regenerate via playwright-implement`) + the AC it traces to. **A test not on this list must pass
unmodified** (new tests may always be added).

### 5.5 Sizing check

A change that would add a new deployable component, service, data store, external integration or
infrastructure resource, touch more than half of the epic's stories, or need a design stage the epic
skipped is **over-size** (E9). It is not asked about: the default is decided and recorded (E9).

## Step 6 — Write THE ONE document: `spec/plans/change-story-<N.M>.md`

(Spec-only path: same template, saved as `spec/plans/change-spec-<X.Y>.md` after the first amended
story, with Sections 4 and 6 marked N/A.)

```markdown
# Change Story <N.M> — <title>
Mode: ENHANCE · Source: <ticket link | "inline description"> · Epic: <EPIC link>
Epic branch: <branch> @ <sha> · Written: <ISO timestamp> · AIRE v<N>

## 1. The change
<what changes and why>

## 2. Impact — code
| Path / range | Change | Owning story (evidence: fragment / history / blame) |

## 3. Impact — stories and acceptance criteria
| Story | State | AC | Class (UNCHANGED / AMENDED / SUPERSEDED) | Old → new text |
Spec-only amendments to stories are listed here too.

## 4. The change story
Story <N.M> — <title> · Covers: <REQ-IDs> · Requires: <stories> · Enables: <stories>
Acceptance criteria:
- AC-1 …

## 5. Test impact
### 5a. Contracts — scenarios and test cases (per story: added / amended / retired)
### 5b. Test Change Authorization list
| File | Test | Action | Traces to |
### 5c. New tests to add (unit / API / step definitions / Playwright via playwright-implement)

## 6. Implementation plan  (this section IS the code-generation plan — checkboxes marked as work completes)
- [ ] Step 1 — … (AC-n / REQ-ID)
Trace check: every change-story AC and every AMENDED/SUPERSEDED AC appears in ≥1 step.

## 7. Tracker and state actions on approval
New tracker story or existing ticket · link to the Parent Epic · comments on affected stories · Epic
reopen (only if the Epic is already Ready for Testing) · dependency edges.

## 8. Warnings
Concurrent work on the same paths · open Verification Engineer PRs on affected test-plan folders · architecture impact ·
OVER-SIZE (if flagged).

## 9. Decisions & assumptions (made by the framework — overrule any with Request Changes)
| # | Decision / assumption | Why | Alternative not taken |

## 10. Revision log
```

Rules: every row cites its evidence; no invented scope; `common/content-validation.md` applies; this is
the **only new planning file** of the run (the change story's `.feature` file and test-plan folder are
contract artifacts, created at Step 9.3 because B1 and the ve's sign-off depend on them).

## Step 7 — THE ONLY QUESTION: approve the plan

Present the document path and a short summary — affected stories with their states, AC counts by class,
the change story's ACs, the Test Change Authorization count, the tracker actions, and every Section 9
decision in one line each — then:

```
 Change Story <N.M> — review spec/plans/change-story-<N.M>.md
   (Section 9 lists every decision I made for you — change any of them with Request Changes.)

A) Request Changes — tell me what to change
B) Approve & Build — apply the spec edits and tracker actions, then build, test and raise the
   [STORY] PR into <epic-branch> automatically

[Answer]:
```

(Spec-only: option B reads `Approve & Apply — amend the specs and commit them to <epic-branch>`.)

`A` → revise the document (a requested change to a Section 9 decision moves that row to "decided by
the user"), log a revision entry, present again. `B` → Step 8. Log the prompt and the raw answer.
Nothing outside the document has been written before this approval.

## Step 8 — Tracker actions and the claim (build path; the spec-only path skips to Step 9.3)

Runs on the refreshed epic-branch checkout, exactly where `dev-implement` Story Selection runs, because
the story branch name needs the tracker ID. Nothing is committed here.

1. **Tracker item** (`common/tracker-sync.md`; LOCAL: local only, `Tracker ID` = `LOCAL`): no ticket →
   create a Story (Section 3 labels/fields, `Built with AIRE v[N]` footer) linked to the Parent Epic
   (Section 6); ticket given → use it and link it to the Parent Epic if not linked yet. Verify.
2. **Re-check the story number** against `origin/<epic-branch>` (E13); renumber if taken.
3. **Story Tracker row + claim** — in the fragment `runtime-artifacts/stories/story-<N.M>/state.md`, never the shared table: add Story <N.M> and claim it in the same step — `In Development`,
   `Start` and `Recorded` set, tracker transitioned to In Development, assignee = the operator,
   `aire-v[N]` label (`common/tracker-sync.md` Sections 4, 5, 9) — exactly as `dev-implement` Story
   Selection does. `Requires` = document Section 4.
4. **Epic sync**: Parent Epic already Ready for Testing → move it back to In Development (authorised by
   the approval), verify, log.
5. **Comment on every affected story's tracker item**:
   `Behaviour amended by Story <N.M> (<link>): <AC list>. Re-verified under Story <N.M>.`

## Step 9 — Branch, baselines, spec edits

### 9.1 Branch and baselines (build path)

Execute `workflows/dev-implement.md` **Step 1.5** for Story <N.M>: the story branch
`story/<TRACKER-ID>-<N.M>-<kebab-title>` is cut from the refreshed epic branch (its dependency-merge
check re-confirms every `requires` is merged), then the three baselines are captured **before any edit**
— full suite (Item 4.5), static D1–D7 with bootstrap (Item 4.6), full Playwright E2E headless
(Item 4.7). The uncommitted fragment `runtime-artifacts/stories/story-<N.M>/` from Step 8 carries onto the branch, as
they do in `dev-implement`.

### 9.2 (reserved — the reproduction proof exists only in `epic-bugfix`)

### 9.3 Apply the approved spec edits (story branch; epic branch for spec-only)

1. **`spec/plans/stories.md`**: append the change story (same format as every other story, with
   `**Tracker ID**:`, `**Covers**:`, `**Requires**:` and
   `**Change document**: spec/plans/change-story-<N.M>.md`). Annotate every AMENDED / SUPERSEDED AC of
   earlier stories in place — `AC-3 (amended by Story <N.M>, <date>): <new text>`, old text struck
   through, never deleted.
2. **`spec/plans/requirements.md`**: new or amended REQ text, marked with the story that changed it.
3. **Dependency graph** — build path: the fragment's `## Dependency Graph Additions` only (`archive-epic` merges it into `spec/plans/dependency-graph.yml` at cycle close; readers combine both meanwhile); spec-only path: `spec/plans/dependency-graph.yml` and the shared `## Dependency Graph` directly. It records the change-story node with its
   `requires` / `enables`, and the new edges from `Ready for Development` stories onto it.
4. **Behaviour specs**:
   - write `spec/behavior/story-<N.M>.feature` per `common/behavior-spec.md` Section 2 — one `@AC-n`
     scenario per change-story AC, failure paths included;
   - amend the scenario(s) of every AMENDED AC in earlier stories' feature files in place, keeping the
     `@AC-n` tag and adding `@amended-by-story-<N.M>`; retire a SUPERSEDED AC's scenario by removing it
     and recording the removal in the document (the AC stays in `stories.md`, marked superseded);
   - amend the `spec/behavior.feature` journeys the change alters.
5. **Test plans**: invoke the `ve-implement` skill in **WORKFLOW MODE** — once for the change story
   (its plan includes a "Re-verification of affected stories" section listing each amended AC and the
   test cases the ve re-runs), and once per affected story, scoped to its AMENDED / SUPERSEDED ACs.
   Never hand-edit a plan to match code.
6. **Architecture** (only when the document records a design change): amend
   `spec/plans/architecture.md`, bump its version, regenerate `architecture-rubric.json` from Section 10
   (`implementation/architecture-doc.md` Section 4). Never hand-edit a rubric.
7. **Coverage check (blocking, fixed silently)**: every change-story AC and every AMENDED AC has ≥1
   scenario and ≥1 test case; nothing remains for a SUPERSEDED AC.
8. **Spec-only path ends here**: update the amended stories' tracker items (AC text + a comment naming
   the document), commit on the epic branch —
   `[Spec] Amend Story <X.Y>[, …] per spec/plans/change-spec-<X.Y>.md` with the `AIRE-Version: [N]`
   trailer — push, emit the spec-only handoff (Step 14), stop. **Build path**: these edits ride the
   change story's own commit (Step 13) and are never pushed to the epic branch directly.

## Step 10 — Build

Execute `workflows/dev-implement.md` from **Step 4.3** (Playwright Readiness — frontend plans only) and
**Step 4.5** (behaviour-spec verification) through **Part 2 generation**, with these overrides and nothing else changed:

- **Plan**: document Section 6 **is** the code-generation plan (it satisfies `dev-implement` Step 4.1);
  mark its checkboxes as steps complete. No separate plan file.
- **Generation order**: application change → the authorised test changes from Section 5b (update
  obsolete assertions, delete dead tests, each traced to its AC) → new tests (Section 5c).
- **Earlier stories' Playwright specs** listed in Section 5b are regenerated by invoking
  `playwright-implement` in WORKFLOW MODE **for that affected story**, scoped to its amended ACs.

## Step 11 — The COMPLETE gate chain

Execute `workflows/dev-implement.md` **Steps 6 through 6.8** for Story <N.M>. Gate semantics with
authorised changes:

- In the full regression (Step 6.5), B2 (Step 6.1) and the Playwright E2E regression (Step 6.8), a test
  green at baseline and red now is a **regression to fix in the application code** — unless it is on the
  Test Change Authorization list, in which case it must already have been updated and must now pass.
- A red test the analysis missed may join the list **only** if it asserts an AC the document classifies
  AMENDED or SUPERSEDED: add it to Section 5b with a revision-log entry, announce it, continue. A red test
  that traces to an UNCHANGED AC is always a regression.
- Every gate keeps its SH-LOOP and 3-attempt budget; exhaustion → SH-4 HALT with the Retry-Limit Report.

## Step 12 — Test Impact Reconciliation (SH-LOOP-15)

A deterministic check, after Step 11 and before the review:

1. `git diff --name-status $(git merge-base origin/<epic-branch> HEAD) -- tests/ spec/behavior/ spec/behavior.feature spec/test-plans/`
2. Every **modified or deleted** test file or test case maps to a Section 5b row (or is one of the
   change story's own new files). A modified or deleted test not on the list → **violation**: restore it
   from the merge-base and fix the application code instead.
3. Every Section 5b row is done (an `update` row whose test was left untouched and now fails is a gate
   failure, not a skip).
4. Every change-story AC and every AMENDED AC has ≥1 scenario that executed in B1/B2 and ≥1 test case;
   no scenario remains for a SUPERSEDED AC.

Write the result to `reports/eval-evidence/story-<N.M>/test-impact-reconciliation.md` and into
`eval.json` `gates.testImpact` (a local-only gate). A failure → fix → re-run the affected Step 11 gates
(continuing their counters) → re-check; one cycle = one SH-LOOP-15 attempt; cap 3; exhaustion → SH-4.

## Step 13 — Review, commit, preflight, PR, attestation, PR review

1. **Code Review** — `workflows/dev-implement.md` **Sections A → B → C**, with the AC scope set to the
   change story's ACs **plus every AMENDED AC of the affected stories** (as amended) and the `Covers`
   REQ-IDs of both. The security pass stays diff-scoped; J1/J2 are blocking. The report adds a
   **Change Impact Verification** table: each affected story → amended ACs → Met / Partially Met /
   Not Met with `file:line`.
2. **Sections D and E** unchanged, with:
   - the State Isolation Check, then the commit including Step 9.3's spec edits, the change document, the reconciliation evidence and the fragment `runtime-artifacts/stories/story-<N.M>/` (never the shared `audit.md` / `aire-state.md`) —
     `[Story <N.M> / <TRACKER-ID>] Change: <summary>` + `AIRE-Version: [N]`;
   - `pr-generator` in WORKFLOW MODE, target = the epic branch, `[STORY]` prefix; the PR body also carries
     a `## Change Impact` section (affected stories and amended ACs, the Test Change Authorization list)
     — **read the body back and verify** it landed;
   - CI preflight and attestation only when `Enabled: Yes`.

## Step 14 — Handoff (verbatim, the last output)

**Build path**:

```
 CHANGE STORY <N.M> PR RAISED — NOT MERGED. Story <N.M> stays In Development until it merges.
   PR: <PR URL>  →  target `<epic-branch>`   Change document: spec/plans/change-story-<N.M>.md
   Affected stories: <X.Y (AMENDED AC-n), …> — their specs, test plans and tests were updated in this PR.
   Gates: all PASS / N/A, including Test Impact Reconciliation — scorecard in the PR body.

NEXT ACTIONS:
   1.  Review, approve and MERGE the PR into `<epic-branch>` yourself — the framework never merges.
       Rejected instead? Leave comments on the PR, then type: pr-fix <PR URL>
   2.  After it merges, Verification Engineer: ve-list-work on `<epic-branch>` — Story <N.M>'s test plan includes the
       re-verification cases for the affected stories.
   3.  More stories to build? type: dev-implement

Type the keywords EXACTLY as shown — any other phrasing is not a framework trigger.
```

**Spec-only path**:

```
 SPEC AMENDED — no code existed yet, so nothing was built.
   Amended: <Story X.Y AC-n, …> in stories.md, their .feature scenarios and test plans; tracker updated.
   Commit <sha> pushed to `<epic-branch>`.   Document: spec/plans/change-spec-<X.Y>.md

NEXT: the amended stories are built as usual — type: dev-implement
```

Log which variant was shown.

---

## Edge cases — every one resolved without a question

| # | Situation | Handling (default recorded in document Section 9 where it is a decision) |
|---|---|---|
| E1 | Affected story not started (`Ready for Development`) | Spec-only amendment of its ACs, scenarios and test cases; `requires` edge onto the change story if its code builds on the change |
| E2 | Affected story being built right now (`🔵`, no PR) | **HALT — blocked**: never change a spec under an in-flight build; finish it, then `pr-fix` (open PR) or re-run (merged) |
| E3 | Affected story has an OPEN, unmerged PR | **HALT — blocked**: comment the change on that PR and run `pr-fix <PR>`, or merge it and re-run |
| E4 | Affected story merged, awaiting ve | Change story; its test plan is amended in the same PR, so the ve tests the amended behaviour once the change story merges too |
| E5 | Affected story already `Ready for Testing` | Not demoted; tracker comment; re-verification cases live in the change story's plan |
| E6 | Parent Epic already Ready for Testing | Moved back to In Development — stated in Section 7, authorised by the approval, verified |
| E7 | Epic already archived | Stop — `ticket-implement` after the Epic PR merges, or revert the archive commit first |
| E8 | The change as described would violate the Security Baseline | **Default**: the change story is shaped to comply (e.g. adds the missing authorisation / validation); Section 9 records what was reshaped and why |
| E9 | Over-size change | **Default**: proceed as one change story; amend `architecture.md` for the new element and regenerate the rubric; Section 8 flags OVER-SIZE and Section 9 names the rejected alternatives (split / full cycle) |
| E10 | Change removes a feature | ACs SUPERSEDED (kept, marked); scenarios/test cases retired; dead tests deleted via the authorization list; dead code removed |
| E11 | Change contradicts an unstarted story's ACs | That story is amended spec-only in the same document |
| E12 | Another in-flight unit or an open `ve/…` PR touches the same paths | Warned in Section 8; whichever merges second resolves the conflict (`pr-fix` handles it on a `[STORY]` PR) |
| E13 | Two clones pick the same story number | Re-read from `origin/<epic-branch>` right before assignment and again before the push; on collision renumber to the next free, rename the branch, announce |
| E14 | LOCAL tracker | Everything stays in `stories.md` and the Story Tracker; no external calls |
| E15 | CI/CD disabled | Manifest reconciliation, preflight and attestation skipped, as in `dev-implement` |
| E16 | The change duplicates an existing `Ready for Development` story's scope | **Default**: amend that story spec-only instead of creating a new one (spec-only path); Section 9 records it |
| E17 | The capture is ambiguous (a limit, a rule, a message text) | **Default**: the reading most consistent with approved ACs, requirements, architecture and existing code; Section 9 records the assumption |
| E18 | The change story becomes the last unit | B3 runs on it when every other unit's PR is merged (live merge state, `dev-implement` Step 6.1) |
| E19 | A test outside the authorization list goes red | Regression — fix the code; it joins the list only if it asserts an AMENDED/SUPERSEDED AC (announced, revision-logged) |
| E20 | Another story merges into the epic branch during the run | The PR shows it; if it conflicts, `pr-fix` merges the epic branch in and re-runs every gate |
| E21 | `ticket-implement` typed while this epic is open | The router offers `epic-enhance` / `epic-bugfix` instead (`workflows/ticket-implement.md` Step 1) |
| E22 | Change story PR rejected | `pr-fix <PR>` — it detects the change document and also re-runs Step 12 |
| E23 | It is really a defect, not a change | Out of this flow — `epic-bugfix` (it adds reproduction proof and AI-origin detection); the run stops with that pointer before writing anything |
| E24 | The change amends, adds or withdraws a **requirement** in `spec/plans/requirements.md` (not just behaviour) | Out of this flow — `epic-change-request` (it versions the requirement, re-points every covering story's `Covers`, and rebuilds the coverage matrix); the run stops with that pointer before writing anything |

---

## Critical Rules

- 🔴 **THE ONLY QUESTION IS THE PLAN APPROVAL.** No clarifying questions, no option menus, no mid-run
  decisions. Decisions the framework makes are written into document Section 9 and overruled only via
  Request Changes. Missing input stops with a usage line; blocks and retry limits are halts, not
  questions.
- 🔴 **ONE NEW DOCUMENT.** `spec/plans/change-story-<N.M>.md` (or `change-spec-<X.Y>.md`) is the only new
  planning file; nothing outside it is written before approval.
- 🔴 **INTO THE EPIC, AS A STORY.** Branch from the epic branch, `[STORY]` PR into the epic branch, Story
  Tracker row, dependency graph node — never a base-branch cycle, never a new `Workflow Type`, never a
  change to `## Tracker`'s Parent Epic.
- 🔴 **NEVER FEWER GATES.** Every `dev-implement` gate runs on the change story, plus Test Impact
  Reconciliation. "Fast" means less ceremony only.
- 🔴 **ONLY AUTHORISED TESTS CHANGE.** An earlier story's test is modified or deleted only if it is on the
  approved Test Change Authorization list and traces to an AMENDED or SUPERSEDED AC. Every other red test
  is a regression fixed in the code (SH-6).
- 🔴 **CONTRACTS MOVE TOGETHER.** An amended AC moves its `stories.md` text, scenario, test case, tests and
  (UI) Playwright spec in the same PR; scenarios and plans are never rewritten to match code, and
  Playwright specs only through the `playwright-implement` subagents.
- 🔴 **NEVER CHANGE WORK IN FLIGHT.** A story being built, or with an open PR, blocks the change.
- 🔴 **NO STATUS DEMOTION, NO MERGING.** Statuses move only as `dev-implement` and `ve-list-work` define;
  the framework never merges a PR.
- 🔴 **SINGLE SESSION, BOUNDED LOOPS, FULL AUDIT.** No forks (Step 0); 3 attempts per loop; every audit
  entry carries the `dev-implement` fields plus `CHANGE`; every commit carries `AIRE-Version: [N]`.
