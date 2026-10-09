# WORKFLOW: `epic-change-request <TICKET-ID | description | --from-requirements | --from-spec <path>>` (Mid-Epic Change Request — into the Epic Branch)

> **READ FIRST.** 🔴 **This workflow amends specifications. It never generates code.** It cuts no story
> branch, installs no work-unit guard, runs no gate chain and raises no PR — those are `dev-implement`'s,
> and this run ends by handing off to it. What binds here: a disclosed gap is never shipped, nothing
> reaches disk before the Phase 9 gate, and the run ends with this workflow's own handoff block verbatim
> — nothing else in that final message.

## WHAT THIS WORKFLOW IS

**A requirement changed while the epic cycle is open.** Not "make it do something new" and not "it is
broken" — the *agreement itself* was revised: a threshold moved, a rule was rewritten, a regulation
landed, a decision was reversed. This workflow makes that change visible in the cycle it arrives in,
versions the requirement, routes every story that promised the old text, and leaves **one new story,
ready to build** — then hands the build to `dev-implement`. 🔴 **It amends specs; it never writes code.**

It is the **third mid-epic workflow**, a peer of the other two — not a variant of either:

| | trigger | its question |
|---|---|---|
| `epic-enhance` | **behaviour** | "make it do X" |
| `epic-bugfix` | **defect** | "it does X but shouldn't" |
| **`epic-change-request` (this)** | **requirement** | "we agreed X; now we agree Y" |

🔴 **This workflow is fully self-contained.** It stands on `workflows/dev-implement.md` and the shared
`common/*.md` contracts only. It never reads, cites or delegates to `epic-enhance.md` or
`epic-bugfix.md`, and deleting either of those files leaves this workflow fully executable.

| | `ticket-implement` → enhancement/bug cycle | **`epic-change-request` (this workflow)** |
|---|---|---|
| Branch | `enhancement/…` or `bug/…` from **base** | **none** — specs commit on the epic branch |
| PR | `[ENH]` / `[BUG]` → base | **none** — `dev-implement` raises the `[STORY]` PR |
| Cycle | Its own: requirements, design stages, STOP checkpoint, archive | **None** — the epic's state, specs, rubrics and CI are reused |
| Requirements | Its own scoped `requirements.md` | **The epic's `requirements.md`, amended and versioned in place** (`common/requirement-versioning.md`) |
| Documents | brief, requirements, impact analysis, design docs, plan | **ONE bundle** — `spec/plans/change-requests/CR-<n>/` |
| Earlier stories' tests | Not its concern | **Gherkin + test plans amended here; unit/API/Playwright named for `dev-implement`** |
| Questions | Several approvals | **ONE — the single gate (Phase 9)** |

---

## WHAT MAKES THIS DIFFERENT FROM EVERY OTHER WORKFLOW

1. **It starts from the requirement, not the code.** The primary walk is REQ-ID → `Covers` → story →
   AC → test (Phase 3). Starting from code would miss a changed requirement that **no story has built
   yet** — precisely the case a Change Request exists to catch.
2. **It versions requirements.** `REQ-F-03` becomes `REQ-F-03@v2`, prior text retained
   (`common/requirement-versioning.md`). Nothing else in the framework mints a version.
3. **It can be triggered by a document edit.** Entry Mode C diffs the operator's own uncommitted
   `requirements.md` edit against the epic branch — drift detection no other workflow performs.
4. **One gate, everything staged.** Nothing reaches disk until the operator answers Phase 9 (CR16).
5. **It stops at the contract.** It amends requirements, stories, `.feature` files and manual test plans,
   then hands off — no branch, no code, no gate chain, no PR. The build is `dev-implement`'s job, and
   keeping it there means code and the tests that assert it change together, under one set of gates.

🔴 **The verbosity contract binds every phase below.** V1 announce each phase · V2 cite evidence on every
finding · V3 counts before lists before detail · V4 every decision with the alternative it rejected ·
V5 never summarise at the gate · V6 measured value against threshold per gate · **V7 fact-only — no
severity adjective, no advisory verb, in any output or artifact (CR14)** · **V8 ASCII-only diagrams,
equal-width box lines (`common/ascii-diagram-standards.md`); `├── └──` tree glyphs are the one carve-out**
· V9 audit parity. Full text: `common/change-request-rules.md` Section 3. The sample output blocks in
each phase show the required shape, not fixed wording.

---

## 🔴 THE ONLY QUESTION IS THE SINGLE GATE (Phase 9)

**The run asks exactly one thing: approve the staged Change Request.** It never asks a clarifying
question, never offers a menu of options, and never asks for a decision mid-run.

- **Input usually comes with the keyword** — `epic-change-request "<change>"`, a ticket ID,
  `--from-requirements` or `--from-spec <path>`. When it does, the entry mode is already known and the
  run goes **straight to analysis**: the gate stays the only question.
- **A bare `epic-change-request` gets a front door instead of a usage line** (Phase 0.5): a short
  welcome and a 4-way picker for *how you want to describe the change*. That is a **routing question**,
  not a clarifying one — it asks which input the user has, never what the change means. It is the only
  question that can precede the gate, it is asked **once**, and passing input with the keyword skips it
  entirely. 🔴 Everything after it stays unchanged: no clarifying questions, no mid-run decisions.
- **Where a decision is needed, the framework decides, and the bundle says so.** Every such decision is
  written into `change-request.md` Section 9 with its reason **and the alternative it rejected** (V4).
  The operator overrules any of them with **Request Changes** — that is the only channel, and it is enough.
- **Approval authorises everything the bundle lists**: the requirement amendments and version bumps, the
  new/CR-born/amended stories, the Test Change Authorization list, the tracker actions and links, the
  dependency edges, an `architecture.md` amendment, and the push.
- After approval the run is **fully automatic** through to the PR and the handoff.
- The sanctioned **halts** stay (they are not questions): a Phase 4 block, a CR12 dependency cycle, a
  Phase 8 pre-emission failure, and a failed push at Phase 10.4.

---

## 🔴 SINGLE-SESSION EXECUTION — NO FORKS

`workflows/dev-implement.md` Step 1.7 applies to this whole workflow, unchanged: every step runs in the
session where the keyword was typed; nothing is delegated to a fork, subagent, Workflow-tool run,
background or remote agent, second session or `claude -p` subprocess. `agents/change-request-analyst.md`
executes **inline**. This workflow makes **no Agent-tool calls at all** — it runs no Playwright gate.
A run inside a fork or subagent HALTS at Phase 0.

---

## MANDATORY: Rule Details Loading

Resolve `aire-workflow/` and load:
- **`common/change-request-rules.md`** — CR1–CR17 + CR13-V. 🔴 THE source of truth for this workflow's
  semantics; rule IDs below refer to it and are never restated inline.
- **`common/requirement-versioning.md`** — the `@vN` model and RV-1…RV-7.
- `common/process-overview.md`, `common/session-continuity.md`, `common/content-validation.md`,
  `common/audit-logging.md`, `common/tracker-sync.md`, `common/branching-strategy.md`,
  `common/requirements-traceability.md` (Rules 1–6 and **Rule 8**), `common/behavior-spec.md`,
  `common/eval-framework.md`, `common/directory-structure.md`, `common/parallel-work-state.md`,
  `common/work-unit-artifacts.md`, `common/self-heal-limit-guidance.md`,
  `common/ascii-diagram-standards.md`
- **`agents/change-request-analyst.md`** — the read-only analyst, executed inline at Phases 2–4.
- `workflows/dev-implement.md` — **for its contracts, not its steps.** This workflow never executes its
  branch, generation, gate-chain or PR steps; it hands those to `dev-implement` (Phase 11). What binds
  here is Step 1.7 (single-session) and Step 4.5's rule that a `.feature` contract is **read, never
  rewritten to match code**.
- `implementation/code-generation.md` (Guardrail — Generation Phase Rules),
  `workflows/code-review.md` + `implementation/code-review.md`, `workflows/remediate.md` +
  `implementation/remediate.md`
- When `## CI/CD Configuration` records `Enabled: Yes`: `common/ci-pipeline-generation.md` Sections
  4.0d, 4.0f, 4.0i and 6.6
- 🔴 **Playwright specs are never touched here** — they are code-layer tests. A CR that invalidates one
  names it on the Test Change Authorization list; `dev-implement` regenerates it through the
  `playwright-implement` skill's own subagents, never by hand.

---

## SELF-HEALING RETRY POLICY — INHERITED, PLUS ONE LOOP

SH-1 … SH-7 from `workflows/dev-implement.md` govern every loop here (3 attempts each, independent
counters, logged root cause per attempt, exhaustion HALTS with the Retry-Limit Report, stalls end the
budget early, no weakening).

At SH-4 the run emits the **Self-Heal Limit message** (`common/self-heal-limit-guidance.md` Section 2)
with **resume keyword = `epic-change-request`**, and records `HALTED —` in the story fragment's
`## Progress`. Typing `epic-change-request` again is a hand-back: the run finds the halted CR story and
follows the resume protocol (Section 4 of that file) instead of starting a new Change Request — **the
single gate is not asked again**.

The loops keep their `dev-implement` IDs, plus:

🔴 **This workflow runs no gate chain, so it owns no gate loop.** The only bounded loop here is the
Phase 9 revise-and-re-present cycle, driven by the user's `Request Changes`.

**SH-LOOP-15 (Test Impact Reconciliation)** belongs to the **build**: `dev-implement` runs it against
the Test Change Authorization list this CR wrote into the bundle. Mechanics:
`common/self-heal-limit-guidance.md:123`; gate: `common/eval-framework.md` Section 5
(`gates.testImpact`, local-only).

---

## MANDATORY: Audit Entry Format

`workflows/dev-implement.md`'s format (`User Email`, `User Input`, `TRACKER ITEM`, `Epic Link`,
`AIRE VERSION`, `AI Response`, `Context`) **plus** one field on every entry:

```markdown
**CHANGE REQUEST**: "CR-<n> — <entry mode> — spec/plans/change-requests/CR-<n>/"
```

Append only; timestamps from one real clock command. 🔴 **V9 — audit parity**: what the operator saw is
what the audit records, never a shorter paraphrase.

---

## 🔴 PARALLEL-SAFE STATE — THIS RUN IS AN INTEGRATION-BRANCH WRITER (`common/parallel-work-state.md`)

This workflow commits **on the epic branch itself** and creates no work-unit branch, so it is an
**integration-branch writer** in every case — there is no build path and no second mode:

- It writes the **shared** `runtime-artifacts/aire-state.md` and `runtime-artifacts/audit.md` directly,
  **pulling immediately before and pushing immediately after** the commit
  (`common/parallel-work-state.md` Section 6), so a concurrent story run never races it.
- The CR story's Story Tracker row, its dependency-graph node and the requirement deltas go to the
  **shared** sections — `## Story Tracker`, `spec/plans/dependency-graph.yml` + `## Dependency Graph`,
  and `## Change Request Additions`.
- 🔴 **No `runtime-artifacts/stories/…` fragment is created.** Fragments belong to work units that build;
  the CR story gets one when `dev-implement` claims it, written by that workflow under its own key
  `story-<N.M>`.
- 🔴 No State Isolation Check, no work-unit guard install, no evidence folders — all of those are
  build-time concerns.

Reads use the **resolved view** (`common/parallel-work-state.md` Section 4), so a story another clone is
mid-build on is seen at its true state.

🔴 **`cr-<n>` is the bundle's identifier, never a unit key.** The only unit key this cycle gains is
`story-<N.M>`, minted by `dev-implement` when it builds the CR story.

---

## Phase 0 — 🔴 Single-Session Check + Preconditions

**Emit this first, verbatim, before any work:**

```
-------------------------------------------------------------------
  AIRE Change Request -- a requirement changed mid-epic
-------------------------------------------------------------------

  Something you already agreed has been revised. I work out what that
  touches -- which requirements move, which stories promised the old
  text, and which tests assert it -- then show you one report and ask
  you once.

  For each affected story I decide one of three things, and tell you why:

    ALREADY BUILT       its code is merged, so I do NOT edit it.
                        A new story replaces the part that changed.
    NOT STARTED YET     no code exists, so its spec is amended in place.
                        No new story needed.
    NOTHING COVERS IT   the requirement is new to the epic.
                        A new story is created for it.

  Two ground rules:
    - Nothing is written to disk until you approve.
    - A story being built right now, or with an open PR, stops me
      rather than having its contract changed under it.
```

Then work **quietly** through Phases 0–8 (V1), emitting only a progress note when a step takes real
time, and only a halt when something blocks. The findings surface once, at Phase 9.

---

## Phase 0.5 — Entry picker (ONLY when the keyword carried no input)

🔴 **Skip this phase entirely when the keyword carried a ticket ID, a description,
`--from-requirements` or `--from-spec <path>`** — the mode is already known, and the run goes straight
to Phase 1. This is a **routing** question (which input do you have), never a clarifying one (what does
your change mean); it is asked once and never re-asked.

```
  How do you want to describe the change?

  [1] Describe it in plain English
      -> "orders over 5000 need supervisor approval"
      -> I find which requirements and stories that affects.

  [2] I already edited spec/plans/requirements.md
      -> I diff your uncommitted edit against the epic branch
         and show you what it breaks. I will NOT rewrite your wording.

  [3] Point me at a separate spec or document
      -> I analyse it as a proposed amendment, without touching
         requirements.md yet.

  [4] It came from a ticket
      -> Give me the ID; I fetch it and use it as the change.

  [5] Exit -- do nothing.

  Type 1, 2, 3, 4 or 5:
```

Branch on the answer, then continue at Phase 1 with the mode already resolved:

| Answer | Next | Resolves to |
|---|---|---|
| **1** | `What's the change? Describe it in your own words.` — take the reply verbatim as the change statement | Mode A |
| **2** | continue immediately | Mode C |
| **3** | `Path to the spec or document? (relative to the project root)` — read it; if the path does not exist, say so and re-ask once, then exit | Mode D |
| **4** | `Which ticket? (<the configured tracker>'s ID)` — fetch it per `common/tracker-sync.md` Section 8 | Mode B |
| **5** | Exit with `Nothing was analysed and nothing was written.` | — |

🔴 **Answer 2 with a clean tree** is the one case worth catching early: say
`spec/plans/requirements.md has no uncommitted change — edit it first, or pick [1] to describe the
change instead.` and exit. It saves the user reaching Phase 0's CR2 check only to be told the same thing.

Log the picker and the raw answer.



**V1**: announce the phase, its inputs and its result. Print each precondition with its **resolved value**.

0. **▶ No hand-back path.** This workflow generates no code and runs no gate chain, so it has no
   halted-build state to resume. A re-run simply starts a fresh analysis; an earlier run that halted
   wrote nothing (CR16). A halted **build** of a CR story is handed back to `dev-implement`, not here.
1. **Fork check** — execute `workflows/dev-implement.md` **Step 1.7** (the framework-wide single-session
   rule), substituting `epic-change-request`. Inside a fork or subagent → HALT with that step's message,
   change nothing.
2. `runtime-artifacts/aire-state.md` exists with `## Branching` → `Epic Branch` recorded and no
   `Workflow Type: bug` / `Workflow Type: enhancement` in `## Tracker`. Otherwise → stop:
   `No open epic cycle here — a requirement change outside an epic cycle belongs to a base-branch cycle (ticket-implement).`
3. The keyword carries a ticket ID, a description, `--from-requirements`, or `--from-spec <path>`.
   Otherwise → stop with the usage line. Asks nothing.
4. **Working tree (CR2)** — modes A/B/D require `git status --porcelain` empty. **Mode C requires the
   operator's uncommitted `requirements.md` edit**, so there the rule narrows to: **`spec/plans/requirements.md`
   is the only modified path** (`git status --porcelain` lists it and nothing else). Anything else modified
   → stop, listing exactly which files, and say that Mode C analyses a requirements edit alone. Nothing
   modified at all → stop: `No uncommitted change to spec/plans/requirements.md — edit it first, or use
   epic-change-request "<description>".` 🔴 Never stash or discard for the operator.
5. `git fetch origin && git checkout <epic-branch> && git pull --ff-only`.
   **Mode C** carries the operator's uncommitted edit through this step — it is the input, and git
   preserves it. 🔴 **But the pull FAILS (and the branch stays stale) when the incoming commits also
   touched `spec/plans/requirements.md`** — git aborts with *"Your local changes would be overwritten"*
   rather than losing the edit. Detect it by checking the exit status of the pull, and **HALT** with:
   ```
   Cannot refresh <epic-branch>: incoming commits also changed spec/plans/requirements.md,
   and you have an uncommitted edit to it. Your edit has NOT been touched.
     1. Save your edit:        git stash push spec/plans/requirements.md
     2. Refresh the branch:    git pull --ff-only
     3. Re-apply and resolve:  git stash pop      (fix any conflict markers)
     4. Re-run:                epic-change-request --from-requirements
   ```
   🔴 Never run the diff against a stale branch — the requirement delta would be measured from the wrong
   baseline, which is worse than not running at all.
6. **The cycle is still open**: `spec/`, `spec/plans/requirements.md`, `spec/plans/stories.md` and the
   Story Tracker are present, and `aire-archives/epics/<EPIC-ID>-*/` does not exist. Archived → stop: the
   change belongs to a base-branch cycle after the Epic PR merges, or the operator reverts the archive
   commit first.
7. Read `## CI/CD Configuration`, `## Tracker`, `## Code Root`, `team_size` and the
   `tests/.evals/config.json` thresholds. Log the preconditions.

**Output (V1/V3)** — a checklist with the resolved value beside each item:

**Emits nothing on success** (V1) — the resolved values go to the audit trail and the report's header. A failed precondition is a **halt** and prints immediately: what was expected, what was found, and the exact command to fix it.

A failed precondition prints **what was expected, what was found, and the exact command to fix it**.

---

## Phase 1 — Entry Mode resolution

Resolve the mode from the argument shape. **Announce which mode was resolved and why** (V1/V4).

| Mode | Invocation | `snapshot-from` → `snapshot-to` |
|---|---|---|
| **A — Description** | `epic-change-request "orders over 5k need supervisor approval"` | current `requirements.md` → in-memory hypothetical amendment |
| **B — Ticket** | `epic-change-request PROJ-240` | ticket fetched per `common/tracker-sync.md` Section 8 (summary, description, ACs, labels, links); same as A thereafter |
| **C — Drift** | `epic-change-request --from-requirements` | `git show origin/<epic-branch>:spec/plans/requirements.md` → the working-tree file |
| **D — Spec file** | `epic-change-request --from-spec <path>` | current `requirements.md` → current + grafted content from `<path>` |

**Mode C is the only mode that reads an edit the operator already made.** Its consequence is recorded
once here and honoured at Phase 10: 🔴 **the workflow never rewrites the operator's requirement prose in
Mode C** — their working tree is the source of truth. It writes only the version annotations
(`common/change-request-rules.md` Section 4 bucket (b)).

In Modes A/B/D the amendment is **constructed in memory and never written to `requirements.md` before
the gate**; the analyst states plainly that the text does not yet exist on disk.

Where the capture leaves something open (a limit, a rule, a message text), **do not ask**: choose the
reading most consistent with the approved ACs, `requirements.md`, `architecture.md` and the existing
code, and record it as an assumption in `change-request.md` Section 9 **with the alternative not taken**.

Log the invocation and the capture verbatim.

**Emits nothing** (V1). The resolved mode, its reason and the snapshot pair are recorded and appear in the report header.

---

## Phase 2 — Requirement anchor-resolution diff (CR3)

Invoke `agents/change-request-analyst.md` **inline** (never as a subagent) with the snapshot pair.

Match **by REQ-ID**, never by line number, position or semantic similarity alone. Classify each
requirement AMENDED / ADDED / SUPERSEDED / UNCHANGED per `common/requirement-versioning.md` Section 2.

🔴 An ID that cannot be resolved is **reported as unresolved, never guessed at** — it fails predicate
CR3 and the run HALTS (a halt, not a question).

**Output (V2/V3)** — counts first, then the before/after for every changed requirement; unchanged
requirements are a count only:

**Emits nothing** beyond a progress note if the scan is slow (`Analysing <N> requirements…`). The classifications and before/after text go to `requirements-delta.md` and the report's REQUIREMENTS block. 🔴 An unresolved REQ-ID is a **halt** and prints immediately.

---

## Phase 3 — Impact ledger: REQ -> stories -> ACs -> tests (CR6)

The analyst performs five walks. 🔴 **No artifact is "affected" without a recorded reason.**

1. **REQ → stories (primary walk)** — every story whose `**Covers**:` names the changed REQ-ID.
   Normalise `@vN` from both sides before matching. Exact, not heuristic: Rule 2 makes `Covers`
   mandatory and non-empty. Cite the `Covers` line. **A changed REQ-ID with no covering story is
   reported explicitly** — it routes to a new story.
2. **Story → ACs** — the ACs implementing that requirement, each classified UNCHANGED / AMENDED /
   SUPERSEDED. Where `stories.md` has an AC-level `AC-n → REQ-ID` breakdown, use it; where it does not,
   every AC is a candidate and the ledger states which were judged in scope **and why**.
3. **Story → code (confirmation walk)** — three independent sources, recording which agree: manifest
   fragments `tests/.evals/ci-manifest.d/story-*.json`; epic-branch history
   (`git log --format='%H %s' origin/<base>..<epic-branch> -- <path>`, subjects carry
   `[Story N.M / TRACKER-ID]`); `git blame -w -M -C -L <range> -- <file>`. Agreement is reported as
   `n/3`. 🔴 Read the code — never infer relevance from a file's name.
4. **Story → tests and contracts** — `tests/unit/**`, `tests/api/**`, `tests/behavior/steps/**`,
   `tests/e2e/<story-slug>/**`, plus `spec/behavior/story-<N.M>.feature` scenarios,
   `spec/test-plans/<ID>-*/` cases and any `spec/behavior.feature` journey. This list is the input to
   the Test Change Authorization list (CR10).
5. **Concurrency scan** — every work unit `In Development` without a merged PR, and every open `ve/…`
   PR, whose diff touches the change surface (`gh pr diff <n> --name-only`).

Emit the impact tags (CR8): `affects_requirements`, `affects_stories`, `affects_shipped`,
`code_touched`, `doc_only`.

**Output (V2/V3)** — counts first, then the ledger with an evidence cell on **every** row, then the tags:

**Emits nothing** beyond a progress note (`Tracing <N> stories…`). The complete evidence chain — every citation, every agreeing source, every test path — is written to `impact-ledger.md`; the report shows one row per affected story and cites that file.

---

## Phase 4 — Routing (CR9)

Route every affected story on its **pre-run status** and its **live PR merge state**.

🔴 **Status is read from the git snapshot** — `git show origin/<epic-branch>:runtime-artifacts/aire-state.md`
plus the committed `runtime-artifacts/stories/*/state.md` fragments, resolved per
`common/parallel-work-state.md` Section 4 — **never from the working tree**, which the operator may have
edited. 🔴 **Merge state is confirmed live** (`gh pr view <branch> --json state,mergedAt`; for LOCAL,
`git branch --merged <epic-branch>`) and is the authority over any tracker label
(`common/behavior-spec.md` Section 6.1). Both are re-asserted immediately before the Phase 10 writes (TOCTOU).

| Story state (git snapshot) | PR state (live) | What the user is told | Route (internal) | Why |
|---|---|---|---|---|
| `Ready for Development` | — | **NOT STARTED YET** → its spec is amended in place; no new story | `spec-only` | No code exists, so the contract can be corrected directly |
| `In Development` | no PR yet | **BEING BUILT RIGHT NOW** → blocked | 🔴 **HALT** | Never change a spec under an in-flight build |
| `In Development` | PR open, unmerged | **HAS AN OPEN PR** → blocked | 🔴 **HALT** | Its code is not on the epic branch yet → comment on that PR and run `pr-fix <PR>`, or merge it and re-run |
| `In Development` | PR **merged** | **ALREADY BUILT** → a new story replaces the part that changed | `CR-born` | Code is merged; it is never edited in place |
| `Ready for Testing` | merged | **ALREADY BUILT, SIGNED OFF** → a new story replaces the part that changed; status **not** demoted | `CR-born` | The Verification Engineer already signed off; re-verification rides the CR story's test plan |
| no story `Covers` the REQ | — | **NOTHING COVERS IT** → a new story is created | `new` | A requirement new to the epic needs its own story |

🔴 **Say the outcome, then the internal term** (V3). The report leads with what happened and why —
`ALREADY BUILT (PR #31 merged) -> Story 1.10 replaces its contract for AC-4  [CR-born]` — so a reader
who has never opened `common/change-request-rules.md` understands it, while the bracketed term keeps
every row traceable to the CR9 rule that produced it.

- **Every affected story is `Ready for Development`** → the **spec-only path**: Phases 5–9 and 10.3 run,
  no CR story is created, nothing is built; Phase 10.3 ends with a direct commit on the epic branch.
- **Any block** → 🔴 **HALT before writing anything.** Emit it in the same plain language as the report,
  so the user knows what to do without reading a rule file:

```
  CANNOT PROCEED -- 1 story is mid-flight

  1.6  Auth Pages & Session
       BEING BUILT RIGHT NOW (claimed, no PR yet)
       Its contract cannot change while someone is building against it.

  What to do:
    - finish and merge Story 1.6, then run epic-change-request again, or
    - if it already has a PR open, put this change on that PR:  pr-fix <PR>

  Nothing was written.
```

Log it. (A halt, not a question.)

**Output (V4)** — per story: snapshot status **and its source**, live PR state, the chosen route, and
the rule that selected it:

**Emits nothing on success** — the routing table is the report's STORIES block. 🔴 A **block** prints immediately as a halt, naming every blocking story, its state, its PR and the exact way forward, and the run stops without writing anything.

When a story blocks, the block is named in full — story, state, PR, and the exact way forward — and the
run HALTS there without writing anything.

---

## Phase 5 — CR collision check (CR11)

Glob `spec/plans/change-requests/CR-*/change-request.md` and grep each affected story-id in their
`## 3. Impact` tables. An **open CR** is one whose story has no merged PR yet.

- **Collision found** → **APPEND** to that CR's affected-stories set rather than drafting a parallel CR
  over the same ground. Announce it and continue — a stated fact, not a question. The run then carries
  the **existing** `CR-<n>` number through every later phase.
- **No collision** → say so explicitly. 🔴 **Never silence** (V1).

**Emits nothing** — the result (a collision and its CR, or none) appears as one line in the report header.

---

## Phase 6 — Requirement versioning (CR4)

Apply `common/requirement-versioning.md`:

- **AMENDED** → `@v<N+1>`; prior text **retained**, struck through, annotated `Amended by CR-<n> on <date>`.
- **ADDED** → a new `REQ-F-<next>` / `REQ-NF-<next>`, **unversioned**. 🔴 Never `@v1` (RV-3).
- **SUPERSEDED** → retained and marked. 🔴 **Never deleted** — Rule 1 forbids reusing a removed ID, so
  the record must stay visible.
- **UNCHANGED** → byte-identical (RV-5).

Then re-point every covering story's `Covers` to the new version, or route that story as blocked
(CR5). A `Covers` naming an older version while a newer exists is a **stale trace** — a blocking gap of
the same class as Rule 3's gap A.

**Output (V3)**:

**Emits nothing** — version transitions appear in the report's REQUIREMENTS block and in full in `requirements-delta.md`.

---

## Phase 7 — Stage everything in memory (CR16 — nothing on disk yet)

🔴 **No file is written in this phase.** Everything is composed in memory and held for the gate.

### 7.1 Numbering (CR12b)

Read `CR-*` ids and the Story Tracker **from `origin/<epic-branch>` immediately before assigning**:
next CR id = `max(n) + 1` (per-epic, not zero-padded); next story number = the next free `N.M`. Both are
re-verified immediately before the push (Phase 10). On collision: renumber, rename the branch, announce.

### 7.2 The bundle

```
spec/plans/change-requests/CR-<n>/
├── change-request.md        # templates/change-request/change-request.TEMPLATE.md — 10 sections
├── requirements-delta.md    # templates/change-request/requirements-delta.TEMPLATE.md
├── impact-ledger.md         # templates/change-request/impact-ledger.TEMPLATE.md
└── README.md                # index + parallel-safety notes
```

🔴 **`change-request.md` Section 4 carries the machine-read build-unit marker**
`CR-BUILDS-STORY: <N.M>` — exactly one line, naming the story this CR created **for `dev-implement`
to build** (no story created: `CR-BUILDS-STORY: none`). 🔴 The CR itself builds nothing; the marker is
how the work-unit guard, later and in `dev-implement`'s run, knows that **that** story owes the
`testImpact` gate — because it carries a Test Change Authorization list. A story merely listed as
affected in Section 3 must never match it. A missing or malformed marker fails Phase 8 check (e).

**Before composing, read first** — without these the content is generic, and the depth rules are not
optional: the body of every story being superseded or amended; the changed requirements' full text
(both revisions); the code implementing the affected stories (from their `## Implementation steps` and
the Phase 3 ledger); the affected `.feature` files and test plans.

### 7.3 CR12 — dependency-cycle check

Walk the `requires` graph across every affected and proposed story (Tarjan SCC). An SCC of size > 1
intersecting the CR's scope means there is no safe ordering → 🔴 **ABORT**, print the cycle members,
write nothing. Cycles elsewhere are reported and do not block.

### 7.4 Staged spec edits

- **`spec/plans/requirements.md`** — the version annotations (Section 3 of the versioning file).
  🔴 **SKIPPED entirely in Entry Mode C** for the prose; only annotations are applied.
- **`spec/plans/stories.md`** — the CR story appended in the same format as every other story
  (`**Tracker ID**:`, `**Covers**:`, `**Requires**:`, `**Change Request**: spec/plans/change-requests/CR-<n>/`);
  every AMENDED / SUPERSEDED AC of earlier stories annotated **in place** —
  `AC-3 (amended by CR-<n>, <date>): <new text>`, old text struck through, **never deleted**; the
  `## Requirements Coverage Matrix` rebuilt (Rule 8 item 3).
- **`spec/behavior/story-<N.M>.feature`** — the CR story's contract per `common/behavior-spec.md`
  Section 2, one `@AC-n` scenario per AC, failure paths included; amended scenarios of earlier stories
  edited in place keeping their `@AC-n` tag and adding `@amended-by-cr-<n>`; a SUPERSEDED AC's scenario
  retired (removal recorded in the bundle; the AC stays in `stories.md`, marked).
- **`spec/behavior.feature`** — any cross-story journey the change alters.
- **`spec/test-plans/**`** — via the **`ve-implement` skill in WORKFLOW MODE** only
  (`implementation/specs-and-test-plans.md`): once for the CR story (its plan carries a
  "Re-verification of affected stories" section) and once per affected story, scoped to its AMENDED /
  SUPERSEDED ACs. 🔴 Never hand-edited.
- **`spec/plans/architecture.md`** — only when the change alters a design decision: amend, bump its
  version, and **regenerate** `tests/.evals/rubrics/architecture-rubric.json` from Section 10
  (`implementation/architecture-doc.md` Section 4). 🔴 Never hand-edit a rubric.
- **Dependency graph** — `spec/plans/dependency-graph.yml` and the shared `## Dependency Graph`
  directly (this run is always an integration-branch writer). It records the CR story's node with its
  `requires` / `enables`, and any new edge from a not-yet-started story onto it.
- **Rule 4 record** — `Requirements coverage verified post-design: [R]/[R] REQ-IDs — [timestamp] (re-verified after CR-<n>)`.

### 7.5 Coverage check (blocking, fixed silently)

Every CR-story AC and every AMENDED AC has ≥1 scenario and ≥1 test case; nothing remains for a
SUPERSEDED AC; every amended requirement has a story tracing to its new version.

**Output (V3)** — a file-by-file manifest of what **will** be written, grouped by CR16 allow-list
bucket, each with a line count, marked clearly as *staged, not written*:

**Emits nothing** — the manifest appears in the report as per-bucket counts (`CR bundle 4 · specs 2 · test plans 2 · …`), not as a file-by-file listing. 🔴 A CR12 dependency cycle is a **halt** and prints immediately.

---

## Phase 8 — Pre-emission validation (CR13)

Eight checks against the **in-memory** staging, **before** the preview. First failure HALTS — a
malformed bundle is never shown to the operator.

| # | Check |
|---|---|
| (a) | **Route coverage** — every affected REQ-ID is routed **exactly once** (CR-born, spec-only, or new story). Both → fail (over-counted). Neither → fail (uncovered). |
| (b) | **Supersede integrity** — every CR-born story names a real story in `supersedes`, and that story's PR is confirmed merged. |
| (c) | **Dependency inheritance** — every CR-born story's `requires` is a superset of the superseded story's, minus ids superseded in this same CR. |
| (d) | **Bundle inventory** — `change-request.md`, `requirements-delta.md`, `impact-ledger.md`, `README.md` all present. |
| (e) | **Section presence + build marker** — `change-request.md` carries all 10 `## ` sections in order (empty ones written as `(none — <reason>)`), **and exactly one `CR-BUILDS-STORY:` line** whose value is the story this run created for `dev-implement`, or `none` when it created none. Zero, several, or a value naming a story this CR did not create → fail. |
| (f) | **Fact-only scan (CR14)** — regex for severity adjectives and advisory verbs across every staged artifact; count must be 0. |
| (g) | **Coverage** — Phase 7.5's result; plus RV-1…RV-7 from `common/requirement-versioning.md`. |
| (h) | **One CR per run** — exactly one bundle is staged, unless this is a CR11 append (which stages zero new bundles and edits one existing). |

**Output (V1)** — all eight with **computed results**, never bare ticks:

**Emits nothing on success** — all eight results are computed, recorded in the audit trail, and summarised in the report as `pre-emission: 8/8 PASS`. 🔴 Any failure is a **halt**: it prints the failed check, the offending file and the remediation, and the report is never shown.

On failure: print the failed check, the offending file/section, the rule violated, and the remediation.
Do **not** proceed to Phase 9.

---

## Phase 9 — 🚦 THE SINGLE GATE (CR16 / V5)

**This is where the whole run surfaces.** Phases 0–8 worked quietly; everything they found is
presented **here, once**, as one scannable report — then the run halts for the only question it asks.

🔴 **Nothing has been written to disk at this point.**

**Shape (V3): counts → table → decisions.** Every number is real; the deep evidence is in the bundle
and is **cited, never pasted** (V2/V3/V5). The report fits on roughly one screen.

```
+-------------------------------------------------------------------+
|  CR-<n>  --  REVIEW BEFORE APPROVING                              |
|  Nothing has been written to disk.                                |
+-------------------------------------------------------------------+

  <one-line summary of the change, in the user's own words>

  Entry mode  : <A description | B ticket <ID> | C your requirements.md edit | D spec file>
  Epic branch : <epic-branch> @ <sha>          Tracker: <TYPE>
  Bundle      : spec/plans/change-requests/CR-<n>/     (staged, not written)
  Collision   : <none | appending to CR-<m>>           Pre-emission: 8/8 PASS

WHAT CHANGED IN THE AGREEMENT    <A> amended, <B> added, <C> withdrawn, <D> untouched
  <REQ-ID> -> @vN   <what differs, one line>

WHAT THAT MEANS FOR YOUR STORIES     Blocked: <none | N -- see below>
  <N.M>  <title>
         ALREADY BUILT (PR #<n> merged)
         -> Story <X.Y> replaces its contract for <AC-n>          [CR-born]
  <N.M>  <title>
         NOT STARTED YET
         -> its acceptance criteria and spec are amended in place  [spec-only]
  --     (nothing covers <REQ-ID>)
         -> new Story <X.Y>                                        [new]

  Nothing already built is edited in place. <X> new, <Y> amended, <Z> untouched.

TESTS          <n> may change; <m> stay as regression guards
  <file>  <test>  <action>  <- <AC-n> <class>
  ...  full list in the bundle

WRITES         <N> files, all inside the allow-list
  CR bundle <n> · requirements.md <n> · stories.md <n> · specs <n> · test plans <n>
  architecture+rubric <n> · state <n>        outside allow-list: 0

DECISIONS I MADE FOR YOU  (overrule any with Request Changes)
  1. <decision> -- <why>.  Rejected: <alternative>.
  2. ...

  Full detail: spec/plans/change-requests/CR-<n>/change-request.md
               (+ requirements-delta.md, impact-ledger.md -- open them to see every citation)

A) Request Changes -- tell me what to change
B) Approve & Apply -- amend the specs and commit them to <epic-branch>,
   then hand the build to dev-implement

[Answer]:
```

(There is no build variant of option B — this workflow never generates code.)

🔴 **What this report must NOT do**: paste the `change-request.md` body (it is staged and its path is
printed — re-printing it buries the decision); reprint the per-phase working state; or list every
citation when the ledger holds them. The user decides from this screen and opens the bundle when they
want the proof.

- **`A`** → revise the staging (a requested change to a Section 9 decision moves that row to "decided by
  the user" with their wording), add a Section 10 revision entry, re-run Phase 8, present again.
  🔴 Nothing has been written, so there is nothing to roll back.
- **`B`** → Phase 10.
- Any other answer → re-prompt: `Please answer A (Request Changes) or B (Approve & Apply).`

Log the prompt and the complete raw answer.

---

## Phase 10 — Apply, then build

🔴 **Everything below happens only after the Phase 9 `B`.** Writes are ordered; a sub-step failure HALTS
with rollback instructions (`git status` + `git restore`) rather than leaving a partial apply (CR16).

### 10.1 Re-assert routing before writing (TOCTOU)

Re-read every affected story's **snapshot status** and confirm its **live PR merge state** exactly as
Phase 4 did. Any story that changed state since the analysis → **HALT** and re-run; never write against
stale routing. Re-check the CR id and story number against `origin/<epic-branch>` (CR12b); renumber,
and announce, if either was taken.

### 10.2 (reserved — no branch, no baselines)

🔴 This workflow cuts **no story branch** and captures **no baselines**. Both belong to the build, which
`dev-implement` owns (Phase 11). The spec edits are committed on the epic branch itself (10.4).

### 10.3 Write the bundle and the approved spec edits

In this order, each re-asserting the snapshot status immediately before it:

1. **The CR bundle** → `spec/plans/change-requests/CR-<n>/` (4 files).
2. **`spec/plans/requirements.md`** — version annotations. 🔴 **Mode C: annotations only**; the
   operator's prose is not rewritten.
3. **`spec/plans/stories.md`** — the CR story appended; every AMENDED / SUPERSEDED AC annotated in
   place, old text struck through, never deleted; the `## Requirements Coverage Matrix` rebuilt.
4. **Behaviour specs** — the CR story's `spec/behavior/story-<N.M>.feature`; amended scenarios of
   earlier stories edited in place (`@AC-n` kept, `@amended-by-cr-<n>` added); retired scenarios removed
   and recorded; `spec/behavior.feature` journeys amended.
5. **Test plans** — the `ve-implement` skill in **WORKFLOW MODE** (never re-implemented), once for the
   CR story and once per affected story scoped to its AMENDED / SUPERSEDED ACs.
6. **Architecture + rubric** — only when the bundle records a design change; the rubric is regenerated,
   never hand-edited.
7. **Dependency graph** — `spec/plans/dependency-graph.yml` + the shared `## Dependency Graph`.
8. **Rule 4 record** — refresh `Requirements coverage verified post-design: …(re-verified after CR-<n>)`.

**Spec-only path ends here**: update the amended stories' tracker items (AC text + a comment naming the
bundle), commit on the epic branch —
`[Spec] CR-<n>: amend <REQ-IDs@vN> and Story <X.Y>[, …]` with the `AIRE-Version: [N]` trailer — push,
emit the spec-only handoff (Phase 11), stop. **Build path**: these edits ride the CR story's own commit
(10.6) and are never pushed to the epic branch directly.

**Output (V1)**: per write, the path and its byte/line count.

### 10.4 Commit the spec edits on the epic branch

🔴 **This workflow does not generate code.** It amends the agreement and the contracts that express it,
then hands the build to `dev-implement` (Phase 11). It cuts no story branch, runs no gate chain, and
raises no PR.

1. **Coverage check (blocking, fixed silently)** — every CR-story AC and every AMENDED AC has ≥1
   scenario and ≥1 test case; nothing remains for a SUPERSEDED AC; every amended requirement has a story
   tracing to its new version (CR5 — no stale traces).
2. **Commit on the epic branch** — pull immediately before and push immediately after
   (`common/parallel-work-state.md` Section 6; this run is an **integration-branch writer**):
   `[CR-<n>] Amend <REQ-IDs@vN>; Story <N.M> created` with the `AIRE-Version: [N]` trailer.
   Staged: the CR bundle, `requirements.md`, `stories.md`, `spec/behavior/**`, `spec/test-plans/**`,
   `spec/plans/architecture.md` + the regenerated rubric when a design decision changed,
   `spec/plans/dependency-graph.yml`, and the shared `runtime-artifacts/aire-state.md` + `audit.md`.
3. **Push.** If the push fails, say so and stop — `dev-implement` cannot start until the specs are on
   origin.

🔴 **No story branch, no work-unit fragment, no `check-work-unit.sh` install, no evidence folders.**
Those belong to the build, and the build belongs to `dev-implement`. The story is left
`Ready for Development` and **unclaimed** — `dev-implement`'s own Story Selection makes the claim, as it
does for every other story.

### 10.5 What `dev-implement` inherits

The CR leaves behind everything the build needs, and nothing it must re-derive:

| Artifact | State on handoff | Who consumes it |
|---|---|---|
| `requirements.md` | amended, `REQ-F-nn@vN` versioned, prior text retained | `dev-implement` Part 1 (REQ-ID thread, Rule 5) |
| `stories.md` | CR story appended; earlier stories' AMENDED/SUPERSEDED ACs annotated in place | Part 1 planning + Code Review scope |
| `spec/behavior/story-<N.M>.feature` | **written by the CR**, one `@AC-n` scenario per AC | `dev-implement` Step 4.5 (verifies, never authors) |
| earlier stories' `.feature` scenarios | **amended by the CR** in place, `@amended-by-cr-<n>` added | B2 tier |
| `spec/test-plans/**` | **written/amended by the CR** via `ve-implement` WORKFLOW MODE | the Verification Engineer, after the PR merges |
| `change-request.md` Section 6 | the implementation plan | `dev-implement` Part 1 grounds its own plan on it |
| **Test Change Authorization list** (Section 5b) | the earlier stories' **unit / API / Playwright** tests that may change, each traced to an AMENDED or SUPERSEDED AC | 🔴 **`dev-implement`** — it updates them during generation |

🔴 **The spec/code split is the whole point of the handoff:**

- **The CR owns the spec layer** — `.feature` contracts and manual test plans. They are the *contract*,
  they must exist before code, and amending them is a requirement decision, not a coding one.
- **`dev-implement` owns the code layer** — unit, API, step-definition and Playwright tests. They assert
  *implementation*, so they change when the code changes, in the same commit, under the same gates.

Updating an obsolete unit test **before** the code that makes it correct would leave the epic branch red
with no way to tell a legitimate amendment from a break. So the CR **names** those tests and does not
touch them; `dev-implement` changes them alongside the code and proves the result with Test Impact
Reconciliation (SH-LOOP-15).

### 10.6 Tracker and state

1. **Tracker item** (`common/tracker-sync.md`; LOCAL: local only, `Tracker ID` = `LOCAL`): create the CR
   story linked to the Parent Epic (Section 6 labels/fields, `Built with AIRE v[N]` footer), left in the
   tracker's **Ready for Development** state. Verify. 🔴 Do **not** transition it to In Development and do
   **not** assign it — `dev-implement` claims it.
2. **Story Tracker row** in the shared `runtime-artifacts/aire-state.md`: Story `<N.M>`,
   `Ready for Development`, `Requires` from the bundle, `Recorded` set.
3. **Dependency graph**: the CR story's node and edges written to `spec/plans/dependency-graph.yml` and
   the shared `## Dependency Graph`.
4. **Rule 4 record** refreshed:
   `Requirements coverage verified post-design: [R]/[R] REQ-IDs — [timestamp] (re-verified after CR-<n>)`.
5. **Comment on every affected story's tracker item**:
   `Requirement amended by CR-<n>: <REQ-IDs@vN>. Delivered by Story <N.M>.`
6. **Epic sync**: Parent Epic already `Ready for Testing` → move it back to In Development (authorised by
   the gate), verify, log.

### 10.7 CR13 self-verification

Print the Section 2 predicates of `common/change-request-rules.md` with **computed results** — CR3, CR4,
CR5, CR6, CR8, CR9, CR11, CR12, CR12b, CR14, CR16, CR13-V — plus RV-1…RV-7. A predicate that could not be
computed counts as **fail**. 🔴 CR10 is recorded as **staged, not enforced**: the Test Change
Authorization list is handed to `dev-implement`, which enforces it at its own Test Impact Reconciliation.

---

## Phase 11 — Handoff to `dev-implement` (verbatim, the last output)

**When the CR created a story to build:**

```
  CR-<n> APPLIED -- specs amended. No code was written.

  Requirements : <REQ-F-nn -> @v2, REQ-F-mm added, REQ-F-kk withdrawn>
  Story <N.M>  : <title>          Ready for Development (unclaimed)
  Amended      : <Story X.Y AC-n, ...> -- their acceptance criteria, .feature
                 scenarios and manual test plans were updated in this commit.
  Bundle       : spec/plans/change-requests/CR-<n>/
  Commit <sha> pushed to `<epic-branch>`.

  <n> earlier test(s) now assert behaviour the agreement no longer requires.
  They are listed in the bundle's Test Change Authorization list and are
  updated by the build -- not here, because changing them before the code
  exists would leave the branch red with no way to tell an authorised
  amendment from a break.

NEXT ACTIONS:
   1.  Build it:  dev-implement <N.M>
       It reads the CR's plan and the authorization list, writes the code,
       updates exactly those tests, runs every gate, and raises the [STORY] PR.
   2.  The Verification Engineer can review the amended test plans now --
       they are already on `<epic-branch>`.

Type the keyword EXACTLY as shown -- any other phrasing is not a framework trigger.
```

**Spec-only (nothing was built and nothing needs building — every affected story was not yet started):**

```
  CR-<n> APPLIED -- specs amended. Nothing needs building.

  Requirements : <REQ-F-nn -> @v2, ...>
  Amended      : <Story X.Y AC-n, ...> -- not started, so their contracts were
                 corrected in place. No new story was created.
  Bundle       : spec/plans/change-requests/CR-<n>/
  Commit <sha> pushed to `<epic-branch>`.

NEXT: those stories are built as usual, against the corrected contracts:
      dev-implement <X.Y>
```

Log which variant was shown.

---

## Edge cases — every one resolved without a question

| # | Situation | Handling (default recorded in `change-request.md` Section 9 where it is a decision) |
|---|---|---|
| E1 | Affected story not started (`Ready for Development`) | Spec-only amendment of its ACs, scenarios and test cases; `requires` edge onto the CR story if its code builds on the change |
| E2 | Affected story being built right now (`In Development`, no PR) | **HALT — blocked**: never change a spec under an in-flight build; finish it, then `pr-fix` (open PR) or re-run (merged) |
| E3 | Affected story has an OPEN, unmerged PR | **HALT — blocked**: comment the change on that PR and run `pr-fix <PR>`, or merge it and re-run |
| E4 | Affected story merged, awaiting the Verification Engineer | CR-born story; its test plan is amended in the same PR |
| E5 | Affected story already `Ready for Testing` | Not demoted; tracker comment; re-verification cases live in the CR story's plan |
| E6 | Parent Epic already Ready for Testing | Moved back to In Development — stated in Section 7, authorised by the gate, verified |
| E7 | Epic already archived | Stop — the change belongs to a base-branch cycle (`ticket-implement`) after the Epic PR merges, or the operator reverts the archive commit |
| E8 | A changed requirement has NO covering story | **New story** (CR9). This is the case only a requirement-first walk finds; it is reported, never silently dropped |
| E9 | The amendment would violate the Security Baseline | **Default**: the CR story is shaped to comply (adds the missing authorisation / validation); Section 9 records what was reshaped and why |
| E10 | Requirement SUPERSEDED (behaviour withdrawn) | ACs marked superseded (kept); scenarios/test cases retired; dead tests deleted via the authorization list; dead code removed; requirement retained and marked, never deleted |
| E11 | Mode C: operator edited a requirement the epic has no story for | Classified ADDED; routes to a new story (E8) |
| E12 | Mode C: operator also modified files outside the watched sources | **Stop** listing them (CR2) — never stash or discard their work |
| E13 | Two clones mint the same `CR-<n>` or story number | Re-read from `origin/<epic-branch>` right before assignment and again before the push; on collision renumber, rename the branch, announce (CR12b) |
| E14 | Story already belongs to an open CR | **Append** to that CR (CR11), never a parallel bundle |
| E15 | Dependency cycle among affected/proposed stories | **ABORT** (CR12), print the SCC, write nothing |
| E16 | LOCAL tracker | Everything stays in `stories.md` and the Story Tracker; no external calls |
| E17 | CI/CD disabled | Manifest reconciliation, preflight and attestation skipped, as in `dev-implement` |
| E18 | The CR story becomes the last unit | B3 runs on it when every other unit's PR is merged (live merge state, `dev-implement` Step 6.1) |
| E19 | A test outside the authorization list goes red | Regression — fix the code; it joins the list only if it asserts an AMENDED/SUPERSEDED AC (announced, revision-logged) |
| E20 | Another story merges into the epic branch during the run | The PR shows it; if it conflicts, `pr-fix` merges the epic branch in and re-runs every gate |
| E21 | The capture is ambiguous (a limit, a rule, a message text) | **Default**: the reading most consistent with approved ACs, requirements, architecture and existing code; Section 9 records the assumption and the alternative |
| E22 | CR story PR rejected | `pr-fix <PR>` — it detects the change document and also re-runs 10.5 |
| E23 | It is not a requirement change at all — behaviour or a defect | Out of this flow: new/changed behaviour with no requirement change is `epic-enhance`; a defect is `epic-bugfix`. The run stops with that pointer **before writing anything** |
| E24 | An unversioned `Covers` after its requirement reached `@v2` | **Stale trace** — a blocking gap (CR5); the story is re-pointed or routed |

---

## Critical Rules

- 🔴 **THE GATE IS THE ONLY DECISION QUESTION.** No clarifying questions, no option menus mid-run, no
  decisions asked of the user after analysis starts. Decisions the framework makes are written into
  Section 9 **with their rejected alternative** and overruled only via Request Changes. The single
  exception is the **Phase 0.5 entry picker**, shown only when the keyword carried no input — it routes
  on which input the user has, never on what the change means, and is skipped whenever input was given.
  Blocks, cycles, pre-emission failures and retry limits are halts, not questions.
- 🔴 **NOTHING ON DISK BEFORE THE GATE** (CR1 / CR16). Everything is staged in memory; every written path
  falls inside the `common/change-request-rules.md` Section 4 allow-list.
- 🔴 **REQUIREMENTS ARE VERSIONED, NEVER RENUMBERED OR DELETED** (CR4). AMENDED → `@v<N+1>` with prior
  text retained; ADDED → unversioned; SUPERSEDED → retained and marked.
- 🔴 **STATE FROM THE GIT SNAPSHOT, MERGE STATE LIVE** (CR9), re-asserted immediately before writing.
- 🔴 **NEVER CHANGE WORK IN FLIGHT.** A story being built, or with an open PR, blocks the change.
- 🔴 **THE SPEC/CODE SPLIT.** The CR amends `.feature` contracts and manual test plans. It **names**
  the earlier stories' unit/API/Playwright tests that the amendment invalidates (CR10) and leaves them
  untouched — `dev-implement` updates exactly those, alongside the code, and proves it with Test Impact
  Reconciliation. Every other red test is a regression fixed in the code.
- 🔴 **CONTRACTS MOVE TOGETHER.** An amended AC moves its `stories.md` text, scenario, test case, tests
  and (UI) Playwright spec in the same PR; scenarios and plans are never rewritten to match code, and
  Playwright specs only through the `playwright-implement` subagents.
- 🔴 **SPECS ONLY — NEVER CODE.** This workflow amends the agreement and the contracts that express it,
  then hands off. No story branch, no generation, no gate chain, no PR. Every gate still runs — on the
  CR story, inside `dev-implement`, where the code and its tests change together.
- 🔴 **NO STATUS DEMOTION, NO MERGING.** Statuses move only as `dev-implement` and `ve-list-work` define;
  the framework never merges a PR.
- 🔴 **INTO THE EPIC, AS A STORY.** The CR story joins the epic's Story Tracker and dependency graph as
  `Ready for Development`, and is built by `dev-implement` like any other — never a base-branch cycle,
  never a new `Workflow Type`, never a change to `## Tracker`'s Parent Epic.
- 🔴 **SELF-CONTAINED.** This workflow never reads, cites or delegates to `epic-enhance.md` or
  `epic-bugfix.md`.
- 🔴 **VERBOSE BY CONTRACT** (CR13-V / V1–V9). No quiet mode, no verbosity flag, no summarising the
  bundle at the gate.
- 🔴 **SINGLE SESSION, BOUNDED LOOPS, FULL AUDIT.** No forks (Phase 0); 3 attempts per loop; every audit
  entry carries the `dev-implement` fields plus `CHANGE REQUEST`; every commit carries `AIRE-Version: [N]`.
