# CR-<n> — Impact Ledger

Epic: <EPIC-ID> · Epic branch: <branch> @ <sha> · Written: <ISO timestamp> · AIRE v[N]
Produced by: `agents/change-request-analyst.md` (read-only) · Decisions by: `workflows/epic-change-request.md`

> 🔴 **CR6 — evidence per claim.** Every row's Evidence cell names what proved it: a `file:line` range,
> a commit SHA, a manifest fragment path, a `git blame` result, or the `Covers` line that established
> the requirement→story link. **A row with an empty Evidence cell is a defect in the analysis**, not a
> finding, and fails predicate CR6.

---

## 1. Requirement → story (the primary walk)

Matched on **bare REQ-ID**, `@vN` normalised away. `Covers` is mandatory on every story
(`common/requirements-traceability.md` Rule 2), so this walk is exact, not heuristic.

| REQ-ID | Class | Covering story | Evidence |
|---|---|---|---|
| REQ-F-03 | AMENDED | Story 2.1 | `stories.md:141` (`**Covers**: REQ-F-03`) |
| REQ-F-11 | ADDED | *(none — routes to a new story)* | searched all `Covers` lines: 0 matches |

🔴 A changed REQ-ID with **no** covering story is reported here explicitly — it is the signal that routes
to a new story (CR9), never an omission.

## 2. Story → acceptance criteria

| Story | AC | Class | Artifacts that move | Evidence |
|---|---|---|---|---|
| Story 2.1 | AC-2 | AMENDED | AC text · `@AC-2` scenario · TC-INT-04 · 3 unit tests | `stories.md:147`; AC-level breakdown present |

Class definitions: **UNCHANGED** (behaviour stays; its tests remain regression guards) · **AMENDED**
(behaviour changes) · **SUPERSEDED** (behaviour withdrawn; AC marked, never deleted).

Where `stories.md` has no AC-level `AC-n → REQ-ID` breakdown, every AC of the story is a candidate —
this table states which were judged in scope **and why**.

## 3. Story → code (confirmation walk, three sources)

| Story | Path | Manifest | History | Blame | Agreement |
|---|---|---|---|---|---|
| Story 2.1 | `src/approval/rules.ts` | ✓ `ci-manifest.d/story-2.1.json` | ✓ `a1b2c3d [Story 2.1 / PROJ-102]` | ✓ lines 40-58 | 3/3 |

Agreement `1/3` is reported as such — a single-source path is low-confidence and stated, not hidden.
🔴 Relevance is determined by **reading the code**, never inferred from a file's name.

## 4. Story → tests and contracts (the Test Change Authorization input)

| Story | Artifact | Type | Asserts AC | Evidence |
|---|---|---|---|---|
| Story 2.1 | `tests/unit/approval/rules.test.ts` | unit | AC-2 | `:31` "routes over threshold" |
| Story 2.1 | `spec/behavior/story-2.1.feature` | scenario `@AC-2` | AC-2 | `:22` |

🔴 Everything **not** on this list is a regression guard (CR10).

## 5. State and routing input

| Story | Pre-run status | Snapshot source | PR | Live merge state | Proposed route |
|---|---|---|---|---|---|
| Story 2.1 | Ready for Testing | `git show origin/<epic>:runtime-artifacts/aire-state.md` | #61 | merged `gh pr view` | CR-born supersede |

Status is read from the **git snapshot**, never the working tree. Merge state is confirmed **live** and
is the authority over any tracker label (CR9).

## 6. Concurrency

| Unit / PR | Status | Overlapping path | Evidence |
|---|---|---|---|

`(none — no in-flight unit or open ve/… PR touches the change surface)` when empty.

## 7. Impact tags (CR8)

```
affects_requirements: <N>
affects_stories:      <N>
affects_shipped:      <bool>
code_touched:         <bool>
doc_only:             <bool>
```

## 8. Unresolved

Anything the analysis could not resolve — an unmatched REQ-ID, a path with no owning story, a PR whose
state could not be read. 🔴 **Never silently omitted**; an unresolved requirement anchor fails CR3 and
halts the run.

`(none)` when empty.
