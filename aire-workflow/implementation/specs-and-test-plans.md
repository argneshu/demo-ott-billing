# Behaviour Specs & Test Plans (STOP CHECKPOINT — every work unit, before any code)

**Purpose**: author the **behavioural contract** (`spec/behavior/<work-unit>.feature`) and the
**manual test plan** (`spec/test-plans/<TICKET-ID>-<title>/`) for **EVERY work unit of the cycle**
while the design is still on the table — **before a single line of code is generated** — and put both
in front of the user for review in ONE pass, exactly like every other design-phase artifact.

**When it runs** — at the STOP CHECKPOINT, after `architecture.md` + the rubrics (and the CI pipeline,
when enabled), **before** the design commit, the smoke test and the Development Handoff:

| Cycle | Invoked from | Scope |
|---|---|---|
| Epic | `CLAUDE.md` MANDATORY STOP **Step 1.7** | EVERY story in the `## Story Tracker` |
| Bug | `workflows/bug-fix.md` **Step 8.5 Item 4.5** | the single ticket (`bug-<TICKET-ID>`) |
| Enhancement | `workflows/enhancement-implement.md` **Step 8.5 Item 4.5** | the single ticket (`enhancement-<TICKET-ID>`) |

**Load this file when**: executing that step, or when an implement workflow needs the backfill rule
(Section 5) because an artifact this stage owns is missing.

---

## 1. Why the contract is written here, not inside the implement workflows

The `.feature` file is the **contract the code is measured against**, and the manual test plan is
**what the ve executes** once the work merges. Both are derived from the acceptance criteria and the
approved design — never from the implementation. So both are knowable the moment the design stages
close, and neither has any dependency on code existing.

Writing them here buys three things the per-unit placement could not:

1. **A human reviews the contract before the code is written**, in the same 2-option pattern as every
   other design artifact — not after the fact, when changing it means re-running gates.
2. **The ve starts from a reviewed plan.** The design commit pushes `spec/test-plans/` to the
   integration branch, so `/ve-implement` opens an existing, approved plan to refine rather than
   authoring one from a blank page.
3. **One coherent pass over the whole cycle.** Cross-unit gaps in the acceptance criteria surface
   while every story is in view, instead of one story at a time.

🔴 **This stage is NOT ve sign-off.** The plans it writes are the ones the ve executes once each work
unit's code is on its branch; `ve-list-work` Option B remains the only sign-off path. `/ve-implement`
stays available for optional rework of a plan, on the ve's own schedule — nothing requires it.

---

## 2. Part A — the behaviour specs

For **every** work unit in scope, write its single `.feature` file per `common/behavior-spec.md`
Section 2 — that file is the authority for content, tagging and style; nothing is restated here:

| Cycle | File |
|---|---|
| Epic | `spec/behavior/story-<N.M>.feature`, one per story |
| Bug | `spec/behavior/bug-<TICKET-ID>.feature` |
| Enhancement | `spec/behavior/enhancement-<TICKET-ID>.feature` |

- One `Scenario` per acceptance criterion, minimum; every scenario tagged `@AC-<n>`; failure paths
  covered; steps stated as business behaviour with concrete, checkable values.
- 🔴 **One `.feature` per work unit is still the ONLY per-unit spec file.** No per-story requirements,
  architecture, constraints or deep-dive document (`common/behavior-spec.md` Section 1).
- `spec/behavior.feature` (the cycle-level cross-unit journeys) is **not** written here — it is
  written earlier in the STOP CHECKPOINT and is a different artifact. Never conflate the two, and
  never copy a per-unit scenario into it.

**Inputs**: the tracker item and `spec/plans/stories.md` for acceptance criteria,
`spec/plans/requirements.md` for the `Covers` REQ-IDs, `spec/plans/architecture.md` for design
constraints, and the approved design artifacts under `spec/plans/`.

---

## 3. Part B — the manual test plans

🔴 **INVOKE the `ve-implement` skill in WORKFLOW MODE — never re-implement it.** Same rule as every
other skill this framework reaches for: the mechanics live in ONE place
(`agents/ve-implement-agent.md` + `implementation/test-plan.md`), so the manual and automatic paths
cannot drift.

For **each** work unit in scope, invoke the skill (Skill tool) with that story/ticket and
**`mode: workflow`**. Per its Mode Detection table that run:

- takes the work unit **as given** — its story-picker is never presented,
- 🔴 **cuts no `ve/…` branch, pushes nothing, raises no PR** — the generated files stay in the
  working tree and ride **this stage's own design commit**,
- auto-confirms `implementation/test-plan.md` Step 2's applicability table (announced, not asked) and
  **skips its Step 6 Approve/Request-Changes checkpoint** — this stage's own approval (Section 4)
  covers the whole set instead,
- still writes `spec/test-plans/<TICKET-ID>-<title>/` and its `runtime-artifacts/audit.md` entry
  exactly as usual, stamped
  `Mode: workflow (invoked by the STOP CHECKPOINT specs & test-plans stage) — no Verification Engineer approval, no Verification Engineer branch, no Verification Engineer PR`.

**Already present** → reuse as-is and say so; never overwrite a folder ve already produced.

🔴 Every rule of `implementation/test-plan.md` still binds — black-box derivation from acceptance
criteria, the `TC-[PLAN]-[nn]` format, the System Under Test precondition block, and the blocking
AC-coverage check. Skipping an approval never skips a check.

---

## 4. The approval — ONE gate for the whole set

Present the **standardized 2-option completion message** below, then **WAIT**. 🔴 Do not invent a
3-option menu, and do not proceed on silence.

```markdown
# Behaviour Specs & Test Plans Complete

 Behaviour contracts: [N] file(s) in `spec/behavior/` — [S] scenarios across [A] acceptance criteria
 Manual test plans:   [N] folder(s) in `spec/test-plans/` — [T] test cases
 AC coverage: [A]/[A] acceptance criteria have at least one scenario AND at least one test case

[One line per work unit: unit — scenarios/ACs — test plans generated, plans marked N/A with reasons]

> **<u>REVIEW REQUIRED:</u>**  
> Behaviour contracts: `spec/behavior/`
> Manual test plans:   `spec/test-plans/`

> ** <u>**WHAT'S NEXT?**</u>**
>
> **You may:**
>
> **Request Changes** - Ask for modifications to any scenario, test case, or coverage gap  
> **Continue to Next Stage** - Approve and proceed to the Development Handoff

---
```

- **Request Changes** → apply the change to the named `.feature` file(s) and/or test-plan file(s),
  re-run the coverage check below, re-present this message, and return to this gate. Repeat until the
  user approves.
- **Continue to Next Stage** → record the approval and proceed with the STOP CHECKPOINT.
- 🔴 Log the prompt before presenting it and the user's **complete raw response** after receiving it,
  per `common/audit-logging.md`.

### 4.1 Blocking coverage check — runs BEFORE the message is presented

Silent, automatic, and blocking — no user prompt:

1. **Every acceptance criterion of every in-scope work unit has ≥1 `@AC-<n>`-tagged scenario.** A
   missing scenario is a gap: write it, then re-check.
2. **Every acceptance criterion has ≥1 manual test case tracing to it** (`implementation/test-plan.md`
   Step 5's coverage table). A gap is fixed by extending the plan, then re-checking.
3. **Every work unit in scope has a `.feature` file** and a `spec/test-plans/<…>/` folder, or an
   explicitly recorded reason it does not (`common/behavior-spec.md`'s `N/A` rule for a unit with no
   externally observable behaviour — a unit with acceptance criteria is never `N/A`).

Do not present the Section 4 message until all three hold.

---

## 5. Downstream contract — the implement workflows VERIFY, they do not author

`dev-implement`, `bug-fix-implement` and `enhancement-implement` **read** these artifacts; they no
longer create them on the happy path.

**At the point each workflow used to write the spec** (`dev-implement` Step 4.5,
`bug-fix-implement` Step 4.5, `enhancement-implement` Step 11.5) and **at its test-plans step**
(`dev-implement` Step 6.7 part 1, `bug-fix-implement` Step 7.7 part 1,
`enhancement-implement` Step 14.7 part 1), the workflow instead:

1. **Verifies the artifact exists** for this work unit, and announces it —
   ` Behaviour contract: spec/behavior/<key>.feature ([n] scenarios, [n] ACs) — written and approved at the STOP CHECKPOINT.`
2. **Reads it as the contract** and implements against it. 🔴 **Never rewrite it to match the code.** A
   scenario changes only when the AC or requirement it encodes genuinely changed — and then the AC,
   `requirements.md` and the tracker item are amended together and the reconciliation is logged
   (`common/behavior-spec.md` Section 6.3, SH-6).
3. 🔴 **BACKFILL — only when the artifact is genuinely absent** (a project that predates this stage, a
   work unit added after the STOP CHECKPOINT, or an interrupted run): create it **now**, following
   Section 2 / Section 3 of this file, **announce the backfill explicitly**, log it in
   `runtime-artifacts/audit.md` with the reason, and continue. A backfilled artifact gets **no**
   approval gate inside the implement workflow — those workflows have no approval gates, and adding
   one here would reintroduce a gate the framework deliberately removed.

🔴 **A missing artifact is never a reason to halt a work unit**, and never a reason to skip its gate:
the behavioural gate (B1) and the ve's test plan both still apply, backfilled or not.

---

## 6. 🔴 Tier activation — what this stage changes about B2/B3

**Before this stage existed, `spec/behavior/` only ever contained feature files for units that were
already built**, so "every OTHER feature file" (B2) was, by construction, a set of scenarios that had
passing step definitions behind them. Authoring every unit's contract up front breaks that
assumption: on story 1.1's branch, `spec/behavior/` now also holds 1.2 … 1.N, whose code does not
exist yet.

**So a feature file is only ACTIVE for B2/B3 once its work unit has been implemented**, resolved by
`tests/.evals/behavior/run.sh` from the **resolved** Story Tracker — the shared `## Story Tracker` in `runtime-artifacts/aire-state.md` plus every `runtime-artifacts/stories/*/state.md` fragment (`common/parallel-work-state.md` Section 4), because claims live in the fragments:

| Tracker state of that unit | In B2/B3? |
|---|---|
| `Ready for Development` (not started) | 🔴 **No** — excluded, and named in the run's output |
| `In Development` / `Ready for Testing` | Yes |
| No row in the shared table or any fragment, or no state file at all | Yes (conservative — preserves legacy behaviour) |

- **B1 is unaffected** — it runs THIS unit's own contract, named by `AIRE_STORY_KEY`.
- **An empty active set is an earned `N/A`** (exit 3), not a failure: correct for the first story of a
  cycle, where every other unit is still `Ready for Development`.
- **A branch that is not a work unit** — a `ci/**` infrastructure branch (the epic pre-handoff smoke
  PR) or a `ve/**` test-docs branch — has no contract of its own, so **every tier is `N/A`** there.
  This is what keeps the zero-diff smoke test honest now that feature files exist before any story:
  `common/ci-pipeline-generation.md` Section 4.0.6 already states the smoke test does **not** validate
  the behaviour tiers.

🔴 The rule lives in `run.sh` **once**, so the developer's local gate and CI resolve the identical
tier membership — never duplicated in YAML, and never re-derived by a workflow.

---

## 7. Where the artifacts go, and when they are committed

Both artifact sets are written on the **cycle branch** (epic / bug / enhancement) and committed with
the rest of the STOP CHECKPOINT artifacts in the design commit — `CLAUDE.md` MANDATORY STOP Step 3,
`bug-fix.md` Step 9 Item 1, `enhancement-implement.md`'s ve Handoff Break Item 1. That push is what
unblocks the ve (`common/directory-structure.md` — Artifact Ownership).

```text
spec/
├── behavior.feature              # cycle-level cross-unit journeys — written EARLIER in the checkpoint
├── behavior/                     # THIS stage, Part A — one file per work unit
│   ├── story-1.1.feature
│   └── story-1.2.feature
└── test-plans/                   # THIS stage, Part B — one folder per work unit
    └── PROJ-101-user-can-reset-password/
        ├── test-plan-summary.md
        └── <plan>-test-steps.md
```

---

## 8. State and audit

Record in `runtime-artifacts/aire-state.md`:

```markdown
## Behaviour Specs & Test Plans
- **Work units covered**: [N]
- **Behaviour contracts**: spec/behavior/ — [N] file(s), [S] scenarios
- **Manual test plans**: spec/test-plans/ — [N] folder(s), [T] test cases
- **AC coverage**: [A]/[A] (scenarios) · [A]/[A] (test cases)
- **Approved**: [ISO 8601 timestamp]
```

Log in `runtime-artifacts/audit.md`, per `common/audit-logging.md`: the stage entry, every
`ve-implement` WORKFLOW MODE invocation, the coverage-check outcome, the approval prompt (before
presenting) and the user's complete raw response (after receiving).

---

## Critical Rules

- 🔴 **Every work unit gets BOTH artifacts, before any code** — the `.feature` contract and the manual
  test plan. A unit with acceptance criteria is never `N/A` for either.
- 🔴 **ONE approval for the whole set**, in the standardized 2-option format. Never a 3-option menu,
  never per-unit approvals, never silent completion.
- 🔴 **Part B INVOKES the `ve-implement` skill in WORKFLOW MODE** — never re-implemented inline, and
  never presented afterwards as ve sign-off.
- 🔴 **The implement workflows VERIFY these artifacts; they never regenerate them** and never rewrite a
  scenario to match code that was written later. Backfill only a genuinely absent artifact, announced
  and logged.
- 🔴 **A feature file is ACTIVE for B2/B3 only once its unit is implemented** (Section 6). An empty
  active set, a `ci/**` branch and a `ve/**` branch are all earned `N/A`, never a failure.
- 🔴 **Both sets are committed on the cycle branch with the design artifacts** — the ve cannot start
  until that push lands on origin.
