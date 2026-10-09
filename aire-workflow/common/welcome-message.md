# aire Welcome Message

**Purpose**: This file contains the user-facing welcome message that should be displayed ONCE at the start of any aire workflow.

---

# Welcome to HelixAI-AIRE 


I'll guide you through an adaptive software development workflow that intelligently tailors itself to your specific needs.

## What is HelixAI-AIRE?

HelixAI-AIRE is a structured yet flexible software development process that adapts to your project's needs. Think of it as having an experienced software architect who:

- **Analyzes your requirements** and asks clarifying questions when needed
- **Plans the optimal approach** based on complexity and risk
- **Skips unnecessary steps** for simple changes while providing comprehensive coverage for complex projects
- **Documents everything** so you have a complete record of decisions and rationale
- **Guides you through each phase** with clear checkpoints and approval gates

## The Two-Phase Lifecycle

```
                         User Request
                              |
                              v
        +---------------------------------------+
        |     PLANNING PHASE                   |
        |     Planning & Application Design     |
        +---------------------------------------+
        | * Workspace Detection (ALWAYS)        |
        | * Reverse Engineering (COND)          |
        | * Requirements Analysis (ALWAYS)      |
        | * User Stories (ALWAYS, all at once   |
        |   + GATE 1 approval, then auto        |
        |   push to tracker)                    |
        | * Dependency Graph (ALWAYS, requires) |
        | * Workflow Planning (ALWAYS)          |
        | * Application Design (CONDITIONAL)    |
        +---------------------------------------+
                              |
                              v
        +---------------------------------------+
        |     IMPLEMENTATION PHASE                |
        |     Design & Implementation           |
        +---------------------------------------+
        | * System-Level DESIGN stages:         |
        |   - Functional Design (COND)          |
        |   - NFR Requirements Assess (COND)    |
        |   - NFR Design (COND)                 |
        |   - Infrastructure Design (COND)      |
        | * Behaviour Specs + Test Plans        |
        |   (every work unit, 1 approval)       |
        | * >> STOP << (before code gen)        |
        | * Code Generation (per-story, via     |
        |   `dev-implement`) + unit tests       |
        | * Code Review & Remediate (automatic) |
        +---------------------------------------+
              |                    |
              |                    +----------------------+
              |                                           |
              |                            +---------------------------------------+
              |                            | Verification Engineer track (parallel)|
              |                            +---------------------------------------+
              |                            | * Test plans for every work unit,     |
              |                            |   written and approved at the STOP    |
              |                            |   checkpoint, before any code exists  |
              |                            | * The Verification Engineer runs them |
              |                            |   once the code is on the branch;     |
              |                            |   `ve-list-work` moves tested         |
              |                            |   stories to Ready for Testing        |
              |                            +---------------------------------------+
              v
                          Complete
```

### Phase Breakdown:

**PLANNING PHASE** - *Planning & Application Design*
- **Purpose**: Determines WHAT to build and WHY
- **Activities**: Understanding requirements, analyzing existing code (if any), planning the approach
- **Output**: Clear requirements, execution plan, a Story Tracker, a story breakdown with **dependencies mapped** so independent stories can be developed in parallel (stories pushed to your chosen tracker — Jira, Azure DevOps, or GitHub — and linked to your existing Parent Epic, or kept fully local)
- **Your Role**: Answer the clarifying questions, review and approve the generated story set (GATE 1) before it is pushed


**IMPLEMENTATION PHASE** - *Detailed Design & Implementation*
- **Purpose**: Determines HOW to build it
- **Activities**: System-level detailed design (when needed); then **every** work unit's Gherkin contract (`spec/behavior/<unit>.feature`) and manual test plan (`spec/test-plans/<TICKET-ID>-<title>/`) are written and approved in ONE pass — before any code exists; then — after a mandatory **STOP** — per-story code generation that you trigger with the **`dev-implement`** keyword (on a story branch cut from the Epic branch, with unit tests generated and run to the `unitTestCoverageMin` threshold, plus — when the story adds/changes an API endpoint — an automated **API & Contract Testing Gate**: functional behavior, response-code validation, role-based authorization 401/403, error-response validation, request validation, and response contract/schema validation), and optional code review
- **Output**: Approved behaviour contracts and manual test plans for every work unit, then working code, unit tests and API & Contract test evidence (when applicable)
- **Your Role**: Review designs, approve the behaviour specs and test plans, type `dev-implement` to build each story, then review each story's PR together with the Verification Engineer (approval and merge are manual)

**Verification Engineer TRACK** - *Test Plan, in parallel with development*
- **Purpose**: Proves each story meets its acceptance criteria
- **Sign-off is not a Implementation stage** — neither at epic level nor at story level. Verification Engineer drives it independently and can start immediately, without waiting for any code. The plans themselves are already written and approved at the STOP checkpoint, so Verification Engineer can review them before a line of code exists
- **Activities**: every work unit's Test Plan artifacts — manual test steps for every applicable test plan (integration, E2E, API, contract, security, performance, accessibility — whichever apply; there is no build-verification artifact), derived from the acceptance criteria, never from source code — are already in `spec/test-plans/<TICKET-ID>-<title>/`. Once a story's code is generated and on the branch, Verification Engineer executes them. For frontend work units the implement workflows also turn the UI-relevant steps into executable Playwright tests. **`ve-list-work`** (on the cycle's integration branch — epic, bug, or enhancement) reports which stories/tickets dev has merged and moves the ones Verification Engineer has tested to Ready for Testing, or records a rejection
- **Your Role (as Verification Engineer)**: review the plans already on the branch, execute the test steps, then `ve-list-work` to sign off

## Key Principles:

- **Fully Adaptive**: Each stage independently evaluated based on your needs
- **Efficient**: Simple changes execute only essential stages
- **Comprehensive**: Complex changes get full treatment with all safeguards
- **Transparent**: You see the execution plan before work begins, and can add or remove stages at any time
- **Documented**: Complete audit trail of all decisions and changes
- **User Control**: You can request stages be included or excluded

## What Happens Next:

1. **I'll check for an existing aire project and ask which issue tracker to use** — Jira, Azure DevOps, GitHub, or Local-only (no external tracker at all, everything tracked right here in the project's own state file). Whichever you pick is used for every story, bug, and enhancement from that point on — Local is a fully supported, complete option, not a fallback.
2. **I'll capture your Parent Epic** (if you gave one) **and analyze your workspace** to understand if this is a new or existing project — pulling existing-system truth from Atlas via Helix when it is needed — then create the Epic branch
3. **I'll ask about context-project artifacts and reference materials** — human-authored notes on how your current system works (under `spec/context-project/existing-knowledge/`), and UX wireframes, design mockups, API specs or other docs that define the target state (under `spec/context-project/new-references/`)
4. **I'll gather requirements** and ask clarifying questions if needed
5. **I'll show an execution plan** and run it, with your approval at each major stage (you can add or remove stages any time)
6. **You'll get working code** with complete documentation and tests

The aire process adapts to:
- Your intent clarity and complexity
- Existing codebase state
- Scope and impact of changes
- Risk and quality requirements

Let's begin!
