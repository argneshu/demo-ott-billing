# Development Handoff Message

**Purpose**: the verbatim message presented at the  MANDATORY STOP checkpoint in `CLAUDE.md`
(after the system-level design stages complete or are skipped, before any Code Generation). This is
the moment the workflow hands off to development and Verification Engineer.

**Load and emit this** at Step 5 of the STOP CHECKPOINT (after the design commit and the conditional epic-level smoke test). Emit the block below **verbatim**, with
every placeholder substituted from real values — never ship an unsubstituted placeholder. Then
**HALT** and wait for the user to type `dev-implement`.

```markdown
# Design Done — Ready to Build

 **[N] user stories created** during Planning.
[IF stories were pushed to the configured tracker:]
 **On [TRACKER TYPE] [PROJECT_KEY / org-repo / org-project]** — stories [TICKET-101 … TICKET-1NN][, all linked to Parent Epic [EPIC-ID] — include this clause ONLY if `## Tracker` records an Epic (not `none`)].
[IF Type: LOCAL, or stories were NOT pushed:]
 Tracked locally only (not pushed to an external tracker).

 Dependency Graph: [M] stories are ready to start now (no unfinished prerequisites).
 Design stages: [list which ran vs were skipped].
 Behaviour specs + manual test plans: **[N] of [N] stories** — `spec/behavior/story-*.feature` and
   `spec/test-plans/*/`, approved at this checkpoint, so every story's contract and test plan exist
   before a line of its code does.
 Epic branch: `[epic-branch]` — design artifacts **committed and pushed** ([commit hash]).

> ** <u>**DEV — use the keyword `dev-implement`**</u>**
> 1.  Stay on / switch to the epic branch `[epic-branch]` and pull the latest.
> 2.  Type **`dev-implement`** and pick a story (by Story ID / number, or Tracker ID).
> Run it **once per story** — it cuts `story/N.M-…` from the epic branch.
> It **reads** that story's already-approved `.feature` contract and test plan; it never rewrites them.

> **<u>Verification Engineer — the manual test plans are already on the epic branch.</u>**
> Every story's `spec/test-plans/<TICKET-ID>-<title>/` was generated and approved at this checkpoint.
> Once a story's code is generated and on the epic branch (its PR merged), verify it by executing that
> story's test plan, then use `ve-list-work` to approve or reject the story.

Type `dev-implement` EXACTLY as shown — do not describe what you want in your
   own words. Any other phrasing is not a framework trigger and the workflow will not advance.
```

- **[N]** = total stories. Show the tracker line only if stories were pushed (Tracker ID column populated); Epic ID from `## Tracker`. Otherwise show the local-only line.
- The behaviour-specs/test-plans line reports the Step 1.7 counts (`implementation/specs-and-test-plans.md`); both numbers equal the story count, or the line names the gap.
- Substitute `[epic-branch]` and the commit hash with real values from `## Branching` / the Step 3 commit — never ship a placeholder.
- Log this handoff in runtime-artifacts/audit.md.
