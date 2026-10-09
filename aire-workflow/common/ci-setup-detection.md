# CI Setup Detection — Conditional CI Pipeline Initialization

**Purpose**: Determine whether the repository already has AIRE-Helix CI infrastructure set up, so workflows can:
- **Skip full CI setup** on established AIRE projects (avoid re-bootstrapping)
- **Run full CI setup** on new repos lacking the infrastructure

---

## Detection Mechanism

### Mandatory CI Artifacts

A repository is considered to have **AIRE-Helix CI already configured** if ALL of the following exist:

1. **`.github/workflows/agentic-eval-pipeline.yml`** — the CI pipeline workflow
2. **`tests/.evals/config.json`** — eval framework configuration with thresholds
3. **`tests/.evals/rubrics/architecture-rubric.json`** — architecture scoring rubric
4. **`tests/.evals/rubrics/security-rubric.json`** — security scoring rubric
5. **`tests/.evals/scripts/run-static-evals.sh`** or **`tests/.evals/scripts/run-static-evals.ps1`** — delta-scoped static evaluation script

### Detection Logic

```bash
# All five files must exist
[ -f ".github/workflows/agentic-eval-pipeline.yml" ] && \
[ -f "tests/.evals/config.json" ] && \
[ -f "tests/.evals/rubrics/architecture-rubric.json" ] && \
[ -f "tests/.evals/rubrics/security-rubric.json" ] && \
( [ -f "tests/.evals/scripts/run-static-evals.sh" ] || [ -f "tests/.evals/scripts/run-static-evals.ps1" ] )
# If ALL are true → CI Setup EXISTS
# If ANY is missing → CI Setup MISSING (ask the opt-in question below before deciding what to do)
```

---

## 🔴 MANDATORY: CI/CD Setup Opt-In — ask ONLY when detection reports MISSING

**If detection reports EXISTS**: skip this question entirely — the repository already has CI/CD
infrastructure; there is nothing to opt into or out of. Record `Status: exists` and continue.

**If detection reports MISSING**: before recording `Status: missing` and before any downstream
workflow generates a single CI file, ask the user once (conversational, CHAT-ONLY — same pattern as
the Tracker Selection / Context Opt-In questions, no question `.md` file):

```
Set up the CI/CD eval pipeline for this project? (yes/no)
```

- **yes** → record `Status: missing` (unchanged — CI still needs to be generated) **plus**
  `## CI/CD Configuration` `Enabled: Yes` `Source: user opt-in` in `runtime-artifacts/aire-state.md`.
  Downstream workflows run full CI setup exactly as the MISSING behavior below describes.
- **no** → record `Status: declined` **plus** `## CI/CD Configuration` `Enabled: No`
  `Source: user opt-out` in `runtime-artifacts/aire-state.md`. Downstream workflows skip CI setup,
  the CI Preflight Gate, and the CI Attestation Gate entirely for this cycle — see the `declined`
  row in the Conditional Behavior table below.

Log the question and the raw answer in `runtime-artifacts/audit.md`. **Ask this ONCE per
ticket/cycle** — on resume, if `## CI Setup Status` already records `exists`, `missing`, or
`declined`, reuse it and never re-ask.

---

## Recording in `runtime-artifacts/aire-state.md`

### Format

Add this section early in the workflow (at the resume check / ticket capture stage):

```markdown
## CI Setup Status
- **Status**: exists | missing | declined
- **Detected At**: [ISO 8601 timestamp when detection ran]
- **Files Found**: [list of found artifacts, or "none"]
```

`declined` records that detection found CI missing AND the user was asked and said no — see the
opt-in question above. `missing` now means "not present, and the user opted IN to setting it up."

### Example — CI Exists

```markdown
## CI Setup Status
- **Status**: exists
- **Detected At**: 2026-09-14T10:30:45Z
- **Files Found**: 
  - .github/workflows/agentic-eval-pipeline.yml (present)
  - tests/.evals/config.json (present)
  - tests/.evals/rubrics/architecture-rubric.json (present)
  - tests/.evals/rubrics/security-rubric.json (present)
  - tests/.evals/scripts/run-static-evals.sh (present)
```

### Example — CI Missing

```markdown
## CI Setup Status
- **Status**: missing
- **Detected At**: 2026-09-14T10:30:45Z
- **Files Missing**: 
  - .github/workflows/agentic-eval-pipeline.yml (missing)
  - tests/.evals/rubrics/architecture-rubric.json (missing)
  - tests/.evals/scripts/run-static-evals.sh (missing)
```

---

## Conditional Behavior Based on Detection

### When CI Setup EXISTS (established AIRE project)

**In `bug-fix.md` Step 8.5 (Section 5 — CI Pipeline Setup):**
- ✅ Skip generating `.github/workflows/agentic-eval-pipeline.yml`, `sonar-project.properties`, and the `tests/.evals/scripts/*` set — reuse whatever already exists AS-IS
- ✅ Announce: "CI infrastructure already exists — skipping full setup"
- ✅ Proceed directly to design artifacts (architecture.md, rubrics) — these are ALWAYS created/reused regardless of CI Setup Status; skipping CI setup never skips architecture.md or behavior.feature

**In `bug-fix.md` Step 9, Item 2 (the `smoke-test-epic.{sh,ps1}` scratch-PR run — a DIFFERENT step from Step 8.5's CI pipeline generation, and the one actually observed to misfire):**
- ✅ **Skip it entirely — do not run it, do not present its "Run smoke test? (yes/no)" prompt.** The environment was already validated by a prior cycle's smoke test when the CI infrastructure was first bootstrapped; re-running it on every ticket is redundant.
- ✅ Announce: "CI infrastructure already exists — skipping the pre-handoff smoke test."
- ✅ Item 1 (commit + push the analysis/design artifacts) and Item 3 (the ve break message) still run exactly as written — only the smoke test itself is skipped.

**In `bug-fix-implement.md` Step 9.1.5 (CI Preflight):**
- ✅ Run normally (preflight validates manifest + script executability) — this is a per-fix declaration check, unrelated to the one-time environment smoke test, and is skipped ONLY by `Status: declined` (see below) — never by `exists`
- ✅ No separate smoke test
- ✅ No duplicate CI artifact generation

**In `enhancement-implement.md` Step 8.5 (Section 5 — CI Pipeline Setup):**
- ✅ Same as `bug-fix.md` Step 8.5 above — skip CI pipeline generation, proceed to design artifacts

**In `enhancement-implement.md`'s ve Handoff Break, Item 2 (the `smoke-test-epic.{sh,ps1}` scratch-PR run):**
- ✅ Same as `bug-fix.md` Step 9 Item 2 above — skip it entirely, announced; Items 1 and 3 still run.

### When CI Setup MISSING (new repo, first AIRE cycle, user opted IN)

**In `bug-fix.md` Step 8.5:**
- ✅ Run full CI setup (pipeline, SonarQube setup gate, scripts) — current behavior
- ✅ Generate all required artifacts

**In `bug-fix.md` Step 9, Item 2:**
- ✅ Run the pre-handoff smoke test before the ve break message — current behavior

**In `bug-fix-implement.md` Step 9.1.5 / Step 10.5:**
- ✅ Run preflight and attestation normally

**In `enhancement-implement.md` Step 8.5:**
- ✅ Run full CI setup — current behavior

**In `enhancement-implement.md`'s ve Handoff Break, Item 2:**
- ✅ Run the pre-handoff smoke test — current behavior

### When CI Setup DECLINED (missing, and the user opted OUT at the question above)

🔴 **This is the one status that skips more than pipeline generation** — with no CI/CD pipeline at
all, there is nothing for CI Preflight or CI Attestation to check against, so those per-fix gates are
skipped too, for this entire cycle:

**In `bug-fix.md` Step 8.5:**
- ✅ Skip Section 5 (CI Pipeline Setup) entirely — same as `exists`, but announce the reason as
  declined, not pre-existing: "CI/CD setup was declined for this ticket — skipping pipeline
  generation." Architecture/rubrics/behavior artifacts still generate normally.

**In `bug-fix.md` Step 9, Item 2 (smoke test):**
- ✅ Skip it entirely, announced: "No CI/CD pipeline for this cycle (declined) — skipping the
  pre-handoff smoke test."

**In `bug-fix-implement.md` Step 9.1.5 (CI Preflight) / Step 10.5 (CI Attestation):**
- ✅ Skip BOTH entirely, announced. Go straight from the commit to the push + PR (Preflight), and
  straight from the PR raise to the auto `pr-review` (Attestation) — no CI mention anywhere in the
  completion output.

**In `enhancement-implement.md` Step 8.5 / ve Handoff Break Item 2 / Step 15.5 / Step 17.5:**
- ✅ Same as the `bug-fix.md` rows above — skip pipeline generation, skip the smoke test, skip CI
  Preflight and CI Attestation. Manifest Reconciliation (Step 15.5) is also skipped — there is no
  manifest to reconcile without a pipeline.

---

## Logging Requirements

Every detection must be logged to `runtime-artifacts/audit.md` with:

```markdown
## CI Setup Detection
**Timestamp**: [ISO 8601]
**User Email**: [session email]
**Detection Result**: [exists / missing]
**Opt-In Question** (only when Detection Result = missing): [question shown]
**Opt-In Answer** (only when asked): [raw user response — yes/no]
**Found Artifacts**: [list]
**Next Action**: [Skip full CI setup (pre-existing) / Run full CI setup (opted in) / Skip full CI setup and all CI-specific gates (declined)]
```

---

## Important Notes

🔴 **Detection runs ONCE per ticket workflow** — do not re-check in every stage. Record the result and reuse it downstream. The opt-in question likewise runs at most ONCE per ticket/cycle — never re-ask once `## CI Setup Status` records `exists`, `missing`, or `declined`.

🔴 **Established projects stay unchanged** — reuse existing CI artifacts AS-IS. Never regenerate or update them unless thresholds changed (that happens at a later stage, outside this detection).

🔴 **Artifact Ownership still applies** — if CI artifacts exist on the base branch, inherited cycles use them AS-IS; create-if-missing only applies to artifacts that are genuinely missing.

🔴 **This detection ONLY gates CI pipeline bootstrap (the `.github/workflows/agentic-eval-pipeline.yml` generation stage), the one-time `smoke-test-epic.{sh,ps1}` scratch-PR run, and — on `declined` only — the per-fix CI Preflight and CI Attestation gates.** It NEVER gates `spec/plans/architecture.md`, `spec/behavior.feature`, the rubrics, or any other STOP CHECKPOINT artifact — those are always created (if genuinely absent) or reused AS-IS, on every ticket, regardless of `## CI Setup Status`. "CI already exists" means "the pipeline and its one-time environment check don't need to run again"; "declined" means "the user chose not to have a pipeline at all for this cycle" — neither skips the design/behavior/rubric artifacts for this ticket.

🔴 **`## CI/CD Configuration` `Enabled: Yes/No` is the same flag the epic flow records at `CLAUDE.md` Step 1.2** — set it here alongside `## CI Setup Status` so every downstream rule file (`common/ci-pipeline-generation.md` Section 0, `dev-implement.md`, `bug-fix-implement.md`, `enhancement-implement.md`) can check one consistent flag regardless of which flow (epic vs. ticket) is running.
