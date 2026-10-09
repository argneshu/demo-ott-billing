# Parallel Work State — Per-Work-Unit Audit and State Fragments

**Purpose**: let several developers (and the ve) work on different stories of the same epic in
parallel **without ever conflicting on the framework's own bookkeeping files**. Every run that works on
a single work unit writes its audit trail and its state into **its own files**, keyed by the work unit.
The shared `runtime-artifacts/audit.md` and `runtime-artifacts/aire-state.md` are written only by
runs that work on the integration branch itself.

This is the same pattern the framework already uses for CI configuration
(`tests/.evals/ci-manifest.d/<unit-key>.json`, `common/ci-pipeline-generation.md` Section 4.0f): one
append-only file per unit, merged by readers, folded back at cycle close.

---

## 1. Why `.gitattributes` `merge=union` is not enough

| Problem | Effect |
|---|---|
| `aire-state.md` rows are **edited in place** (a Story Tracker row changes Status, PR, Merged, Recorded) | `merge=union` keeps **both** versions of a changed line — two contradictory rows for the same story, with **no conflict marker**. Silent state corruption. |
| GitHub's server-side PR merge **does not run `merge=` drivers** | A story PR that touched `audit.md` or `aire-state.md` still shows *"This branch has conflicts"* on GitHub; the union driver only helps when someone merges locally. |
| `audit.md` entries from two branches | Union concatenates the two sides' hunks — entries land out of chronological order. |
| Every story PR touching the same two files | Forces merge/rebase churn on every parallel PR, even when the code is unrelated. |

With the fragments below, **a work-unit PR never touches a shared bookkeeping file**, so none of these
can happen. Every work-unit file is disjoint from every other unit's by construction.

---

## 2. Two kinds of writer

| Writer | Where it commits | Writes to |
|---|---|---|
| **Integration-branch writers** — Workspace Detection through the STOP checkpoint (planning, design, specs & test plans), `bug-fix.md` analysis and `enhancement-implement.md` Phase A (before the Verification Engineer handoff), `ve-list-work`, `playwright-implement` standalone (pushes to the integration branch), the `epic-enhance` spec-only path, `archive-epic` | The integration branch itself (epic / bug / enhancement branch), one writer at a time | The **shared** `runtime-artifacts/audit.md` and `runtime-artifacts/aire-state.md` |
| **Work-unit writers** — `dev-implement` (from the story being chosen), `epic-enhance` / `epic-bugfix` build path, `pr-fix`, `bug-fix-implement`, `enhancement-implement` Phase B (from Step 9), `ve-implement` standalone | A work-unit branch (`story/…`, `ve/…`), or a bug/enhancement branch while Verification Engineer work runs in parallel on `ve/…` branches | **Only its own fragment** — `runtime-artifacts/stories/<unit-key>/audit.md` and `runtime-artifacts/stories/<unit-key>/state.md` |

🔴 A work-unit writer **reads** the shared files (they hold the epic-level truth it needs) but **never
writes** them, and never writes another unit's fragment.

### 2.1 Unit keys (the same keys the evidence folders use)

| Work unit | Unit key | Written by |
|---|---|---|
| Epic story (including `epic-enhance` change stories, `epic-bugfix` bugfix stories and `epic-change-request` CR stories) | `story-<N.M>` | `dev-implement`, `epic-enhance`, `epic-bugfix`, `epic-change-request`, `pr-fix` |
| Bug cycle fix | `bug-<TICKET-ID>` | `bug-fix-implement`, `pr-fix` |
| Enhancement cycle implementation | `enhancement-<TICKET-ID>` | `enhancement-implement` Phase B, `pr-fix` |
| ve test-plan run (standalone) | `ve-<TICKET-ID>` | `ve-implement` standalone |

A story renumbered after a collision (`workflows/epic-enhance.md` E13; `common/change-request-rules.md`
CR12b) moves its fragment with
`git mv runtime-artifacts/stories/story-<old> runtime-artifacts/stories/story-<new>` in the same step.

---

## 3. Fragment formats

### 3.1 `runtime-artifacts/stories/<unit-key>/audit.md`

```markdown
# Audit Trail — <unit-key>
Work unit: <Story N.M — title | BUG-ID | ENH-ID | Verification Engineer test plan for TICKET-ID>
Branch: <branch> · Workflow: <dev-implement | epic-enhance | epic-bugfix | pr-fix | bug-fix-implement | enhancement-implement | ve-implement>

---
```

followed by entries in **exactly** the format the writing workflow already defines (all its fields —
`User Email`, `TRACKER ITEM`, `Epic Link`, `AIRE VERSION`, and any workflow-specific ones), plus one
field on every entry:

```markdown
**Unit**: "<unit-key>"
```

`common/audit-logging.md` applies unchanged: complete raw input, one real clock command per timestamp,
append only, to the END of **this** file.

### 3.2 `runtime-artifacts/stories/<unit-key>/state.md`

```markdown
# Work-Unit State — <unit-key>
Workflow: <…> · Branch: <…> · Created: <ISO timestamp> · AIRE v<N>

## Story Tracker Row
| Story | Title | Requires | Tracker ID | Status | PR | Merged | Start | End | Recorded |
|-------|-------|----------|------------|--------|----|--------|-------|-----|----------|
| <this unit's ONE row — every column filled, the whole row rewritten on each change> |

## Claim
- Tracker: <JIRA|ADO|GITHUB> <TRACKER-ID> · In Development — verified <ISO timestamp>   (LOCAL: `- Tracker: LOCAL — no external claim`)
- Assignee: <accountId | login | email> — verified <ISO timestamp>   (or: `unresolved — <identity>, user warned <ISO timestamp>`; LOCAL: `- Assignee: LOCAL — n/a`)
- Parent Epic: <moved to In Development — verified <ISO timestamp> | already In Development | not the first work unit | skipped — none/LOCAL>

## Progress
Current step/gate: <…> · Gates passed: <list> · Last updated: <ISO timestamp>

## Self-Healing Counters
| SH-LOOP | Attempts used | State |

## Dependency Graph Additions          (epic-enhance / epic-bugfix / epic-change-request only)
<the change story's node: id, title, tracker_id, requires, enables>

## Change Request Additions            (epic-change-request only)
<CR id; per amended requirement: REQ-ID, version transition, class (AMENDED/ADDED/SUPERSEDED);
 per affected story: the route taken. Kept in the fragment so parallel runs never collide on the
 shared requirements record — `archive-epic` folds it in at cycle close.>

## PR Feedback Rounds                  (pr-fix only — same columns as workflows/pr-fix.md Step 18)

## Defect Provenance Log               (epic-bugfix only — same columns as workflows/epic-bugfix.md Step 5)
```

Sections that do not apply are omitted. A bug/enhancement cycle's row uses the ticket ID in the
`Story` column. A `ve-<TICKET-ID>` fragment has no Story Tracker row (ve-implement never changes status)
— only `## Progress`.

---

## 4. Reading: the resolved view

Every reader — the workflows, `story-selection.md`, `ve-list-work`, `pr-fix`, `pr-generator`,
`pr-review`, `code-review` (all-stories scope), resume (`common/session-continuity.md`), `archive-epic` and
the behaviour runner `tests/.evals/behavior/run.sh` (B2/B3 activation) — reads the **resolved view**:
the shared files **plus every fragment present in the working tree**.

1. **Epic-level sections** (`## Tracker`, `## Branching`, `## CI/CD Configuration`, `## Code Root`,
   `## Extension Configuration`, `## Context Project`, `## Design References`, stage progress,
   `team_size`, …) come **only** from the shared `aire-state.md`. Fragments never contain them.
2. **Story Tracker**: start from the shared table. For each fragment row, compare it with the shared
   row of the same story: **the row with the later `Recorded` wins, whole row**; on a tie, the row with
   the more advanced status wins (`Ready for Testing` > `In Development` > `Ready for Development`). A fragment row for a story the shared table does
   not have (a change, bugfix or Change Request story) is appended.
3. **Dependency graph**: `spec/plans/dependency-graph.yml` plus every fragment's
   `## Dependency Graph Additions`.
4. **PR Feedback Rounds / Defect Provenance Log / Change Request Additions**: the union of the shared section and every fragment's.
5. **Audit trail**: the shared `audit.md` plus every fragment's `audit.md`. A reader that needs one
   work unit's history (pr-generator, pr-review, pr-fix, resume) reads **that unit's fragment first**;
   a reader that needs the whole cycle merges all of them by `Timestamp`.
6. **`PR: pending` / `Merged: no` are resolved live.** A work unit commits its fragment before its PR
   exists (the PR is raised from that commit), and never pushes a state-only commit afterwards — that
   would start a CI run on a new head SHA. So a committed fragment may say `PR: pending` or `Merged: no`
   after the fact. A reader that needs the PR or its merge state resolves it live from the unit's
   branch: `gh pr list --head <branch> --state all --json number,url,state,mergedAt,baseRefName`. The
   Doability Gate and `ve-list-work` already check merge state live; this rule makes it universal.

**Visibility**: a unit's fragment reaches other developers when its PR merges into the integration
branch — exactly when its code does. Until then, the **external tracker** (JIRA / ADO / GitHub, read
live) is the real-time source for "who has claimed what"; `story-selection.md` already reads it. With a
LOCAL tracker and parallel clones, a claim is visible to others only after the merge — coordinate on
independent stories from the Dependency Graph, as the sequential-development banner says.

---

## 5. Writing rules for work-unit writers

1. **Pre-key buffering.** Entries logged before the unit key is known (the `dev-implement` selection
   prompt, `epic-enhance` / `epic-bugfix` Steps 1–5, `pr-fix` Step 1) are held and written into the
   fragment, **with their original timestamps**, the moment the key is known. If the run ends before a
   key exists (a stop, a block, a halt), write the held entries to the shared `audit.md` only when the
   run is on the integration branch with nothing else to commit; otherwise leave them in the session
   output and say so — never commit them to the shared file from a work-unit branch.
2. **The Story Tracker row lives in the fragment.** Claiming (`Ready for Development → In Development`), recording the PR URL, setting
   `Merged = no`, refreshing `Recorded` — all rewrite the one row in `state.md`. The shared table is not
   touched.
3. **Progress and SH counters live in the fragment**, so a resumed run (a new session, the same branch)
   continues from `## Progress` with the counters it already had (SH-2).
4. **External tracker updates are unchanged** — they never touched git.
5. **🔴 State Isolation Check — before EVERY commit a work-unit writer makes:**
   ```bash
   BASE="$(git merge-base origin/<integration-branch> HEAD)"
   git diff --name-only "$BASE" -- runtime-artifacts/ ; git diff --name-only --cached -- runtime-artifacts/
   ```
   Every path listed must be under `runtime-artifacts/stories/<own-unit-key>/`. For any other path
   (usually the shared `audit.md` / `aire-state.md`, from a run that predates this rule or a slip):
   copy its new entries / row into the own fragment (keeping their timestamps), restore the shared file
   to the merge-base version (`git restore --source "$BASE" --staged --worktree -- <path>`), and re-run
   the check. The commit happens only when the check is clean. Log the check result in the fragment.
   A path under **another unit's** fragment is never edited — restore it the same way and report it.

## 6. Writing rules for integration-branch writers

- They write the shared files as before (append-only `audit.md`; in-place `aire-state.md` rows).
- **When they change a unit's row** (`ve-list-work` Option B promoting `In Development → Ready for Testing`, or recording a
  rejection), they read the resolved row first and write the **full resolved row** into the shared
  table with a new `Recorded` — so it wins over the fragment's older row (Section 4.2). They never edit
  a fragment.
- They pull (`git pull --ff-only`) immediately before editing and push immediately after, so two
  integration-branch writers rarely overlap. If a push is rejected, pull and redo the edit on the fresh
  file — never hand-merge a Story Tracker row.

## 7. Cycle close — folding (`archive-epic`)

Before the archive copy, `archive-epic` folds the fragments (`agents/archive-epic-agent.md` Step 4):
the resolved Story Tracker is written into the shared table, the union sections are merged into their
shared sections, each fragment's audit entries are **appended** to the shared `audit.md` under
`## Work-Unit Audit Trails (folded at cycle close)` (one sub-heading per unit, entries in timestamp
order — append-only is preserved), and the fragments are archived with everything else.

## 8. `.gitattributes`

- `runtime-artifacts/audit.md merge=union` stays — the shared audit is append-only, so a local merge
  of two integration-branch appends is safe.
- `runtime-artifacts/aire-state.md` has **no** union driver. Its rows are edited in place; a genuine
  conflict there (two integration-branch writers on one row) must surface as a conflict, not be merged
  into duplicate rows.
- `runtime-artifacts/stories/**` needs no driver — each unit's files are touched by one unit only.

## 9. Edge cases

| # | Situation | Handling |
|---|---|---|
| P1 | An in-flight branch created before this rule already edited the shared files | The State Isolation Check on its next commit moves those edits into its fragment and restores the shared files |
| P2 | Two clones claim the same story (LOCAL tracker) | Both fragments share one path → the second PR conflicts on its own `state.md`, which is the correct signal; resolve by keeping the merged unit's row and renumbering or dropping the other work |
| P3 | A story is renumbered (collision) | `git mv` the fragment directory with the branch rename |
| P4 | `pr-fix` merges the integration branch into a PR head | Disjoint paths — the merge cannot conflict on bookkeeping |
| P5 | A reader runs on a branch that does not yet contain another unit's fragment | Correct by design: that unit's state is not on this branch yet; the external tracker covers live claims |
| P6 | The shared file and a fragment disagree on a row | Section 4.2 decides — later `Recorded` wins, then the more advanced status |
| P7 | A run halts before its unit key exists | Section 5.1 — held entries go to the session output, never into a shared file on a work-unit branch |
| P8 | `archive-epic` finds fragments | Step 4 folds them before the copy; none is lost |
