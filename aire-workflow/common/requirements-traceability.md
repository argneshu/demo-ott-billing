# Requirements Traceability (REQ-ID Thread)

## Purpose
Requirement fidelity is enforced by ONE unbroken thread of stable requirement IDs, carried from `requirements.md` through the stories, through the post-design verification, and into every story's code-generation plan and code review. Without this thread, decomposition loss (requirements silently dropped or diluted between stages) is invisible to every downstream gate — each gate would only verify the previous stage's *derived* artifact against itself.

## Enforcement Mode — automatic, silent, blocking
**Every check in this file is AUTOMATIC and BLOCKING**:
- It runs silently INSIDE an existing stage — it NEVER adds a new approval gate, user question, or workflow stage.
- A failed check is fixed by the AI in the same interaction (regenerate/extend the deficient artifact) and re-checked BEFORE the stage's existing completion message is presented.
- Each check's outcome (pass, or gap found + fix applied) is logged in `runtime-artifacts/audit.md` per the standard audit format appended at the end.

---

## Rule 1 — REQ-IDs at the source (Requirements Analysis)
`spec/plans/requirements.md` MUST assign a stable ID to EVERY requirement:
- Functional: `REQ-F-01`, `REQ-F-02`, …
- Non-functional: `REQ-NF-01`, `REQ-NF-02`, …

IDs are permanent: never renumbered, never reused after removal. Every later artifact refers to requirements ONLY by these IDs.

**Versioned IDs (`REQ-F-03@v2`)**: a requirement amended MID-CYCLE by a Change Request carries a version suffix per `common/requirement-versioning.md`. This does NOT change Rule 1 — the ID is still permanent and still never reused; the suffix records which revision of that requirement's text is current. 🔴 Requirements Analysis mints **plain, unversioned** IDs and nothing else; only `workflows/epic-change-request.md` ever mints a version. An unversioned ID always means v1, and a project that never ran a Change Request contains no suffixes at all.

## Rule 2 — Stories MUST carry coverage (User Stories)
Referencing requirements from stories is **MANDATORY, never optional** ("if requirements exist, reference them" is superseded — Requirements Analysis always executes, so requirements always exist):
- EVERY story in `stories.md` carries a `**Covers**: REQ-F-xx, REQ-NF-yy` line naming the requirement(s) its acceptance criteria implement (an AC-level breakdown `AC-n → REQ-ID` is encouraged for multi-requirement stories).
- A story with an empty `Covers` line is invalid — either it implements a requirement (name it) or it is scaffolding another story needs (cover it under that requirement's ID).
- A `Covers` entry MAY carry a version suffix (`REQ-F-03@v2`) — and does, for every requirement a Change Request has amended (`common/requirement-versioning.md` Section 4). An entry without a suffix means v1. **Every consumer normalises the suffix away before matching IDs**, so a reader that knows nothing about versions is never wrong.

## Rule 3 — Full-coverage check at story generation (before the story-set approval is presented)
After all stories are generated and BEFORE the story set is announced (and gated behind GATE 1 approval prior to being pushed to the configured tracker):
1. Build the coverage matrix: every `REQ-ID` in requirements.md → the story ID(s) whose `Covers` names it. **Match on the bare ID — strip any `@vN` suffix from both sides first** (`common/requirement-versioning.md` Section 5), so `REQ-F-03` and `REQ-F-03@v2` are one requirement, not two. A requirement marked SUPERSEDED by a Change Request is excluded from step 2's gap check and recorded `N/A` with the CR that withdrew it.
2. **Blocking gap A — uncovered requirement**: any REQ-ID with ZERO covering stories → add/extend stories automatically, then re-check.
3. **Blocking gap B — partial coverage**: for each REQ-ID, the UNION of its covering stories' acceptance criteria must express the requirement's full end-to-end behavior (including cross-story seams: if a requirement is split across stories for parallelism, the integration behavior between the slices must be owned by an explicit AC on one of them). Diluted/partial expression → strengthen the ACs automatically, then re-check.
4. Append the coverage matrix to `stories.md` (section `## Requirements Coverage Matrix`: REQ-ID | covering stories | status  Full) and include a one-line coverage summary in the stage completion message (e.g., ` Requirements coverage: 12/12 REQ-IDs fully covered by story ACs`).

## Rule 4 — Post-design coverage re-verification (after the LAST design stage, before the STOP CHECKPOINT handoff)
The system-level design stages (Functional/NFR/Infrastructure) may refine or contradict behavior the stories assumed — and stories were written BEFORE design. Therefore, after the last executed design stage is approved (or immediately when ALL design stages are skipped), automatically:
1. Re-verify the coverage matrix (Rule 3) against the approved design artifacts under `spec/plans/`.
2. Reconcile in place any story AC the design contradicted or refined (update `stories.md` + the matrix; log every reconciliation in runtime-artifacts/audit.md with the design artifact that drove it).
3. Record in `runtime-artifacts/aire-state.md`: `Requirements coverage verified post-design: [R]/[R] REQ-IDs — [timestamp]`.
4. Report the coverage line in the Development Handoff message.

**Fallback**: if `dev-implement` is invoked and `runtime-artifacts/aire-state.md` carries NO post-design verification record, run this rule's check first (scoped verification, silent) before Story Selection planning proceeds — the thread must never reach code generation unverified.

## Rule 5 — Plan-level trace (Code Generation Part 1 / dev-implement)
The per-story code-generation plan MUST:
1. Load `requirements.md` and resolve the story's `Covers` REQ-IDs — the requirement text (not just the story's AC restatement) is planning input.
2. Tag EVERY plan step with the REQ-ID(s) and acceptance criteria it implements (`(REQ-F-03, AC-2)`).
3. **Self-check completeness before the plan is announced**: every REQ-ID in `Covers` and every AC of the story appears in ≥1 plan step. A REQ/AC with no plan step is a blocking gap — extend the plan, then re-check. Include the trace summary in the plan document.

## Rule 6 — Review against the thread (Code Review)
"Mapped requirements" in the Code Review scope means EXACTLY the story's `Covers` REQ-IDs. The review verifies the code against each covered REQ-ID as written in `requirements.md`, in addition to the story's own acceptance criteria — an AC set that is a weaker statement than its requirement does not cap the review. When a `Covers` entry carries a version (`REQ-F-03@v2`), the review reads that requirement's **current text in `requirements.md`** — which is the amended text; the struck-through prior revision retained beneath it is provenance, never the thing reviewed against.

## Rule 7 — Single-story flows (enhancement / bug)
- **Enhancement**: the single story's `Covers` names the REQ-IDs from the enhancement-scoped `requirements.md`; plan steps are tagged per Rule 5.
- **Bug**: the "requirement" is the expected behavior in `spec/plans/bug-brief.md` — plan steps trace to the brief's expected-behavior statements and the impact-analysis entries instead of REQ-IDs.

## Rule 8 — Mid-cycle requirement amendment (Change Request)
A requirement may change AFTER the story set was approved — a new regulation, a corrected assumption, a decision reversed. That change is made ONLY by `workflows/epic-change-request.md`, and it MUST close the thread it opens:

1. **Version the requirement** per `common/requirement-versioning.md`: AMENDED → `@v<N+1>` with the prior text retained; ADDED → a new unversioned ID; SUPERSEDED → retained and marked, never deleted. 🔴 Rule 1 still binds — no ID is renumbered or reused.
2. **Re-point every affected story's `Covers`** to the new version, or route that story as blocked. A `Covers` naming a superseded version while a newer one exists is a **stale trace** and a blocking gap of the same class as Rule 3's gap A.
3. **Rebuild the Rule 3 coverage matrix** over the amended requirement set (normalising `@vN`, excluding SUPERSEDED requirements from the gap check) and re-append it to `stories.md`.
4. **Refresh the Rule 4 record** in `runtime-artifacts/aire-state.md`: `Requirements coverage verified post-design: [R]/[R] REQ-IDs — [timestamp] (re-verified after CR-<n>)`. 🔴 Without this the record silently describes a requirement set that no longer exists, and Rule 4's fallback makes the next `dev-implement` re-derive it.
5. **Rule 5 applies unchanged** to the CR's own story: every plan step is tagged with the REQ-ID(s)/AC(s) it implements, including the newly versioned ones.

Enforcement is the same as every other rule here — automatic, silent, blocking, fixed in the same interaction and logged. This rule is scoped to the epic (cycle) flow; the single-story flows keep Rule 7.
