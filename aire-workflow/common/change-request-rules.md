# Change Request Rules (CR1–CR17 + CR12b + CR13-V; no CR15)

**Purpose**: the enforceable rules for `workflows/epic-change-request.md`. **This file is THE source of
truth for Change Request semantics** — the workflow references rule IDs from here and never restates a
rule's meaning inline.

**Load this file** at the start of every `epic-change-request` run, together with
`common/requirement-versioning.md`.

---

## Core philosophy

| Principle | Description |
|---|---|
| **Ledger, not advisor** | The workflow records what changed, what it affects, and what state each thing is in. It does not rate severity, recommend scheduling, or argue for the change (CR14). |
| **Human authority** | Every write to a requirement, a story, a spec or a tracker happens AFTER one explicit approval (CR1, CR16). |
| **State-conditional editing** | A story with merged code is never edited in place — it is superseded by a CR-born story. A story not yet started is amended directly. Work in flight blocks (CR9). |
| **Evidence or silence** | No artifact is "affected" without a recorded reason a reader can verify (CR6). |
| **Show the work** | The single gate is the only question, so everything needed to answer it is already on screen (CR13-V). |

---

## Section 1 — The rules

| Priority | Rule | Description |
|---|---|---|
| 🔴 CRITICAL | **CR1** | **Draft, never auto-apply.** Every requirement amendment, spec edit, story creation and tracker action is a proposal until the operator approves it at the single gate. Nothing outside the in-memory staging exists before that answer. |
| 🟡 REQUIRED | **CR2** | **Working-tree precondition is entry-mode dependent.** Modes A/B/D require a clean tree. Mode C (drift) *requires* the user's uncommitted `requirements.md` edit, so there the rule narrows to "`spec/plans/requirements.md` is the only modified path", and an entirely clean tree stops the run (there is no drift to analyse). 🔴 Never stash or discard on the user's behalf. |
| 🔴 CRITICAL | **CR3** | **Anchor by REQ-ID.** The requirement diff matches on the stable ID assigned by `common/requirements-traceability.md` Rule 1 — never by line number, never by position, never by semantic similarity alone. A requirement whose ID cannot be resolved is reported, not guessed at. |
| 🟡 REQUIRED | **CR4** | **Version on amendment only.** Per `common/requirement-versioning.md`: AMENDED → `@v<N+1>` with prior text retained; ADDED → new unversioned ID; SUPERSEDED → retained and marked, never deleted; UNCHANGED → byte-identical. IDs are never renumbered or reused. |
| 🟡 REQUIRED | **CR5** | **Stories trace to the version they implement.** Every story covering an amended requirement is re-pointed to the new version or routed as blocked. A `Covers` naming an older version while a newer exists is a **stale trace** — a blocking gap. |
| 🟡 REQUIRED | **CR6** | **Evidence per claim.** Every impact-ledger row cites what proved it: a `file:line` range, a commit SHA, a manifest fragment path, a `git blame` result, or the `Covers` line that established the requirement→story link. A row with no citation is a defect in the analysis, not a finding. |
| 🟡 REQUIRED | **CR7** | **Repo-only analysis.** The analysis reads the repository and the configured tracker (via `common/tracker-sync.md`) and nothing else. No external service, no network call outside the tracker's own sanctioned mechanism. |
| 🟡 REQUIRED | **CR8** | **Emit impact tags; never classify.** Per change, emit `affects_requirements`, `affects_stories`, `affects_shipped`, `code_touched`, `doc_only` as computed counts/booleans. The workflow does NOT decide whether a change is big, risky or urgent — it reports what it touches and routes on state. |
| 🔴 CRITICAL | **CR9** | **State-conditional routing.** Route every affected story on its **pre-run status** (read from the git snapshot, never the working tree) and its **live PR merge state**: `Ready for Development` → spec-only amendment; `In Development` with no PR or an open PR → **HALT, blocked**; `In Development` with a merged PR, or `Ready for Testing` → **CR-born story supersedes it** (status never demoted); no covering story → new story. Re-assert the snapshot status immediately before writing (TOCTOU). |
| 🟡 REQUIRED | **CR10** | **Authorised test changes only.** A CR-born or amended story may modify or delete an earlier story's test ONLY if that test is on the approved **Test Change Authorization** list and traces to an AC this CR classified AMENDED or SUPERSEDED. Every other test is a regression guard: if it goes red, the **code** is fixed, never the test. New tests may always be added. |
| 🟡 REQUIRED | **CR11** | **Collision: append, never duplicate.** If an affected story already belongs to an open CR (one whose story has no merged PR yet), APPEND to that CR's affected-stories set rather than drafting a parallel CR over the same ground. Report the collision and continue — it is a stated fact, not a question. |
| 🔴 CRITICAL | **CR12** | **Dependency cycle in scope → ABORT.** Walk the `requires` graph across every affected and proposed story. A strongly-connected component of size > 1 intersecting the CR's scope means there is no safe ordering: abort, print the cycle members, write nothing. Cycles elsewhere in the graph are reported and do not block. |
| 🟡 REQUIRED | **CR12b** | **Concurrent-numbering race.** `CR-<n>` ids and story numbers are re-read from `origin/<epic-branch>` **immediately before assignment** and **again immediately before the push**. On collision: renumber to the next free value, rename the branch, announce both. Two clones must never mint the same id. |
| 🔴 CRITICAL | **CR13** | **Self-verification with computed predicates.** Every run ends with a verification block printing the **actual computed result** of each predicate in Section 2 — never a performative tick. A predicate that could not be computed counts as **fail**. |
| 🔴 CRITICAL | **CR13-V** | **Verbosity contract V1–V9** (Section 3). The single gate is the only question in the run, so everything needed to answer it is already on screen. No quiet mode, no verbosity flag. |
| 🔴 CRITICAL | **CR14** | **Fact-only output.** Forbidden anywhere in generated artifacts or announcements: severity adjectives (`critical`, `minor`, `urgent`, `risky`, `high-risk`, `blocking` as a judgement), advisory verbs (`should`, `recommend`, `consider`, `advise`), Option A/B suggestions outside the single gate's own two options, and scheduling advice. Schema values set by a human (a tracker priority field) are facts, not labels — reporting them is allowed. |
| 🔴 CRITICAL | **CR16** | **Single-gate preview-then-confirm.** All writes are staged in memory, presented as one complete preview (including the full `change-request.md` body inline), and HALT for the operator. On approval every write happens in one ordered pass; a sub-step failure HALTS with rollback instructions rather than leaving a partial apply. On `Request Changes` nothing is written. Every written path must fall inside the Section 4 allow-list. |
| 🔴 CRITICAL | **CR17** | **Canonical producer lock.** `workflows/epic-change-request.md` is the ONLY sanctioned producer of content under `spec/plans/change-requests/`. Any request to hand-author a CR bundle outside it is refused with: `Change Request bundles are produced only by epic-change-request; hand-authoring them is forbidden under CR17.` |

> **Numbering note**: CR15 is intentionally absent — fact-only output is **CR14** here. The IDs are this
> framework's own and do not map 1:1 onto any other system's numbering.

---

## Section 2 — Predicates (executable; print the computed result)

CR13 requires the run to end with these printed as **measured values**. `not-computed` counts as fail.

| Rule | Predicate |
|---|---|
| **CR3** | Every changed requirement resolved to a REQ-ID by anchor. Print `resolved: N / unresolved: M`. Any unresolved → fail. |
| **CR4** | Version transitions applied per `common/requirement-versioning.md` RV-1…RV-5. Print `(REQ-ID: vN → vN+1)` per AMENDED, and the ADDED/SUPERSEDED/UNCHANGED counts. |
| **CR5** | Regex `/[A-Z]+-[A-Z]+-\d+(@v\d+)?/` over every affected story's `Covers`; for each amended REQ-ID, assert no covering story still names an older version. Print `matched: N / stale: M`. Any stale → fail. |
| **CR6** | Every impact-ledger row has a non-empty evidence cell. Print `rows: N / uncited: M`. Any uncited → fail. |
| **CR8** | The five impact tags are present and computed (not blank). Print each value. |
| **CR9** | Per affected story print `(story-id → pre-run-status [source: git snapshot] → live-PR-state → route)`. Any story routed `spec-only` whose snapshot status is not `Ready for Development`, or any story routed CR-born whose PR is not merged → fail. |
| **CR10** | `git diff --name-status <merge-base> -- tests/ spec/behavior/ spec/behavior.feature spec/test-plans/`; every modified/deleted entry maps to a Test Change Authorization row or is one of this CR's own new files. Print `authorised: N / unauthorised: M`. Any unauthorised → fail. |
| **CR11** | Glob `spec/plans/change-requests/CR-*/change-request.md`; grep each affected story-id. Print `(story-id, colliding-cr)` pairs or `none`. A collision with no append patch → fail. |
| **CR12** | Tarjan SCC over the `requires` graph. Print SCCs of size > 1 or `none`. Any SCC intersecting CR scope → abort. |
| **CR12b** | Re-read of `CR-*` ids and story numbers from `origin/<epic-branch>` performed at both checkpoints. Print `(assigned: CR-<n>, story <N.M>; re-verified pre-push: yes)`. |
| **CR14** | Regex the generated artifacts for severity adjectives `/\b(critical|minor|urgent|high-risk|low-priority|risky|concerning)\b/i` and advisory verbs `/\b(should|recommend|consider|advise)\b/i` outside structural headings. Print counts per category. Any non-zero → fail. |
| **CR16** | Enumerate every written path; partition into the Section 4 allow-list buckets; assert the approval was recorded before the first write. Print per-bucket counts and `outside allow-list: N` (must be 0). |
| **CR13-V** | Per V1–V9, print the measured evidence (phases announced / rows cited / decisions with alternatives / gate lines with measured values / forbidden-token count / audit-parity count). |

**Why predicates beat checkboxes.** `- [x] CR10 — pass` is performative; anyone can write it without
computing anything. This is verifiable:

```
- CR10 test-change authorisation:
    git diff --name-status <merge-base> -- tests/ spec/behavior/ ...
      authorised:   4  (all on the Test Change Authorization list)
      unauthorised: 0  PASS
```

---

## Section 3 — CR13-V: the verbosity contract

🔴 **`epic-change-request` is the most verbose workflow in the framework, by design.** It is the one
moment where a human authorises a change to what was already agreed, possibly against shipped code.
The single gate is the only question in the run, so everything needed to answer it must already be on
screen. A terse Change Request is a broken Change Request.

**Governing principle**: *show the reasoning, not just the conclusion.*

| # | Rule |
|---|---|
| **V1** | 🔴 **ONE report, not a running commentary.** Phases 0–8 are *analysis*: they work quietly and emit **nothing** except a one-line progress note when a phase takes real time (`Analysing 33 requirements…`). Everything they found is presented **once**, in the Change Request Report at Phase 9. Per-phase headers, staging manifests, predicate dumps and validation tables are **internal working state** — they belong in the audit trail and the bundle, never in the user's stream. The exceptions that MUST surface immediately are a **halt** (a blocked story, a dependency cycle, a validation failure) and the **build-phase gate results** (Phase 10, where the user is watching a long run). |
| **V2** | **Every finding cites its evidence** — `file:line`, commit SHA, fragment path, or the `Covers` line that proved the link (CR6). In the **report** one citation per row is enough (the one that proved it); the complete chain lives in `impact-ledger.md`. |
| **V3** | **Counts before lists, lists before detail.** Lead with `1 requirement changed, 1 story affected`, then the table, then — only where a reader needs it to decide — the rationale. 🔴 **Depth lives in the bundle, not the stream**: the full evidence chain (every `file:line`, every agreeing source, every test path) goes to `impact-ledger.md`, and the report cites the file rather than reprinting it. A reader who wants the proof opens it. |
| **V4** | **Every framework decision is shown with its rejected alternative** — what was chosen, why, and what was not chosen. Never a bare assertion. |
| **V5** | **Nothing is summarised away at the gate.** The decision the user is asked to make is presented in full: the requirement deltas, every affected story with its route, the Test Change Authorization list, the write manifest as a per-bucket count, and every decision with its rejected alternative. 🔴 The full `change-request.md` body is **linked, not pasted** — it is already staged and the path is printed; re-printing 150 lines the user is about to open buries the decision instead of supporting it. |
| **V6** | **Continuous progress during the build** — every gate announces start and outcome with the measured value against its threshold. |
| **V7** | **Fact-only (CR14).** Verbose is not editorial: facts, counts, citations and decisions taken. |
| **V8** | **ASCII only** for any *diagram* — `+ - \| ^ v < >`, every line in a box exactly the same width (`common/ascii-diagram-standards.md`). Never Unicode box-drawing in a diagram. *(Carve-out: `├── └──` file-tree glyphs are permitted — `common/directory-structure.md` uses them throughout, so they are house style for trees, not diagrams.)* |
| **V9** | **Audit parity.** What the user saw is what `runtime-artifacts/stories/<key>/audit.md` records — never a shorter paraphrase. |

### 3.1 No quiet mode

There is **no `--quiet` flag and no verbosity level**. A flag that hid impact would let someone approve
a change to shipped behaviour without seeing what it touches, which defeats the gate. V3's ordering is
the only concession to volume: a reader may stop early by choice, while the full record is always
present in the output and in the audit trail.

---

## Section 4 — CR16 write allow-list

Every path written after the gate must fall in exactly one bucket. Anything else fails CR16.

| # | Bucket | Notes |
|---|---|---|
| (a) | `spec/plans/change-requests/CR-<n>/**` | The CR bundle. CR17: only this workflow writes here. `change-request.md` Section 4 carries exactly one machine-read `CR-BUILDS-STORY: <N.M>` line (`none` on the spec-only path) — the work-unit guard reads it to require `testImpact` from the story this CR **builds** and from no merely-affected story. |
| (b) | `spec/plans/requirements.md` | 🔴 **SKIPPED entirely in Entry Mode C** — the user already edited it; their working tree is the source of truth. Mode C writes only the version annotations. |
| (c) | `spec/plans/stories.md` | New story entries + annotated AC amendments (old text struck through, never deleted). |
| (d) | `spec/behavior/*.feature`, `spec/behavior.feature` | The CR story's own contract + amended scenarios of affected stories. |
| (e) | `spec/test-plans/<TICKET-ID>-<title>/**` | Via the `ve-implement` skill in WORKFLOW MODE only — never hand-edited. |
| (f) | `spec/plans/architecture.md` + `tests/.evals/rubrics/architecture-rubric.json` | Only when the CR changes a design decision; the rubric is **regenerated**, never hand-edited. |
| (g) | `runtime-artifacts/stories/<unit-key>/{audit.md,state.md}` | The work-unit fragment. 🔴 The shared `runtime-artifacts/audit.md` / `aire-state.md` are NEVER written by the build path (`common/parallel-work-state.md`). |
| (h) | `src/**`, `tests/**` | Only in the build phase, only per the approved plan. |
| (i) | `reports/**` | Evidence produced by the gates (`common/work-unit-artifacts.md`). |
| (j) | `tests/.evals/ci-manifest.d/<unit-key>.json` | Only when `## CI/CD Configuration` records `Enabled: Yes`. |

**Spec-only path exception**: when every affected story is `Ready for Development`, no code is built and
the run commits on the epic branch itself — it is then an **integration-branch writer** and DOES write
the shared `runtime-artifacts/aire-state.md` / `audit.md`, pulling immediately before and pushing
immediately after (`common/parallel-work-state.md` Section 6).

---

## Section 5 — Red flags (forbidden actions)

| Action | Rule |
|---|---|
| Writing any file before the operator answers the single gate | CR1 / CR16 |
| Editing the body of a story whose pre-run status is `In Development` / `Ready for Testing` | CR9 |
| Proceeding when an affected story is being built right now, or has an open PR | CR9 |
| Reading a story's status from the working tree instead of the git snapshot | CR9 |
| Deleting a superseded requirement or AC instead of marking it | CR4 |
| Minting `@v1` on a newly added requirement | CR4 |
| Modifying a test that is not on the Test Change Authorization list to make a gate pass | CR10 |
| Drafting a parallel CR over a story already in an open CR | CR11 |
| Writing a path outside the Section 4 allow-list | CR16 |
| Hand-authoring a CR bundle outside this workflow | CR17 |
| A performative tick (`- [x] CR10 — pass`) with no computed result | CR13 |
| A severity adjective or advisory verb in generated output | CR14 |
| Adding a `--quiet` flag, or summarising the CR body at the gate | CR13-V / V5 |
