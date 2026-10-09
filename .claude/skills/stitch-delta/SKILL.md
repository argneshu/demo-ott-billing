---
name: stitch-delta
description: >
  Refreshes the Atlas deep dive document so it describes the application as it is NOW, after a
  cycle has merged. Runs on the BASE branch AFTER the cycle's [EPIC]/[BUG]/[ENH] PR has merged —
  which is what makes the merged code available as ground truth. Reads each pending delta from its
  cycle archive (aire-archives/<type>/<ID>-<slug>/spec/plans/delta/…), then performs a FULL-DOCUMENT
  refresh: every section of the deep dive is decided against the merged tree — refreshed, kept only
  on positive re-verification, or resolved/removed — and the complete body is written back to the
  same Atlas document. It is NOT limited to the sections the delta happens to name. Appends one row
  per delta to aire-archives/stitch-ledger.md; that append-only ledger plus a header stitch marker
  are two independent guards against publishing the same cycle twice. Its whole repository footprint
  is the ledger row plus archived audit entries, raised as a stitch-delta/<name> PR into base — it
  never commits to base directly and never touches spec/, src/ or tests/.
when_to_use: >
  Trigger when the user says: "stitch-delta", "stitch the delta", "stitch deltas",
  "apply pending deltas", "refresh the deep dive", "update the deep dive on Atlas",
  "publish the cycle delta to Atlas", "post-merge stitch".
allowed-tools: Read Grep Glob Bash Write Edit
---

# 🧵 Stitch Delta — Refresh the Atlas Deep Dive to the Current Face of the Application

Load and execute the agent instructions from:

```
aire-workflow/agents/stitch-delta-agent.md
```

Read that file completely and follow every step defined in it.

**Key rules**:
- 🔴 **The deliverable is a WHOLLY CURRENT document, not a set of edits.** A deep dive is a full system
  analysis — directory structure, statistics, entry points, component catalog, flows, dependency graph,
  database, test coverage, security posture, technical debt, file inventory — and a real cycle
  invalidates most of it at once. **Every section that is no longer true is brought current in this run**,
  whether or not `delta.md` named it. A 90%-current document is untrustworthy, because no reader can tell
  which 10% is stale.
- 🔴 **"Not named in the delta" is NEVER a reason to leave a section alone.** Each heading gets one of
  three outcomes, decided against the merged code: **REFRESH**, **KEEP** (only on positive
  re-verification), or **REMOVE/RESOLVE**. This deliberately supersedes the earlier "apply only the
  directives, never widen scope" rule, which once left `### Directory Structure` describing a codebase
  that no longer existed after an epic added three new module folders and a seed script.
- 🔴 **The merged working tree on base is the ground truth; the delta is the narrative.** Every path,
  count, dependency and metric is measured from the real repo (`git ls-files`, the real manifest files,
  `git diff --name-status <range>`), never carried forward from the old document and never estimated.
  That grounding is the whole reason this skill runs post-merge on base.
- **Coverage checklist = the document's own outline**, read live (headings-only view) — never an
  assumed list. Sections that are almost always stale after a cycle get an explicit check every run:
  Directory Structure · Statistics · Entry Points · Component Catalog · Internal Dependencies + Coupling ·
  Database Analysis · Test Coverage · the Appendix file inventory and dependency list · Referenced Paths.
- **Refresh in place — never restructure.** Same headings, same order, same depth; content is what
  changes. Human-authored commentary that is still true is preserved verbatim. A genuinely new area (a
  new flow, a new service) is added in the document's existing pattern and named in the ledger.
- 🔴 **`## Referenced Paths` must close the document**, regenerated from what the refresh examined — the
  Helix markdown save contract requires it.
- 🔴 **Base branch, after the merge — always.** A delta whose cycle PR is not confirmed `MERGED` is
  **skipped, not published**: the document must never describe code that is not on base.
- **Publishing**: re-read the document `version` immediately before writing; if it moved, re-read the
  body and redo the pass against it — 🔴 never blind-overwrite a newer version. The refreshed body
  replaces the same `document_id` (a whole-document refresh is a whole-document write), then is verified
  by re-reading before any ledger row is written. A partial write is never ledgered.
- 🔴 **Several pending deltas = ONE refresh pass**, reflecting the cumulative current state, with one
  ledger row per delta all naming the same resulting version — never N serial re-analyses of the same tree.
- 🔴 **Two guards against publishing a cycle twice**: the append-only ledger row, and the
  `> **Stitched**: <CYCLE-ID> at <ts>` marker in the document header (cumulative, one per cycle). Marker
  present but row missing → write the missing row, do **NOT** refresh again.
- **The ledger is append-only and written by this skill alone** — `aire-archives/stitch-ledger.md`, one
  row appended immediately after the Atlas write verifies. `archive-epic` writes nothing to it, and there
  is no "pending" row: a delta is pending precisely because it has none. It deliberately has **no
  `merge=union`** — this skill is the only writer, on base, one run at a time (it refuses to start while
  another `stitch-delta/*` PR is open), so a conflict there means that serialization broke and must surface.
- 🔴 **HALT if Helix/Atlas is unreachable or no deep-dive document exists** — nothing is written and the
  deltas stay safe in their archives, so the run repeats as-is once Helix is connected.
- 🔴 **Never commits or pushes directly to base.** Always a `stitch-delta/<name>` branch + PR, carrying
  `ai-generated` and `aire-v[N]` labels and an `AIRE-Version: [N]` commit trailer — read **live** from
  `CLAUDE.md`, never hardcoded.
- **Touches no `spec/`, `src/` or `tests/` path.** The repo diff is the ledger row plus the archived
  audit entries; `runtime-artifacts/audit.md` no longer exists, so logging appends to each published
  cycle's archived copy. `common/audit-logging.md` applies in full.
- **Nothing pending is a normal outcome**, not an error: report it and stop.
