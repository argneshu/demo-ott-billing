# WORKFLOW: `ticket-implement <TICKET-ID>` (Unified Router — Bug OR Enhancement)

**Purpose**: ONE front door for working on an existing ticket in whichever tracker is configured (`## Tracker` → `Type`) — a Jira key, an ADO work item ID, a GitHub issue ref, or — for `Type: LOCAL` — no ID at all (the user describes the item inline instead). The router itself does NO development work — it captures the ticket, asks the user what it's about (bug fix vs enhancement), then hands off to the EXISTING workflow for that answer and follows it exactly:


The router NEVER duplicates, modifies, or shortcuts either target workflow. After routing, every rule of the chosen workflow applies as written.

## MANDATORY: Rule Details Loading

May be invoked standalone in a fresh session. Resolve `aire-workflow/` and load:
- `common/process-overview.md`, `common/session-continuity.md`, `common/question-format-guide.md`
- **`common/ci-setup-detection.md`** — detect existing AIRE-Helix CI infrastructure (Step 1.5 below)

Do NOT pre-load the bug or enhancement workflow files — load ONLY the one the user selects (saves context). Display the welcome message (`common/welcome-message.md`) once at start — the target workflow MUST NOT display it again.

All CLAUDE.md audit-logging rules apply: log EVERY user input verbatim in `runtime-artifacts/audit.md` (append-only, ISO 8601 timestamps, `**User Email**:` on every entry).

---

## Step 1 — Resume Check FIRST

If `runtime-artifacts/aire-state.md` exists, read it before anything else:
- If `## Tracker` records this SAME ticket with a `Workflow Type:` of `bug` or `enhancement`, **route immediately without asking** — the classification was already made. Route **stage-aware**:
  - `Workflow Type: bug`, analysis NOT yet complete → resume `workflows/bug-fix.md` from the recorded stage.
  - `Workflow Type: bug`, state records analysis/design complete (`awaiting bug-fix-implement`) but the fix not yet done — e.g. the session ended after analysis → announce ` Analysis already done for [TICKET-ID] — continuing with the fix implementation.`, read `workflows/bug-fix-implement.md`, and follow it exactly, as if the user had typed `bug-fix-implement`. (In an uninterrupted session this state is reached at `bug-fix` Step 9's Verification Engineer Handoff Break — it persists only if the user answered `no` there.)
  - A `PAUSED —` record (Playwright Readiness restart) → resume the fix / implementation phase at the step it names.
  - A `HALTED —` record in the ticket's `runtime-artifacts/stories/<unit-key>/state.md` `## Progress` (a self-healing limit or tool-installation halt) → resume the fix / implementation phase as a **hand-back**, per `common/self-heal-limit-guidance.md` Section 4 (`bug-fix-implement.md` Step 1 item 5, or `enhancement-implement.md` Phase B).
  - `Workflow Type: enhancement` → resume `workflows/enhancement-implement.md` from the recorded stage (its own yes/no implementation gate handles the analysis→implementation handoff — there is no second keyword in that flow).
  - Follow `common/session-continuity.md` for resume mechanics in all cases.
- **An EPIC cycle is open here** (`## Branching` records an `Epic Branch`, `## Tracker` has no `Workflow Type: bug`/`enhancement`, and `aire-archives/epics/<EPIC-ID>-*/` does not exist): a base-branch bug/enhancement cycle would overwrite this epic's state. Ask inline, exactly these two options, and wait:
  ```
   An epic cycle is open in this workspace (<EPIC-ID>, branch <epic-branch>).
     A) Deliver [TICKET-ID] inside the epic — a change story on the epic branch
        (runs epic-bugfix / epic-enhance: one change document, earlier stories' tests updated, [STORY] PR)
     B) Keep it separate — a base-branch bug/enhancement cycle. Run ticket-implement from a SEPARATE
        clone of the repo; nothing is changed here.
  [Answer]:
  ```
  **A** → ask this router's Step 3 question (bug fix vs enhancement) only if the ticket type is unclear, then read `workflows/epic-bugfix.md` (bug fix) or `workflows/epic-enhance.md` (enhancement) and follow it with this ticket, as if the user had typed `epic-bugfix <TICKET-ID>` / `epic-enhance <TICKET-ID>`. **B** → stop with that instruction. Log the prompt and the raw answer.
  🔴 **Exception — the ticket changes a REQUIREMENT, not just behaviour** (it amends, adds or withdraws text in `spec/plans/requirements.md`): that is neither a bug fix nor an enhancement. Do NOT ask Step 3's question; stop with the pointer `This ticket changes a requirement — run: epic-change-request <TICKET-ID>` (`workflows/epic-change-request.md`), which versions the requirement and routes every story that covered it. Log the pointer.
- If it records a DIFFERENT ticket/epic, ask the user which to keep — NEVER silently overwrite.
- If no state exists, continue to Step 2.

## Step 1.5 — CI Setup Detection + CI/CD Opt-In (runs once, recorded for downstream use)

**Execute this BEFORE routing**, whether resuming or starting fresh:

1. Load `common/ci-setup-detection.md` and execute the detection mechanism (check for the five mandatory CI artifacts).
2. **If detection reports EXISTS**: record `## CI Setup Status` `Status: exists` plus
   `## CI/CD Configuration` `Enabled: Yes` `Source: pre-existing` — **do NOT announce or ask
   anything**, this branch is a silent, automatic check.
3. **If detection reports MISSING**: ask the CI/CD Setup Opt-In question defined in
   `common/ci-setup-detection.md` (blocking — wait for the answer) and record `## CI Setup Status`
   `Status: missing` (yes) or `Status: declined` (no), plus the matching `## CI/CD Configuration`
   `Enabled: Yes|No`.
4. Log the detection (and, when asked, the question + raw answer) in `runtime-artifacts/audit.md`
   with the complete result. The recorded status/flag is read and consumed by the downstream workflow
   (`bug-fix.md` / `bug-fix-implement.md` / `enhancement-implement.md`) to decide whether to run full
   CI setup and whether to run the per-fix CI Preflight/Attestation gates.

On **resume**, if `## CI Setup Status` already exists in `aire-state.md` (`exists`, `missing`, or
`declined`), skip this step and reuse the recorded status — never re-ask.

## Step 2 — Ticket Capture

Dispatch on `## Tracker` → `Type`, per `common/tracker-sync.md` Section 8:
1. **JIRA/ADO/GITHUB**: parse the `<TICKET-ID>` from the invocation (key/ID/number or URL). If missing, ask for it and wait. Fetch the ticket (`getJiraIssue` / `az boards work-item show` / `gh issue view`): key, issue type, summary, description, acceptance criteria, labels.
2. **LOCAL**: no ID is expected in the invocation. Ask ` Describe the bug/enhancement (what's broken or what should change, and why):`, capture the answer, and mint a local ID (`BUG-LOCAL-N` / `ENH-LOCAL-N` — next unused N found by scanning `runtime-artifacts/aire-state.md`) to use as `<TICKET-ID>` for the rest of this flow.
3. **MANDATORY**: Log the invocation (complete raw input) and the ticket fetch/capture in runtime-artifacts/audit.md.

## Step 3 — Ask What the Ticket Is About ( blocking question)

Present a short ticket summary, then ask with a **recommendation derived from the ticket** (issue type Bug, `bug`/`defect` labels, or defect-style wording → recommend A; issue type Story/Task describing new/changed behavior → recommend B). The recommendation is a suggestion only — **the user's answer decides**.

** GUARDRAIL — exactly TWO options, inline in the terminal, nothing else**:
- Print the question **inline in the chat/terminal** as plain markdown — NEVER via an interactive picker/menu tool, and NEVER in a question file.
- The options are **exactly `A` and `B` as shown below** — do NOT add a `C`, an "Other", "Both", "Skip", "Not sure", or any additional option. This deliberately OVERRIDES `common/question-format-guide.md`'s A–E/"Other" pattern: routing is binary.
- Do NOT reword, merge, or extend the two options; only the `[bracketed]` placeholders are substituted.
- Accept only `A` or `B` (case-insensitive) as the answer. Anything else (including "C" or "other") → re-ask the same two-option question, do not guess.

```markdown
 **[TICKET-ID]** — [summary]
Type: [issue type] | Labels: [labels]
[1–2 line description excerpt]

 What is this ticket about?

A)  Bug fix — something existing is broken and must be fixed
   (runs the bug workflow: bug-fix analysis, the Verification Engineer handoff break, then the fix)
B)  Enhancement — extend or change the existing system's behavior
   (runs the enhancement workflow: analysis + implementation in one flow)

 Recommended: [A/B] — [one-line reason based on the ticket]

[Answer]:
```

**Block until the user answers.** Log the question and the verbatim answer in runtime-artifacts/audit.md.

## Step 3.5 — Context Project Opt-In (ask ONCE here, downstream reuses it)

This is an **input-capture** step, not development work — it does not create requirements, branches, or code. Ask it here so it is asked ONCE for the whole ticket flow; the routed workflow reads the recorded answer instead of re-asking.

1. **Ensure the folder**: ensure `spec/context-project/existing-knowledge/` exists at the workspace ROOT — **check first, create an empty folder only if missing**, never overwrite an existing one, no README (per `planning/workspace-detection.md` Step 4.6).
2. **Skip the question if already answered**: if `runtime-artifacts/aire-state.md` already has `## Context Project` with an `Existing Knowledge` field, reuse it — do NOT re-ask.
3. Otherwise ask ONCE (inline, per `common/question-format-guide.md`):
   ```
    Are there any context-project artifacts I should use for this task?
      (Human-authored knowledge about the CURRENT project — how the existing system works,
       where things live, what each module does — under spec/context-project/, one subfolder per
       module named exactly after it. This is context about what exists, NOT the ticket's requirements.)

   A) Yes — paste the exact path of the file/folder to use (e.g. spec/context-project/existing-knowledge/ABC.corp/interview.md)
   B) No  — continue without it

   [Answer]:
   ```
4. Record in `runtime-artifacts/aire-state.md` (only that pasted path is ever read — no auto-scan):
   ```markdown
   ## Context Project
   - **Existing Knowledge**: [Yes/No]
   - **Existing Knowledge Path(s)**: [exact path(s) pasted — or `—` if No]
   ```
   These are the field names `planning/workspace-detection.md` Step 4.7 writes and every stage reads.
5. Block until answered; log the prompt and verbatim answer in runtime-artifacts/audit.md. On A with a non-existent path, tell the user and re-ask.

## Step 3.5b — Context References Opt-In (ask ONCE here, downstream reuses it)

This is an **input-capture** step for reference materials that guide the NEW work (UX wireframes, design mockups, API specs, research docs, etc.). Ask it here so it is asked ONCE for the whole ticket flow; the routed workflow reads the recorded answer instead of re-asking.

1. **Ensure the folder**: ensure `spec/context-project/new-references/` exists at the workspace ROOT — **check first, create an empty folder only if missing**, never overwrite an existing one, no README.
2. **Skip the question if already answered**: if `## Context Project` in `runtime-artifacts/aire-state.md` already has a `New References` field, reuse it — do NOT re-ask.
3. Otherwise ask ONCE (inline, per `common/question-format-guide.md`):
   ```
    Do you have any reference materials I should use for this work?
      (UX wireframes, design mockups, UI/UX specifications, API specs, research docs,
       architecture diagrams, or any other reference documents — placed under spec/context-project/new-references/
       at the workspace root. These guide what to BUILD, not what already exists.)

   A) Yes — paste the exact path(s) of the file(s)/folder(s) to use
      (e.g. spec/context-project/new-references/wireframes/checkout-flow.png, spec/context-project/new-references/api-spec.yaml)
   B) No  — continue without it

   [Answer]:
   ```
4. Record in the same `## Context Project` section of `runtime-artifacts/aire-state.md` (only those paths are ever read — no auto-scan):
   ```markdown
   - **New References**: [Yes/No]
   - **New Reference Path(s)**: [comma-separated exact paths pasted — or `—` if No]
   ```
5. Block until answered; log the prompt and verbatim answer in runtime-artifacts/audit.md. On A with a non-existent path, tell the user and re-ask for that path.
6. **Auto-register UI/UX references as Design References**: any path that is a UI wireframe, mockup, screenshot, or design spec is ALSO registered in `## Design References` per DR-1.

## Step 3.6 — Load the Design Reference Guardrail (NO question — enforcement only)

**Load `common/design-reference-grounding.md` and apply it for the whole ticket flow.**

**Do NOT ask the user anything here.** This step adds no prompt. It is purely reactive enforcement:

- **DR-1** — any file path, folder path, spec document, screenshot, or design URL the user names in ANY input during this ticket flow (the ticket text itself, an answer, a scope adjustment, a remediation comment) is registered in `## Design References` in `runtime-artifacts/aire-state.md` at that moment.
- **DR-2/DR-3/DR-4** — the routed workflow MUST read its **actual content** in the stage where it was named, before generating that stage's artifacts. Confirming a path exists or listing folder names is not reading; a binary format is not a reason to defer.
- **DR-5** — re-consult it automatically before writing code touching a covered component, stating per component either `Design reference: <path> — grounded (...)` or `Design reference: none covers this component`. No gate, no checkpoint.
- **DR-8 / DR-6** — on a mismatch, check the `### Reconciliations` table first: a point already decided against the reference by an earlier stage is **settled — follow the framework artifact and never reintroduce it**. Otherwise follow the reference, state plainly what differed and that you followed it, amend the AC to stay truthful, record the reconciliation, and continue. **Never turn it into a question and never halt.**

If the ticket description itself names such an artifact, register it now and log it in `runtime-artifacts/audit.md`.

## Step 4 — Route to the Existing Workflow

On the user's answer:

- **A (Bug)** → announce ` Routing [TICKET-ID] to the bug workflow.`, read `workflows/bug-fix.md`, and follow it **exactly** from its Step 1, as if the user had typed `bug-fix [TICKET-ID]`. The already-fetched ticket content MAY be reused for its Ticket Capture step (no second fetch needed) — everything else runs as written — at the end of analysis it **breaks once** for the ve handoff (that flow's Step 9: design artifacts committed + pushed, `/ve-implement` instructions shown), then continues into `bug-fix-implement` in the same session on the user's `yes` — no second keyword needed. If the user answers `no`, or the session is interrupted after analysis, `ticket-implement [TICKET-ID]` resumes straight into `bug-fix-implement` via the router's Step 1 resume.
- **B (Enhancement)** → announce ` Routing [TICKET-ID] to the enhancement workflow.`, read `workflows/enhancement-implement.md`, and follow it **exactly** from its Step 1, as if the user had typed `enhancement-implement [TICKET-ID]`. The already-fetched ticket content MAY be reused for its Ticket Capture step. Its own issue-type warning still applies (a Bug-type ticket routed to enhancement → warn and confirm, per that workflow).

Log the routing decision in runtime-artifacts/audit.md. From this point on the target workflow OWNS the session — branch naming, state (`Workflow Type:`), gates, PR type, and archive location all come from it.

---

## Critical Rules

- 🔴 The router asks ONE question and routes — it never generates requirements, stories, branches, or code itself.
- 🔴 The routing question has EXACTLY two options — `A` and `B`, printed inline in the terminal. NEVER a `C`/"Other"/extra option, never an interactive menu, never a question file (this overrides the question-format-guide for this one question). Only `A` or `B` is a valid answer; anything else → re-ask.
- 🔴 The USER'S answer decides the route — the recommendation from issue type/labels is advisory only.
- 🔴 Load the target workflow file ONLY after the answer (context saving); then follow it EXACTLY — no steps skipped, merged, or reordered.
- 🔴 Resume safety: an existing `Workflow Type: bug|enhancement` for the same ticket routes immediately without re-asking.
- 🔴 Every audit entry carries `**User Email**:`; the routing question and answer are logged verbatim.
