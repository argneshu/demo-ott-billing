# Requirement Versioning (`REQ-ID@vN`)

**Purpose**: the single source of truth for how a requirement that changes **mid-cycle** is versioned,
how stories trace to the version they implement, and how the coverage matrix reads a versioned ID.

**Load this file when**: amending `spec/plans/requirements.md` after the story set has been approved —
i.e. from `workflows/epic-change-request.md`. Nothing else in the framework mints a version.

> 🔴 **This file adds a suffix to an existing model; it does not replace it.** Every rule in
> `common/requirements-traceability.md` still binds — Rule 1's "IDs are permanent: never renumbered,
> never reused after removal" most of all. A version is not a new ID.

---

## 1. The rule in one line

**A requirement carries no version until a Change Request amends it.** The first amendment makes the
amended text `@v2`; the original text is retained in place as `@v1`.

```
REQ-F-03                         <- authored by Requirements Analysis. No suffix. This is v1.
REQ-F-03@v2                      <- after CR-1 amended it. REQ-F-03@v1 text retained below it.
REQ-F-03@v3                      <- after a later CR amended it again.
```

- An **unversioned** `REQ-F-03` in any artifact means **v1**. It is never an error, never a migration
  target, and never rewritten by a CR that did not touch that requirement.
- 🔴 **A version is never minted outside `epic-change-request`.** Requirements Analysis, User Stories,
  the design stages and every implement workflow write plain IDs, exactly as they do today.

### 1.1 Why amendment-only (and not versions everywhere)

Versioning every requirement from authoring time would touch `planning/requirements-analysis.md`,
`planning/user-stories.md`, Rules 1–6 of `common/requirements-traceability.md`, the Code Review scope
and **every existing project's `requirements.md` and `stories.md` on disk**. Amendment-only versioning
is a pure superset: a project that never runs a Change Request is byte-identical to one on the previous
framework version, and a reader who has never heard of `@vN` reads `REQ-F-03` and is correct.

---

## 2. The four classifications

A Change Request classifies every requirement it touches as exactly one of:

| Class | Meaning | What happens to the ID | What happens to the text |
|---|---|---|---|
| **UNCHANGED** | Not touched by this CR | Nothing — stays unversioned (or keeps its current `@vN`) | Untouched, byte-identical |
| **AMENDED** | The requirement still exists, but says something different | `@v<N+1>` | New text becomes current; prior text **retained**, struck through, annotated |
| **ADDED** | A genuinely new requirement | New `REQ-F-<next>` / `REQ-NF-<next>`, **unversioned** | New text only — it has no history to retain |
| **SUPERSEDED** | The requirement is withdrawn | Keeps its ID and current version | Text retained, marked superseded — 🔴 **never deleted** (Rule 1 forbids reuse of a removed ID, so the record must stay visible) |

🔴 **`ADDED` never produces `@v1`.** A brand-new requirement is unversioned, consistent with everything
Requirements Analysis authors. Writing `REQ-F-12@v1` is a defect.

---

## 3. How an amendment is written into `requirements.md`

The amended requirement stays in its original position in the file. It is not moved, and the file is
not re-sorted.

```markdown
### REQ-F-03@v2 — Payment approval threshold

Payments above **5000 USD** require a supervisor approval before submission.

> **Amended by CR-3 on 2026-09-25** (was REQ-F-03, threshold 1000 USD).
> Prior text (v1), retained for traceability:
> ~~Payments above 1000 USD require a supervisor approval before submission.~~
```

A superseded requirement:

```markdown
### REQ-F-07 — Single-approver fast path  *(SUPERSEDED)*

> **Superseded by CR-3 on 2026-09-25.** Withdrawn; the behaviour it described no longer applies.
> Retained because Rule 1 forbids reusing a removed requirement ID.
> ~~Payments below the threshold may be approved by the submitting user alone.~~
```

Rules:
- The heading carries the current version; the annotation block carries the provenance.
- Prior text is struck through, never removed — a reader must be able to see what changed without
  consulting git.
- Every annotation names the **CR id** and the **date**, and nothing else. No severity, no rationale
  adjectives (`common/change-request-rules.md` CR15).

---

## 4. How stories trace to a version (extends Rule 2)

A story's `**Covers**:` line names the version it implements **only for requirements a CR has amended**:

```markdown
**Covers**: REQ-F-03@v2, REQ-F-07, REQ-NF-02
             ^^^^^^^^^^^  ^^^^^^^^^
             amended by a CR        never amended — stays unversioned
```

| Situation | What `Covers` says |
|---|---|
| Requirement never amended | `REQ-F-07` — unversioned, exactly as today |
| Story written **before** the CR, and the CR amended this requirement | The CR updates that story's `Covers` to `@vN` as part of its routing (spec-only amendment or CR-born story) |
| Story created **by** the CR | `@vN` from the start, for the requirements the CR amended |
| Requirement superseded | The covering story's AC is marked superseded; `Covers` keeps the ID so the trace is not lost |

🔴 **A story is never left tracing to a version that no longer exists.** If a CR amends `REQ-F-03` to
`@v2`, every story whose `Covers` names `REQ-F-03` is either updated to `@v2` or is routed as blocked —
that is the whole point of the CR's routing phase. A `Covers` entry naming `@v1` after `@v2` exists is
a **stale trace** and a gate failure.

---

## 5. How the coverage matrix reads versions (extends Rules 3 and 4)

The matrix is keyed by **bare REQ-ID**, never by versioned ID — otherwise `REQ-F-03` and `REQ-F-03@v2`
would look like two separate requirements and the "uncovered requirement" check would fire falsely.

```markdown
## Requirements Coverage Matrix
| REQ-ID | Current version | Covering stories | Status |
|--------|-----------------|------------------|--------|
| REQ-F-03 | @v2 (CR-3) | Story 3.1 | Full |
| REQ-F-07 | — (superseded by CR-3) | Story 2.4 (AC superseded) | N/A |
| REQ-F-11 | — | Story 3.2 | Full |
```

Matching rules:
1. **Normalise before comparing** — strip any `@vN` suffix from both sides. `REQ-F-03@v2` in a story's
   `Covers` matches the `REQ-F-03` row.
2. **Then verify the version** — a covering story whose `Covers` names an *older* version than the
   requirement's current one is reported as a **stale trace**, which is a blocking gap of the same
   class as Rule 3's gap A.
3. **A SUPERSEDED requirement is not an uncovered requirement.** It is excluded from the gap-A check
   and recorded `N/A` with the CR that withdrew it. Failing to exclude it would make every CR that
   withdraws a requirement permanently unable to pass its own coverage check.

---

## 6. Backward compatibility — what must NOT change

This is the contract that keeps the change a pure superset:

- 🔴 A project that never runs `epic-change-request` contains **no `@vN` anywhere** and behaves exactly
  as it did before this file existed.
- 🔴 No existing workflow, stage or skill is required to understand `@vN`. Every consumer that reads a
  REQ-ID **normalises first** (Section 5 rule 1), so an unversioned reader is never wrong — it simply
  reads the requirement's current text, which is what it wants.
- 🔴 `requirements-analysis.md`, `user-stories.md` and the design stages are **not modified** by this
  model. They mint plain IDs.
- 🔴 Code Review (`common/requirements-traceability.md` Rule 6) reads the requirement text **as
  currently written in `requirements.md`** — that is, the current version. A story tracing to `@v2` is
  reviewed against the `@v2` text. This needs no change to the review itself, because the current text
  is what the file holds at the top of the entry.

---

## 7. Self-check predicates (run by the CR that mints versions)

Printed with computed results, never as bare ticks:

| # | Predicate |
|---|---|
| **RV-1** | Every AMENDED requirement's heading carries `@v<N+1>` where `N` was its version before this run (unversioned → `@v2`). Print `(REQ-ID: vN → vN+1)` per requirement. |
| **RV-2** | Every AMENDED requirement retains its prior text struck through, with a `CR-<n>` + date annotation. Print present/absent per requirement. |
| **RV-3** | No ADDED requirement carries `@v1`. Print the count of violations (must be 0). |
| **RV-4** | No SUPERSEDED requirement was deleted from the file. Print retained/deleted per requirement. |
| **RV-5** | No UNCHANGED requirement differs byte-for-byte from its pre-run text. Print the count of unintended diffs (must be 0). |
| **RV-6** | Every story whose `Covers` names an amended REQ-ID either names the new version or is routed (spec-only / CR-born / blocked). Print `(story → REQ-ID@vN | routed-as)`. |
| **RV-7** | The coverage matrix normalises suffixes before matching, and no SUPERSEDED requirement is counted as an uncovered gap. Print the matrix row count and the excluded-superseded count. |
