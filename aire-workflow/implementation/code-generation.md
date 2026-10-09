# Code Generation - Detailed Steps

## Overview
Code Generation is **per-story** and is triggered ONLY by the **`dev-implement`** keyword (orchestrated by `workflows/dev-implement.md`). It runs after the system-level design stages and the  STOP CHECKPOINT. It has two parts, preceded by Story Selection:
- **Step 0 - Story Selection (MANDATORY)**: identify WHICH story to implement (by Tracker ID or Story ID), run the Doability Gate, move it from `Ready for Development` to `In Development`
- **Part 1 - Planning**: Create detailed code generation plan — implementation steps per layer, ending with the mandatory **Unit Test & Coverage** step
- **Part 2 - Generation**: Execute the announced plan to generate code and artifacts, then generate + RUN unit tests until coverage is ≥90% (Step 11a — same run), then — **when this story touches an API layer** — generate + RUN the API & Contract Testing Gate (Step 11a.5 — same run), then run the FULL repo regression suite and diff it against the pre-change baseline (Step 11b — same run), then run the Static Eval Gate D1–D7 and diff it against the pre-change static baseline (Step 11c — same run), then — **when this story touches the UI** — generate + RUN the Playwright UI Automation Gate using Playwright's own real Planner/Generator/Healer agents, against a locally started instance of the app, remediating any failure in this same run (Step 11d — same run), then re-run the ENTIRE existing `tests/e2e/` suite and diff it against the pre-change baseline so nothing an earlier work unit shipped was broken — for EVERY story, UI or not (Step 11e — same run, before Code Review). CI later re-executes the same Playwright run headless as a trust gate, never as the first execution.

**Extensions**: test-mandating extensions (e.g., Property-Based Testing) apply — their required tests are included in the Unit Test & Coverage step per the extension's scope.

**Note**: For brownfield projects, "generate" means modify existing files when appropriate, not create duplicates.

**Audit entries**: EVERY runtime-artifacts/audit.md entry written during this stage (plan approval prompts/responses, per-step generation logs, coverage evidence, completion) MUST include the `**TRACKER ITEM**:` field — the story's Tracker ID as a clickable link, or the local Story ID when `Tracker ID = —` — AND the `**Epic Link**:` field — the full Parent Epic URL as a clickable link, read from `## Tracker` in `runtime-artifacts/aire-state.md`, or `none` when no Epic is recorded. See the Audit Entry Format in `workflows/dev-implement.md`.

**Note on design context**: The system-level design artifacts (functional/NFR/infrastructure under `spec/plans/`) apply to every story. Code for each story is written into the application structure documented in Application Design (or, if Application Design was skipped, per the structure patterns in Critical Rules below).

## Prerequisites
- System-level design stages complete (functional/NFR/infrastructure as applicable)
- Dependency Graph exists (`spec/plans/dependency-graph.yml`) and the `## Story Tracker` exists in `runtime-artifacts/aire-state.md`
- The story selected via `dev-implement` has passed the Doability Gate (every `requires` story's PR is merged)
- The story branch is active, cut from the epic branch AFTER the dependency-merge check passed (`common/branching-strategy.md` Section 3). If any prerequisite story's branch is NOT yet merged into the epic branch, code generation MUST NOT start — the workflow has already warned and stopped (Case B): the user must merge the prerequisite's PR into the epic branch first and re-run `dev-implement`

---

# PART 1: PLANNING

## Step 0: Story Selection (MANDATORY)
- [ ] Load and execute all steps from `implementation/story-selection.md` — it asks which story, runs the Doability Gate, and moves the story from `Ready for Development` to `In Development` automatically (tracker + local Story Tracker updated without asking, transition verified for non-LOCAL). Do NOT restate that logic here.
- [ ] Carry the resolved story (ID, title, acceptance criteria, Tracker ID/link) into the planning steps below.

## Step 1: Analyze Story & Design Context
- [ ] Read the selected story and its acceptance criteria from `spec/plans/stories.md`
- [ ] **Read `spec/plans/requirements.md` and resolve the story's `Covers` REQ-IDs** — the requirement text itself (not just the story's AC restatement) is MANDATORY planning input; an AC set that understates its requirement never caps the plan (`common/requirements-traceability.md` Rule 5)
- [ ] **Fallback coverage verification**: if `runtime-artifacts/aire-state.md` carries NO `Requirements coverage verified post-design` record, run `common/requirements-traceability.md` Rule 4 now (silent, blocking) before planning proceeds — the thread must never reach code generation unverified
- [ ] Read the system-level design artifacts (functional-design, nfr-design, infrastructure-design under `spec/plans/`)
- [ ] Read the `New References` fields of `## Context Project` in `runtime-artifacts/aire-state.md`. **IF `New References: Yes`**, load all listed reference paths — UX wireframes/mockups dictate the exact UI to build (layouts, controls, interactions); API specs dictate the exact endpoints and data shapes. When generating code, implement what the references show — they are authoritative for visual/structural fidelity alongside the acceptance criteria.
- [ ] Identify the story's dependencies and interfaces (from the Dependency Graph `requires`/`enables`)
- [ ] Validate the story is ready for code generation (Doability Gate passed in Step 0)

### Step 1.5:  RE-CONSULT the Design References (MANDATORY — automatic, ask the user nothing)

**Load `common/design-reference-grounding.md`** and read `## Design References` in `runtime-artifacts/aire-state.md`.

**This step adds NO question, NO gate, and NO checkpoint to code generation.** It runs silently as part of analysing story context. This phase has NO approval gate at all (the former GATE 2 plan approval is removed) — this step adds none either.

- [ ] **FIRST, read the `### Reconciliations` table** in `## Design References` (rule **DR-8**). Every point listed there is a **settled decision taken deliberately against the reference** by an earlier design stage — an excluded capability, a narrowed scope, a locally-scoped stylesheet, an NFR or accessibility constraint. **Those points are closed: follow the framework artifact, NOT the raw reference, and do not re-report them as contradictions.** The design docs the framework generated are the reconciled source of truth wherever they have actually considered a point.
- [ ] **Re-open** every reference whose `Governs` covers a component THIS story builds or modifies, and ground **only the points the reconciliations table does NOT settle**. A fresh read for THIS story's scope is required — *"it was read at Requirements Analysis / Application Design"* does not count, because those stages read only what was in their own scope.
- [ ] For a UI prototype, open the real `*.component.html` / `*.ts` / `*.css` (or equivalent) for this story's components and extract: actual control types (plain `<select>` vs searchable grouped combobox; single- vs multi-select), grouping/ordering, labels and icons, interaction behaviour (search/filter, click-outside-to-close, keyboard, empty states), and custom CSS classes — checking whether those classes exist in the live app's global styles.
- [ ] **On any remaining difference, apply DR-8 precedence — do NOT blanket-prefer the reference:**
   - **Reconciled** (the artifact recorded a decision on this point) → **follow the artifact**; note in one line that the reference differs here by prior decision. **Never reintroduce something a design stage deliberately excluded.**
   - **Unreconciled** (no artifact ever addressed this point — the AC is simply generic or silent) → **follow the reference**, state plainly in the plan what the AC said versus what the design shows, amend the AC / `requirements.md` / the tracker item per `common/requirements-traceability.md`, and record the reconciliation.
   - Either way: **do NOT stop, do NOT ask an A/B question** — it is stated in the announced plan like everything else in it.
- [ ] A capability the prototype shows that is **outside** this story's ACs → check the reconciliations table first: if it is already recorded as excluded, honour that silently. If it is new, note in the plan that you saw it and excluded it as out of scope, and record the reconciliation so no later story re-adds it. Never silently build it, never silently drop it, never ask about it.
- [ ] Any reference still `Read? ` — read it now (DR-2/DR-3/DR-4) and carry on.
- [ ] Log in `runtime-artifacts/audit.md` which references were re-opened, for which components, what was extracted, and any deviation reported.

**The plan (Step 2) states, for EVERY component it creates or changes, exactly one of:**

```
Design reference: <path>/<file> — grounded (<what the reference actually specifies>)
Design reference: none covers this component — built from ACs only
```

This is your own self-check while writing the plan — satisfy it yourself before announcing the plan.

## Step 2: Create Detailed Story Code Generation Plan
- [ ] Read workspace root and project type from `runtime-artifacts/aire-state.md`
- [ ] Determine code location (see Critical Rules for structure patterns)
- [ ] **Brownfield only**: Review reverse engineering code-structure.md for existing files to modify
- [ ] Document exact paths (never spec/)
- [ ] Create explicit steps for implementing this story:
  - Project Structure Setup (greenfield only)
  - Business Logic Generation
  - Business Logic Summary
  - API Layer Generation
  - API Layer Summary
  - Repository Layer Generation
  - Repository Layer Summary
  - Frontend Components Generation (if applicable) — 🔴 **the ONE place a work unit is declared frontend**: include it whenever the unit adds or changes anything the browser renders or runs (components, screens, pages, client-side routing, styles, UI state). Its presence makes Playwright Readiness and the Playwright UI Automation step below mandatory; its absence makes both N/A.
  - Frontend Components Summary (if applicable)
  - Database Migration Scripts (if data models exist)
  - **Unit Test & Coverage** — generate unit tests for ALL new/changed code, run them, measure coverage, and iterate until ≥90% (Step 11a — MANDATORY, always the step after implementation)
  - **API & Contract Testing Gate** — when this story adds/changes an API endpoint (i.e. the plan includes an API Layer Generation step above), generate automated tests against the actual endpoints, run them, and iterate until every applicable checklist item passes (Step 11a.5 — MANDATORY WHEN APPLICABLE, always the step after Step 11a; N/A when no API layer is touched)
  - **Full Regression vs Baseline** — re-run the ENTIRE repo suite (including any API & Contract tests from Step 11a.5) and diff against the baseline captured at the Story Branch checkpoint; any NEW failure is fixed in the same run (Step 11b — MANDATORY, always the step after Step 11a / Step 11a.5)
  - **Static Eval Gate (D1–D7)** — lint, type check, SAST, dependency vulnerabilities, licences, complexity, secrets; diffed against the static baseline captured at the Story Branch checkpoint; any NEW finding is fixed in the same run (Step 11c — MANDATORY, always the step after Step 11b)
  - **Playwright Readiness** — only when the plan has a Frontend Components Generation step: runner, browsers and Playwright's official test agents installed before any code (the invoking workflow's readiness step — `dev-implement` Step 4.3, `bug-fix-implement` Step 4.4, `enhancement-implement` Step 11.4)
  - **Playwright UI Automation** — only when the plan has a Frontend Components Generation step: `playwright-implement` in workflow mode generates, runs (`--headed`) and heals this unit's specs in `tests/e2e/<key>-<title>/` (Step 11d part B)
  - **Playwright E2E Regression** — every plan: the full `tests/e2e/` suite re-run and diffed against the baseline (Step 11e); N/A only when `tests/e2e/` held no spec at baseline
  - Documentation Generation (API docs, README updates)
  - Deployment Artifacts Generation
- [ ] Number each step sequentially
- [ ] Include story mapping references
- [ ] **Tag EVERY implementation step with the REQ-ID(s) and acceptance criteria it implements** — e.g., `Step 3: Order validation service (REQ-F-03, AC-1, AC-2)` (`common/requirements-traceability.md` Rule 5)
- [ ] Add checkboxes [ ] for each step

## Step 3: Include Story Implementation Context
- [ ] For this story, include:
  - The story's acceptance criteria and the intake brief context (`epic-brief.md`, if present)
  - Dependencies on other stories (`requires`/`enables` from the Dependency Graph)
  - Expected interfaces and contracts (from Application Design, if it ran)
  - Database entities this story owns or touches
  - Service/component boundaries and responsibilities (from Application Design)

## Step 4: Create Story Plan Document
- [ ] Save complete plan as `spec/spec-generation/story-N.M-code-generation.md`
- [ ] Include step numbering (Step 1, Step 2, etc.)
- [ ] Include story context and dependencies
- [ ] Include story traceability
- [ ] **Trace completeness self-check (MANDATORY — automatic, blocking, BEFORE the plan is announced)**: verify every REQ-ID in the story's `Covers` AND every acceptance criterion appears in ≥1 tagged plan step. A REQ/AC with no plan step is a blocking gap — extend the plan and re-check (no user prompt). Include the trace summary (REQ/AC → plan steps) in the plan document (`common/requirements-traceability.md` Rule 5)
- [ ] Ensure plan is executable step-by-step
- [ ] Emphasize that this plan is the single source of truth for Code Generation

## Step 5: Summarize Story Plan
- [ ] Provide summary of the story code generation plan to the user
- [ ] Highlight the implementation approach
- [ ] Explain step sequence and story coverage
- [ ] Note total number of steps and estimated scope

## Step 6: Log the Finalized Plan ( no approval prompt)
- [ ] **There is NO plan-approval gate.** The plan is finalized, announced and executed in the same run — never ask "Approve this plan?" (the former GATE 2 is removed).
- [ ] Log the finalized plan with timestamp in `runtime-artifacts/audit.md` under a **plain heading** — e.g. `## Code Generation Part 1 — Plan Finalized (auto-approved, no gate) (Story N.M)`. **The word "GATE" must NOT appear in any heading written by this stage.**
- [ ] Include the path to the complete story code generation plan, the step count, and the REQ/AC trace summary
- [ ] Include the `**TRACKER ITEM**:` field (story's Tracker ID link, or local Story ID) and the `**Epic Link**:` field (full Parent Epic URL from `## Tracker` in runtime-artifacts/aire-state.md, or `none`)


## Step 7: Announce and Proceed (no wait)
- [ ] Present the plan summary as an **announcement**, then proceed straight to Part 2 (Generation) — do NOT wait for a response
- [ ] If the user volunteers changes to the plan (now or mid-generation), apply them, update the plan document, announce the revision, log it, and continue — an interrupt, not a gate

## Step 8: (removed — there is no approval response to record)
- [ ] Superseded by Step 6's auto-approval note. Any user-volunteered plan change is logged as an ordinary interaction with their complete raw input, under a plain (non-"GATE") heading.

## Step 9: Update Progress
- [ ] Mark Code Generation Part 1 (Planning) complete in `runtime-artifacts/aire-state.md`

---

# PART 2: GENERATION

## Step 10: Load Story Code Generation Plan
- [ ] 🔴 **HARD CHECKPOINT — the plan file must exist on disk before ANY code is generated.** `Read` `spec/spec-generation/story-N.M-code-generation.md`. If it does not exist (was only narrated in chat/audit.md and never written), this is a process violation — STOP, write the file now per Step 4 in full (numbered steps, checkboxes, story context/dependencies, REQ/AC trace summary), log the correction in `runtime-artifacts/audit.md`, and only then proceed. Never generate code against a plan that exists only in the conversation.
- [ ] Read the complete plan from `spec/spec-generation/story-N.M-code-generation.md`
- [ ] Identify the next uncompleted step (first [ ] checkbox)
- [ ] Load the context for that step (story, dependencies, design artifacts)

## Step 11: Execute Current Step
- [ ] Verify target directory from plan — code goes to the resolved code root, never to `spec/`
- [ ] **Brownfield only**: Check if target file exists
- [ ] If this step is the **Unit Test & Coverage** step, execute Step 11a in full (mandatory — tests are generated, RUN, and iterated to `unitTestCoverageMin` coverage in this same run, never deferred to ve or a later session).
- [ ] If this step is the **Behavioural Test Gate**, execute the  Gherkin gate in full per `common/behavior-spec.md` Section 4.3 — implement the step definitions in `tests/behavior/steps/` against the app's public surface, RUN every scenario in this unit's `<work-unit>.feature`, and iterate (max 3 attempts) until all pass and every `@AC` tag is executed. 🔴 Fix the code, never the scenario.
- [ ] If this step is the **API & Contract Testing Gate**, execute Step 11a.5 in full (mandatory WHEN this story's plan includes an API Layer Generation step — tests are generated, RUN, and iterated until every applicable checklist item passes in this same run, never deferred to ve or a later session).
- [ ] Generate exactly what the current step describes:
  - **If file exists**: Modify it in-place (never create `ClassName_modified.java`, `ClassName_new.java`, etc.)
  - **If file doesn't exist**: Create new file
- [ ] Write to correct locations:
  - **Application Code**: the resolved code root (`src/` by default) per project structure
  - **Unit tests (including UI/component tests — RTL, jsdom, Enzyme, etc.)**: **repo-root**
    `tests/unit/`, mirroring the area of `src/` they cover (e.g. a components baseline/guard suite →
    `tests/unit/components/`) · **API & Contract Testing Gate tests (Step 11a.5)**: **repo-root**
    `tests/api/` · **Gherkin step definitions**: **repo-root** `tests/behavior/steps/` ·
    **Playwright**: `tests/e2e/`
    🔴 **HARD RULE, no exceptions**: EVERY unit test — including a grouped/baseline UI-component test
    suite that covers many `src/` modules at once — goes under `tests/unit/`. Never create a sibling
    top-level folder (e.g. `tests/components/`) for it, even when the suite doesn't mirror `src/` 1:1.
    🔴 **API & Contract tests (Step 11a.5) go ONLY in `tests/api/`** — never in `tests/unit/`, never
    colocated with the endpoint's own unit tests. There is no ambiguity to resolve at generation
    time — dispatch purely on test type: unit (incl. component) → `tests/unit/`; real-endpoint
    API/contract → `tests/api/`.
    🔴 The `tests/` tree is ALWAYS at the repository root, never nested under `src/` and never
    under a brownfield `## Code Root`. The Code Root remapping is for application code only.
    `tests/.evals/behavior/run.sh` mounts and runs `tests/behavior/` inside Podman, and the
    coverage gate reads the manifest's `testPaths` — a test written elsewhere is invisible to both.
  - **Documentation / specs**: `spec/` (markdown only — e.g. the `.feature` contract under `spec/behavior/`)
  - **Generated evidence**: `reports/` (unit / behavior / api-contract / eval evidence — never under `spec/`)
  - **Build/Config Files**: workspace root (they belong there by tooling convention)
  - 🔴 **Never** a source file under `spec/`
- [ ] Follow the story's acceptance criteria
- [ ] Respect dependencies and interfaces

## Step 11a: Unit Test & Coverage Step (MANDATORY — after implementation, the `unitTestCoverageMin` threshold, same run)
Runs ONCE per story, immediately after all implementation steps are complete (business logic, API, repository, frontend):

🔴 **Working directory is a manifest fact for EVERY command in Steps 11a/11a.5/11b/11c below, on a
monorepo or not** — before running the test runner, the API-test runner, the full-suite re-run, or any
D1–D7 tool, resolve that command's owning entry in `tests/.evals/config.json`'s `ci.roots[]`, `cd` into
`"$(git rev-parse --show-toplevel)/<root>"` (resolved fresh, never cached), and verify the declared
`markerFile` is present before running the bare command (`common/ci-pipeline-generation.md` Section
4.0d, `common/eval-framework.md` Section 1.1). A single-root repo does this as a no-op `cd "."` plus a
marker check; skipping it on a monorepo is exactly what lets a local run and CI's later re-run of the
SAME manifest command disagree on which directory they actually ran in. A missing/mismatched root is a
**Manifest defect** — fix `ci.roots[]`, never invent a different path around it.

- [ ] **Generate unit tests** covering ALL of the story's new/changed code — happy paths, edge cases, error scenarios, per acceptance criterion
- [ ] **RUN the tests** with the project's test runner; fix any failures (whether in the tests or defects they expose in the implementation) until 100% of tests pass
- [ ] **Measure coverage** on the story's new/changed code using the stack's standard coverage tool (e.g., jest `--coverage`, pytest-cov, JaCoCo)
- [ ] **Iterate until the threshold is met**: if coverage is below `unitTestCoverageMin` (`tests/.evals/config.json`), identify the uncovered lines/branches, add or adjust tests, and re-run — repeat WITHIN THIS SAME RUN until coverage is ≥90%. Do not defer the gap to ve or a later session
- [ ] If the threshold is genuinely unreachable (e.g., untestable generated boilerplate), surface the gap to the user with the measured %, the uncovered code, and the reason — never silently accept below-target coverage
- [ ] **Capture PROOF artifacts (MANDATORY — durable, verifiable evidence, not just a text claim)**: from the FINAL passing test run, save the actual tool output to `reports/unit-test-evidence/story-[N.M]/`:
  - [ ] **`unit-test-run.log`** — the raw, unedited stdout/stderr of the final test-runner invocation (the run that shows X/X passing). Do NOT hand-transcribe or summarize it — capture the real output (e.g., `npm test -- --coverage > unit-test-run.log 2>&1`, `pytest --cov ... | tee unit-test-run.log`)
  - [ ] **`coverage-report.*`** — the coverage tool's own machine-readable report from the same run, stored in `reports/unit-test-evidence/story-[N.M]/coverage/` together with `coverage/changed-lines-coverage.json` (the changed-lines measurement that is the gate metric — format in `common/work-unit-artifacts.md` Section 2.2). **This file is MANDATORY, not best-effort.** You MUST invoke the runner with the flags that emit a real report file — do NOT rely on the terminal summary alone:
    - **Node/JS (jest, nyc, vitest)**: enable coverage reporters so `coverage/lcov.info` (and/or `coverage-final.json`, HTML) is produced — e.g., `jest --coverage --coverageReporters=lcov --coverageReporters=json-summary`
    - **Python (pytest-cov)**: `pytest --cov=<pkg> --cov-report=xml --cov-report=html` → `coverage.xml` (+ `htmlcov/`)
    - **Java (JaCoCo)**: the `jacoco.xml`/HTML report from the build
    - **Any other stack**: use that stack's standard coverage-report flag to emit a machine-readable file (lcov / xml / json / HTML)
    Copy the emitted report into the evidence folder so it survives independent of the build workspace. **🔴 GATE FAILURE — if the stack HAS coverage-report tooling but no report file is produced and stored, the Unit Test & Coverage gate is NOT satisfied: STOP and surface it to the user (the terminal summary in `unit-test-run.log` alone is NOT sufficient proof).**
    - ** Narrow exception — only when the stack has NO coverage-report tooling at all**: if the language/test stack genuinely provides no way to emit a machine-readable coverage report (after actually checking for the standard tool), this is a **documented, surfaced exception — NOT a silent skip**. Record in `evidence-manifest.md` which coverage tool(s) were checked and why none is available, keep the mandatory `unit-test-run.log`, and explicitly surface the exception to the user for acknowledgment. This exception NEVER applies when a coverage tool exists for the stack (Python/pytest-cov, JS/jest·nyc·vitest, Java/JaCoCo, Go `-coverprofile`, .NET coverlet, etc.) — there the report file remains strictly mandatory.
  - [ ] **`evidence-manifest.md`** — a short manifest recording: the exact command(s) run, the test runner + coverage tool used, tests passing (X/X), the measured coverage % on the story's new/changed code, and a relative-path link to each artifact above
- [ ] **Cite the proof, not just the numbers**: in the story summary and runtime-artifacts/audit.md, record tests passing (X/X) and the measured coverage %, AND link the evidence folder path `reports/unit-test-evidence/story-[N.M]/`. The numbers reported downstream (completion message, Code Review, PR/tracker comment) MUST match these saved artifacts

## Step 11a.5:  API & Contract Testing Gate (MANDATORY WHEN APPLICABLE — after Step 11a, same run)

**Purpose**: the Unit Test & Coverage gate (Step 11a) proves the story's code paths are exercised, but it does not prove the story's API is *callable correctly from the outside* — right status codes, right auth semantics, right error shape, right request/response schema. This step closes that gap with **automated, dev-executed API tests plus schema/contract validation** for every endpoint this story adds or changes.

### Applicability (automatic — no question asked)
- **Applies** to this story IF its code-generation plan (Step 2) includes an **API Layer Generation** step — i.e., the story adds or changes an API-visible endpoint/route/controller/handler.
- **N/A** if the plan has no API Layer Generation step. State this explicitly — `API & Contract Testing: N/A — no API layer touched by this story` — in the plan and in `evidence-manifest.md` (see below), and skip straight to Step 11b.
- Applicability is decided at the STORY level (does *this story* touch the API layer), not the whole application.

### Scope — the checklist (for EVERY new/changed endpoint this story touches)
Generate automated tests that call the actual endpoint (in-process test client — e.g. supertest, httpx/TestClient, RestAssured, MockMvc — or a spun-up test server; whichever is the stack's standard integration-test mechanism) and assert. 🔴 **HARD RULE — these test files live in `tests/api/` at the repo root, never in `tests/unit/` and never colocated with the endpoint's unit tests** (`common/directory-structure.md` rule 4b):
1. **Functional / happy path** — the documented success behavior per acceptance criterion, end to end through the real endpoint.
2. **Response Code Validation** — the correct HTTP status code for every documented success AND failure path (2xx variants, 4xx, 5xx as applicable) — not just 200-on-success.
3. **Authorization Testing — role-based access** — for every endpoint requiring auth: an unauthenticated request → `401`; an authenticated request with an insufficient role/permission → `403`; an authenticated request with the correct role → success. **401 and 403 must be distinguished correctly — never collapse them into one behavior.** N/A only for a genuinely unauthenticated/public endpoint (state why).
4. **Error Response Validation** — every documented error condition returns the codebase's/design docs' standard error envelope/format AND the correct error code — assert the error *schema*, not just the status code.
5. **Request Validation (inbound contract)** — required fields, data types, and enum constraints on the request payload are enforced: a missing required field, a wrong type, or an invalid enum value each produce the expected validation error. N/A only for an endpoint with no request body (state why).
6. **Response Contract Validation (outbound contract)** — the response payload matches its declared schema/contract (from Application Design, an OpenAPI/DTO/interface definition, or the API's own schema): required fields present, correct types, enum values within the declared set.

This is "API Testing along with Contract Testing" as **ONE gate**: functional behavior AND schema/contract compliance of both the request and the response. It is schema/contract validation of THIS service's own API — not consumer-driven cross-service contract testing (e.g. Pact); that remains out of scope unless the project already practices it elsewhere.

### Mechanics (mirrors the Unit Test & Coverage gate)
- [ ] **Generate** the tests per the checklist above for every new/changed endpoint.
- [ ] **RUN** them with the project's standard test runner / API-testing library (reuse the unit-test runner if it can drive HTTP/in-process calls, e.g. jest+supertest, pytest+httpx, JUnit+RestAssured).
- [ ] **Iterate within the SAME run** until every applicable checklist item passes — fix defects the tests expose in the implementation (never weaken the assertion to force a pass).
- [ ] **Pass criterion**: every new/changed endpoint has a passing test for EACH applicable checklist item. An item is inapplicable only when it genuinely does not apply to that endpoint (e.g., a public endpoint skips Authorization Testing, a GET with no body skips Request Validation) — state why per endpoint in the evidence manifest.
- [ ] If a checklist item genuinely cannot be satisfied (e.g., the stack defines no schema/contract to validate the response against), surface this to the user explicitly with the reason — never silently skip it.
- [ ] **Capture PROOF artifacts** to `reports/api-contract-test-evidence/story-[N.M]/`:
  - [ ] **`api-contract-test-run.log`** — the raw, unedited stdout/stderr of the final passing run.
  - [ ] **`api-contract-test-report.*`** — the test runner's own machine-readable report from the same run. **This file is MANDATORY, not best-effort.** You MUST invoke the runner with the flags/plugin that emit a real report file — do NOT rely on the raw log alone:
    - **Node/JS (jest)**: `jest --json --outputFile=api-contract-test-report.json` (built into jest, no extra package needed) — or `jest-junit` for JUnit XML if the project already uses it
    - **Python (pytest)**: `pytest --junitxml=api-contract-test-report.xml` (built into pytest, no plugin needed)
    - **Java (JUnit/RestAssured/MockMvc)**: the `TEST-*.xml` JUnit report Surefire/Gradle already emits (`target/surefire-reports/` or `build/test-results/test/`) — copy it into the evidence folder
    - **Go**: `go test -json ./... > api-contract-test-report.json` (built into `go test`) — or `gotestsum --junitfile=...`
    - **.NET**: `dotnet test --logger "trx;LogFileName=api-contract-test-report.trx"` (or `--logger junit`)
    - **Any other stack**: use that stack's standard test-report flag/plugin to emit a machine-readable file (JUnit XML / JSON)
    Copy the emitted report into the evidence folder so it survives independent of the build workspace. **🔴 GATE FAILURE — if the stack's test runner supports a machine-readable report but none is produced and stored, the API & Contract Testing Gate is NOT satisfied: STOP and surface it to the user (the raw log in `api-contract-test-run.log` alone is NOT sufficient proof).**
    - ** Narrow exception — only when the runner genuinely has NO way to emit a machine-readable report at all** (after actually checking for the standard flag/plugin above): this is a **documented, surfaced exception — NOT a silent skip**. Record in `evidence-manifest.md` which report mechanism(s) were checked and why none is available, keep the mandatory `api-contract-test-run.log`, and explicitly surface the exception to the user for acknowledgment. This exception NEVER applies to the common stacks above (pytest, jest, JUnit/Surefire/Gradle, `go test -json`, dotnet trx) — there the report file remains strictly mandatory.
  - [ ] **`evidence-manifest.md`** — a per-endpoint checklist table: endpoint + method, each of the 6 checklist items →  Pass / N/A + one-line reason, and the overall tests-passing count.
- [ ] **Cite the proof, not just a claim**: in the story summary, Code Review, and PR/tracker comment, reference `reports/api-contract-test-evidence/story-[N.M]/` — the numbers reported downstream MUST match these saved artifacts.

## Step 11a.6: Test Placement Verification Gate (MANDATORY — after Step 11a and Step 11a.5, same run)

**Purpose**: Steps 11a/11a.5 and `common/directory-structure.md` rules 4a/4b state WHERE tests must go
(`tests/unit/<mirror-of-src>/`, `tests/api/`), but a narrated rule is only as reliable as the run that
remembers it. This step is a **deterministic, zero-token mechanical check** — not a re-reading of the
rule — that catches drift before it reaches Code Review, the same way D1–D7 catch lint/type drift.
🔴 This gate is separate from and additional to D1–D7; it is never satisfied by a clean D1–D7 run.

- [ ] **Diff scope**: `git diff --name-only --diff-filter=ACMR <baseline-sha>...HEAD` (the same baseline
  SHA captured at Step 1.5 Item 4.5/4.6) — only files this story's own run added or modified.
- [ ] **Run the check script** (when the project has it — otherwise apply the same rules to the diff yourself and write the same log, `common/work-unit-artifacts.md` Section 2.3; the check is never skipped because the script is missing) (`tests/.evals/scripts/check-test-placement.*` — a project-added script; the framework ships none,
  `common/ci-pipeline-generation.md` Section 4.0.7) against that diff. The
  script classifies each changed path as `application`, `unit-test`, `api-test`, or `other` by filename
  pattern (`*.test.*`, `*.spec.*`, `test_*.py`, `*_test.py`, `*Test.java`, `*Tests.cs`, `*_test.go`
  unless the file is Go/Rust's own co-location convention, plus the stack's own convention from
  `tests/.evals/config.json`) and flags a **violation** when:
  1. A `unit-test`/`api-test` file lives under the resolved code root (`src/` or `## Code Root`) —
     unless the stack's own co-location convention applies (Go `_test.go`, Rust `#[cfg(test)]`), in
     which case it is not a violation.
  2. A `unit-test` file lives under `tests/` but **outside** `tests/unit/` (e.g. a new top-level
     `tests/components/`, `tests/services/`, or a file directly at `tests/` root).
  3. An `api-test` file (identified by calling a real endpoint — imports/uses supertest, httpx,
     RestAssured, MockMvc, or spins up a test server) lives under `tests/unit/` instead of `tests/api/`.
  4. `tests/unit/` gained a new **top-level** subfolder this run that has no corresponding top-level
     folder under `src/` (i.e., the mirrored-path rule was skipped rather than followed) — flagged as a
     warning requiring an explicit one-line justification in `evidence-manifest.md` (a legitimate
     grouped/baseline suite per rule 4a is not itself a violation, but it must be traceable to a real
     `src/` area, not an invented one).
- [ ] **Zero violations required to pass.** On any violation: **move the file to its correct mirrored
  path** (`tests/unit/<area>/` or `tests/api/`), fix its relative imports, re-run it to confirm it still
  passes, then re-run the check script. **This is SH-LOOP-12 — capped at 3 remediation attempts (SH-1).
  On exhaustion apply SH-4: HALT and emit the Retry-Limit Report.** Never leave a misplaced file in place
  and never rename/relax the check to make it pass.
- [ ] **Capture PROOF artifacts** to `reports/unit-test-evidence/story-[N.M]/test-placement-check.log`
  (the script's raw output — files scanned, classification, verdict) and record the pass/fail + any
  moved-file list in `evidence-manifest.md`.
- [ ] **N/A** only when this story changed no test files at all (a pure config/docs step) — state that
  explicitly; a story with any new/changed test file is never N/A.

## Step 11b: Full Regression checkpoint (MANDATORY — after Step 11a, Step 11a.5 and Step 11a.6, same run)
The coverage gate in Step 11a is scoped to the story's NEW/changed code. It cannot detect assertions this story invalidated in **pre-existing shared test files** — that is what this step is for. Where Step 11a.5 applied, its new API & Contract tests are now part of the repo suite and are included in this regression run going forward.
- [ ] **Re-run the ENTIRE repo test suite** (all pre-existing tests + this story's new tests) and save the raw output to `reports/unit-test-evidence/story-[N.M]/full-regression.log`
- [ ] **Diff against `baseline-regression.log`** captured on the story branch before any code was generated (`workflows/dev-implement.md` Step 1.5 Item 4.5)
- [ ] **NEW failures (green at baseline, red now)** — **this story broke them, so this story fixes them.** Fix them within THIS SAME run (no user prompt), then re-run and re-diff, iterating until the diff is clean. Fix each according to what actually broke:
  - **Obsolete expectation** — behaviour legitimately changed, the assertion encodes the old contract → **update the assertion** (keep the test; it still guards real behaviour)
  - **Genuinely dead** — exercises a code path this story removed → **delete it** after confirming the new tests cover the replacement path
  - **Real regression** — the test is correct and the implementation broke it → **fix the implementation, never the test**
- [ ] 🔴 **NEVER delete, skip, or weaken a failing test merely to turn the suite green** — that discards the guard and hides real regressions while the coverage gate still reports ≥90% on new code
- [ ] **Failures already red at baseline** → not this story's doing. They are already logged in `baseline-regression.log`; ignore them and do not block/fix on them.
- [ ] **Record in `evidence-manifest.md`**: baseline vs post-change pass/fail counts, and each NEW failure with what broke and how it was fixed
- [ ] Proceed to Code Review only once the diff is clean (zero NEW failures, ignore the old failures from baseline run)

## Step 11c:  Static Eval Gate — D1–D7 (MANDATORY — after Step 11b, same run)

The test gates prove the code **behaves** correctly. They say nothing about whether it lints, type-checks, imports safely, or is licence-clean. This step closes that gap with **deterministic, zero-token checks**, gated on the **delta** against the baseline captured before generation.

- [ ] Run **D1–D7** per `common/eval-framework.md` Section 2 — lint, type check, SAST, dependency vulnerabilities, licences, cyclomatic complexity on changed functions, secret scan of the diff — using whatever tooling the repo already has (Section 2.2 covers detection and the `N/A` exception)
- [ ] Save the raw output to `reports/eval-evidence/story-[N.M]/static/`
- [ ] **Diff against the baseline** captured before any code was generated (`workflows/dev-implement.md` Step 1.5 Item 4.6, in `static/baseline/`)
- [ ] **NEW findings above the `tests/.evals/config.json` thresholds, on files this story changed** → **this story introduced them, so this story fixes them** in THIS SAME run (no user prompt), then re-run and re-diff until the diff is clean
- [ ] 🔴 **NEVER suppress a finding to pass the gate** — no blanket `eslint-disable`, no `# nosec`, no `# type: ignore`, no ignore-list entry, no widening `disallowedLicenses`. That is the exact analogue of deleting a failing test to make the suite green and is equally forbidden. **Fix the code.**
- [ ] **Findings already present at baseline** → pre-existing debt, not this story's. Logged under `static/baseline/`; ignore them and do not block on them
- [ ] Write `eval.json` + `eval-summary.md` per `common/eval-framework.md` Section 6 — `verdict` is `PASS` only if every entry under `gates` is `PASS` or `N/A`
- [ ] Proceed to Step 11d only once the diff is clean

## Step 11d:  Test Plans + Playwright UI Automation Gate (MANDATORY — after Step 11c, before Code Review, same run)

**Purpose — two things, one step:**
1. **The story ships with its own manual test plan** (`spec/test-plans/<TICKET-ID>-<title>/`) — normally the one **already written and approved at the STOP CHECKPOINT** (`CLAUDE.md` Step 1.7 / `implementation/specs-and-test-plans.md`), which this step only **verifies** is present; a genuinely absent plan is backfilled here. Either way the ve can simply **execute** it once the story PR merges rather than having to generate it first. This half applies to **every** story.
2. Steps 11a–11c prove the code behaves correctly at the unit/API/static level, but none of them prove the **UI** actually works end-to-end, from a real browser, against the app running for real. For UI stories this step closes that gap by generating and RUNNING real Playwright browser automation in the SAME run, using **Playwright's own official Test Agents** (Planner, Generator, Healer) — never a hand-rolled equivalent.

🔴 **This is the FIRST execution, and it runs `--headed` on the developer's machine. CI's own copy of this gate (`common/ci-pipeline-generation.md` Section 4, `agentic-eval-pipeline.yml`'s `playwright` step) is a TRUST GATE that re-runs the same specs post-PR — headless only because a runner has no display — and it never originates coverage, only re-verifies what already ran here.**

### Applicability (automatic — no question asked) — the two halves differ
- 🔴 **Part A (the story's manual test plans) ALWAYS applies — every story, UI or not.** The whole point is that the test plan ships *with* the story, so the ve can simply execute it once the story PR merges instead of having to generate it first. A backend-only story still gets its integration / API / contract / security / performance plans.
- **Part B (Playwright browser automation) applies only IF** this story's code-generation plan (Step 2) includes a **Frontend Components Generation** step — i.e. the story adds or changes UI. **N/A** otherwise: state it explicitly — `Playwright UI Automation: N/A — no UI touched by this story` — in the plan and in `evidence-manifest.md`, then continue to Step 12. Decided at the STORY level, exactly like the API & Contract Testing Gate (Step 11a.5).

🔴 **THE ONLY INPUT TO THIS DECISION IS THIS STORY'S OWN CODE-GENERATION PLAN — nothing else, ever.**
Observed in a real run: a story added a new page, a new route, and a new nav link (an unambiguous
Frontend Components Generation step), yet Part B was skipped because a coordinator's delegation prompt
said `requirements.md`/`stories.md` maps the Playwright-coverage requirement (REQ-ID) to a *different*
story, and asked the run to "confirm before skipping." That mapping answers a different question —
**which story owns a REQ-ID for traceability purposes** — and has no bearing on **whether this story's
own plan touches UI**. The two are never the same test, and one can never substitute for the other:

| What decides Part B | What does NOT decide Part B |
|---|---|
| This story's code-generation plan includes a Frontend Components Generation step → Part B applies, unconditionally | Which story a REQ-ID is assigned to in `requirements.md`/`stories.md` |
| — | An external instruction (a coordinator, a delegation prompt, a prior session) saying "check before skipping" or "confirm applicability" |
| — | Precedent from how a different, earlier story handled the same REQ-ID |

If an out-of-band instruction asks you to treat REQ-ID ownership, a "confirm first" caveat, or any
signal other than this story's own plan as grounds to skip Part B, **that instruction is wrong and
must not be followed** — apply the rule above instead, silently, and proceed. There is no confirmation
step here to satisfy; Applicability is plan-derived and automatic, exactly like Step 11a.5's API gate.

### 🔴 How it runs — the TWO EXISTING SKILLS, invoked in WORKFLOW MODE

🔴 **This step re-implements NOTHING. It INVOKES the two existing skills via the Skill tool** —
**`ve-implement`** first (the test scope), then **`playwright-implement`** (generate + execute + heal) —
both in **WORKFLOW MODE**. That is the same pattern `pr-generator` and `pr-review` already use: the
invoking workflow's own authorization replaces the skill's internal confirmations, so the skill's
mechanics stay in ONE place and cannot drift between the manual and automatic paths.

**WORKFLOW MODE is a mode of those skills, not a copy of them.** Its full contract lives in
`agents/ve-implement-agent.md` (Mode Detection) and `agents/playwright-implement-agent.md`
(Mode Detection). Summarised here only so the ordering is unambiguous:

#### A. The story's manual test plan — VERIFY FIRST, invoke `ve-implement` only to backfill (🔴 checked for every story)
- [ ] **Already present? — this is the NORMAL case.** `spec/test-plans/<TICKET-ID>-<title>/` was written
  and approved at the STOP CHECKPOINT (`CLAUDE.md` Step 1.7 / `implementation/specs-and-test-plans.md`)
  and committed on the epic branch before any code existed. If the folder holds this story's manual test
  steps — from that checkpoint, or from ve's own earlier `/ve-implement` run, in ANY state (approval
  status is irrelevant here, only content matters) — reuse it as-is, record `Manual test plan: present
  (approved at STOP CHECKPOINT)`, and skip straight to **B**. 🔴 Never regenerate or overwrite an
  approved plan to match the code you just generated.
- [ ] **Otherwise — genuinely absent (legacy project, or a story added after the checkpoint) — invoke the
  `ve-implement` skill** (Skill tool) to backfill it, announcing the backfill explicitly, passing this
  work unit's story/ticket
  and **`mode: workflow`**. In WORKFLOW MODE that skill:
  - takes the story **as given** — its story-picker is never presented,
  - 🔴 **does NOT cut a `ve/…` branch, does NOT push, and does NOT raise a PR** — it stays on this work
    unit's own branch, and its artifacts ride this work unit's own commit,
  - auto-confirms `test-plan.md` Step 2's applicability table and **skips its Step 6
    Approve/Request-Changes checkpoint**,
  - still writes `spec/test-plans/<TICKET-ID>-<title>/` and its `runtime-artifacts/audit.md` entry exactly as usual,
    stamped `Mode: workflow (invoked by <workflow>) — no Verification Engineer approval, no Verification Engineer branch, no Verification Engineer PR`.
- [ ] 🔴 This is **scope derivation, not ve's sign-off**. ve's own `/ve-implement` run remains the
  authoritative, independently-scheduled track; if ve runs it later it finds the folder populated and
  applies its normal refresh-or-stop convention. Never present this content as ve-approved.

#### B. Invoke `playwright-implement` — generate, execute, heal (🔴 UI stories only)

> 🔴🔴 **TRIPWIRE — READ BEFORE YOU WRITE ANY FILE UNDER `tests/e2e/` OR `spec/playwright-specs/`.**
>
> **Ask yourself: has a `Skill(playwright-implement)` tool call happened in THIS run?**
> If the answer is no and you are about to `Write`/`Edit` a `.spec.*` file, **you are in the middle of
> violating this gate — stop and invoke the skill instead.** There is exactly ONE permitted producer of
> those files: the skill's own Planner and Generator subagents. Your own hand is never one of them, no
> matter how faithful the spec looks.
>
> 🔴 **Every one of these rationalisations is FORBIDDEN. Each was observed verbatim in a real run:**
>
> | What the agent told itself | Why it is wrong |
> |---|---|
> | *"Playwright's official Test Agents aren't installed in this repo/session"* | **Installing them is this gate's own first step** (Step 0a), not a blocker to route around. Install, then HALT for the session restart. |
> | *"Functionally equivalent — real browser, real app, real assertions"* | Equivalence is not the test. The Generator's locators come from the **live DOM it actually observed**; a hand-written spec's come from a document. That difference **is** the gate. |
> | *"Same precedent as Stories 1.1/1.3"* · *"mirroring this pattern"* | A prior story that did this is a **defect to backfill**, never a licence. Precedent does not launder a violation. |
> | *"Disclosed, not silent"* · a `NOTE:` comment in the file admitting the shortcut | **Disclosure is not mitigation.** A header confessing the gate was bypassed is *evidence of* the violation, not a remedy for it. |
>
> 🔴 **Writing the spec yourself is a worse outcome than halting.** A halt is recoverable in one
> command; a hand-authored spec merges, becomes the regression baseline, and nobody ever learns the
> browser never verified those locators.
>
> 🔴🔴 **THE CATCH-ALL — this rule closes the class, not just the known cases.**
> **ANY reason whatsoever that you cannot invoke the real Playwright subagents resolves to HALT.
> There is no reason that resolves to "write them myself".** Not the ones already observed (agents not
> installed · MCP server not connected · running inside a fork or subagent with no Agent tool), and not
> whatever new one you are looking at right now. If you find yourself constructing a justification for
> why *this particular* blocker is the exception — that construction **is** the violation. Stop, state
> the blocker plainly, and halt.
>
> 🔴 **EXECUTION-CONTEXT PRECONDITION — check this BEFORE anything else in Part B.** This gate requires
> a context that can call the **Agent tool**, because `subagent_type: "playwright-test-{planner,
> generator,healer}"` are Agent-tool invocations. **A fork, or any subagent whose instructions say
> "do NOT spawn subagents / you ARE the fork, execute directly", cannot run this gate at all.** Detect
> it, and HALT with:
>
> ```
>  PLAYWRIGHT GATE CANNOT RUN IN THIS EXECUTION CONTEXT
>
>    Work unit: [Story N.M / TICKET-ID] — [title]     Branch: [branch]
>    Blocker:   this run is a [fork | restricted subagent] and cannot call the Agent tool, which is
>               required to invoke Playwright's own Planner/Generator/Healer subagents.
>               This is NOT fixable by installing anything or restarting the session.
>
>    Nothing is lost. [gates already passed] are recorded in runtime-artifacts/audit.md.
>       No commit, no push, no PR, no tracker change. NO specs were hand-authored.
>
> NEXT ACTIONS:
>    1.  Re-run this work unit's Playwright gate from a NORMAL session or a general-purpose agent —
>        one that can call the Agent tool.
>    2.  Or re-invoke [dev-implement | bug-fix-implement | enhancement-implement] outside the fork;
>        it resumes at this gate, skipping every gate already recorded as passed.
> ```
>
> 🔴 **Never continue the run past this halt, and never "disclose and proceed".** A backend-only work
> unit is unaffected — Part B is `N/A` for it and the fork can complete normally.
> 🔴 **Exception — `dev-implement` and `pr-fix` never run in a fork at all.** Their Single-Session
> Execution rule (`workflows/dev-implement.md` Step 1.7, `workflows/pr-fix.md` Step 0) halts a
> forked run before any work unit is touched, backend-only included, so for those two workflows this
> precondition is already settled before Part B is reached.
- [ ] **Invoke the `playwright-implement` skill** (Skill tool), passing the same story and
  **`mode: workflow`**. In WORKFLOW MODE that skill:
  - takes the story **as given** — its story-picker is never presented,
  - 🔴 **skips its Step 2a both-merges gate** — nothing has merged yet *by design*; that gate exists for
    the post-merge standalone path, and here the code under test is in this very working tree,
  - 🔴 **skips its Step 3 integration-branch resolution/checkout** — it works on this work unit's branch
    and never switches branches mid-run,
  - runs its Step 5 **Prerequisite Gate** (`playwright-automation.md` Step 0) as a **real blocking
    gate**: 🔴 **anything missing is INSTALLED automatically, announced — never skipped.** Missing
    `@playwright/test`, missing `.claude/agents/playwright-test-*`, or a missing `.mcp.json` entry
    means run `npm i -D @playwright/test && npx playwright install` and/or `npx playwright init-agents
    --loop=claude` on the spot. In workflow mode "confirm-first" resolves to **proceed**, never to
    "unavailable". 🔴 **If `init-agents` had to run, the gate HALTS there and asks for a Claude Code
    session restart** (Step 0a's verbatim block) — the `playwright-test` MCP server it just registered
    is not connected in this session, so the Planner/Generator/Healer cannot run. This is a
    **sanctioned hard stop, not an approval prompt** — the run physically cannot continue, exactly like
    a Retry-Limit halt. Nothing is committed, pushed or transitioned. It records
    `PAUSED — Playwright agents installed — resume at <this gate's step> — <timestamp>` in the work unit's
    `runtime-artifacts/stories/<key>/state.md` `## Progress`; on restart the user types the same keyword and
    the workflow's resume check finds that record and resumes **at this gate**, skipping every gate already
    recorded as passed in the work unit's audit trail. When everything was already installed,
    no pause happens at all. It then **auto-derives and applies** the **Seed Test Gate** (Step 0d)
    instead of asking,
  - **starts the app locally itself** (Bash, backgrounded) using the project's own start command —
    resolved repo script → direct invocation, never invented — polls the readiness URL until it
    answers, and tears the server down on every exit path,
  - invokes the **real Planner** (Agent tool, `subagent_type: "playwright-test-planner"`),
    🔴 **auto-approves its plan — its Step 7 Approval Gate is SKIPPED**,
  - invokes the **real Generator** per scenario, **sequentially** (`subagent_type:
    "playwright-test-generator"`) — never in parallel — then runs the Cross-Scenario Consistency Pass,
  - **executes via Bash, `--headed` exactly as the standalone path does**:
    `npx playwright test tests/e2e/<story-slug>/ --headed` — 🔴 this is the developer's own machine and
    watching the browser exercise the story just built is the point. **Headless belongs to CI alone**
    (a runner has no display); it is never a local default. The one local fallback is a machine with
    genuinely no display, proven by the failure, recorded as `"headed": false` with the real reason,
  - invokes the **real Healer** (`subagent_type: "playwright-test-healer"`) on any failure, never
    intervening in its internal loop,
  - 🔴 **skips its Step 12 Push Gate and direct push to the integration branch** — the generated
    artifacts ride this work unit's own commit instead (Section D / the commit step of the invoking
    workflow).
- [ ] **Record the resolved `startCommand` and `readinessUrl`** into this work unit's manifest fragment
  (`ci.playwright`, `common/eval-framework.md` Section 1) — this is exactly what lets CI's trust-gate
  run reuse the identical commands instead of re-deriving them.
- [ ] 🔴 **A `test.fixme()` outcome does NOT satisfy this gate.** In the standalone skill a `test.fixme()`
  is merely flagged as a candidate defect for a human to triage later; **inside this automatic gate it
  means the Healer's own analysis found a real app defect — fix the application code in this same run**
  (exactly the class of issue this gate exists to catch before code review) and re-run, rather than
  deferring it.
- [ ] **If the Seed Test Gate cannot be confidently derived** (ambiguous role, several distinct login
  flows, no anchor precondition), that is a one-time blocking input gap, not a retry-loop failure: HALT
  with a short, clearly-labeled report naming exactly what `tests/e2e/seed.spec.ts` needs, and resume
  this step once the user supplies it — do **not** consume an SH-LOOP-11 attempt on it.

### Self-healing — SH-LOOP-11, capped at 3 attempts (SH-1)
- [ ] **Verification that must pass**: every generated Playwright spec passes with zero `test.fixme()` outcomes.
- [ ] Below that → **SH-LOOP-11**: diagnose the root cause (SH-7), fix the application code (never the generated spec, unless the spec itself is provably wrong against the approved acceptance criteria), re-run Step 4, re-heal if needed. Capped at 3 remediation attempts (SH-1); on exhaustion apply SH-4 — **HALT and emit the Retry-Limit Report**, naming the failing spec(s) and the Healer's own diagnosis.
- [ ] 🔴 **Forbidden shortcuts** (SH-6): marking a genuinely failing spec `test.fixme()` to force a pass, deleting or weakening a generated assertion, or silently narrowing the Planner's scope to dodge a hard scenario.

### Evidence and scorecard integration
- [ ] **Capture PROOF artifacts** to `reports/playwright-test-evidence/story-[N.M]/`:
  - [ ] **`playwright-test-run.log`** — the raw, unedited stdout/stderr of the final passing run.
  - [ ] **`playwright-test-report.json`** — the **mandatory machine-readable** report (`npx playwright test tests/e2e/<story-slug>/ --reporter=line,json:reports/playwright-test-evidence/story-[N.M]/playwright-test-report.json`). A raw log alone does NOT satisfy the gate.
  - [ ] **`evidence-manifest.md`** — a table: manual TC → generated spec → result, plus the Cross-Scenario Consistency Pass notes and the Healer outcomes (healed vs. fixed-in-app).
- [ ] 🔴 **PROVENANCE CHECK — the gate is not satisfied until this passes.** Before recording the result, assert all three; any failure is **ERROR**, never PASS, never `N/A`:
  1. A **`Skill(playwright-implement)` invocation exists in this run's transcript and in `runtime-artifacts/audit.md`.** No invocation → the specs were not agent-generated → ERROR.
  2. **`spec/playwright-specs/<story-slug>.md` exists** — the real Planner's own `planner_save_plan` output. A `tests/e2e/<story-slug>/` directory with **no corresponding Planner plan** is the signature of hand-authored specs: the Generator cannot run without a plan, so specs-without-a-plan means neither agent ran. 🔴 **Scope: THIS work unit's own slug, in THIS run** — the plan was written minutes ago by the skill invocation asserted in (1), so it is always live here. Do **not** generalise this into a sweep over every `tests/e2e/*` directory: `spec/` is cycle-scoped and an earlier closed cycle's plan lives in its archive, not live (`common/directory-structure.md`). The cross-cycle case is `implementation/code-review.md`'s provenance check, which resolves live-or-archive.
  3. **No generated file contains a disclosure comment** admitting it was hand-written / not agent-generated (grep the new specs for `hand-authored`, `not agent-generated`, `agents are not installed`, `precedent`). Such a comment is a **confession of the violation**, not a mitigation — its presence is itself the ERROR.
  🔴 On any failure: delete the hand-authored artifacts, install the agents if needed, and run the gate properly via the skill. Never record a `playwright` gate result produced by hand.
- [ ] **Write into `eval.json`'s `gates` block under id `"playwright"`** (per `common/eval-framework.md` Section 1/6) — `PASS`/`FAIL`/`N/A` with scenario counts — so `eval-summary.md`, the PR body, and the downstream **CI Attestation gate (SH-LOOP-10)** all pick it up automatically, exactly like every other gate.
- [ ] **Commit the generated artifacts** (`tests/e2e/<story-slug>/`, `spec/playwright-specs/<story-slug>.md`, any confirmed `tests/e2e/seed.spec.ts` addition, `playwright.config.ts` if newly created, `spec/test-plans/<TICKET-ID>-<title>/automation-summary.md`) together with the rest of the story's changes — there is no separate branch or push here; this is part of the SAME story branch and the SAME commit as everything else in this Part.
- [ ] Proceed to Step 11e (the Playwright E2E Regression Gate) only once the diff is clean (zero failing specs).


## Step 11e: 🧪 Playwright E2E Regression Gate (MANDATORY — after Step 11d, before Code Review, same run)

**Purpose**: Step 11d proves **this work unit's own** new Playwright specs pass. It proves nothing about the specs every *earlier* work unit already shipped. This step closes that gap — it is the **UI counterpart of the Full Regression gate (Step 11b)**, and it works exactly the same way: photograph the existing `tests/e2e/` suite before any code is written, re-run it after, and attribute only the difference.

### 🔴 Applicability — EVERY work unit, UI or not (deliberately unlike Step 11d)

| Gate | Applies when | Scope |
|---|---|---|
| **Step 11d part B** (UI Automation) | the plan has a **Frontend Components Generation** step | this unit's OWN new specs |
| **Step 11e** (this gate) | **ALWAYS** — every work unit | the ENTIRE existing `tests/e2e/` suite |

🔴 **Do NOT skip this gate because the work unit touches no UI.** A backend handler, a changed API response shape, a renamed field, a migration, a config or dependency bump is precisely what breaks an already-shipped browser flow — and it is the case a UI-only gate can never catch. This is the same reasoning that makes Step 11b run the whole repo suite rather than only the story's own tests.

**`N/A` — exactly one legitimate reason**, recorded explicitly (never a silent skip): `tests/e2e/` contains
no spec files at all — no earlier work unit generated any (which includes a project with no UI), so there is
nothing to regress. 🔴 Specs that exist but a runner or browsers not installed on this machine is **not** N/A —
the invoking workflow installs them at its baseline step and runs the sweep.

### The baseline comes first — and it is captured by the invoking workflow

The pre-change run is **not** part of this step. Like Step 11b's `baseline-regression.log`, it is captured on the freshly cut branch **before any code is generated**, by whichever workflow invoked this file:

| Workflow | Baseline captured at |
|---|---|
| `dev-implement` | Step 1.5 Item 4.7 |
| `bug-fix-implement` | Step 3 Item 6 |
| `enhancement-implement` | Step 10 (Baseline Playwright E2E Regression Run) |

🔴 **ORDER IS LOAD-BEARING — baseline → generate code → Step 11d → Step 11e → diff.** A baseline captured *after* code generation measures the changed system and can never attribute anything; a work unit would then be blamed for, or credited with hiding, every pre-existing UI failure. This is the same ordering rule Step 11b and Step 11c already carry.

### Mechanics

- [ ] **Start the application the same way Step 11d does** — the `startCommand` / `readinessUrl` recorded in `tests/.evals/config.json` `ci.playwright` (plus `backendStartCommand` / `backendReadinessUrl` when the local gate needed frontend and backend as two separate processes), resolved from the project's own scripts — 🔴 **never invented**. Poll readiness before running, and **tear the server(s) down on every exit path**, including failure.
- [ ] **Run the ENTIRE `tests/e2e/` suite** — every earlier work unit's specs **plus** any this unit just generated in Step 11d — not a subdirectory, not a filtered subset:
      `npx playwright test tests/e2e/ --reporter=line,json:reports/playwright-test-evidence/<key>/regression/playwright-regression-report.json`
- [ ] 🔴 **Run headless — a deliberate, narrow carve-out from Step 11d's `--headed` rule.** That rule exists because a developer is meant to *watch* the browser exercise the story they just built. This is a bulk sweep of dozens of already-approved specs that nobody watches, so headless is the default here, for speed. Record `"headed": false, "reason": "bulk regression sweep, not the authoring gate"` in the evidence manifest. (A developer may still run it `--headed` by hand when diagnosing.)
- [ ] **Diff against the baseline.** Only specs that were **green at baseline and are red now** count against this gate.
- [ ] **NEW failures → this work unit broke them, so this work unit fixes them**, within THIS SAME run; then re-run and re-diff until the diff is clean. **This is SH-LOOP-13 — capped at 3 remediation attempts (SH-1). On exhaustion apply SH-4: HALT and emit the Retry-Limit Report**, naming each newly-red spec and what the three attempts changed.
- [ ] **Failures already red at baseline** → not this work unit's doing. They are already logged in `playwright-baseline-regression.log`; ignore them and do not block on them.
- [ ] 🔴 **FIX THE APPLICATION CODE, NEVER THE SPEC.** A generated Playwright spec encodes an acceptance criterion an earlier work unit shipped and a human approved. **Deleting it, marking it `test.fixme()` or `.skip`, loosening a locator, widening a timeout, or narrowing an assertion to make it green is the exact analogue of deleting a failing unit test and is equally forbidden (SH-6).** A spec changes only when the acceptance criterion it encodes genuinely changed — and then the AC, `requirements.md` and the tracker item are amended together and the reconciliation is logged.
- [ ] **Capture PROOF artifacts** to `reports/playwright-test-evidence/<key>/regression/`:
  - [ ] **`playwright-baseline-regression.log`** — the raw pre-change run (written by the invoking workflow's baseline step)
  - [ ] **`playwright-baseline-report.json`** — the **mandatory machine-readable** baseline report
  - [ ] **`playwright-full-regression.log`** — the raw post-change run
  - [ ] **`playwright-regression-report.json`** — the **mandatory machine-readable** post-change report. A raw log alone does NOT satisfy this gate.
  - [ ] **`evidence-manifest.md`** — baseline vs post-change pass/fail counts, the exact commands, `headed` + its reason, the app start commands used, and each NEW failure with what broke and how it was fixed
- [ ] **Write the result into `eval.json`'s `gates` block under id `"playwrightRegression"`** — `PASS` / `FAIL` / `N/A` with the new-failure count — so `eval-summary.md`, the PR body and the completion message all pick it up like every other gate.
- [ ] 🔴 **This is a LOCAL-ONLY gate, exactly like `regression` and `apiContract`** (`common/eval-framework.md` Section 5): CI has no baseline to diff against, so **`playwrightRegression` is NEVER added to `ci.gates`** — a declared gate with no result is an ERROR there. CI's own `playwright` job stays what it already is: a trust gate that re-executes the specs, with no attribution.
- [ ] Proceed to Step 12 (and Code Review) only once the diff is clean (zero NEW failing specs).
## Step 12: Update Progress
- [ ] Mark the completed step as [x] in the code generation plan
- [ ] **Story Tracker**: ensure the story being implemented is `In Development` with a `Start` date; update `Recorded` to the current timestamp in `runtime-artifacts/aire-state.md`
- [ ] Update `runtime-artifacts/aire-state.md` current status
- [ ] **Brownfield only**: Verify no duplicate files created (e.g., no `ClassName_modified.java` alongside `ClassName.java`)
- [ ] Save all generated artifacts

## Step 13: Continue or Complete Generation
- [ ] If more steps remain, return to Step 10
- [ ] If all steps complete, proceed to present completion message

## Step 14: Present Completion Message
- Present completion message in this structure:
     1. **Completion Announcement** (mandatory): Always start with this:

```markdown
# Code Generation Complete - Story [N.M]
```

     2. **AI Summary** (optional): Provide structured bullet-point summary
        - **Brownfield**: Distinguish modified vs created files (e.g., "• Modified: `src/services/user-service.ts`", "• Created: `src/services/auth-service.ts`")
        - **Greenfield**: List created files with paths (e.g., "• Created: `src/services/user-service.ts`")
        - List tests, documentation, deployment artifacts with paths
        - Keep factual, no workflow instructions
     3. **Formatted Workflow Message** (mandatory): Always end with this exact format:

```markdown
> ** <u>**REVIEW REQUIRED:**</u>**  
> Please examine the generated code at:
> - **Application Code**: `[actual-workspace-path]`
> - **Documentation**: `reports/ticket-summary/`



> ** <u>**WHAT'S NEXT?**</u>**
>
> Code generation is complete. An **automated Code Review now runs for this story** — you are not
> asked for anything. If it reports findings they are **remediated automatically** and re-reviewed
> until the verdict is clean; then the commit, push and PR happen on their own.

---
```

## Step 15: Hand Off to Automated Code Review (no user gate here)

🔴 **GUARDRAIL — "Code Review" and "Remediate" here are WORKFLOW RULE FILES, NOT Claude skills.** They are executed by `Read`ing and following `workflows/code-review.md` / `workflows/remediate.md` (which pull detailed steps from `implementation/code-review.md` / `implementation/remediate.md`). There is **NO** Claude skill named `code-review` or `remediate` — **NEVER** invoke one via the Skill tool. The only review that IS a skill is **`pr-review`** (post-PR, AUTO MODE, as-is).

- **When invoked via `dev-implement`** (the normal path): do NOT stop for a "Request Changes / Continue" choice. Immediately hand control back to `workflows/dev-implement.md` **Post-Code-Generation Automation**, which auto-runs Code Review, audits the full log, and then routes on the verdict itself — a clean verdict goes straight to commit/push/PR, and any finding is fixed by the automatic remediate loop. No approval is requested at any point.
- **When invoked standalone** (code generation only, not under `dev-implement`): present the completion announcement and wait for the user to either request changes or confirm; do not auto-run downstream workflows.

## Step 16: Record Approval & Story Status
> **When invoked via `dev-implement`** (the normal path): do NOT change the status here. The story stays `In Development` through code generation, the automated Code Review, any Remediate loop, the PR raise (Section D — which only STORES the PR URL and sets `Merged=no`), and the auto PR review
- Log approval in the audit trail with timestamp
- Record the user's approval response with timestamp
- **Post-implementation status — standalone code-generation too**: the story remains `In Development`. Code generation never promotes a story; `Ready for Testing` is set only by `ve-list-work` Option B after the story's PR has merged and the ve has tested it.
- **The ONLY valid Story Tracker statuses are `Ready for Development`, `In Development`, and `Ready for Testing`.**

---

## Critical Rules

### Code Location Rules — 🔴 `src/` IS THE ONLY CODE ROOT

Full layout: `common/directory-structure.md`. The five roots and what belongs in each:

| Root | Contents |
|---|---|
| **`src/`** | ALL application code — greenfield AND brownfield |
| **`tests/`** | `unit/` · `behavior/` ( Gherkin step definitions) · `e2e/` (Playwright) |
| **`spec/`** | Specs + docs ONLY. 🔴 Never a source file. |
| **`reports/`** | Generated test/eval evidence ONLY (unit / behavior / api-contract / eval) |
| **`tests/.evals/`** | `config.json`, `rubrics/`, `scripts/` |

- **Read the code root from `runtime-artifacts/aire-state.md` `## Code Root`** before generating. If the block is
  absent, the root is `src/`.
- 🔴 **Never write application code outside the resolved code root**, and never into `spec/`.

**Structure patterns by project type** (all *inside* the code root):
- **Greenfield (default)**: `src/` for code, `tests/` for tests, `config/` for configuration
- **Greenfield, multiple services (per Application Design)**: `src/{service-name}/`, `tests/unit/{service-name}/`
- **Greenfield, modular monolith (per Application Design)**: `src/{module-name}/`, `tests/unit/{module-name}/`
- **Brownfield**: use the EXISTING structure under the recorded code root (e.g. `src/main/java/`,
  `packages/api/src/`). 🔴 Never mass-move an existing tree into `src/` — that produces an
  unreviewable diff and breaks every import. Record the real root once and treat it as `src/` for the
  whole cycle (`common/directory-structure.md` — Brownfield reconciliation).
- **Brownfield with no discernible code root** (files loose at the repo root): create `src/`, put
  **only new** code there, record it, and leave the existing files alone.

### Brownfield File Modification Rules
- Check if file exists before generating
- If exists: Modify in-place (never create copies like `ClassName_modified.java`)
- If doesn't exist: Create new file
- Verify no duplicate files after generation (Step 12)

### Planning Phase Rules
- Create explicit, numbered steps for all generation activities
- Include story traceability in the plan
- **REQ-ID THREAD**: load requirements.md + the story's `Covers` REQ-IDs as planning input, tag every step with the REQ/AC it implements, and pass the trace completeness self-check (every covered REQ-ID and every AC in ≥1 step) before the plan is announced — per `common/requirements-traceability.md` Rule 5
- Document story context and dependencies
- NO approval before generation — the plan is announced and executed (there is no plan gate)

### Generation Phase Rules
- **NO HARDCODED LOGIC**: Only execute what's written in the story plan
- **FOLLOW PLAN EXACTLY**: Do not deviate from the step sequence
- **UPDATE CHECKBOXES**: Mark [x] immediately after completing each step
- **STORY TRACEABILITY**: Mark the story's plan steps [x] when functionality is implemented
- **RESPECT DEPENDENCIES**: Only implement when every `requires` dependency's PR is merged (Doability Gate)
- 🔴 **SQL RESERVED-WORD GUARDRAIL**: when generating any SQL (queries, migrations, stored procedures), never use a target-dialect reserved keyword (e.g., in T-SQL: `key`, `order`, `date`, `user`, `identity`, `year`, `percent`, `session`, `open`, `close`) as an unquoted column/table alias or identifier. Always bracket/quote any alias that could collide (`AS [Order]` in T-SQL, backticks in MySQL, double quotes in Postgres), or simply pick a non-colliding alias name.
- 🔴 **ANGULAR/JS ASYNC SCOPE GUARDRAIL**: when generating Angular (or any JS/TS) code with async callbacks, always use arrow functions for `.subscribe()`, `.then()`, `.pipe()` operator, and other async callbacks inside a class, so `this` correctly resolves to the enclosing component/service/directive instance — never a plain `function() {...}` callback in that position. Always unsubscribe from long-lived Observables in `ngOnDestroy` (`Subscription.unsubscribe()`, `takeUntil(this.destroy$)`, or the `async` pipe) so a callback never fires against a destroyed component instance. Never shadow an outer-scope variable name inside a nested/chained API-call callback — give inner-scope variables from chained calls distinct names.

### Unit Test & Coverage Rules (MANDATORY — every story)
- 🔴 **TESTS AFTER IMPLEMENTATION, SAME RUN**: Once the story's implementation is complete, ALWAYS execute Step 11a — generate unit tests, RUN them, and iterate to the coverage target before the story is announced complete
- 🔴 **COVERAGE GATE (threshold from `tests/.evals/config.json`)**: measure coverage on the story's new/changed code; below target → add/adjust tests and re-run within the same run until met (or surface the gap to the user with the measured % and a reason).
- 🔴 **PROOF ARTIFACTS (MANDATORY)**: from the FINAL passing run, save the raw runner output (`unit-test-run.log`), the coverage tool's **machine-readable report file** (`coverage-report.*` — lcov/xml/json/HTML), and an `evidence-manifest.md` to `reports/unit-test-evidence/story-[N.M]/`. Evidence is the actual tool output, NOT a hand-written claim. **The coverage-report file is MANDATORY whenever the stack has coverage tooling** — run the tool with the flags that emit it (`--cov-report=xml`, `--coverageReporters=lcov`, JaCoCo report, etc.); a terminal summary alone does NOT satisfy the gate. Only when the stack genuinely has NO coverage-report tooling is the file waived — a documented, user-surfaced exception recorded in `evidence-manifest.md`, never a silent skip. Every X/X-passing and coverage-% figure reported downstream (completion message, Code Review, PR/tracker comment) MUST match these saved artifacts.

  | Metric | Target | Scope |
  |--------|--------|-------|
  | Unit Test Coverage | `unitTestCoverageMin` | All new/changed code for the story |

### API & Contract Testing Rules (MANDATORY WHEN the story touches an API layer)
- 🔴 **APPLICABILITY IS PLAN-DERIVED, AUTOMATIC**: if the story's plan includes an API Layer Generation step, this gate is MANDATORY — never skip it and never ask the user whether it applies. If the plan has no API Layer Generation step, it is N/A — state that explicitly, do not silently omit the section.
- 🔴 **ONE GATE, SIX CHECKLIST ITEMS**: functional/happy-path, response-code validation, role-based authorization (401 vs 403), error-response validation (standard format + codes), request validation (required fields/types/enums), and response contract validation (schema compliance) — generated as automated tests against the REAL endpoints, RUN, and iterated to a full pass in the SAME run as implementation, never deferred to ve or a later session.
- 🔴 **PROOF ARTIFACTS (MANDATORY)**: `api-contract-test-run.log`, the **mandatory machine-readable** `api-contract-test-report.*` (JUnit XML/JSON — run the tool with the report-emitting flag/plugin, e.g. `pytest --junitxml=...`, `jest --json --outputFile=...`; a raw log alone does NOT satisfy the gate whenever the runner supports a report), and `evidence-manifest.md` (per-endpoint checklist table) to `reports/api-contract-test-evidence/story-[N.M]/`. Only a genuinely reportless runner (documented, surfaced exception) waives the report file. Every X/X-passing figure reported downstream MUST match these saved artifacts.
- 🔴 **NEVER weaken a checklist assertion to force a pass** — a genuinely inapplicable item is marked N/A with a stated reason, not silently dropped or asserted away.
- 🔴 This gate is **separate from and does not replace** ve's `/ve-implement` MANUAL API/Contract test *steps* (`spec/test-plans/<TICKET-ID>-<title>/api-test-steps.md` / `contract-test-steps.md`) — those remain ve's independent black-box design/validation layer.

### Step 11d Rules — Test Plans (ALWAYS) + Playwright UI Automation (UI stories only)
- 🔴 **THE TWO HALVES HAVE DIFFERENT APPLICABILITY — never skip the whole step because the story has no UI.** **Part A (the story's manual test plan) is CHECKED for EVERY story**, UI or not — it was authored and approved at the STOP CHECKPOINT, so the normal case is a presence check; `ve-implement` is invoked in WORKFLOW MODE only to backfill a genuinely absent plan, announced. Either way the ve simply executes the plan after the story PR merges instead of generating it first. **Part B (`playwright-implement` → browser automation) runs only when the story's plan includes a Frontend Components Generation step.**
- 🔴 **APPLICABILITY IS PLAN-DERIVED, AUTOMATIC**: never ask the user whether either half applies. If the plan has no Frontend Components Generation step, Part B is N/A — state that explicitly, and still complete Part A.
- 🔴 **INVOKE THE SKILLS, NEVER RE-IMPLEMENT THEM** — `ve-implement` then `playwright-implement`, both via the Skill tool in **WORKFLOW MODE**. `ve-implement` and `playwright-implement` ARE real Claude skills (unlike `code-review`/`remediate`, which are rule files and must never be invoked as skills). Their mechanics live in `agents/ve-implement-agent.md`, `agents/playwright-implement-agent.md`, `implementation/test-plan.md` and `extensions/testing/playwright-automation/playwright-automation.md` — this gate only supplies the story and the mode.
- 🔴 **REAL PLAYWRIGHT AGENTS ONLY** — the Planner, Generator and Healer invoked inside that skill are Playwright's own installed subagents. Never re-implement their logic.
- 🔴 **NOT INSTALLED IS AN ERROR TO FIX, NOT A GAP TO DISCLOSE.** Missing Playwright, missing `.claude/agents/playwright-test-*`, or a missing `.mcp.json` entry → **install them** (`npm i -D @playwright/test && npx playwright install`, `npx playwright init-agents --loop=claude`) and continue. Same verdict `common/eval-framework.md` Section 2.5.2 already gives `"gitleaks not installed"`: **ERROR, never `N/A`**. The one genuine blocker is the newly-written `.mcp.json` not yet loaded into this session — that is a **HALT + restart**, never a fallback.
- 🔴 **A HAND-AUTHORED `.spec.ts` IS NOT A GATE RESULT.** If the real Generator subagent did not write it, this gate did not pass — exactly as `eval-framework.md` Section 2.5.2 rules a hand-written claim out for D1–D7: *the gate is the TOOL's output, or it is ERROR; there is no third option.* Hand-writing specs from the manual test plan and disclosing it as a known gap produces tests generated from nobody's observation of the live DOM, with locators verified against nothing — the exact failure the Planner/Generator exist to prevent. 🔴 **And a previous story's disclosed gap is never precedent** — it is a defect to backfill, not a pattern to follow.
- 🔴 **WORKFLOW MODE SKIPS APPROVALS AND GIT, NOTHING ELSE** — no story-picker, no ve approval checkpoint, no Planner-plan approval gate, no both-merges gate, no `ve/…` branch, no push, no PR, no Push Gate. Every *verification* the skills perform still runs, and every generated spec must still actually PASS — auto-approval is not a shortcut on correctness.
- 🔴 **LOCALLY STARTED, `--headed`, TORN DOWN** — the app is started by this gate itself (never assumed already running), executed **`--headed` exactly as the standalone skill does** (this is the developer's machine; the browser is meant to be visible), and torn down on every exit path. **Headless is CI's alone**, because a runner has no display — never a local default. The one local fallback is a machine with genuinely no display, proven by the failure and recorded as `"headed": false` with the real reason in the evidence manifest.
- 🔴 **`test.fixme()` NEVER SATISFIES THIS GATE** — a healed-but-still-`fixme()`'d spec means a real app defect; fix it in this same run (SH-LOOP-11), never defer it.
- 🔴 **PROOF ARTIFACTS (MANDATORY)**: `playwright-test-run.log`, the **mandatory machine-readable** `playwright-test-report.json`, and `evidence-manifest.md` to `reports/playwright-test-evidence/story-[N.M]/`. The result is also written into `eval.json`'s `gates.playwright` so CI's later trust-gate re-run is cross-checked automatically by the CI Attestation gate.
- 🔴 CI's own Playwright step is a **trust gate that re-executes the same specs post-PR — headless only because a runner has no display, and never the first execution**. A CI-only Playwright failure on a gate that passed here is a CI provisioning/manifest defect (missing start command, missing browsers, wrong readiness URL), handled exactly like every other CI-vs-local mismatch — never grounds to re-litigate the local result.


### Step 11e Rules — Playwright E2E Regression (EVERY work unit, UI or not)
- 🔴 **APPLIES TO EVERY WORK UNIT — deliberately unlike Step 11d.** Step 11d part B is UI-only and scoped to this unit's OWN new specs; Step 11e is the UI counterpart of the Full Regression gate and runs the **entire** `tests/e2e/` suite for **every** work unit. **Never skip it because the unit touches no UI** — a backend, API, schema, config or dependency change is exactly what breaks an already-shipped browser flow, and nothing else in the run would catch it.
- 🔴 **BASELINE BEFORE CODE, FULL RUN AFTER, THEN DIFF** — the same three-beat shape as Step 11b: the invoking workflow captures the baseline on the freshly cut branch before any code is generated (`dev-implement` Step 1.5 Item 4.7, `bug-fix-implement` Step 3 Item 6, `enhancement-implement` Step 10), this step re-runs and diffs. A baseline taken after code generation is worthless and blames this unit for pre-existing failures.
- 🔴 **ONLY THE DELTA COUNTS.** Green at baseline + red now = this unit's problem, fixed in the same run under **SH-LOOP-13** (3 attempts, then SH-4 HALT + Retry-Limit Report). Red at baseline = pre-existing debt: logged, ignored, never blocking.
- 🔴 **FIX THE CODE, NEVER THE SPEC.** No deleting, no `test.fixme()`, no `.skip`, no loosened locator, no widened timeout, no narrowed assertion to force an existing spec green — the analogue of deleting a failing unit test, and equally forbidden (SH-6). An approved spec changes only when its acceptance criterion genuinely changed, amended together with the AC, `requirements.md` and the tracker item, and logged.
- 🔴 **HEADLESS IS THE DEFAULT HERE** — a narrow, reasoned carve-out from Step 11d's `--headed` rule, which exists so the developer can watch the specs being authored for the story in hand. A bulk sweep of already-approved specs is not that. Record `"headed": false` with the reason in the evidence manifest.
- 🔴 **THE APP IS STARTED AND TORN DOWN BY THIS GATE**, using the same `ci.playwright` start/readiness commands Step 11d resolved from the project's own scripts — never invented, never assumed already running.
- 🔴 **PROOF ARTIFACTS (MANDATORY)**: `playwright-baseline-regression.log`, `playwright-baseline-report.json`, `playwright-full-regression.log`, the **mandatory machine-readable** `playwright-regression-report.json`, and `evidence-manifest.md` — all under `reports/playwright-test-evidence/<key>/regression/`. Every figure reported downstream MUST match them; a hand-written claim is never a gate result.
- 🔴 **`N/A` has exactly one legitimate reason** — `tests/e2e/` holds no specs at all (no earlier work unit generated any). Recorded explicitly with the reason; a missing runner or browser is installed, never a reason for N/A. 🔴 Never `N/A` because *this* unit has no UI, and never reported as a pass.
- 🔴 **LOCAL-ONLY GATE** — `playwrightRegression` goes into `eval.json`'s `gates` block but is **never** added to `ci.gates`, for the same reason `regression` and `apiContract` are local-only: CI has no baseline, so it cannot compute the attribution this gate exists for.
### Automation Friendly Code Rules
When generating UI code (web, mobile, desktop), ensure elements are automation-friendly:
- Add `data-testid` attributes to interactive elements (buttons, inputs, links, forms)
- Use consistent naming: `{component}-{element-role}` (e.g., `login-form-submit-button`, `user-list-search-input`)
- Avoid dynamic or auto-generated IDs that change between renders
- Keep `data-testid` values stable across code changes (only change when element purpose changes)

## Completion Criteria
- Story Selection completed (Step 0) and the implemented story recorded in the Story Tracker
- Complete code generation plan created and approved
- All steps in the code generation plan marked [x]
- The selected story implemented according to plan
- All code generated, with unit tests generated AND executed after implementation (Step 11a)
- Unit test coverage ≥ `unitTestCoverageMin` for all new/changed code (measured and iterated to target in the same run)
- **Proof artifacts saved** to `reports/unit-test-evidence/story-[N.M]/` — `unit-test-run.log` (raw runner output), `coverage-report.*` (the coverage tool's **mandatory** machine-readable report: lcov/xml/json/HTML), and `evidence-manifest.md` — with the reported X/X passing + coverage % matching those artifacts. Missing the coverage-report file = gate not satisfied
- **API & Contract Testing Gate applied when the story touches an API layer** — every new/changed endpoint has a passing automated test for each applicable checklist item (functional, response code, role-based authorization, error-response validation, request validation, response contract validation), with proof artifacts saved to `reports/api-contract-test-evidence/story-[N.M]/`; explicitly marked N/A (with reason) when the story touches no API layer
- **The story's manual test plan exists at `spec/test-plans/<TICKET-ID>-<title>/`** — normally the one approved at the STOP CHECKPOINT (`CLAUDE.md` Step 1.7) and verified at Step 11d Part A, otherwise backfilled there via `ve-implement` in WORKFLOW MODE or reused from ve's own earlier run — so the ve can execute it as soon as the story PR merges
- **Playwright UI Automation applied when the story touches UI** — every generated Playwright spec passes (zero `test.fixme()` outcomes) `--headed` against a locally started instance of the app, with proof artifacts saved to `reports/playwright-test-evidence/story-[N.M]/` and the result written into `eval.json`'s `gates.playwright`; explicitly marked N/A (with reason) when the story touches no UI
- **Playwright E2E regression run for EVERY work unit, UI or not** — the entire existing `tests/e2e/` suite captured as a baseline before any code (invoking workflow) and re-run after Step 11d, with **zero NEW failing specs** versus that baseline; proof artifacts saved to `reports/playwright-test-evidence/story-[N.M]/regression/` and the result written into `eval.json`'s `gates.playwrightRegression`; explicitly marked N/A (with reason) only when `tests/e2e/` holds no specs at all
- Post-implementation Story Tracker update applied (status + timestamps); tracker phase prompt presented and applied if confirmed for non-LOCAL tracked stories
- Deployment artifacts generated
- Story ready for build and verification
