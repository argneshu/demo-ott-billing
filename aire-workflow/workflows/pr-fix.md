# WORKFLOW: `pr-fix [PR-NUMBER]` (Rejected PR — Review-Feedback Fix for a Story, Bug or Enhancement)

> **READ FIRST.** The six non-negotiables at the top of `workflows/dev-implement.md` bind this workflow
> too: every gate runs (no scope calls), the Gate Ledger is complete before the commit, the work-unit
> guard (`sh aire-workflow/templates/hooks/check-work-unit.sh --install <unit-key>` right after the PR head branch is checked out, with that PR's unit key) is installed and
> never bypassed, the claim (In Development + assignee) is made on the external tracker and recorded in the fragment's `## Claim` block — a `pr-fix` run whose unit has no such block makes the claim now —, a disclosed gap is never shipped, and the run
> ends with the Step 19 handoff block verbatim — nothing else in that final message.

## WHAT THIS WORKFLOW IS

A **work-unit PR that a human rejected** — a `[STORY]` PR into the epic branch, a `[BUG]` PR or an
`[ENH]` PR into the base branch — comes back to the framework through this ONE keyword. The workflow:

1. asks **which PR** to fix (skipped when the PR number is typed with the keyword),
2. harvests every unresolved human review comment on that PR (developer, ve, or any other reviewer),
3. triages each comment into a **Feedback Ledger**, fixes the actionable ones on the PR's own head
   branch,
4. **re-runs the COMPLETE gate chain of the workflow that originally built the work unit**
   (`dev-implement` / `bug-fix-implement` / `enhancement-implement`) — baselines, unit tests +
   coverage, Gherkin B1/B2/B3, API & contract, test placement, full regression, static D1–D7,
   Playwright UI + Playwright E2E regression, automated Code Review with the Security Baseline pass and
   the J1/J2 judge gates, auto-remediation, manifest reconciliation, CI preflight and CI attestation,
5. pushes the fix **to the same PR** (never a new PR, never a force-push), refreshes the PR's eval
   scorecard, replies to every comment it acted on, re-requests review, and hands back.

It never merges the PR, never approves it, never resolves a review thread and never dismisses a
review — those stay human actions.

---

## Section 1 — When a PR gets rejected: the scenarios this workflow handles

### 1.1 What "rejected" means here

A PR is **rejected** when it is still **OPEN** and a human has signalled that it must change before it
can merge. Any of these signals makes it a `pr-fix` candidate:

| Signal | Where it lives | Typical author |
|---|---|---|
| A **Request changes** review | GitHub PR reviews (`state: CHANGES_REQUESTED`) | ve, a second developer, a tech lead |
| A **Comment** review or inline line comments asking for a change | GitHub PR reviews / review threads | the developer who ran `dev-implement` (see the identity note below), ve, any reviewer |
| A top-level PR conversation comment asking for a change | GitHub PR issue comments | anyone |
| A **ve rejection on the tracker while the PR is still open** — the `Verification Engineer rejected the story` comment + `ve-rejected` label written by `ve-list-work` Option B | Tracker item (JIRA/ADO/GITHUB) or the local Story Tracker | ve (normal on bug/enhancement cycles, where ve signs off on the bug/enhancement branch **before** the PR merges) |
| CI failed and **CI self-repair exhausted its budget** (the `auto-fix-agent` exhaustion comment on the PR) | PR comments + the latest `agentic-eval-pipeline.yml` run | the pipeline |

🔴 **Identity note — the developer's own comments ARE human feedback.** `dev-implement`, `pr-generator`
and the AUTO-MODE `pr-review` all act under the developer's own GitHub identity, so the developer is
the PR author and GitHub will not let them submit a formal **Request changes** on their own PR. A
developer therefore rejects their story PR with **Comment** reviews and inline comments. This workflow
never skips a comment because its author is the PR author; it tells human comments apart from the
framework's own output **by record, not by login** (Step 4.3).

### 1.2 Developer rejection scenarios

| # | Scenario | Example comment | Ledger class (Step 5) |
|---|---|---|---|
| D1 | An AC is implemented but an edge case is wrong | "Empty cart still lets checkout through — AC-3 says it must be blocked." | FIX-CODE |
| D2 | Code sits in the wrong layer or breaks an `architecture.md` Section 10 constraint | "Pricing logic is in the controller; ARCH-02 says the service layer owns it." | FIX-CODE |
| D3 | Repo convention / naming / structure mismatch | "We use `snake_case` for DB columns in this repo." | FIX-CODE |
| D4 | Tests are weak, missing or misplaced | "This test mocks the unit under test, it asserts nothing." | FIX-TEST |
| D5 | Performance problem | "N+1 query in `listOrders` — load items in one query." | FIX-CODE |
| D6 | Security concern on the changed surface | "The token is logged at INFO level." | FIX-CODE |
| D7 | The PR no longer merges cleanly / integrates badly after a sibling story merged into the epic branch | "Conflicts with Story 1.3's migration." | handled by Step 3 (merge) + FIX-CODE |
| D8 | Scope creep — unrelated files changed | "Why is `billing/` touched? Revert that." | FIX-CODE (revert) |
| D9 | A question, no change requested | "Why a queue here instead of a direct call?" | ANSWER |
| D10 | CI failed and CI self-repair gave up | auto-fix-agent exhaustion comment | CI-FAILURE |

### 1.3 ve rejection scenarios

| # | Scenario | Example comment | Ledger class (Step 5) |
|---|---|---|---|
| V1 | A manual test-plan step fails on the PR branch (expected ≠ actual) | "TC-E2E-04 step 5: expected 'Order placed', got a blank page." | FIX-CODE |
| V2 | The code meets the letter of the AC but not its intent, and the ve's reading changes the contract | "AC-2 means *all* roles, not just admins." | AMEND-AC (asks first — Step 6) |
| V3 | UI defect: copy, label, layout, missing error message, accessibility | "Submit button has no accessible name; focus is lost after the error." | FIX-CODE |
| V4 | API contract defect | "Invalid payload returns 500, contract says 400 with the error envelope." | FIX-CODE |
| V5 | A test-plan case has no automated counterpart | "TC-API-07 (expired token) is not covered by any automated test." | FIX-TEST |
| V6 | Regression in a flow an earlier work unit shipped | "Login redirect broke after this PR." | FIX-CODE |
| V7 | Works only with local seed data / missing migration | "Fails on a clean DB — the migration is missing." | FIX-CODE |
| V8 | ve rejected on the tracker (`ve-list-work` Option B) while the `[BUG]`/`[ENH]` PR is still open | tracker comment `Verification Engineer rejected the story — <finding>` | FIX-CODE / FIX-TEST |

### 1.4 Outcomes that are NOT a code change

| Situation | Ledger class | What happens |
|---|---|---|
| The request contradicts an approved AC / requirement / scenario | AMEND-AC | Asked once (Step 6): amend the contract, keep it, or defer |
| The request would break the Security Baseline, an `architecture.md` Section 10 constraint, or is a forbidden shortcut ("skip this test", "disable the lint rule", "lower the coverage bar") | DECLINE | Not applied; the reply cites the rule it would break (SH-6) |
| Valid, but belongs to another work unit or is new scope | DEFER | Not applied; the reply recommends `/raise-defect` or a new story |
| Two reviewers ask for incompatible things, or the comment is ambiguous | CONFLICT | Asked once (Step 6) |
| The current head already satisfies it (often an outdated thread) | ALREADY-ADDRESSED | Reply with the `file:line` evidence |

### 1.5 When `pr-fix` is the WRONG tool — route instead

| Situation | Route |
|---|---|
| The PR is **MERGED** (e.g. the ve rejected an epic story via `ve-list-work` after its `[STORY]` PR merged) | A merged PR cannot be updated. The Verification Engineer logs the finding with `/raise-defect`; it is fixed through `ticket-implement <BUG-ID>`. |
| The PR is **CLOSED without merging** | Reopen it first, then `pr-fix`; or re-run the owning implement workflow. |
| The PR is an `[EPIC]` PR, a `[TEST]` PR (Verification Engineer test plans), a `[STITCH]` PR or a distribution PR | Out of scope. Test-plan PRs are amended with `ve-list-work` Option C or `/ve-implement`. |
| The review comment is on a PR not raised by AIRE (no `ai-generated` label) | Out of scope — there is no work unit, spec or evidence to re-run against. |

---

## THIS WORKFLOW ASKS ONE THING — WHICH PR

**Naming the PR is the only user decision in a normal run.** Everything after it runs without an
approval prompt: harvesting, triage, the fix plan (announced, not approved), the fix, the full gate
chain, the review, remediation, the commit, the push, the PR update, the replies and the handoff.

There are exactly **three** sanctioned stops — none of them an approval of the framework's own work:

1. **Step 6 Clarification** — asked **only** when the Feedback Ledger contains AMEND-AC or CONFLICT
   items. A human reviewer asking to change an approved contract, or two reviewers disagreeing, is a
   human decision the framework must not make alone. Asked once, as one inline block.
2. **Step 2.6 Archived-cycle recovery** — asked only when the bug/enhancement cycle archive has already
   run on the PR's head branch.
3. **Retry-limit halts (SH-4)** and the **Playwright agent-install restart pause** inherited from the
   owning workflow — halts, not questions.

A user who volunteers a correction mid-run is an **interrupt** — apply it, record it in the Feedback
Ledger and `runtime-artifacts/audit.md`, and continue. Never turn it into a standing gate.

---

## 🔴 SINGLE-SESSION EXECUTION — NO FORKS, NO DELEGATION

This workflow runs **from start to finish in the session where the user typed `pr-fix`**. It is the
same rule `workflows/dev-implement.md` Step 1.7 enforces, restated here because this workflow re-runs
that workflow's gates:

- **Never** hand this workflow, or any step of it, to another execution context: no Agent-tool fork,
  no general-purpose / Explore / Plan subagent, no Workflow-tool orchestration, no background or remote
  agent, no second Claude Code session, no `claude -p` subprocess. Harvesting, triage, planning,
  coding, every gate, the Code Review pass, the J1/J2 judging, remediation, the commit, the push, the PR
  update and the replies are all done **by this session's own tool calls**.
- The `agents/*.md` files this workflow loads (`code-security-review-agent.md`,
  `ve-implement-agent.md`, `playwright-implement-agent.md`) are **procedures executed inline in this
  session** — never spawned as subagents. The Code Review pass is kept read-only **by discipline**
  (no `Edit`/`Write` on `src/**` or `tests/**` during the review pass), never by spawning a read-only
  subagent.
- Skills this workflow invokes (`ve-implement`, `playwright-implement`, `pr-review`) run **inline**
  via the Skill tool.
- Long test suites run through this session's own shell. A command may run in the background only if
  this session waits for it to finish before advancing — a gate never advances on a result it has not
  read.
- 🔴 **The ONE permitted Agent-tool use** is Playwright's own official **Planner / Generator / Healer**
  test agents, invoked by the `playwright-implement` skill inside the Playwright UI gate, **one call at
  a time, synchronously**, with this session waiting on each. They are Playwright's installed test
  agents, not a fork of this workflow, and no other part of the run may be delegated to them.
- **If this run is itself executing inside a fork or a subagent**, Step 0 HALTS it before anything is
  read or changed.

---

## MANDATORY: Rule Details Loading

Resolve the rule details directory (`aire-workflow/`) and load:
- `common/process-overview.md`, `common/session-continuity.md`, `common/content-validation.md`,
  `common/question-format-guide.md`, `common/audit-logging.md`, `common/tracker-sync.md`,
  `common/branching-strategy.md`, `common/requirements-traceability.md`, `common/eval-framework.md`,
  `common/behavior-spec.md`
- **The owning workflow resolved at Step 2.3, in full** — `workflows/dev-implement.md`,
  `workflows/bug-fix-implement.md` or `workflows/enhancement-implement.md`. Its gate steps are
  executed **by reference** at Step 11 and Step 13; its Self-Healing Retry Policy (SH-1 … SH-7) and its
  Retry-Limit Report bind this workflow too.
- `implementation/code-generation.md` (Guardrail — Generation Phase Rules, Steps 11a–11e),
  `workflows/code-review.md` + `implementation/code-review.md`, `workflows/remediate.md` +
  `implementation/remediate.md`
- When `## CI/CD Configuration` records `Enabled: Yes`: `common/ci-pipeline-generation.md`
  Sections 4.0d, 4.0f, 4.0i and 6.6
- 🔴 The three Playwright non-negotiables in `workflows/dev-implement.md` ("MANDATORY: Rule Details
  Loading") apply unchanged: only the `playwright-implement` skill's own subagents may write
  `tests/e2e/**` or `spec/playwright-specs/**`; missing agents mean INSTALL, then restart; disclosing a
  shortcut does not permit it.

---

## SELF-HEALING RETRY POLICY — INHERITED, PLUS ONE LOOP

Every automatic loop in this workflow is governed by the owning workflow's **SH-1 … SH-7**: 3 attempts
per loop, independent per-loop counters, every attempt logged with its root cause, exhaustion HALTS
with the Retry-Limit Report, a stall ends the budget early, no weakening of any check.

- **Counters are per pr-fix round.** A new `pr-fix` invocation on a PR starts a new round (Step 2.7)
  with fresh counters. **Resuming a halted round** continues that round's counters (SH-2), except the loop
  that halted: the developer's manual fix and hand-back (`pr-fix <n>` again) grants it a fresh budget.
- The loops re-run here keep their owning-workflow IDs (SH-LOOP-1 … 13, Step 11 table), plus:

| ID | Loop | Defined in | Verification that must pass to exit |
|---|---|---|---|
| **SH-LOOP-14** | Feedback Resolution Verification | Step 12 | Every FIX-CODE, FIX-TEST, CI-FAILURE and applied AMEND-AC ledger item is demonstrably satisfied by the head diff, with `file:line` evidence |

The Retry-Limit Report is the **Self-Heal Limit message in `common/self-heal-limit-guidance.md` Section 2**,
emitted verbatim with one extra line under `Branch:` — `PR:        #<n> (<url>) — pr-fix round <R>` —
the "HOW TO FIX IT YOURSELF" steps from its Section 3 playbook row, and **resume keyword = `pr-fix <n>`**.
Typing `pr-fix <n>` again after a manual fix is a hand-back: Step 2.7 resumes the in-progress round and
applies the resume protocol of Section 4 (check the manual change, reject forbidden shortcuts, keep the
developer's code, fresh budget for the halted loop only).

---

## MANDATORY: Audit Entry Format

Every `runtime-artifacts/audit.md` entry written by this workflow carries the owning workflow's fields
**plus two**:

```markdown
## [Stage Name or Interaction Type]
**Timestamp**: [ISO 8601 from ONE real clock command]
**User Email**: [current session email — read live from the session context]
**User Input**: "[Complete raw user input - never summarized]"
**TRACKER ITEM**: "[clickable tracker link, or the local Story ID]"
**Epic Link**: "[full Parent Epic URL from ## Tracker, or "none"]"
**AIRE VERSION**: "[read live from the "AIRE Framework Version" line in CLAUDE.md]"
**PR**: "[#<n> — <PR URL>]"
**PR-FIX ROUND**: "[R]"
**AI Response**: "[AI's response or action taken]"
**Context**: [Stage, action, or decision made]

---
```

Self-healing entries also add `**SH-LOOP**:`, `**Root cause**:` and `**Verification**:`. Append only,
to the END of the file.

## 🔴 PARALLEL-SAFE STATE — THIS PR WRITES ONLY ITS WORK UNIT'S FRAGMENT (`common/parallel-work-state.md`)

A `pr-fix` round commits on a PR head while other PRs merge into the same integration branch. So it
**never writes the shared `runtime-artifacts/audit.md` or `runtime-artifacts/aire-state.md`**:

- Every audit entry goes to **`runtime-artifacts/stories/<unit-key>/audit.md`** — the work unit's existing
  fragment (`story-<N.M>`, `bug-<ID>`, `enhancement-<ID>`), plus `**Unit**:`. Step 1 entries are held
  until Step 2 resolves the unit key.
- The Story Tracker row, `## PR Feedback Rounds`, progress and SH counters go to
  **`runtime-artifacts/stories/<unit-key>/state.md`**.
- This overrides every mention of those two shared paths below. Reads use the **resolved view**.
- A PR head created before this rule may already carry shared-file edits: the **State Isolation Check**
  (Section 5.5) before this round's commit moves them into the fragment and restores the shared files.
- Step 3's merge of the target branch into the head can therefore never conflict on bookkeeping.

---

## Step 0 — 🔴 Single-Session Check (MANDATORY, before anything else)

Determine whether this run is the user's own interactive session or a fork / subagent (signals: the
run's own instructions say it is a fork or a subagent, tell it to "execute directly" or not to spawn
agents, or the Agent tool is unavailable to it).

- **Main session** → continue silently.
- **Fork or subagent** → HALT immediately. Read nothing further, change nothing, and output:
  ```
   pr-fix MUST RUN IN YOUR OWN SESSION
     This run is executing inside a [fork | subagent]. pr-fix never runs delegated — every fix and
     every gate must happen in the session you typed it in.
     Nothing was read, changed, committed or pushed.
  Type pr-fix in your main Claude Code session.
  ```
  Log the halt in `runtime-artifacts/audit.md` if the file is reachable.

## Step 1 — Which PR?

1. **Log** the invocation (complete raw input) in `runtime-artifacts/audit.md`.
2. **PR given with the keyword** (`pr-fix 142`, `pr-fix #142`, or a PR URL) → use it; go to Step 2.
3. **No PR given** → list the candidates and ask:
   ```bash
   gh pr list --state open --label ai-generated --limit 50 \
     --json number,title,headRefName,baseRefName,reviewDecision,url,updatedAt
   ```
   Keep only titles starting `[STORY]`, `[BUG]` or `[ENH]`. For each, count unresolved review
   threads (the Step 4.1 GraphQL query, `isResolved: false`). Present:
   ```
   Which PR should I fix? (number or URL)

   #    Type     Work unit        Review decision     Unresolved threads   Head → Target
   142  [STORY]  Story 1.2 PROJ-102  CHANGES_REQUESTED   4                    story/PROJ-102-1.2-… → epic/PROJ-50-…
   151  [BUG]    PROJ-123         REVIEW_REQUIRED     2                    bug/PROJ-123-… → main

   [Answer]:
   ```
   Sort CHANGES_REQUESTED first, then by unresolved-thread count. If there are no candidates, say so
   and stop. **Never guess the PR** — wait for the answer, and log it verbatim.

## Step 2 — Resolve the PR, the work unit and the preconditions

1. **Read the PR**:
   `gh pr view <n> --json number,title,state,isDraft,headRefName,baseRefName,labels,author,reviewDecision,mergeable,mergeStateStatus,url,body,headRefOid`
2. **State check**:
   - `MERGED` → stop with the Section 1.5 route (raise a defect → `ticket-implement`).
   - `CLOSED` → stop: reopen it or re-run the owning implement workflow.
   - `OPEN` (draft or not) → continue.
3. **Resolve the work unit and the owning workflow** — all three signals must agree:

   | Title prefix | Head branch | Target branch | Work unit | Evidence key | Behaviour spec | Owning workflow |
   |---|---|---|---|---|---|---|
   | `[STORY]` | `story/<…N.M>-…` | the Epic Branch in `## Branching` | Story N.M (Story Tracker row whose `PR` column is this PR) | `story-N.M` | `spec/behavior/story-N.M.feature` | `workflows/dev-implement.md` |
   | `[BUG]` | `bug/<ID>-…` | the Base Branch | the bug ticket (the PR in its state fragment, or live from the bug branch) | `bug-<ID>` | `spec/behavior/bug-<ID>.feature` | `workflows/bug-fix-implement.md` |
   | `[ENH]` | `enhancement/<ID>-…` | the Base Branch | the enhancement ticket | `enhancement-<ID>` | `spec/behavior/enhancement-<ID>.feature` | `workflows/enhancement-implement.md` |

   Any other prefix, a missing `ai-generated` label, or signals that disagree → stop with the
   Section 1.5 route, naming the mismatch. Load the owning workflow now.
4. **Working tree**: `git status --porcelain` must be empty. Uncommitted changes → stop and tell the
   user to commit or stash them; never stash or discard them yourself.
5. **Tracker**: resolve the work unit's `Tracker ID` from the Story Tracker / `## Tracker`.
6. **Archived-cycle check (bug/enhancement PRs)**: after Step 3 checks out the head branch, if
   `runtime-artifacts/aire-state.md` or `spec/` is missing there **and**
   `aire-archives/{bugs|enhancements}/<ID>-<slug>/` exists, the cycle archive already ran on this PR.
   The gates cannot re-run without the live `spec/`, `reports/` and `runtime-artifacts/`. Ask once:
   ```
    The cycle archive already ran on <head-branch> (commit <sha>), so spec/, reports/ and
      runtime-artifacts/ are no longer live. Fixing this PR needs them back.
      A) Revert the archive commit (git revert <sha> — no history rewrite), fix, then YOU re-run
         archive-epic before the PR merges
      B) Stop — nothing changed
   [Answer]:
   ```
   A → `git revert --no-edit <archive-sha>`, announce it, and carry a reminder into the Step 19
   handoff. B → stop. Log the prompt and the raw answer.
7. **Round number** — round states: `in-progress` (before this round's commit) → `pushed` (its
   `pr-fix round <R>` commit is on the PR head) → `complete` (Steps 15–18 done; recorded locally and
   carried by the next commit). R = 1 + the number of `pushed` or `complete` rounds for this PR in the **resolved**
   `## PR Feedback Rounds` (the work unit's fragment `runtime-artifacts/stories/<unit-key>/state.md`
   plus the shared section — `common/parallel-work-state.md` Section 4). A round recorded
   `pushed` (or an `in-progress` round whose commit is already on the PR head) was interrupted after its
   push — resume it from Step 15. If that table has an **in-progress**
   round for this PR, resume it: reload its Feedback Ledger and SH counters and continue from the
   gate it stopped at, skipping every gate the ledger records as passed. Announce which.

## Step 3 — Sync the head branch (no history rewrite, ever)

1. `git fetch origin`, `git checkout <head-branch>`, `git pull --ff-only`.
2. **Never race CI self-repair** (`common/ci-pipeline-generation.md` Section 6.6): if a self-repair
   run is `queued`/`in_progress` on this head (`gh run list --branch <head> --json status,name`), wait
   for it to conclude, then `git pull --ff-only` again and re-read its result.
3. **Bring the target in**: if `origin/<target>` has commits the head lacks
   (`git rev-list --count HEAD..origin/<target>` > 0), merge it:
   `git merge --no-ff origin/<target> -m "Merge <target> into <head-branch> (pr-fix round R)"`.
   - Clean merge → record it; baselines are recaptured at Step 8.
   - Conflicts → resolve them as part of this round, grounding each hunk in both sides' specs
     (the other work unit's ACs are as binding as this one's). A conflict whose correct resolution
     cannot be derived from the specs → abort the merge (`git merge --abort`), HALT, and report the
     files and the competing intents.
   - 🔴 Never `git rebase` a pushed branch, never `git push --force`.
4. Log the head SHA before and after, and the merge result.

## Step 4 — Harvest the feedback

1. **Pull everything in one GraphQL call** (paginate if `hasNextPage`):
   ```bash
   gh api graphql -F owner=<owner> -F name=<repo> -F number=<n> -f query='
   query($owner:String!,$name:String!,$number:Int!){
     repository(owner:$owner,name:$name){ pullRequest(number:$number){
       reviewThreads(first:100){ nodes{ id isResolved isOutdated path line originalLine
         comments(first:100){ nodes{ databaseId author{login} body createdAt url } } } }
       reviews(first:100){ nodes{ databaseId state author{login} body submittedAt url } }
       comments(first:100){ nodes{ databaseId author{login} body createdAt url } }
     } } }'
   ```
2. **Tracker feedback**: on a non-LOCAL tracker, read the work unit's comments created after the PR was
   opened and keep those starting `Verification Engineer rejected the story`. On LOCAL, read the ve rejection note in the
   Story Tracker / `runtime-artifacts/audit.md`.
3. **CI feedback**: if the latest `agentic-eval-pipeline.yml` run on the head concluded `failure` and
   CI self-repair has exhausted `retryLimitForSelfRepair` (its exhaustion comment is on the PR), read
   `failed-gates.txt` / `eval.json` from that run's `eval-results` artifact.
4. **Separate human feedback from the framework's own output — by record, never by login**:
   - **Exclude as framework output**: every review and review comment whose ID `runtime-artifacts/audit.md`
     records as an AUTO-MODE `pr-review` post (the owning workflow's auto PR review step, and Step 17
     of earlier rounds); every comment carrying an `<!-- aire:` marker; comments by bot accounts
     (except the CI exhaustion case above).
   - **Include an auto-review thread only when a human replied in it** asking for action ("agreed,
     please fix") — the human reply makes it human feedback.
   - **Exclude**: resolved threads; pure approval or praise ("LGTM", "nice"); and any item whose
     latest message is a pr-fix reply (marker present) with no later human message — it was handled in
     an earlier round.
   - **Keep outdated threads** that are still unresolved — they become ALREADY-ADDRESSED if the head
     now satisfies them, otherwise normal items.
5. **Nothing actionable** → if `reviewDecision` is `CHANGES_REQUESTED` with no actionable text, say:
   `PR #<n> has changes requested but no comments to act on — ask the reviewer to add the change they
   need as a comment, then type pr-fix <n>.` Otherwise say `Nothing to fix on PR #<n>.` Stop without a
   commit. Log it either way.

## Step 5 — Triage into the Feedback Ledger

Give every harvested item an ID `FB-NN` and exactly one class:

| Class | Meaning | Action |
|---|---|---|
| **FIX-CODE** | A defect or change within the approved ACs, requirements and design (includes in-scope nits) | Fixed at Step 10 |
| **FIX-TEST** | A missing, weak or misplaced test | Fixed at Step 10 |
| **CI-FAILURE** | A failed CI gate that CI self-repair could not fix | Fixed at Step 10 |
| **AMEND-AC** | Asks for behaviour that differs from an approved AC, `Covers` requirement or `.feature` scenario | Step 6 decides |
| **CONFLICT** | Incompatible requests, or too ambiguous to act on safely | Step 6 decides |
| **ANSWER** | A question with no change requested | Answered in the reply; if answering reveals a defect, reclassify FIX-CODE |
| **DECLINE** | Would break the Security Baseline, an `architecture.md` Section 10 constraint, an approved AC, or is a forbidden shortcut (SH-6) | Not applied; the reply cites the rule |
| **DEFER** | Valid but outside this work unit's scope | Not applied; the reply recommends `/raise-defect` or a new story |
| **ALREADY-ADDRESSED** | The current head already satisfies it | Reply with `file:line` evidence |

Rules:
- **Ground every classification**: cite the AC / REQ-ID / ARCH-NN / SECURITY-NN it rests on. A
  classification with no citation is a triage defect — redo it.
- **Read the comment against the code it points at** (`path` + `line` for inline threads) before
  classifying. Never classify from the comment text alone.
- A reviewer comment is never DECLINE merely because it is inconvenient; DECLINE needs a cited rule.
- Split a comment that asks for several things into several items.

Write the ledger to `reports/pr-feedback/<evidence-key>/round-<R>/feedback-ledger.md`:

```markdown
# Feedback Ledger — PR #<n> — <work unit> — round <R>
Head at start: <sha> · Target: <target> · Started: <ISO timestamp>

| ID | Source | Author | Where | Request (quoted) | Class | Grounded in | Status | Evidence |
|----|--------|--------|-------|------------------|-------|-------------|--------|----------|
| FB-01 | review thread <url> | @login | src/cart/service.ts:88 | "…" | FIX-CODE | AC-3 | open | — |
```

Announce the ledger summary (counts per class) and log it in full. Record the round as
`in-progress` in `## PR Feedback Rounds` (Step 18 lists the columns).

## Step 6 — Clarification (CONDITIONAL — the only question in a normal run)

**Skip this step entirely when the ledger has no AMEND-AC and no CONFLICT items.** Otherwise ask ONE
inline block covering all of them, and wait:

```
 PR #<n> needs your decision on <K> item(s) before I change anything:

FB-03 — @<login>, inline src/orders/api.ts:42: "<quoted request>"
   Conflicts with the approved contract: AC-2 of Story 1.2 — "<AC text>"
   A) Amend the contract — update the AC, the covered requirement, the .feature scenario, the
      test plan and the tracker item together, then implement it
   B) Keep the approved contract — decline FB-03, citing AC-2 in the reply
   C) Defer — out of this PR; I will recommend a new ticket in the reply

FB-05 — CONFLICT between @<dev-login> (src/ui/form.tsx:10) and @<ve-login> (review <url>):
   @<dev-login>: "<quote>"   @<ve-login>: "<quote>"
   A) Follow @<dev-login>   B) Follow @<ve-login>   X) Other (describe)

[Answer]:  (one line per item, e.g. "FB-03 A, FB-05 B")
```

Validate that every listed item got exactly one answer; re-ask only for missing or invalid ones. Apply
the answers to the ledger (A on AMEND-AC → it stays AMEND-AC and is applied at Step 7; B → DECLINE;
C → DEFER; a CONFLICT answer → FIX-CODE / FIX-TEST in the chosen direction, or DECLINE). Log the prompt
and the complete raw answer.

## Step 7 — Apply approved contract amendments (only for AMEND-AC items answered A)

A contract change moves every artifact that encodes it **together**, in this order, each change
announced and logged as a reconciliation citing the FB-ID and the comment URL:

1. The AC in `spec/plans/stories.md` (bug/enhancement: the single story section), and the tracker item's
   description / AC field via `common/tracker-sync.md` (LOCAL: the local story only).
2. The covered REQ text in `spec/plans/requirements.md`, only if the requirement itself changed.
3. The scenario(s) in the behaviour spec (`spec/behavior/<key>.feature`) — the ONE place a scenario may
   be rewritten, because the contract itself changed; keep the `@AC-n` tag.
4. The manual test plan — invoke the `ve-implement` skill in **WORKFLOW MODE**, scoped to the amended
   AC(s); it re-derives those cases with AC traceability. Never hand-edit the plan to match code.
5. `spec/plans/architecture.md` Section 10 only if a **design decision** changed; then regenerate
   `tests/.evals/rubrics/architecture-rubric.json` from it (`implementation/architecture-doc.md`
   Section 4). Never hand-edit a rubric, and never touch Section 10 to rescue a judge score.

These edits ride this round's commit.

## Step 8 — Baselines for this round

The gates diff against a baseline, and that baseline must describe the target branch as it is now.

- **Reuse** the work unit's existing baseline evidence (`baseline-regression.log`,
  `static/baseline/`, `playwright-baseline-regression.log`, committed on the head branch under
  `reports/`) **only if** Step 3 merged nothing **and** `git merge-base origin/<target> HEAD` equals the
  base SHA recorded in the original run's evidence manifest. Record `baseline: reused (<sha>)`.
- **Otherwise recapture**, in this session, at the current merge-base, using a throw-away worktree in
  the scratchpad (a directory, not a new session):
  ```bash
  BASE_SHA="$(git merge-base origin/<target> HEAD)"
  git worktree add "<scratchpad>/aire-pr-fix-baseline-<key>" "$BASE_SHA"
  ```
  1. Copy the head branch's eval tool configs (the lint / type / complexity / gitleaks configs the
     work unit's bootstrap created) into the worktree first, so the baseline and the post-fix run
     measure under the **same rules** (`common/eval-framework.md` Section 2.3).
  2. Install per the manifest's `installCommands` for each root, then run the owning workflow's three
     baseline runs there — full test suite, D1–D7, the full `tests/e2e/` suite headless (or record
     its N/A reason).
  3. Write the results over the work unit's baseline evidence files, marking each evidence manifest
     `baseline recaptured by pr-fix round <R> at <BASE_SHA>`.
  4. Remove the worktree (`git worktree remove --force <path>`) on every exit path.
- Baseline failures stay pre-existing debt: logged, never fixed here, never blocking.

## Step 9 — Fix plan (announced, not approved)

Write `spec/spec-generation/<evidence-key>-pr-fix-round-<R>.md`:
- one checkbox step per change, each tagged with the FB-ID(s) it resolves and the AC / REQ-ID it
  touches,
- a trace self-check: every FIX-CODE, FIX-TEST, CI-FAILURE and applied AMEND-AC item appears in at
  least one step (blocking, fixed silently before announcing),
- nothing that is not traceable to a ledger item — no opportunistic refactors.

Re-read the file from disk to confirm it exists, then announce it and log it under a plain heading
(`## pr-fix Round <R> — Plan Finalized (auto-approved, no gate)`). **Never ask for approval.**

## Step 10 — Apply the fixes

Execute the plan exactly, marking each step `[x]` as it completes. Application code goes in `src/` (or
the recorded `## Code Root`), tests in the repo-root `tests/` tree (`tests/unit/`, `tests/api/`,
`tests/behavior/steps/`), nothing in `spec/` except Step 7's contract edits. A needed deviation →
revise the plan file, announce what changed and why, log it, continue. 🔴 **Fix the code, never the
check**: SH-6 forbids deleting, skipping or weakening a test, suppressing a finding, lowering a
threshold or editing an approved scenario to make feedback "pass".

## Step 11 — Re-run the COMPLETE gate chain

Run every gate of the owning workflow, **in its order, exactly as that step defines it**, against the
**whole work unit** — its full diff versus `git merge-base origin/<target> HEAD`, not only this round's
fix. A reviewer's comment fixed in one place must not have broken an AC somewhere else in the same work
unit.

| Gate | Story — `dev-implement` | Bug — `bug-fix-implement` | Enhancement — `enhancement-implement` | Loop |
|---|---|---|---|---|
| Playwright Readiness (when this round makes or changes UI) | Step 4.3 | Step 4.4 | Step 11.4 | — |
| Behaviour spec verify (read, never rewrite; Step 7 is the only amendment path) | Step 4.5 | Step 4.5 | Step 11.5 | — |
| Unit tests + coverage ≥ `unitTestCoverageMin` | Step 6 | Step 6 | Step 13 | SH-LOOP-1 |
| Gherkin B1 → B2 → B3 in Podman (B3 only if this is the last work unit by PR merge state) | Step 6.1 | Step 6.2 | Step 13.2 | SH-LOOP-7 / 8 |
| API & contract (when the work unit or this fix touches an API layer) | Step 6.2 | Step 6.5 | Step 13.5 | SH-LOOP-2 |
| Test placement verification | Step 6.3 | — (not in that workflow) | — (not in that workflow) | SH-LOOP-12 |
| Full regression vs the Step 8 baseline | Step 6.5 | Step 7 | Step 14 | SH-LOOP-3 |
| Static eval D1–D7 vs the Step 8 baseline | Step 6.6 | Step 7.5 | Step 14.5 | SH-LOOP-4 |
| Test plan presence + Playwright UI automation | Step 6.7 | Step 7.7 | Step 14.7 | SH-LOOP-11 |
| Playwright E2E regression — every work unit, UI or not | Step 6.8 | Step 7.8 | Step 14.8 | SH-LOOP-13 |

Round-specific rules:
- **Evidence** is refreshed in place under the same evidence key (`reports/unit-test-evidence/<key>/`,
  `reports/behavior-test-evidence/<key>/`, `reports/eval-evidence/<key>/`, and so on); the previous
  round's evidence stays in git history. Every evidence manifest records `pr-fix round <R>`.
- **Playwright UI gate applicability**: if the work unit already has specs in
  `tests/e2e/<slug>/`, re-execute them `--headed` every round. Invoke the `playwright-implement`
  skill in WORKFLOW MODE when this round's fix changes UI behaviour a spec covers, when a UI AC was
  amended at Step 7, or when the fix introduces UI into a work unit that had none. Otherwise part 2 is
  N/A with the reason recorded.
- **Every gate runs**, including ones that passed in the original run. "It passed last time" is not
  evidence for this head.
- **Change, bugfix and Change Request stories** (a `[STORY]` PR whose story has
  `spec/plans/change-story-<N.M>.md` or `spec/plans/bugfix-story-<N.M>.md`, raised by `epic-enhance` /
  `epic-bugfix`, **or** whose plan lives in a Change Request bundle
  `spec/plans/change-requests/CR-<n>/change-request.md`, raised by `epic-change-request`): also honour that
  document's **Test Change Authorization list** in the regression gates and run
  `workflows/epic-enhance.md` **Step 12 (Test Impact Reconciliation, SH-LOOP-15)** after the chain —
  for a bugfix story including its reproduction check (`workflows/epic-bugfix.md` Step 14), and for a
  Change Request story including its stale-trace check (`workflows/epic-change-request.md` Phase 10.5
  item 5: every amended requirement has a story tracing to its new version). A reviewer comment that
  needs an earlier story's test changed beyond the list is an AMEND-AC item (Step 6), never a silent
  list extension.
- Exhaustion of any loop → SH-4: HALT at that gate with the Retry-Limit Report. No commit, no push, no
  PR update, no tracker change; the round stays `in-progress` in `## PR Feedback Rounds`.

## Step 12 — Feedback Resolution Verification (SH-LOOP-14)

For every FIX-CODE, FIX-TEST, CI-FAILURE and applied AMEND-AC item, re-read the original comment and
the head diff, and confirm the request is actually satisfied — not merely touched. Record
`resolved` with `file:line` evidence (and the test that proves it, where one exists) in the ledger.

- Every item resolved → Step 13.
- Any item not resolved → fix it, then re-enter Step 11 at the earliest gate the change affects,
  **continuing** those loops' existing counters (SH-2). One fix-and-reverify cycle is one SH-LOOP-14
  attempt; cap 3; exhaustion → SH-4 HALT naming each unresolved FB-ID.

## Step 13 — Automated Code Review, security, judge gates, auto-remediation

Execute the owning workflow's review block — **Story: Sections A → B → C; Bug: Step 8 (8a → 8b → 8c);
Enhancement: Step 15 (15a → 15b → 15c)** — unchanged, with these additions:
- The review produces the next report version `v[X+1]` under `reports/reviews/`; its Phase 0 mode is
  whatever `implementation/code-review.md` Phase 0 selects from the report history.
- Pass the Feedback Ledger in as review input. The report adds a **Review Feedback Resolution** table
  (FB-ID → class → status → `file:line`), and a FIX-* item the review finds unresolved is a 🔴 finding.
- The Phase 2.5 security pass stays **diff-scoped to the whole work unit**; its 🔴/🟠 findings become
  `SEC-ISS-XXX` findings.
- **J1 + J2 are re-scored once** on the whole work unit's diff against the current rubrics and are
  **blocking** — below minimum → SH-LOOP-6.
- Findings → the auto-remediate loop (SH-LOOP-5), max 3 rounds, re-running the regression gates the
  fix touches, then re-reviewing. The review runs inline and read-only by discipline (Single-Session
  Execution).

## Step 14 — Scorecard, manifest, commit, CI preflight, push

1. **Scorecard**: `reports/eval-evidence/<key>/eval.json` and `eval-summary.md` reflect this round's
   gates (every gate PASS or N/A with its reason; `selfHealing` counters for this round).
2. **Resolution summary**: write `reports/pr-feedback/<key>/round-<R>/resolution-summary.md` — the final
   ledger, the gate table, the commit(s) and the review report version.
2.5. **Artifact Completeness Check (SH-LOOP-16)** — `common/work-unit-artifacts.md` Section 5 for this work unit, on the refreshed evidence, before manifest reconciliation; nothing is committed until it is clean.
3. **Manifest reconciliation** — only when `## CI/CD Configuration` records `Enabled: Yes`: extend this
   work unit's **own** fragment `tests/.evals/ci-manifest.d/<key>.json` for anything this round's
   fix newly established (append-only; never another unit's fragment, never `config.json`), then re-run
   `validate-pipeline.{sh,ps1}`.
4. **Commit** on the head branch — the fix, tests, Step 7 contract edits, refreshed evidence, the
   ledger and summary, the CI manifest fragment, and the work unit's state fragment
   `runtime-artifacts/stories/<unit-key>/` with this round recorded `pushed` in `## PR Feedback Rounds` —
   nothing unrelated, and 🔴 never the shared `runtime-artifacts/audit.md` / `aire-state.md` (run the
   State Isolation Check, `common/parallel-work-state.md` Section 5.5, first):
   ```
   git commit -m "[<Story N.M | BUG | ENH> / <TRACKER-ID>] pr-fix round <R> — address review feedback on PR #<n>" \
              -m "Resolves: FB-01, FB-02, FB-04" -m "AIRE-Version: [N]"
   ```
   `[N]` is read live from `CLAUDE.md`. Record the commit hash.
5. **CI preflight (SH-LOOP-9)** — only when `Enabled: Yes`: execute the owning workflow's preflight
   step (Story: Section D Step 2.5; Bug: Step 9 item 1.5; Enhancement: Step 16 item 1.5) exactly.
6. **Push**: check again for an in-flight CI self-repair run (Step 3.2), then `git push origin
   <head-branch>`. 🔴 Never `--force`. If the push is rejected because the remote moved, fetch, merge
   (`git merge --no-ff origin/<head-branch>`); if the incoming commits touch `src/**` or `tests/**`,
   re-run Step 11 onward once; if the remote moves again during that re-run, HALT and report.

## Step 15 — CI attestation (SH-LOOP-10)

Only when `Enabled: Yes`: execute the owning workflow's attestation step (Story: Section D Step 8; Bug:
Step 10.5; Enhancement: Step 17.5) for the new head SHA — watch the run, cross-check CI's `gates`
against this round's local results, repair declarations only, and leave Code-class failures to CI
self-repair.

## Step 16 — Update the PR

1. **Scorecard in the PR body**: read the body (`gh pr view <n> --json body`), replace the contents of
   its `## Eval Scorecard` section with this round's `eval-summary.md`, and add or update a
   `## Review Feedback Rounds` section (one row per round: round, date, commit, fixed / answered /
   declined / deferred counts, link to `resolution-summary.md`). Write it back with
   `gh pr edit <n> --body-file <file>`, then **read it back and confirm both sections landed** — record
   only what the read-back shows.
2. **Labels**: confirm `ai-generated` and `aire-v[N]` are still present; re-add any that are missing.
3. **Reply to every ledger item except those still open**, each reply starting with the marker line:
   ```
   <!-- aire:pr-fix round=<R> item=FB-NN replies-to=<comment-id> -->
   **AIRE pr-fix — round <R> — FB-NN: <CLASS>**
   <FIXED: what changed, with file:line | ANSWER: the answer | DECLINE: the rule it would break, cited |
    DEFER: why it is out of scope + the recommended /raise-defect or story | ALREADY-ADDRESSED: evidence>
   Commit: <sha> · Evidence: reports/pr-feedback/<key>/round-<R>/resolution-summary.md
   ```
   - Inline thread → `gh api repos/<owner>/<repo>/pulls/<n>/comments/<comment-id>/replies -f body=@-`
   - Review body or top-level comment → `gh pr comment <n> --body-file <file>`, quoting and linking the
     original.
   - Tracker ve rejection → a tracker comment via `common/tracker-sync.md` Section 10, leading with
     `pr-fix round <R>: the Verification Engineer findings were addressed in PR <url>`.
   - 🔴 **Never resolve a thread and never dismiss a review** — the reviewer decides whether the reply
     satisfies them.
4. **Re-request review** from every human reviewer who left feedback this round and is not the PR
   author: `gh api -X POST repos/<owner>/<repo>/pulls/<n>/requested_reviewers -f "reviewers[]=<login>"`.
5. Log the PR updates, every reply URL and the re-requested reviewers in `runtime-artifacts/audit.md`.

## Step 17 — Automated PR review

Invoke the `pr-review` skill in **AUTO MODE** on the updated PR (the owning workflow's auto PR review
step, unchanged): a plain COMMENT review, no prompt. Record its review ID and URL in
`runtime-artifacts/audit.md` as framework output, so later rounds exclude it at Step 4.4.

## Step 18 — Tracker and state

1. **Status does not change.** The work unit stays `In Development`; only `ve-list-work` Option B
   promotes to `Ready for Testing`. Do not remove a `ve-rejected` label — `ve-list-work` removes it
   on approval.
2. **Tracker comment** (non-LOCAL, automatic): `AIRE pr-fix round <R>: PR <url> updated — <x> fixed,
   <y> answered, <z> declined, <w> deferred.` Verify it landed. LOCAL: note it in the Story Tracker.
3. **Story Tracker row** (in the fragment): `PR` unchanged, `Merged` = `no`, `Recorded` = now.
4. **`## PR Feedback Rounds`** in the work unit's fragment `runtime-artifacts/stories/<unit-key>/state.md`
   (never the shared file) — mark this round complete. This post-push update is **not pushed on its
   own** (a state-only push would start a CI run on a new head); it rides the next commit on the PR
   (`common/parallel-work-state.md` Section 4.6):

   | PR | Work Unit | Round | Started | Finished | Head SHA | Fixed | Answered | Declined | Deferred | Outcome |
   |----|-----------|-------|---------|----------|----------|-------|----------|----------|----------|---------|

5. **Repeat-feedback signal**: if any FB-ID in this round re-raises a request an earlier round marked
   resolved for the same reviewer and location, list it in the handoff under "Needs a conversation" —
   two rounds disagreeing about the same line is a human conversation, not another fix.

## Step 19 — Handoff (MANDATORY — the last thing the run outputs)

Emit this block verbatim, placeholders substituted, choosing the one NEXT line that matches the work
unit type. Say nothing after it.

```
 PR UPDATED — review feedback round <R> addressed. <Work unit> stays In Development.
   PR: <PR URL>  →  target `<target-branch>`   Commit: <sha>
   Feedback: <x> fixed · <y> answered · <z> declined (reasons in the replies) · <w> deferred
   Gates re-run on the whole work unit: all PASS / N/A — scorecard refreshed in the PR body.
   [Needs a conversation: FB-NN, FB-NN — same request resolved in an earlier round]
   [Reminder: the cycle archive was reverted — re-run archive-epic before this PR merges]

NEXT ACTIONS:
   1.  Reviewers (<@logins>): re-review the PR — every comment has an AIRE reply. Resolve the threads
       you are satisfied with; leave a new comment on anything still wrong.
   2.  Still not right? Type: pr-fix <n>
   3.  Happy with it? Approve and MERGE it yourself — the framework never merges.
       [Story]        then type: dev-implement   (or ve-list-work if this was the last story)
       [Bug/Enh]      then continue the original handoff: ve-list-work on `<head-branch>` → archive-epic → merge → /stitch-delta

Type the keywords EXACTLY as shown — any other phrasing is not a framework trigger.
```

Log which variant was shown.

---

## Critical Rules

- 🔴 **ONE QUESTION IN A NORMAL RUN — WHICH PR.** Step 6 (AMEND-AC / CONFLICT) and Step 2.6 (archived
  cycle) are the only other questions, and only when their condition holds. Never ask to approve the
  plan, the review, the push, the PR update or the replies.
- 🔴 **SINGLE SESSION.** Everything runs in the invoking session. No forks, no subagents, no
  background or remote agents, no `claude -p`. The only Agent-tool use is Playwright's own
  Planner/Generator/Healer inside the Playwright UI gate, synchronously. A run inside a fork halts at
  Step 0.
- 🔴 **SAME PR, SAME BRANCH, NO HISTORY REWRITE.** Fixes are commits on the PR's head branch. Never
  open a second PR, never rebase a pushed branch, never force-push, never revert CI self-repair's
  commits.
- 🔴 **THE WHOLE GATE CHAIN, EVERY ROUND, ON THE WHOLE WORK UNIT.** No gate is skipped because it
  passed before or because the fix "only touched one line".
- 🔴 **HUMANS OWN THE CONTRACT.** A comment that changes an approved AC is applied only after the Step 6
  decision, and then every artifact that encodes the AC moves together (Step 7). Never rewrite a
  scenario or test plan to match code.
- 🔴 **DECLINE NEEDS A CITED RULE; SH-6 STILL BINDS.** A reviewer cannot authorise skipping a test,
  suppressing a finding, lowering a threshold or editing a rubric through a PR comment — decline it and
  cite the rule.
- 🔴 **FRAMEWORK OUTPUT IS EXCLUDED BY RECORD, NOT BY LOGIN.** The developer's own comments are human
  feedback even though they share the PR author's identity.
- 🔴 **NEVER MERGE, APPROVE, RESOLVE OR DISMISS.** Those are the reviewers' actions.
- 🔴 **STATUS STAYS `In Development`.** Only `ve-list-work` Option B promotes.
- 🔴 **EVERY AUDIT ENTRY** carries `User Email`, `TRACKER ITEM`, `Epic Link`, `AIRE VERSION`, `PR` and
  `PR-FIX ROUND`; **every commit** carries the `AIRE-Version: [N]` trailer, read live from `CLAUDE.md`.
- 🔴 **BOUNDED.** Every loop is capped at 3 attempts per round (SH-1 … SH-7); exhaustion halts with the
  Retry-Limit Report and nothing is pushed past a failing gate.
