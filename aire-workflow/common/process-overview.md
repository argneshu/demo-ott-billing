# aire Adaptive Workflow Overview

**Purpose**: Technical reference for AI model and developers to understand complete workflow structure.

**Note**: Similar content exists in welcome-message.md (user welcome message) and README.md (documentation). This duplication is INTENTIONAL - each file serves a different purpose:
- **This file**: Detailed technical reference with Mermaid diagram for AI model context loading
- **welcome-message.md**: User-facing welcome message with ASCII diagram
- **README.md**: Human-readable documentation for repository

## The Two-Phase Lifecycle:
• **PLANNING PHASE**: Planning and architecture (Workspace Detection → Requirements → User Stories → Dependency Graph → Workflow Planning → Application Design)
• **IMPLEMENTATION PHASE**: System-level design → Behaviour Specs & Test Plans (every work unit, one approval) →  STOP → per-story Code Generation via `dev-implement` (on a story branch cut from the Epic branch; code, then unit tests to `unitTestCoverageMin` coverage, then — when the story touches an API layer — the API & Contract Testing Gate) → automatic Code Review & Remediate

**🧪 ve TRACK (parallel, NOT part of any phase)**: **Test plan SIGN-OFF belongs to ve, not to Implementation** — neither at epic level nor at story level. 🔴 The plans themselves are now *authored* earlier: every work unit's `spec/test-plans/<TICKET-ID>-<title>/` is generated and approved at the **STOP CHECKPOINT**, before any code exists (`CLAUDE.md` Step 1.7, `implementation/specs-and-test-plans.md`), by invoking the same `ve-implement` skill in WORKFLOW MODE. ve reviews those plans and runs **`ve-list-work`** on the epic branch to move merged, tested stories to Ready for Testing — that remains the only sign-off path.

## The Adaptive Workflow:
• **Workspace Detection** (always; captures the Parent Epic link if provided, in whichever tracker was selected) → **Reverse Engineering** (brownfield only) → **Requirements Analysis** (always, adaptive depth) → **User Stories** (always; no team-size or creation-mode question — `team_size` is fixed at 2, all stories generated at once; the set requires explicit human approval — GATE 1 — then pushes to the configured tracker AUTOMATICALLY, linked to the Parent Epic) → **Dependency Graph** (always; assigns `requires`) → **Workflow Planning** (always) → **Application Design** (conditional) → **System-Level Design** (conditional; single pass) → **Behaviour Specs & Test Plans** (always; every work unit's `.feature` contract + manual test plan, ONE approval gate) →  **STOP** → **Code Generation** (per-story, via `dev-implement`, on story branches cut from the Epic branch, with unit tests to `unitTestCoverageMin` coverage plus — when the story touches an API layer — the API & Contract Testing Gate, and NO approval gates) → **Code Review & Remediate** (automatic inside every implement workflow — review, auto-fix findings, re-review until clean; also invokable standalone, story-wise or all stories). Running alongside: the **Verification Engineer track** — executing each story's approved test plan once its code is on the branch, and signing off with **`ve-list-work`**.

## How It Works:
• **AI analyzes** your request, workspace, and complexity to determine which stages are needed
• **These stages always execute**: Workspace Detection (incl. automatic Epic branch creation), Requirements Analysis (adaptive depth), User Stories (fixed team_size 2, all-at-once generation, GATE 1 human approval, then automatic push to the configured tracker), Dependency Graph (`requires`), Workflow Planning, Code Generation (per-story via `dev-implement`, with unit tests to `unitTestCoverageMin` coverage, plus the API & Contract Testing Gate when the story touches an API layer)
• **All other stages are conditional**: Reverse Engineering, Application Design, system-level design stages (Functional Design, NFR Requirements, NFR Design, Infrastructure Design)
• **Also invokable standalone**: Code Review and Remediate run automatically inside every implement workflow, and can also be invoked at any time for a specific story or all stories together (`code-review`, `remediate`)
• **ve-initiated, parallel to everything above**: executing the approved test plans once a story's code is on the branch, then `ve-list-work` (merged, tested stories → Ready for Testing). Never auto-run — ve types it.
• **Behaviour Specs & Test Plans (always, at the STOP CHECKPOINT)**: every work unit's Gherkin contract (`spec/behavior/<unit>.feature`) and manual test plan (`spec/test-plans/<TICKET-ID>-<title>/`) are written and approved in one pass **before any code is generated**; the implement workflows then read them and never author them
• **Mandatory STOP**: after the design stages and before any code generation, the workflow halts — code is generated per-story only when the user types `dev-implement`
• **No fixed sequences**: Stages execute in the order that makes sense for your specific task

## Your Team's Role:
• **Answer questions** in dedicated question files using [Answer]: tags with letter choices (A, B, C, D, E)
• **Option E available**: Choose "Other" and describe your custom response if provided options don't match
• **Work as a team** to review and approve each phase before proceeding
• **Collectively decide** on architectural approach when needed
• **Important**: This is a team effort - involve relevant stakeholders for each phase

## aire Two-Phase Workflow:

```mermaid
flowchart TD
    Start(["User Request"])
    
    subgraph PLANNING["🔵 PLANNING PHASE"]
        WD["Workspace Detection<br/><b>ALWAYS</b>"]
        RE["Reverse Engineering<br/><b>CONDITIONAL</b>"]
        RA["Requirements Analysis<br/><b>ALWAYS</b>"]
        Stories["User Stories<br/>(all-at-once + GATE 1)<br/><b>ALWAYS</b>"]
        DG["Dependency Graph<br/>(requires)<br/><b>ALWAYS</b>"]
        WP["Workflow Planning<br/><b>ALWAYS</b>"]
        AppDesign["Application Design<br/><b>CONDITIONAL</b>"]
    end
    
    subgraph IMPLEMENTATION["🟢 IMPLEMENTATION PHASE"]
        FD["Functional Design<br/><b>CONDITIONAL</b>"]
        NFRA["NFR Requirements<br/><b>CONDITIONAL</b>"]
        NFRD["NFR Design<br/><b>CONDITIONAL</b>"]
        ID["Infrastructure Design<br/><b>CONDITIONAL</b>"]
        SPECS["Behaviour Specs & Test Plans<br/>every work unit, before any code<br/><b>ALWAYS — 1 approval</b>"]
        STOP[" STOP — use dev-implement<br/><b>MANDATORY HALT</b>"]
        CG["Code Generation<br/>per-story + unit tests ≥ `unitTestCoverageMin`<br/><b>dev-implement</b>"]
        CR["Code Review / Remediate<br/><b>AUTOMATIC</b>"]
    end
    
    subgraph veTRACK["🧪 ve TRACK — parallel, not a phase"]
        BT["Test Plan execution<br/>plans written at the STOP checkpoint<br/><b>manual, by the ve</b>"]
        QS["ve Sign-off<br/>merged + tested → Ready for Testing<br/><b>ve-list-work</b>"]
    end
    
    Start --> WD
    WD -.-> RE
    WD --> RA
    RE --> RA
    
    RA --> Stories
    Stories --> DG
    DG --> WP
    
    WP -.-> AppDesign
    AppDesign -.-> FD
    WP -.-> FD
    FD -.-> NFRA
    NFRA -.-> NFRD
    NFRD -.-> ID
    ID --> SPECS
    WP --> SPECS
    SPECS --> STOP
    STOP -->|user types dev-implement| CG
    CG -.->|repeat per story| CG
    CG -.-> CR
    SPECS -.->|plans already written & approved| BT
    BT -.->|repeat per story| BT
    BT --> QS
    CG --> QS
    QS --> End(["Complete"])
    
    style WD fill:#4CAF50,stroke:#1B5E20,stroke-width:3px,color:#fff
    style RA fill:#4CAF50,stroke:#1B5E20,stroke-width:3px,color:#fff
    style Stories fill:#4CAF50,stroke:#1B5E20,stroke-width:3px,color:#fff
    style DG fill:#4CAF50,stroke:#1B5E20,stroke-width:3px,color:#fff
    style WP fill:#4CAF50,stroke:#1B5E20,stroke-width:3px,color:#fff
    style SPECS fill:#4CAF50,stroke:#1B5E20,stroke-width:3px,color:#fff
    style STOP fill:#E53935,stroke:#B71C1C,stroke-width:3px,color:#fff
    style CG fill:#4CAF50,stroke:#1B5E20,stroke-width:3px,color:#fff
    style BT fill:#26A69A,stroke:#00695C,stroke-width:3px,color:#fff
    style QS fill:#26A69A,stroke:#00695C,stroke-width:3px,color:#fff
    style CR fill:#FFA726,stroke:#E65100,stroke-width:3px,stroke-dasharray: 5 5,color:#000
    style RE fill:#FFA726,stroke:#E65100,stroke-width:3px,stroke-dasharray: 5 5,color:#000
    style AppDesign fill:#FFA726,stroke:#E65100,stroke-width:3px,stroke-dasharray: 5 5,color:#000
    style FD fill:#FFA726,stroke:#E65100,stroke-width:3px,stroke-dasharray: 5 5,color:#000
    style NFRA fill:#FFA726,stroke:#E65100,stroke-width:3px,stroke-dasharray: 5 5,color:#000
    style NFRD fill:#FFA726,stroke:#E65100,stroke-width:3px,stroke-dasharray: 5 5,color:#000
    style ID fill:#FFA726,stroke:#E65100,stroke-width:3px,stroke-dasharray: 5 5,color:#000
    style PLANNING fill:#BBDEFB,stroke:#1565C0,stroke-width:3px, color:#000
    style IMPLEMENTATION fill:#C8E6C9,stroke:#2E7D32,stroke-width:3px, color:#000
    style veTRACK fill:#B2DFDB,stroke:#00695C,stroke-width:3px, color:#000
    style Start fill:#CE93D8,stroke:#6A1B9A,stroke-width:3px,color:#000
    style End fill:#CE93D8,stroke:#6A1B9A,stroke-width:3px,color:#000
    
    linkStyle default stroke:#333,stroke-width:2px
```

**Stage Descriptions:**

**🔵 PLANNING PHASE** - Planning and Architecture
- Workspace Detection: Analyze workspace state and project type (ALWAYS)
- Reverse Engineering: Analyze existing codebase (CONDITIONAL - Brownfield only)
- Requirements Analysis: Gather and validate requirements (ALWAYS - Adaptive depth)
- User Stories: Create user stories and personas (all in one pass, `team_size` fixed at 2 — neither is asked); populate the Story Tracker; the generated story set requires explicit human approval (GATE 1) before it pushes to the configured tracker, each story linked to the Parent Epic from `runtime-artifacts/aire-state.md` `## Tracker` (ALWAYS)
- Dependency Graph: Record each story's `requires` dependencies so independent stories can be developed in parallel; write dependency-graph.yml (ALWAYS — right after User Stories)
- Workflow Planning: Create execution plan (ALWAYS)
- Application Design: High-level component identification and service layer design (CONDITIONAL)

**🟢 IMPLEMENTATION PHASE** - Design and Implementation
- Functional Design: Detailed business logic design at the system level (CONDITIONAL, system-level)
- NFR Requirements: Determine NFRs and select tech stack (CONDITIONAL, system-level)
- NFR Design: Incorporate NFR patterns and logical components (CONDITIONAL, system-level)
- Infrastructure Design: Map to actual infrastructure services (CONDITIONAL, system-level)
- Behaviour Specs & Test Plans: for EVERY work unit of the cycle, in one pass and under ONE approval gate — `spec/behavior/<unit>.feature` (one `@AC-n` scenario per acceptance criterion) and `spec/test-plans/<TICKET-ID>-<title>/` (manual steps, via the `ve-implement` skill in WORKFLOW MODE). Written **before any code exists**, committed with the design artifacts, then read — never rewritten — by the implement workflows (ALWAYS, at the STOP CHECKPOINT)
- STOP: mandatory halt after the design stages and the specs/test-plans approval, before any Code Generation
- Code Generation: Per-**story**, triggered by `dev-implement` only — Story Selection (by Tracker ID) → story branch cut from the Epic branch → Part 1 Planning → Part 2 Generation → unit tests generated + run to `unitTestCoverageMin` coverage (ALWAYS, per-story) → API & Contract Testing Gate (MANDATORY WHEN the story touches an API layer — automated tests against the real endpoints: functional, response-code validation, role-based authorization 401/403, error-response validation, request validation, response contract/schema validation) → Full Regression Gate
- Code Review: Review a story's code, or all stories together, read-only, produce a versioned report (automatic inside every implement workflow; standalone via `code-review`)
- Remediate: Fix issues from a review report (fix → unit test → green, running only the in-scope story's unit tests), annotate the report in place (automatic inside every implement workflow; standalone via `remediate`)

**🧪 ve TRACK** - Parallel to Implementation, owned by ve (NOT a Implementation stage at epic or story level)
- Test Plan: authored for every work unit at the STOP CHECKPOINT (above) by the `ve-implement` skill in WORKFLOW MODE — it reads the acceptance criteria (the configured tracker / `stories.md`), requirements and design artifacts, and writes **manual test steps** for every applicable test plan (integration, E2E, API, contract, security, performance, accessibility — whichever apply; there is no build-verification artifact) into `spec/test-plans/<TICKET-ID>-<title>/`. **Never reads application source code.** Manual test steps only: no test automation, no test execution. The Verification Engineer executes them once a story's code is on the branch. A standalone `/ve-implement` run on a story carries its reworked docs on its own `ve/...` branch and PR
- ve Sign-off: Triggered by **`ve-list-work`** on the cycle's integration branch (epic branch for epic cycles, bug/enhancement branch for those cycles) — pulls latest, reports which stories/tickets dev has merged (test these) vs still in development, then asks ve which merged-and-tested items to move to Ready for Testing and moves exactly those in the Story Tracker and the configured tracker (ve-initiated)
- Playwright Test Automation (mandatory extension): runs inside the implement workflows for frontend work units (the UI automation gate and the E2E regression sweep); **`/playwright-implement`** also runs standalone once a story's dev work and test plan are on the integration branch — orchestrates Playwright's own Planner/Generator/Healer agents into executable **UI/browser-only** automation. Never touches Story Tracker or tracker status

**Key Principles:**
- Phases execute only when they add value
- Each phase independently evaluated
- PLANNING focuses on "what" and "why"
- IMPLEMENTATION focuses on "how" — Test Plan is ve's parallel track, not a Implementation stage
- Simple changes may skip conditional PLANNING stages
- Complex changes get full PLANNING and IMPLEMENTATION treatment
---

## Bug/Defect Flow (variant)

When `runtime-artifacts/aire-state.md` `## Tracker` records `Workflow Type: bug` (started via `ticket-implement <TICKET-ID>` routed to bug, or the direct keyword `bug-fix <TICKET-ID>`, on an existing Bug/Story ticket in whichever tracker is configured — JIRA/ADO/GITHUB, or LOCAL with no ID at all), the lifecycle is the TRIMMED variant defined in `workflows/bug-fix.md` + `workflows/bug-fix-implement.md` — ONE flow with a single break at design-done — the **ve Handoff Break** (`bug-fix.md` Step 9: analysis + design artifacts committed and pushed on the bug branch, the Verification Engineer told to pull it and run `/ve-implement <TICKET-ID>`, then a yes/no that continues into the fix in the same session, no second keyword) — NOT the epic flow above:
• ONE branch `bug/<TICKET-ID>-<title>` from the base branch (no epic/story branches) • Impact Analysis + line-level AI-Origin Detection via `agents/defect-provenance-analyst.md` (traces each defective line to its introducing commit; may label the ticket `ai-generated-defect`; resolves the originating story/bug/enhancement ticket and links the bug to it as `is caused by` — automatic, no confirmation; JIRA resolves a typed link at runtime, ADO/GITHUB fall back to a comment, LOCAL notes it locally) • ONE story from the ticket, NO Dependency Graph, no tracker story push • no PR at requirements approval — a single `[BUG]` PR to the base branch at the end • baseline + full regression runs around the fix • ticket stays In Development after the PR — Verification Engineer transitions it via `ve-list-work` Option B run **on the bug branch, before the archive** (never on the base branch; a cycle completes when its PR merges) • 🔴 **MANUAL archive** — the operator runs `archive-epic` (→ `aire-archives/bugs/<BUG-ID>-<name>/`) once the ve test-plan PR has merged into the bug branch, and before the `[BUG]` PR merges; the workflow NEVER auto-invokes it. archive-epic writes this cycle's RE delta to `spec/plans/delta/<TICKET-ID>-<slug>/`, archives it, and removes the live `spec/`/`reports/`/`runtime-artifacts/` trees; once the `[BUG]` PR merges, the operator runs **`/stitch-delta`** on the base branch, which reads that delta **from the archive** and publishes it to the Atlas deep dive via the Helix MCP (its own PR is a single ledger row) — so the next cycle pulls truth from Atlas that already includes this one.
A resumed session MUST check `Workflow Type` FIRST and follow the bug workflow files when it is `bug`.
