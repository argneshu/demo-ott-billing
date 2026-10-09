# CR-<n> — <one-line summary>

Mode: CHANGE REQUEST · Entry: <A description | B ticket <TICKET-ID> | C drift | D spec file <path>>
Epic: <EPIC-ID> (<epic link>) · Epic branch: <branch> @ <sha>
Written: <ISO timestamp> · AIRE v[N] · Produced by: epic-change-request (CR17)

> 🔴 **Template contract**: all six `## ` sections below are MANDATORY and appear in this order, even
> when a section's answer is "none" — an empty section is written with an explicit `(none — <reason>)`
> line, never omitted (CR13 / V1). Every row cites its evidence (CR6). Fact-only: no severity
> adjectives, no advisory verbs, no options outside the single gate (CR14).

---

## 1. The change

<What changed in the agreement, and what it now requires. Stated as fact, in the user's own terms where
Entry Mode A/B supplied them. Two to five sentences.>

**Source**: <ticket link | "inline description" | "operator edit to spec/plans/requirements.md" | spec file path>

## 2. Requirements — delta and versions

| REQ-ID | Class | Version | Before → After |
|---|---|---|---|
| REQ-F-03 | AMENDED | → @v2 | <old clause> → <new clause> |
| REQ-F-11 | ADDED | — (new, unversioned) | — → <new text> |
| REQ-F-07 | SUPERSEDED | @v1 retained, marked | <withdrawn clause> → (withdrawn) |

Unchanged: <N> requirements, byte-identical.
Full per-requirement detail: `requirements-delta.md`.

## 3. Impact — stories, acceptance criteria and tests

| Story | Pre-run status (snapshot) | PR state (live) | AC | AC class | Route | Evidence |
|---|---|---|---|---|---|---|

Blocked stories: <list with the exact way forward, or `(none)`>.
Full ledger: `impact-ledger.md`.

**Impact tags** — `affects_requirements: <N>` · `affects_stories: <N>` · `affects_shipped: <bool>` ·
`code_touched: <bool>` · `doc_only: <bool>`

## 4. Resolution — what this CR does

> 🔴 **Build-unit marker (machine-read — keep this line exact).** The work-unit guard
> (`templates/hooks/check-work-unit.sh`) reads it to know which story this CR *builds*, so that story
> requires the `testImpact` gate while merely-affected stories do not. One line, immediately below:
>
> `CR-BUILDS-STORY: <N.M>`   (spec-only CR — no story is built: `CR-BUILDS-STORY: none`)

CR-BUILDS-STORY: <N.M>

### 4a. CR-born stories (supersede a story whose code is merged)
Story <N.M> — <title> · Covers: <REQ-IDs@vN> · Supersedes: <story> · Requires: <stories> · Enables: <stories>
Acceptance criteria:
- AC-1 …

### 4b. Spec-only amendments (stories not yet started)
| Story | ACs amended | Scenario(s) | Test case(s) |

### 4c. New stories (no story covered the requirement)
Story <N.M> — <title> · Covers: <REQ-IDs> · Epic: <Epic-N>

*(Any subsection with no entries carries `(none — <reason>)`.)*

## 5. Test impact

### 5a. Contracts — per story: scenarios and test cases added / amended / retired
### 5b. Test Change Authorization list (CR10)
| File | Test | Action (`update assertion` / `delete — dead` / `regenerate via playwright-implement`) | Traces to |

🔴 A test **not** on this list must pass unmodified. Every other red test is a regression fixed in the
application code. New tests may always be added.

### 5c. New tests to add (unit / API / step definitions / Playwright via playwright-implement)

## 6. Implementation plan

> 🔴 **This section IS the code-generation plan** (it satisfies `dev-implement.md` Step 4.1). Checkboxes
> are marked `[x]` in the same interaction the step completes. No separate plan file is created.

- [ ] Step 1 — … (REQ-F-03@v2, AC-1)
- [ ] Step 2 — …
- [ ] Step N — Unit tests to `unitTestCoverageMin` coverage

**Trace check**: every CR story AC and every AMENDED/SUPERSEDED AC appears in ≥1 step
(`common/requirements-traceability.md` Rule 5).

## 7. Tracker, state and dependency actions on approval

Tracker story created/reused · linked to Parent Epic · comments on affected stories · Epic reopened
(only if already Ready for Testing) · dependency edges added · Story Tracker row.

## 8. Warnings

Concurrent in-flight units on the change surface · open `ve/…` PRs on affected test-plan folders ·
architecture impact · anything the analysis could not resolve. `(none)` if empty.

## 9. Decisions & assumptions — made by the framework (overrule any with Request Changes)

| # | Decision | Why | Alternative not taken |
|---|---|---|---|

> V4: every decision is listed with the alternative it rejected. A decision the operator overrules at
> the gate moves to "decided by the user" with their wording recorded.

## 10. Revision log

| # | When | What changed | Trigger |
|---|---|---|---|
