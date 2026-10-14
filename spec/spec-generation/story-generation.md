# Story Generation Plan

Epic: Self-Serve Premium Upgrade | Requirements: `spec/plans/requirements.md` (REQ-F-01..11, REQ-NF-01..07)
`team_size` is fixed at 2 and `story_creation_mode` at all-at-once (neither is asked).

## Slicing analysis (SPIDR)
The Epic ships one 7-AC story that spans UI and backend, which breaks the sizing ceilings (more than 5 ACs, more than one new layer, several scenario classes). Proposed split:

| Story | Title | SPIDR axis | Covers |
|---|---|---|---|
| 1.1 | Backend prorated upgrade to Premium | Interface (backend) + Rules (proration) | REQ-F-03, F-04, F-06, F-09, F-11, NF-03 |
| 1.2 | Upgrade request rejection paths | Paths (error handling) | REQ-F-05, NF-01 |
| 1.3 | Upgrade button for Standard users | Interface (UI), Rules (visibility) | REQ-F-01, NF-07 |
| 1.4 | Upgrade confirmation modal with prorated preview | Steps (preview before commit) | REQ-F-02, F-08, NF-07 |
| 1.5 | Confirm upgrade and refresh Billing page | Steps (commit) + Paths (failure) | REQ-F-07, F-10, NF-05 |

NF-02 (tests), NF-04 and NF-05 apply to every story as acceptance criteria. Stories 1.1 and 1.3 have no prerequisites, so at least 2 can run in parallel.

## Execution checklist
- [x] Record team_size 2 and story_creation_mode all-at-once in state
- [x] Apply SPIDR slicing (above)
- [x] Collect answers to the questions below
- [x] Generate stories.md (Epic header line first, `Covers` on every story, at most 5 ACs each)
- [x] Generate personas.md
- [x] Populate the Story Tracker
- [x] Requirements coverage check and granularity check
- [x] GATE 1: story set approval

## Question 1: Number of stories
How many user stories should I create for this work?

Recommended: 5 stories (suggested range: 4-6)

Why 5:
- 11 functional requirements SPIDR-sliced into single-purpose stories (backend happy path, error paths, button, modal, confirm)
- keeps 2 stories (1.1 backend, 1.3 button) runnable in parallel so no developer is idle
- each story stays within the sizing ceilings (at most 5 ACs, one new layer, one scenario class), so review is small

Reply with a number to override, or "ok" / "use recommended" to accept 5.

[Answer]: ok 

## Question 2: Breakdown approach
A) Feature/layer-based as in the table above (backend first, then UI steps) (Recommended)

B) User-journey-based: one story per step of the upgrade journey, each cutting through UI and backend

X) Other (please describe after [Answer]: tag below)

[Answer]: A
