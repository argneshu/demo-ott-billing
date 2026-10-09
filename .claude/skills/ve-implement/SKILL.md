---
name: ve-implement
description: >
  Verification Engineer Test Plan for ONE story, run in PARALLEL with development. Test Plan is not a stage
  of the development workflow — it lives here. Resolves a story, reads its acceptance criteria from
  the configured tracker (JIRA/ADO/GITHUB) / stories.md plus requirements.md and the implementation design artifacts — never application
  source code — and writes that story's Test Plan artifacts as MANUAL test steps
  (integration, E2E, API, contract, security, performance, accessibility — whichever apply; there is
  no build-verification artifact, each plan opens with a System Under Test precondition block instead)
  into spec/test-plans/<TICKET-ID>-<title>/, with every test case traced to an acceptance criterion.
  Needs no DEV code, branch, PR or merge, so Verification Engineer can run it the moment a story exists — it never
  depends on or waits for the dev's branch/PR. IN STANDALONE MODE ONLY it cuts its own `ve/<TICKET-ID>-<title>` branch
  from the resolved integration branch (Epic Branch for epic cycles, Bug/Enhancement Branch for
  those cycles), commit the generated docs once the Verification Engineer approves them, then push and raise its own PR back into
  that branch, labeled `ai-generated` + `aire-v<version>` (the framework version read live from
  CLAUDE.md, same convention as pr-generator). No test automation, no test execution, no application code
  changes — and never changes story or tracker status (that remains `ve-list-work`'s job).
  TWO MODES: STANDALONE (Verification Engineer types /ve-implement — everything above applies as written, including the
  story-picker, the ve/... branch, the Approve/Request-Changes checkpoint and the PR), and WORKFLOW
  (mode: workflow with the story passed in — the story-picker, the ve/... branch, the approval
  checkpoint and the push/PR are all SKIPPED; the generated spec/test-plans/ files stay in the working
  tree and ride the caller's own commit). WORKFLOW MODE has two callers: the STOP CHECKPOINT
  (CLAUDE.md Step 1.7 / implementation/specs-and-test-plans.md), which invokes it once per work unit
  of the cycle BEFORE any code is generated and approves the whole set at its own gate — the primary
  path now — and dev-implement / bug-fix-implement / enhancement-implement, which invoke it only to
  backfill a genuinely absent plan. Content and rigour are identical in both modes; WORKFLOW MODE
  output is NOT Verification Engineer sign-off.
when_to_use: >
  Trigger when the user says: "/ve-implement 1.2", "/ve-implement PROJ-123", "/ve-implement",
  "Test Plan for story 1.2", "generate test steps for story 1.2",
  "manual test cases for PROJ-123", "test plan for this story",
  "test cases from acceptance criteria", "Verification Engineer this story", "run ve-implement", "ve-implement".
allowed-tools: Read Grep Glob Bash Write
---

# 🧪 ve Implement — Test Plan (per story)

Load and execute the agent instructions from:

```
aire-workflow/agents/ve-implement-agent.md
```

Read that file completely and follow every step defined in it.

🔴 **FIRST resolve the mode** (`ve-implement-agent.md` → **Mode Detection**): **STANDALONE** (ve typed
the trigger) runs every step as written; **WORKFLOW** (`mode: workflow`, with the story passed in —
by the STOP CHECKPOINT for every work unit of the cycle, or by `dev-implement` /
`bug-fix-implement` / `enhancement-implement` to backfill a missing plan) skips the story-picker, the
`ve/…` branch, the Approve/Request-Changes checkpoint and the push/PR — and touches git not at all.
🔴 In either mode, never overwrite a test plan that was approved at the STOP CHECKPOINT.

