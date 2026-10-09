# WORKFLOW: `epic-bugfix <TICKET-ID | description>` (Mid-Epic Bug Fix — into the Epic Branch)

> **READ FIRST.** The six non-negotiables at the top of `workflows/dev-implement.md` bind this workflow
> too: every gate runs (no scope calls), the Gate Ledger is complete before the commit, the work-unit
> guard (`sh aire-workflow/templates/hooks/check-work-unit.sh --install <unit-key>` right after the story branch is cut) is installed and
> never bypassed, the claim (In Development + assignee) is made on the external tracker and recorded in the fragment's `## Claim` block — a `pr-fix` run whose unit has no such block makes the claim now —, a disclosed gap is never shipped, and the run
> ends with this workflow's own handoff block verbatim — nothing else in that final message.

## WHAT THIS WORKFLOW IS

A defect in work **the open epic already built** — typically found by the ve while testing a merged
story (`ve-list-work` Option B reject → `/raise-defect`), or by a developer — is fixed **inside that
epic** as ONE new bugfix story on the epic branch, instead of as a separate base-branch bug cycle.

On the way it **automatically determines whether the defective code was AI-generated** — line by line,
on git evidence, with no question asked — labels the bug `ai-generated-defect` when it was, and links
the bug to the story that introduced it.

New or changed behaviour (not a defect) has its own flow: `epic-enhance` (`workflows/epic-enhance.md`).

| | `ticket-implement` → bug cycle | **`epic-bugfix` (this workflow)** |
|---|---|---|
| Branch | `bug/…` from **base** | `story/…` from the **epic branch** |
| PR | `[BUG]` → base | **`[STORY]` → epic branch** |
| Cycle | Its own: requirements, design stages, STOP checkpoint, ve handoff break, archive | **None** — the epic's state, specs, rubrics and CI are reused |
| Documents | bug brief, requirements, impact analysis, design docs, plan | **ONE** — `spec/plans/bugfix-story-<N.M>.md` |
| Reproduction | Inside the fix | **Proven twice** — in a scratch worktree before the plan (so the plan rests on a real failure), and on the branch baseline before the fix |
| AI-origin detection | Yes | **Yes — automatic, per defective line; label + causation link applied without asking** |
| Questions | Requirements approval, story approval, specs set, "continue to the fix?" | **None — only the plan approval** |

---

## FAST BY DESIGN — LESS CEREMONY, NEVER FEWER GATES

**Cut**: requirements Q&A, design stages, the STOP checkpoint, the smoke test, the ve handoff break, a
separate plan file, a separate ve test-plan PR, a separate archive, and every clarifying question.

**Never cut**: the reproduction proof, the baselines, every gate of `workflows/dev-implement.md` (unit +
coverage, Gherkin B1/B2/B3, API & contract, test placement, full regression, D1–D7, Playwright UI + E2E
regression, Code Review with the Security Baseline pass and the blocking J1/J2 judges,
auto-remediation, CI preflight and attestation), the 3-attempt retry cap, and the rule that a test is
never weakened to go green.

---

## 🔴 THE ONLY QUESTION IS THE PLAN APPROVAL

**The run asks exactly one thing: approve the bugfix document (Step 9).**

- **Input comes with the keyword**: `epic-bugfix PROJ-301` or
  `epic-bugfix "discount is applied twice when the cart is edited after checkout starts"`. A bare
  `epic-bugfix` stops with one usage line —
  `Usage: epic-bugfix <TICKET-ID | "what is broken, where, and how to trigger it">` — and asks nothing.
- **AI-origin detection, the `ai-generated-defect` label and the `is caused by` link are automatic** —
  they rest on positive, verifiable git evidence, so there is no judgement left to ask about
  (`workflows/bug-fix.md` Step 5b/5c, same rule).
- **Where a decision is needed, the framework decides and records it** in the document's
  **Section 10 — Decisions & assumptions** (defaults in the Edge cases table). The user overrules any of
  them with **Request Changes** at the approval.
- After approval the run is **fully automatic** through to the PR and the handoff.
- The sanctioned **halts** stay (they are not questions): the defect cannot be reproduced (Step 4),
  a blocked affected story (Step 6), SH-4 retry-limit exhaustion, and the Playwright agent-install
  restart pause.

---

## 🔴 SINGLE-SESSION EXECUTION — NO FORKS

`workflows/dev-implement.md` Step 1.7 applies unchanged: every step — including the Defect Provenance
Analyst procedure, which is executed **inline**, never spawned — runs in the session where the keyword
was typed. The only Agent-tool use is Playwright's own Planner/Generator/Healer inside the Playwright UI
gate, synchronously. A run inside a fork or subagent HALTS at Step 0.

---

## MANDATORY: Rule Details Loading

Resolve `aire-workflow/` and load:
- `common/process-overview.md`, `common/session-continuity.md`, `common/content-validation.md`,
  `common/audit-logging.md`, `common/tracker-sync.md` (Sections 3–10, especially 7 and 9),
  `common/branching-strategy.md`, `common/requirements-traceability.md`, `common/behavior-spec.md`,
  `common/eval-framework.md`, `common/directory-structure.md`
- **`agents/defect-provenance-analyst.md`** — the AI-origin procedure (Step 5 and Step 12)
- `workflows/bug-fix.md` **Step 5b and 5c** — the labeling and causation-link mechanics this workflow
  reuses (JIRA direction rules, ADO/GITHUB/LOCAL fallbacks)
- `workflows/epic-enhance.md` — its Step 4 routing table, Step 11 gate semantics and Step 12 Test Impact
  Reconciliation are executed **by reference**
- `workflows/dev-implement.md` **in full** — Step 1.5, Steps 4.5–6.8 and Sections A–F by reference; its
  Self-Healing Retry Policy and Retry-Limit Report bind this workflow
- `implementation/code-generation.md` (Guardrail), `workflows/code-review.md` +
  `implementation/code-review.md`, `workflows/remediate.md` + `implementation/remediate.md`
- When `## CI/CD Configuration` records `Enabled: Yes`: `common/ci-pipeline-generation.md` Sections
  4.0d, 4.0f, 4.0i and 6.6

---

## SELF-HEALING RETRY POLICY — INHERITED

SH-1 … SH-7 from `workflows/dev-implement.md` govern every loop (3 attempts each, independent counters,
logged root cause per attempt, exhaustion HALTS with the Retry-Limit Report). The loops keep their
`dev-implement` IDs plus **SH-LOOP-15 — Test Impact Reconciliation** (`workflows/epic-enhance.md`),
which here also verifies the reproduction proof.

At SH-4 the run emits the **Self-Heal Limit message** (`common/self-heal-limit-guidance.md` Section 2 —
what is failing, why it stopped, how the developer reproduces and fixes it, what the gates reject) with
**resume keyword = `epic-bugfix`**, and records `HALTED —` in the story fragment's `## Progress`. Typing
`epic-bugfix` again is a hand-back: the run finds the halted change story and follows the resume protocol
(Section 4) instead of starting a new change — the plan approval is not asked again.

---

## MANDATORY: Audit Entry Format

`workflows/dev-implement.md`'s format plus, on every entry:

```markdown
**CHANGE**: "BUGFIX — Story <N.M> — spec/plans/bugfix-story-<N.M>.md"
**AI-ORIGIN**: "[AI-generated | human | mixed | undetermined | pending]"
```

The Step 5 entry also records the complete Provenance Verdict table verbatim. Append only; timestamps
from one real clock command.


## 🔴 PARALLEL-SAFE STATE — THIS STORY WRITES ONLY ITS OWN FRAGMENT (`common/parallel-work-state.md`)

Other developers build other stories of the same epic at the same time, and the ve signs stories off on
the epic branch. So that none of their PRs conflict on the framework's bookkeeping, **the build path of
this workflow never writes the shared `runtime-artifacts/audit.md` or `runtime-artifacts/aire-state.md`**:

- Every audit entry goes to **`runtime-artifacts/stories/story-<N.M>/audit.md`** (same format plus
  `**Unit**: "story-<N.M>"`). Entries from Steps 1–7, before the story number exists, are held and written there with their original timestamps as soon as Step 7.4 assigns it. A run that halts before that (not reproduced, blocked) prints the held entries in its halt message instead.
- The story's Story Tracker row, progress and SH counters go to
  **`runtime-artifacts/stories/story-<N.M>/state.md`**; the change story's dependency-graph node goes to
  its `## Dependency Graph Additions` section (the shared `## Dependency Graph` section is never
  edited); the `## Defect Provenance Log` rows go to the fragment's section of the same name.
- This overrides every mention of those two shared paths below. Reads use the **resolved view**
  (`common/parallel-work-state.md` Section 4).
- 🔴 **State Isolation Check before every commit** (Section 5.5). No push only to record a PR URL
  (Section 4.6).
- The automatic tracker actions of Step 5 (label, causation link, comments) are external calls — they
  need no git write and happen immediately, as defined.
---

## Step 0 — 🔴 Single-Session Check

Exactly `workflows/dev-implement.md` Step 1.7's fork check. Inside a fork or subagent → HALT with that
step's message (substituting `epic-bugfix`), change nothing.

## Step 1 — Preconditions

Exactly `workflows/epic-enhance.md` Step 1 — including its item 0 hand-back check, which here resumes a
halted bugfix story from the first code gate (Step 13) or the halted gate — (open epic cycle, input present,
clean tree, refreshed epic branch, cycle not archived, configuration read), with `epic-bugfix` in the
messages.

## Step 2 — Capture the defect

- **Ticket ID**: fetch it per `common/tracker-sync.md` Section 8 — summary, description, severity,
  environment, labels, links (a ticket raised by `/raise-defect` carries Severity, Environment Found and
  Discovery Activity).
- **Description**: use it verbatim.

Extract, as far as the capture allows: **observed** behaviour, **expected** behaviour (and the AC or
requirement that states it), **trigger** (steps, data, role, environment), **severity**. A gap is never
asked about — the most likely reading, grounded in the approved ACs and the code, is recorded as an
assumption in document Section 10, and Step 4's reproduction either confirms it or halts. Log the
invocation and the capture verbatim.

## Step 3 — Locate the defect and its blast radius

1. **Root cause** with explicit `file:line-range` evidence for every defective range — read the code
   path the trigger exercises, never infer from names. For a **missing** check (omission bug), record the
   enclosing function/block where the check belongs.
2. **Blast radius**: callers, consumers, shared files and tests that the fix could affect.
3. **Map paths, behaviour and tests to stories** exactly as `workflows/epic-enhance.md` Step 3 items
   2–5 do (manifest fragments, `[Story N.M / …]` history, blame; every story's ACs; every affected
   story's tests, scenarios and test cases; concurrency scan).
4. **Expected-behaviour anchor**: name the AC (story + `AC-n`) or REQ-ID the defect violates. If no AC or
   requirement states the expected behaviour, the defect is a **spec gap** (E14).

## Step 4 — Reproduce it (scratch worktree, BEFORE the plan)

A plan to fix a defect nobody has reproduced is a guess. Reproduce first, in a throw-away worktree in
the scratchpad — a directory in this session, not a new session:

```bash
git worktree add "<scratchpad>/aire-bugfix-repro-<key>" origin/<epic-branch>
```

1. Install per the manifest's `installCommands` for the affected root(s).
2. Write the **smallest** reproduction that exercises the Step 2 trigger through the public surface — a
   unit or API test in the repo's own test framework (and, for a UI defect, the manual trigger steps
   recorded for the `@bug` scenario). Name it for the defect.
3. Run it. It **must fail, for the documented reason** (the assertion of the expected behaviour — not an
   import error, not a setup failure).
4. Keep the reproduction's source and its failing output (they are re-created on the story branch at
   Step 11.2); remove the worktree (`git worktree remove --force <path>`) on every exit path.

**Not reproduced** (it passes, or fails for an unrelated reason after correcting the setup) → **HALT**,
not a question:

```
 COULD NOT REPRODUCE — <BUG-ID | "the described defect">
   Trigger tried: <steps / data / role / environment>
   Reproduction: <test name> — result: <passed | failed for an unrelated reason: …>
   Code path read: <file:line ranges>
   Nothing was written, labeled, linked, branched or committed.
Add exact reproduction steps (data, role, environment, expected vs actual) to the ticket or the
   description, then type: epic-bugfix <TICKET-ID | "…">
```

Log it. Never fix a defect that has not been reproduced.

## Step 5 — AI-origin detection (AUTOMATIC — no question)

1. **Execute `agents/defect-provenance-analyst.md` inline** with Step 3's defective `file:line-range`
   list: `git blame -w -M -C -L` per range, walk past cosmetic commits with `git log -L`, attribute
   omission bugs to the enclosing block (basis `enclosing-block`), resolve each introducing commit's PR
   (`gh api repos/<owner>/<repo>/commits/<sha>/pulls`), resolve the **originating tracker item** (PR
   title → commit subject → branch), and apply the verdict rule on **positive evidence only**:
   **AI-generated** if the PR carries `ai-generated`, or the commit carries a `Co-Authored-By: Claude`
   trailer, or an `AIRE-Version:` trailer; **human** for an identifiable human author with none of them;
   **undetermined** when history is unreachable. The PR-label check is always attempted before
   concluding human or undetermined (squash merges strip trailers).
2. **Origin scope per row** (new here, because the epic branch is not on base yet):
   - `this epic` — the introducing commit is reachable from `origin/<epic-branch>` but not from
     `origin/<base>` (`git merge-base --is-ancestor <sha> origin/<base>` fails) → name the story;
   - `base` — already on the base branch (predates this epic) → E12;
   - `pre-framework` — no framework markers and no resolvable ticket.
3. **Overall verdict**: `AI-generated` if every row is AI-generated; `mixed` if AI and human rows
   coexist; `human` if every row is human; `undetermined` if no row could be attributed. Mixed rows are
   kept as they are, never merged into one verdict.
4. **Act on it — automatically, now if the bug ticket already exists** (otherwise at Step 10, when the
   Bug is created):
   - **Any row AI-generated** → label the bug `ai-generated-defect` per `common/tracker-sync.md`
     Section 9 (LOCAL: a note on the local entry), **verify** it landed, announce:
     ` Labeled <BUG-ID> ai-generated-defect — <file:lines> introduced by AI-generated code (evidence: <PR #n "ai-generated" label | Claude co-author on <sha> | AIRE-Version trailer>).`
     Already labeled → skip silently. A failed tracker call is reported and does not block.
   - **Originating items resolved** → link the bug `is caused by` each of them, with the direction rules
     and fallbacks of `workflows/bug-fix.md` Step 5c (self-link guard; JIRA typed link verified by
     read-back, `Relates` + comment fallback; ADO/GITHUB comment; LOCAL note).
   - **Comment on each originating story's tracker item**:
     `Defect <BUG-ID> traced to this story (commit <sha>, PR #<n>; AI-origin: <verdict>). Fixed under Story <N.M>.`
   - **`human` / `undetermined`** → no label; log the per-line evidence.
5. **Record** the Provenance Verdict table in the document (Section 6) and append one row per defective
   range to the `## Defect Provenance Log` section of the story's fragment `runtime-artifacts/stories/story-<N.M>/state.md` (held until Step 7.4 assigns the number; the resolved view unions all fragments' logs) — the
   running record the AI defect ratio is computed from:

   | Bug | Bugfix Story | Originating item | File:Lines | Verdict | Basis | Introducing commit | PR | Marker | Origin scope | Recorded |
   |-----|--------------|------------------|------------|---------|-------|--------------------|----|--------|--------------|----------|

6. **Announce** the verdict table (not a question) and log it verbatim with the `AI-ORIGIN` field.

## Step 6 — Route on the state of each affected story

Apply `workflows/epic-enhance.md` **Step 4**'s table to every affected story (the originating story
first):

- originating story **merged** (awaiting ve, ve-rejected, or already `🧪`) → proceed;
- originating story with an **open, unmerged PR** → **HALT — blocked**: the fix belongs on that PR —
  put the defect on it as a review comment and run `pr-fix <PR>` (the labels and link from Step 5 stay);
- originating story **being built** (`🔵`, no PR) → **HALT — blocked** until it is finished;
- a `Ready for Development` story whose ACs describe the defective behaviour → amended spec-only in the same document.

A block halts before anything beyond Step 5's automatic tracker actions is written. Log it.

## Step 7 — Test impact

1. **Classify affected ACs** as in `workflows/epic-enhance.md` Step 5.1. A normal defect leaves every AC
   **UNCHANGED** (the code violates an AC that was right). Only a spec gap or a wrong AC makes one
   **AMENDED** (E14).
2. **Why did no test catch it?** Name the gap precisely — the missing unit/API case, the scenario that
   did not cover this path, the test-plan case that did not exercise it — and plan to close each:
   - the **reproduction test** from Step 4 joins the suite permanently (unit / API, in the repo-root
     `tests/` tree);
   - a **`@bug` scenario** reproducing the defect goes into the bugfix story's own
     `spec/behavior/story-<N.M>.feature`;
   - a **missed-case test case** is added to the originating story's test plan (via `ve-implement`
     workflow mode, scoped to the violated AC), plus the bugfix story's own plan.
3. **Test Change Authorization list** (`workflows/epic-enhance.md` Step 5.4): normally **empty** — a bug
   fix adds tests, it does not change them. An existing test gets a row only when it **asserts the
   defective behaviour** (it encoded the bug); its row cites the unchanged AC it contradicts
   (`update assertion — encoded the defect, contradicts AC-n`).
4. **Bugfix story**: next free `N.M` (re-read from `origin/<epic-branch>` — E13 of `epic-enhance`);
   title `Bugfix: <summary>`; ACs = the corrected behaviour (at least one) — normally the violated AC
   restated for the defect's trigger; Covers = the violated AC's REQ-IDs; Requires = the originating
   story (and any other story whose code the fix changes); Tracker ID = the bug ticket.

## Step 8 — Write THE ONE document: `spec/plans/bugfix-story-<N.M>.md`

```markdown
# Bugfix Story <N.M> — <title>
Source: <bug ticket link | "inline description"> · Severity: <…> · Epic: <EPIC link>
Epic branch: <branch> @ <sha> · Written: <ISO timestamp> · AIRE v<N>

## 1. The defect
Observed · Expected (violates <Story X.Y AC-n | REQ-ID>) · Trigger · Environment

## 2. Reproduction (Step 4)
Test: <path::name> — failed on origin/<epic-branch>@<sha> with: <assertion output excerpt>

## 3. Root cause and blast radius
| File:Lines | What is wrong | Basis (direct-line / enclosing-block) |
Blast radius: <callers, consumers, shared files, tests>

## 4. Impact — stories and acceptance criteria
| Story | State | AC | Class | Note |

## 5. The bugfix story
Story <N.M> — <title> · Tracker: <BUG-ID> · Covers: <REQ-IDs> · Requires: <stories>
Acceptance criteria:
- AC-1 …

## 6. AI-origin (automatic — Step 5)
Overall: <AI-generated | mixed | human | undetermined>
| File:Lines | Verdict | Basis | Introducing commit | PR | Evidence | Originating item | Origin scope |
Actions taken: <ai-generated-defect label: applied / not applicable / pending bug creation> ·
<is caused by → items> · <comments posted>

## 7. Test impact
### 7a. Why no test caught it
### 7b. Tests, scenarios and test cases to add
### 7c. Test Change Authorization list  (normally empty)
| File | Test | Action | Traces to |

## 8. Fix plan  (this section IS the code-generation plan — checkboxes marked as work completes)
- [ ] Step 1 — … (AC-n / REQ-ID)
Trace check: every bugfix-story AC appears in ≥1 step.

## 9. Tracker and state actions on approval
Bug linked to the Parent Epic · claimed In Development · Epic reopen (only if already Ready for Testing)

## 10. Decisions & assumptions (made by the framework — overrule any with Request Changes)
| # | Decision / assumption | Why | Alternative not taken |

## 11. Warnings · 12. Revision log
```

Every row cites its evidence; `common/content-validation.md` applies. This is the only new planning
file of the run.

## Step 9 — THE ONLY QUESTION: approve the plan

Present the document path and a summary — the defect, the reproduction result, the root cause, the
AI-origin verdict (with the label/link actions already taken), the bugfix story's ACs, the tests to add,
and every Section 10 decision in one line — then:

```
 Bugfix Story <N.M> — review spec/plans/bugfix-story-<N.M>.md
   Reproduced: yes (<test>) · AI-origin: <verdict> · Root cause: <file:line>
   (Section 10 lists every decision I made for you — change any of them with Request Changes.)

A) Request Changes — tell me what to change
B) Approve & Fix — build the fix, run every gate and raise the [STORY] PR into <epic-branch>
   automatically

[Answer]:
```

`A` → revise, log a revision entry, present again. `B` → Step 10. Log the prompt and the raw answer.

## Step 10 — Tracker actions and the claim

On the refreshed epic-branch checkout, nothing committed:

1. **Bug item**: ticket given → link it to the Parent Epic if not linked yet. No ticket → create a Bug
   per `common/tracker-sync.md` Section 3 (labels `bug`, `defect`, `ai-generated`, `aire`,
   `aire-v[N]`) linked to the Parent Epic (Section 6), then apply the Step 5 actions that were pending on
   its creation (the `ai-generated-defect` label, the `is caused by` links). Verify each. LOCAL: local
   entry only.
2. **Re-check the story number** against `origin/<epic-branch>`; renumber if taken.
3. **Story Tracker row + claim** — in the fragment `runtime-artifacts/stories/story-<N.M>/state.md`, never the shared table: add Story <N.M> (Tracker ID = the bug) and claim it — `In Development`,
   `Start`/`Recorded`, tracker transitioned to In Development, assignee = the operator, `aire-v[N]` label —
   exactly as `dev-implement` Story Selection does.
4. **Epic sync**: Parent Epic already Ready for Testing → back to In Development, verified, logged.
5. The originating story's status is **not changed** (a ve rejection stays as it is; `ve-list-work`
   re-tests it after the fix merges).

## Step 11 — Branch, baselines, reproduction proof, spec edits

1. **Branch + baselines**: `workflows/dev-implement.md` **Step 1.5** for Story <N.M> — branch
   `story/<BUG-ID>-<N.M>-<kebab-title>` from the refreshed epic branch, then the full-suite, D1–D7 and
   Playwright E2E baselines, **before any edit**.
2. **Reproduction proof on the branch**: re-create the Step 4 reproduction test (and the `@bug` scenario
   with its step definitions) and run it on the baseline code. It must fail for the same documented
   reason; save the output to `reports/unit-test-evidence/story-<N.M>/reproduction-baseline.log`. If it
   now passes (someone fixed it meanwhile), HALT and report — nothing to fix, nothing committed.
3. **Spec edits** (on the story branch):
   - `spec/plans/stories.md` — append the bugfix story (`**Tracker ID**:`, `**Covers**:`,
     `**Requires**:`, `**Bugfix document**: spec/plans/bugfix-story-<N.M>.md`, `**Caused by**: Story X.Y`);
     annotate AMENDED ACs only when Section 4 says so;
   - `spec/plans/requirements.md` — only for a spec gap (E14);
   - the fragment's `## Dependency Graph Additions` — the bugfix node and its edges (merged into `spec/plans/dependency-graph.yml` by `archive-epic` at cycle close);
   - `spec/behavior/story-<N.M>.feature` — one `@AC-n` scenario per bugfix-story AC plus the `@bug`
     reproduction scenario; amended scenarios in earlier files only for AMENDED ACs;
   - test plans — `ve-implement` in **WORKFLOW MODE** for the bugfix story (including a "Re-verification"
     section for the originating story's violated AC) and, scoped to the missed case, for the originating
     story;
   - **coverage check** (blocking, fixed silently): every bugfix-story AC has ≥1 scenario and ≥1 test
     case.

## Step 12 — Fix

Execute `workflows/dev-implement.md` from **Step 4.3** (Playwright Readiness — frontend plans only) and
**Step 4.5** through **Part 2 generation**, with document
Section 8 as the plan (it satisfies Step 4.1; checkboxes marked there) and this order: the fix → the
reproduction test and the missed-case tests → any Section 7c authorised update.

**Provenance re-check (automatic)**: if the fix has to change lines outside Section 3's defective
ranges because they are part of the defect, add them to Section 3 and run Step 5's procedure on
**only** those new ranges; a newly AI-generated row labels the bug if it is not labeled yet (automatic,
verified, announced) and is appended to `## Defect Provenance Log`.

## Step 13 — The COMPLETE gate chain

`workflows/dev-implement.md` **Steps 6 through 6.8** for Story <N.M>, with `workflows/epic-enhance.md`
**Step 11**'s semantics for authorised test changes, plus: **the reproduction test and the `@bug`
scenario must pass**. Every gate keeps its SH-LOOP and 3-attempt budget; exhaustion → SH-4 HALT.

## Step 14 — Test Impact Reconciliation (SH-LOOP-15)

`workflows/epic-enhance.md` **Step 12**, plus: the reproduction test failed on the baseline (Step 11.2
evidence) **and** passes now, and it is committed in the repo-root `tests/` tree (it guards the defect
from now on). Result into `reports/eval-evidence/story-<N.M>/test-impact-reconciliation.md` and
`eval.json` `gates.testImpact`.

## Step 15 — Review, commit, preflight, PR, attestation, PR review

1. **Code Review** — `workflows/dev-implement.md` **Sections A → B → C**, AC scope = the bugfix story's
   ACs plus the violated AC of the originating story; the report adds a **Defect Verification** row:
   reproduction test red on baseline → green now, with evidence paths.
2. **Sections D and E** unchanged, with:
   - the State Isolation Check, then commit `[Story <N.M> / <BUG-ID>] Bugfix: <summary>` + `AIRE-Version: [N]`, including the fragment `runtime-artifacts/stories/story-<N.M>/`, the spec edits,
     the bugfix document and the evidence;
   - `pr-generator` in WORKFLOW MODE, target = the epic branch, `[STORY]` prefix; the PR body also carries
     a `## Defect Provenance` section (overall verdict, the verdict table, label/link actions,
     reproduction evidence) — **read it back and verify** it landed;
   - CI preflight and attestation only when `Enabled: Yes`.

## Step 16 — Handoff (verbatim, the last output)

```
 BUGFIX STORY <N.M> PR RAISED — NOT MERGED. <BUG-ID> stays In Development until it merges.
   PR: <PR URL>  →  target `<epic-branch>`   Document: spec/plans/bugfix-story-<N.M>.md
   Root cause: <file:line> — introduced by Story <X.Y> (<commit>, PR #<n>)
   AI-origin: <AI-generated | mixed | human | undetermined> — <label ai-generated-defect applied | no label>
   Reproduction: red on the baseline → green now. Gates: all PASS / N/A — scorecard in the PR body.

NEXT ACTIONS:
   1.  Review, approve and MERGE the PR into `<epic-branch>` yourself — the framework never merges.
       Rejected instead? Leave comments on the PR, then type: pr-fix <PR URL>
   2.  After it merges, Verification Engineer: ve-list-work on `<epic-branch>` — re-test Story <X.Y> and sign off
       Story <N.M> (its test plan carries the re-verification cases).
   3.  More stories to build? type: dev-implement

Type the keywords EXACTLY as shown — any other phrasing is not a framework trigger.
```

Log it.

---

## Edge cases — every one resolved without a question

| # | Situation | Handling (default recorded in document Section 10 where it is a decision) |
|---|---|---|
| E1 | Defect not reproducible | **HALT** (Step 4) with what was tried; nothing written |
| E2 | Reproduction passes on the branch baseline (fixed meanwhile) | **HALT** (Step 11.2); nothing committed; the claim is undone — the Story Tracker row removed, the bug transitioned back to its previous status (verified), the story branch deleted locally |
| E3 | Originating story has an open, unmerged PR | **HALT — blocked**: fix it on that PR with `pr-fix` (Step 6) |
| E4 | Originating story being built right now | **HALT — blocked** until it is finished |
| E5 | Originating story ve-rejected (`ve-rejected` label) | Normal case: its status stays; the bugfix story fixes it; the ve re-tests both after merge |
| E6 | Originating story already `Ready for Testing` | Not demoted; tracker comment; re-verification in the bugfix story's plan |
| E7 | Mixed provenance (AI and human lines) | Kept per row; the label applies because at least one defective line is AI-generated |
| E8 | Squash-merged PR stripped the trailers | The PR-label check via the commits→pulls API decides; only if no PR resolves is the row `undetermined` |
| E9 | Omission bug (a missing check) | Attributed to the enclosing block's introducing commit, basis `enclosing-block` |
| E10 | Provenance history unreachable (shallow clone) | `git fetch --unshallow` first; still unreachable → `undetermined`, never labeled |
| E11 | Defective lines introduced by an earlier change or bugfix story | Attributed to that story like any other (`[Story N.M / …]` subject) |
| E12 | Defect predates the epic (origin scope `base`) | **Default**: fix it in the epic (it ships with the epic); Section 11 warns that the base branch is affected now and a separate hotfix (`ticket-implement` from another clone) may be needed |
| E13 | The fix must touch lines beyond the defective ranges | Provenance re-check on only the new ranges (Step 12); label if newly AI |
| E14 | No AC states the expected behaviour, or the AC itself is wrong (spec gap) | **Default**: the AC is AMENDED (or a REQ added) in the document and moves with its scenario and test case; Section 10 records it |
| E15 | An existing test asserts the buggy behaviour | Listed in the Test Change Authorization list with the AC it contradicts; any other red test is a regression |
| E16 | Defect is really a missing feature | **Default**: stop with a pointer to `epic-enhance` before writing anything (a halt, not a question) |
| E17 | Same defect already has an open bugfix story | Stop with that story and its PR; nothing written |
| E18 | Tracker call for the label or link fails | Reported, non-blocking; the evidence stays in the document and `## Defect Provenance Log` |
| E19 | LOCAL tracker | Label and causation are notes on the local entry; everything else is local |
| E20 | CI/CD disabled | Manifest reconciliation, preflight and attestation skipped |
| E21 | Bugfix story becomes the last unit | B3 runs on it when every other unit's PR is merged |
| E22 | Bugfix PR rejected | `pr-fix <PR>` — it detects the bugfix document and re-runs the reconciliation |
| E23 | `ticket-implement <BUG-ID>` typed while the epic is open | The router offers `epic-bugfix` (`workflows/ticket-implement.md` Step 1) |

---

## Critical Rules

- 🔴 **THE ONLY QUESTION IS THE PLAN APPROVAL.** Missing input stops with a usage line; decisions are
  recorded in Section 10 and overruled only via Request Changes; halts are not questions.
- 🔴 **AI-ORIGIN IS AUTOMATIC AND EVIDENCE-ONLY.** Every defective line range is traced to its
  introducing commit; the verdict uses only the framework's markers (`ai-generated` PR label, Claude
  co-author trailer, `AIRE-Version:` trailer); `undetermined` is never labeled; the label and the
  `is caused by` link are applied without asking and verified; stylometry is never used.
- 🔴 **REPRODUCE BEFORE PLANNING, AND AGAIN BEFORE FIXING.** No reproduction, no fix. The reproduction
  test stays in the suite.
- 🔴 **ONE NEW DOCUMENT**, `spec/plans/bugfix-story-<N.M>.md`.
- 🔴 **INTO THE EPIC, AS A STORY** — branch from the epic branch, `[STORY]` PR into it; never a
  base-branch cycle, never a new `Workflow Type`.
- 🔴 **NEVER FEWER GATES; ONLY AUTHORISED TESTS CHANGE** — every `dev-implement` gate plus Test Impact
  Reconciliation; a bug fix adds tests and changes only those that encoded the defect.
- 🔴 **NEVER CHANGE WORK IN FLIGHT; NO STATUS DEMOTION; NO MERGING.**
- 🔴 **SINGLE SESSION, BOUNDED LOOPS, FULL AUDIT** — no forks; 3 attempts per loop; every audit entry
  carries the `dev-implement` fields plus `CHANGE` and `AI-ORIGIN`; every commit carries
  `AIRE-Version: [N]`.
