# Helix AIRE

HELIX AIRE is an adaptive, AI-driven software development workflow framework. It takes you from a product idea → a refined Epic → requirements → a finished, reviewed product — with a human approval at planning stage and a complete audit trail. Works with Jira, Azure DevOps, GitHub Issues, or fully local (no external tracker at all).

---

## Contents

1. [How It Works](#how-it-works)
2. [Prerequisites](#prerequisites)
3. [The CI/CD Evaluation Pipeline](#the-cicd-evaluation-pipeline)
4. [Usage](#usage)
5. [Where Files Go](#where-files-go)
6. [Context Project](#context-project)
7. [Resumable Sessions](#resumable-sessions)
8. [Parallel Development Without Conflicts](#parallel-development-without-conflicts)
9. [The Epic Journey](#the-epic-journey)
10. [The Bug-Fix Journey](#the-bug-fix-journey)
11. [The Enhancement Journey](#the-enhancement-journey)
12. [Changes While an Epic Is Still Open](#changes-while-an-epic-is-still-open)
13. [Fixing a Rejected Pull Request](#fixing-a-rejected-pull-request)
14. [Dependency Graph](#dependency-graph)
15. [Keyword Workflows](#keyword-workflows)
16. [Claude Code Skills](#claude-code-skills)
17. [Agents](#agents)

---

## How It Works

```
                       Your product idea
                               |
                               v
  +-------------------------------------------------------+
  | intent-intake (skill, optional)                       |
  | Captures the idea as a short baseline intent and      |
  | creates an Epic in Jira, Azure DevOps or GitHub.      |
  +-------------------------------------------------------+
                               |
                               v
  +-------------------------------------------------------+
  | intent-refinement (skill, optional)                   |
  | Works through the Epic until it is                    |
  | detailed and verifiable, then updates the baseline.   |
  +-------------------------------------------------------+
                               |
                               v
  +-------------------------------------------------------+
  | In Claude Code, inside your project, type:            |
  |                                                       |
  |     Using AIRE, <epic reference>                      |
  |                                                       |
  | A Jira, Azure DevOps or GitHub link, a description    |
  | for a local-only project, or a request to implement   |
  | an Epic held in Atlas through the Helix MCP.          |
  +-------------------------------------------------------+
                               |
                               v
  +-------------------------------------------------------+
  | AIRE lifecycle                                        |
  | Planning, system design, story-by-story build,        |
  | Verification Engineer sign-off and cycle close.       |
  +-------------------------------------------------------+
                               |
                               v
              Reviewed, merged and documented product
```

If your Epic already exists, either in your tracker or in Atlas, skip the two intent skills and start
at "Using AIRE".

For the detailed, step-by-step flow of every workflow, see
[aire-workflow/aire-workflow-diagram.md](aire-workflow/aire-workflow-diagram.md).

The framework has four parts:

| Part | Location | Purpose |
|------|----------|---------|
| `CLAUDE.md` | Repository root | The master workflow. Claude Code reads it automatically. It routes every phase, checkpoint and keyword, and stays short on purpose. |
| `aire-workflow/` | Repository root | The rulebook: planning and implementation stages, keyword workflows, shared rules, agent procedures, extensions, CI templates and the commit hook. It also holds [`aire-workflow-diagram.md`](aire-workflow/aire-workflow-diagram.md), the end-to-end flow diagrams. Rule files are loaded only when a stage needs them. |
| `.claude/skills/` | Repository root | Thirteen skills, such as intent intake, test planning, defect raising, pull request creation and review, and cycle archiving. |
| Generated project files | `spec/`, `tests/`, `reports/`, `runtime-artifacts/` | What the framework builds against, what it is judged by, the evidence it leaves behind, and the state that lets a session resume. |

### Which tracker do I use?

AIRE asks which tracker to use once, at the start of a cycle. It never works this out from a link you
paste.

| Tracker | How stories reach it | Prerequisite |
|---------|----------------------|--------------|
| Jira | The Atlassian MCP server | Prerequisite 3 |
| Azure DevOps | The `az boards` command line tool | Prerequisite 5 |
| GitHub | The `gh` command line tool | Prerequisite 2 |
| Local | Nothing leaves the repository.  | None |

Everything else behaves the same whichever tracker you choose. The examples in this document use Jira
keys; substitute an Azure DevOps work item number, a GitHub issue number, or nothing at all for Local.

---

## Prerequisites

Install and configure the following before you use the framework in a project.

### 1. Claude Code

The framework runs entirely inside Claude Code: the command line tool, the desktop app, or an IDE
extension.

### 2. GitHub CLI (`gh`)

Used to push/manage github issues, raise pull requests, review them and check whether they have merged. Pull requests always go
through GitHub, whichever issue tracker you use.

```bash
# macOS
brew install gh

# Windows
winget install --id GitHub.cli

# Linux (Debian/Ubuntu)
sudo apt install gh
```

- Installation guide: <https://github.com/cli/cli#installation>
- Sign in after installing: `gh auth login` (choose GitHub.com, HTTPS, and log in through the browser).
- Check it worked: `gh auth status` should show you signed in with `repo` access.

### 3. Atlassian (Jira) MCP connection

Needed only if your tracker is Jira.

In Claude Code, run:

```bash
claude mcp add --transport http atlassian https://mcp.atlassian.com/v1/mcp/authv2
```

Then run `/mcp` inside a Claude Code session and complete the sign-in to your Atlassian site.

In Claude Desktop, open Settings, then Extensions, select Browse extensions, then Plugins, search for
Atlassian and install it.

- Atlassian's server documentation: <https://support.atlassian.com/atlassian-rovo-mcp-server/docs/getting-started-with-the-atlassian-remote-mcp-server/>
- Claude Code MCP setup: <https://docs.anthropic.com/en/docs/claude-code/mcp>
- Check it worked: run `/mcp` in a Claude Code session.

### 4. Turn off Claude Code's built-in `code-review` skill

AIRE has its own `code-review` workflow, and the built-in skill of the same name would intercept it.

1. Open your user settings file, `~/.claude/settings.json` (on Windows,
   `C:\Users\<you>\.claude\settings.json`).
2. Add this top-level key, merged into the existing JSON:

   ```json
   "skillOverrides": {
       "code-review": "off"
   }
   ```

3. Save the file and restart Claude Code.

### 5. Azure CLI

Needed only if your tracker is Azure DevOps. Install it from
<https://learn.microsoft.com/en-us/cli/azure/install-azure-cli>, then add the DevOps extension and sign
in:

```bash
az extension add --name azure-devops
az login
```

`az login` opens a browser window. The session lasts until you run `az logout`.

### 6. Podman

The behavioural (Gherkin) tests run inside a container so that a local run and a CI run behave the
same way. Podman must be installed and running.

Install Podman Desktop, which includes the `podman` command and manages the virtual machine for you:
<https://podman-desktop.io/downloads>. Or install only the command line tool:

```bash
# macOS
brew install podman

# Windows
winget install -e --id RedHat.Podman

# Linux (Debian/Ubuntu)
sudo apt install podman
```

On macOS and Windows, create and start the Podman machine once:

```bash
podman machine init
podman machine start
```

Check it worked: `podman info` should return without an error.

If Podman is not installed, the behavioural tests run directly on your machine instead, and the
evidence records that local and CI parity was not verified. The framework never falls back to Docker.

### 7. Playwright and its official test agents

For any story whose plan includes frontend work, `dev-implement`, `bug-fix-implement` and
`enhancement-implement` generate browser tests before the automated code review. They do this by
calling Playwright's own Planner, Generator and Healer agents, which are subagents backed by the
`playwright-test` MCP server. Those agents must exist in the repository.

Run these three commands from the true workspace root, the same folder that holds `spec/`, and never
from a subfolder such as `frontend/`. Claude Code only looks for `.claude/agents/` and `.mcp.json` in
the folder it was started from.

```bash
npm i -D @playwright/test
npx playwright install
npx playwright init-agents --loop=claude
```

Install Playwright per project, not globally. `@playwright/test` becomes a development dependency in
the project's `package.json`, and the agents and `.mcp.json` are written into the project, so every
teammate and the CI pipeline use the same version. The browsers downloaded by `npx playwright install`
go to a shared cache on your machine, which is expected.

Then restart the Claude Code session. MCP servers connect only when a session starts, so the
`playwright-test` server registered by the third command is not available until you restart. Check it
with `/mcp`.

If the agents are missing when a frontend story needs them, the framework installs them itself and
then pauses, asking you to restart the session. Nothing is committed, pushed or moved on the tracker
at that point. After the restart, type the same keyword again and the run continues from the
Playwright step, skipping everything that already passed. Installing up front avoids the pause.
Projects with no user interface never reach this step.

### 8. Helix MCP connection (recommended)

Connect the Helix MCP server to Claude Code once per repository. AIRE uses it to read Atlas, which
holds the reviewed description of the existing system (the deep dive document and knowledge graph) and
can also hold the Epic itself.

For existing codebases, migrations and integrations with an existing system, Atlas is required. If no
Helix connection can be found, the framework stops and offers two choices:

- A) Connect Helix then run AIRE again.
- B) Continue without Atlas. The framework then generates the existing-system documentation locally
  and marks every document it produces with a note saying Atlas was not consulted.

New projects with no existing system skip this check entirely.

---

## The CI/CD Evaluation Pipeline

At the end of the design stages, AIRE asks once: `Set up the CI/CD eval pipeline for this project?
(yes/no)`. Bug and enhancement cycles ask the same question at the start, through `ticket-implement`,
when the pipeline files are not already in the repository. The answer is recorded and never asked
again for that cycle.

If you answer yes, AIRE generates `.github/workflows/agentic-eval-pipeline.yml` for your project from
its real build files and its real thresholds. The pipeline re-runs the checks that already ran
locally: static analysis, unit tests and coverage, the Gherkin behaviour tests, Playwright, and the
architecture and security judge scores. It also includes a self-repair job that uses the Claude Code
command line tool to fix a failing check. CI re-verifies the local result.

If you answer no, no CI files are generated. Every local check still runs in full.

### Secrets

Three secrets belong to your own accounts and cannot be generated. The checks still run and still
block the pull request without them; only the parts listed below are skipped.

| Secret | Purpose | Required? |
|--------|---------|-----------|
| `CLAUDE_CODE_OAUTH_TOKEN` | Lets the pipeline score the architecture and security judge checks and run the self-repair job | No. Without it, judge scoring and self-repair are skipped. |
| `SONAR_TOKEN` | Signs in to SonarQube (cloud or self-hosted) for the static security check | No. Semgrep and the 16-rule Security Baseline review still run. SonarQube is an addition. |
| `SONAR_HOST_URL` | The address of your SonarQube server | No. Only needed with `SONAR_TOKEN`. |
| `GITHUB_TOKEN` | Used by the secret scanner (gitleaks) | Provided automatically by GitHub Actions. |


### Getting `CLAUDE_CODE_OAUTH_TOKEN`

1. Install Claude Code if you do not have it: `npm install -g @anthropic-ai/claude-code`
2. Sign in once by running `claude`, completing the browser prompt, and leaving with `/exit`.
3. Create a long-lived token for CI: `claude setup-token`
4. Copy the value it prints. It is shown only once.

### Getting `SONAR_TOKEN` and `SONAR_HOST_URL`

Method A, SonarQube Cloud (hosted, free for public repositories):

1. Open <https://sonarcloud.io> and sign in with GitHub.
2. Select Analyze new project and choose this repository.
3. Open My Account, then Security.
4. Enter a token name and select Generate. Copy the value; it is shown only once.
5. Your `SONAR_HOST_URL` is `https://sonarcloud.io`.

Method B, SonarQube Community Build (free, self-hosted):

1. Start the server:

   ```bash
   podman run -d --name sonarqube -p 9000:9000 docker.io/sonarqube:community
   ```

2. Wait about 90 seconds, then open `http://localhost:9000`.
3. Sign in as `admin` with password `admin`, and set a new password when asked.
4. Open My Account, then Security. Enter a token name, select Generate and copy the value.
5. Your `SONAR_HOST_URL` is an address your CI runner can reach. `http://localhost:9000` does not work
   from a GitHub-hosted runner; use a reachable host name or a self-hosted runner.

### Setting your SonarQube organization

1. Open `sonar-project.properties`, which AIRE generates.
2. Find `sonar.organization=YOUR_ORG_NAME`.
3. Replace `YOUR_ORG_NAME` with your organization key, found in SonarQube Cloud under My Organizations
   or in your project's URL.
4. Self-hosted SonarQube has no organizations, so delete the line instead.

During generation, AIRE prints these setup steps in full and waits. Type `proceed` once the secrets
are in place, or `skip` to leave SonarQube switched off. Skipping is always allowed.

### Adding the secrets to GitHub

1. Open the repository on GitHub.
2. Go to Settings, then Secrets and variables, then Actions.
3. Select New repository secret.
4. Add `CLAUDE_CODE_OAUTH_TOKEN`, `SONAR_TOKEN` and `SONAR_HOST_URL` with their values.

---

## Usage

Start any piece of work by typing "Using AIRE," followed by the Epic:

```
Using AIRE, https://yoursite.atlassian.net/browse/PROJ-42                  # Jira
Using AIRE, https://dev.azure.com/myorg/MyProject/_workitems/edit/4821     # Azure DevOps
Using AIRE, https://github.com/my-org/my-repo/issues/42                    # GitHub
Using AIRE, implement the epic from Helix                                  # Atlas through the Helix MCP
Using AIRE, <a plain description of what to build>                         # Local only
```

From there:

1. The workflow starts on its own. It shows a welcome message, detects whether the repository is new or
   existing, fetches the Epic, and creates the Epic branch.
2. User answer the questions it asks. Most questions are written to a file under `spec/spec-generation/` as
   lettered options with an "Other" choice; you answer under each `[Answer]:` tag and reply "done".
   Three questions are asked in the chat instead: which tracker to use, which context documents to
   read, and whether to set up the CI pipeline.
3. Review every document the framework produces. The requirements, the story set, each design document, test plans and the behaviour files all require Human approval.
4. Once the design is approved, the framework stops and hands over. From then on, `dev-implement` builds
   one story at a time without asking anything beyond which story to build.

---

## Where Files Go

The framework writes only into these locations:

- `src/` holds all application code. In an existing repository whose code lives elsewhere, that
  location is recorded once in `runtime-artifacts/aire-state.md` under `## Code Root` and treated as
  `src/`. Existing code is never moved automatically.
- `tests/` holds `unit/` (unit tests), `api/` (API and contract tests), `behavior/steps/` (Gherkin
  step definitions) and `e2e/` (Playwright). The evaluation framework lives in `tests/.evals/`:
  `config.json` (every threshold), `rubrics/`, `scripts/`, `behavior/` (the container definition) and
  `ci-manifest.d/` (one manifest file per story).
- `spec/` holds specifications and documentation, never source code:
  - `behavior.feature`, the cross-story journeys, written once per cycle.
  - `plans/`, every planning and design document: `epic-brief.md`, `requirements.md`,
    `stories.md`, `personas.md`, `dependency-graph.yml`, `executions.md`, `application-design.md`,
    `functional-design.md`, `nfr.md`, `infrastructure-design.md`, `architecture.md`,
    `atlas-deep-dive.md` and the other existing-system documents, plus `delta/<CYCLE-ID>-<slug>/`,
    written when the cycle closes.
  - `spec-generation/`, the question files and generation plans.
  - `behavior/`, one `.feature` contract per story.
  - `test-plans/`, the manual test plans, one folder per story.
  - `playwright-specs/`, the approved Playwright Planner plan per story. The `.spec.ts` files it
    produces are test code and live in `tests/e2e/`.
  - `context-project/`, documents you provide (see the next section).
- `reports/` holds generated output only: `unit-test-evidence/`, `behavior-test-evidence/`,
  `api-contract-test-evidence/`, `playwright-test-evidence/`, `eval-evidence/`, `reviews/`,
  `code-security-reviews/`, `ticket-summary/` and `pr-feedback/`.
- `runtime-artifacts/` holds `audit.md`, `aire-state.md` and one folder per story under `stories/`.
- `aire-archives/` holds one archived folder per completed cycle and the stitch ledger.

When CI is switched on, the framework also generates `.github/workflows/agentic-eval-pipeline.yml`.

The whole of `spec/` belongs to one cycle. When the cycle closes, `archive-epic` copies it into the
archive.

---

## Context Project

`spec/context-project/` is where you place documents for the framework to read. It has two subfolders,
both created empty at the start of a cycle:

- `spec/context-project/existing-knowledge/` holds notes written by people about how the current system
  works: what each module does, where things live, interview notes. Use one subfolder per module, named
  exactly after the module. This applies to existing codebases only.
- `spec/context-project/new-references/` holds material describing what to build: wireframes, design
  mockups, UI specifications, API specifications, architecture diagrams and research.

```
spec/context-project/
  existing-knowledge/
    Abc.corp/              named exactly after the module
      interview.md
  new-references/
    wireframes/
      checkout-flow.png
    api-spec.yaml
```

During workspace detection, the framework asks one two-part question in the chat:

```
1) Existing knowledge: notes on how the current system works.
   Place under spec/context-project/existing-knowledge/
2) New references: what to build (wireframes, mockups, API specs, diagrams).
   Place under spec/context-project/new-references/
```
---

## Resumable Sessions

No session state is held inside a chat. Two files in the repository are the record:

- `runtime-artifacts/aire-state.md` holds the tracker settings, branches, story tracker, stage progress
  and every recorded answer.
- `runtime-artifacts/audit.md` holds every input, prompt, response and decision, with a timestamp and
  the operator's email address.

Close the session, change machines or hand over to a colleague, and the next session picks up exactly
where the last one stopped.

---

## Parallel Development Without Conflicts

Developers can build different stories of the same Epic at the same time by following the dependency graph. Their pull requests do not
conflict on the framework's own files, because every run that works on a single story keeps its own
audit trail and state.

---

## The Epic Journey

This is the full path for a new piece of work, from idea to merged Epic.

### Step 1 (optional): capture the idea with `intent-intake`

Run `/intent-intake` when you have an idea but no Epic yet. The skill asks whether you have a document
to work from (a PRD, research notes, a Confluence page) or would rather explain in plain English. It
then collects six baseline fields: the outcome, how success is measured, the success signal, what is
out of scope, known constraints, and your confidence with the open unknowns. After you confirm, it
creates an Epic in Jira, Azure DevOps or GitHub, labelled `intent-intake`.

### Step 2 (optional): deepen it with `intent-refinement`

Run `/intent-refinement` and give the reference epic created using `intent-intake`. The skill fetches the Epic, shows what is present
and what is missing, and works through focused question batches: measurable success criteria with
thresholds, scope and exclusions, constraints, the domain model, quality expectations and risks. After
you confirm, it updates the same Epic with the refined content and adds the label `intake-refined`. It
ends by telling you how to start AIRE.

### Step 3: start the workflow

Open Claude Code in your project and type "Using AIRE," followed by the Epic link
or tell it to fetch epic using Helix MCP.

The workflow then:

1. Asks which tracker to use, unless the project already has one recorded.
2. Records the Parent Epic in `runtime-artifacts/aire-state.md` and copies the Epic content into
   `spec/plans/epic-brief.md`, the brief that defines what to build.
3. Checks for existing code. For existing code, migrations or integrations, it reads the existing-system
   truth from Atlas via Helix MCP (see Prerequisite 8).
4. Creates the Epic branch, `epic/<EPIC-KEY>-<title>`, from the branch you were on, and records both.
   All later work happens on this branch and on story branches cut from it.
5. Asks the context question.

It then runs the planning stages:

- Reverse engineering, for existing code only, when Atlas has no deep dive and you chose to generate
  documentation locally.
- Requirements analysis: The framework asks clarifying questions in a file, including whether to turn
  on the optional extensions (resiliency and property-based testing). The Security Baseline is always
  on. It then writes `spec/plans/requirements.md`, where every requirement has a permanent identifier
  such as `REQ-F-03`. Once you approve, the planning documents are committed and pushed on the Epic
  branch. No pull request is raised at this point.
- User stories: Stories are written all at once for a fixed team size of two. Every
  story names the requirements it covers, and every requirement must be covered. You then review the
  whole set at the story set approval checkpoint and choose Request Changes or Approve & Continue. On
  approval, the stories are created in your tracker, set to Ready for Development and linked to the
  Parent Epic. Nothing is pushed for Local.
- Dependency graph. The framework works out which stories need which others to exist first and writes
  `spec/plans/dependency-graph.yml`. The stories, personas and graph are
  then committed and pushed together.
- Workflow planning. The framework decides which design stages are needed, records the reasons in
  `spec/plans/executions.md`, and continues.
- Application design, when new components or services are needed. You approve it.

### Step 4: system design, then the handoff

The implementation phase opens with the design stages that the Workflow plan selected: functional design,
non-functional requirements, non-functional design and infrastructure design. Each asks focused
questions, writes its document and requires Human approval.

When design is done, the framework runs the design handoff checkpoint:

1. It asks once whether to set up the CI pipeline.
2. It writes `spec/behavior.feature`.
3. It writes `spec/plans/architecture.md` from the approved design documents and the Atlas
   description of the existing system.
4. It derives the rubrics in `tests/.evals/rubrics/`: the architecture rubric and a security rubric based on the OWASP Top 10 (2025). These are what the architecture
   and security judge checks score every story against.
5. If you said yes to CI, it generates the pipeline from your repository's real stack and thresholds,
   prints the CI setup steps, and waits for `proceed` or `skip`.
6. For every story, before any code exists, it writes the Gherkin contract
   `spec/behavior/story-N.M.feature` (one `@AC-n` scenario per acceptance criterion, including failure
   paths) and the test plan in `spec/test-plans/<TICKET-ID>-<title>/`. Every acceptance criterion must have at least
   one scenario and at least one test case. You review the whole set once and choose Request Changes
   or Continue to Next Stage.
7. It commits and pushes the design documents, contracts, test plans and evaluation files on the Epic
   branch.
8. If CI was set up, it opens a scratch pull request with no changes to prove the CI environment works.
9. It shows the Development Handoff message and stops. Code generation never starts on its own.

From here, the developer pulls the Epic branch and types `dev-implement` once per story.

### Step 5: build story using `dev-implement`

Type `dev-implement`, then give the story to build: its tracker key, or its story number for Local.
That is the only thing the run asks:

1. Doability checkpoint: Every prerequisite story must be Ready for Testing, or have its pull request
   merged. The framework never merges a pull request itself, not
   even an approved one. If a prerequisite is not merged, the run stops and names it.
2. The selected story moves to In Development in the story tracker and in your tracker, and the tracker
   item is assigned to you. The first story to start also moves
   the Epic to In Development.
3. The Epic branch is refreshed, prerequisites are confirmed,
   and the story branch `story/N.M-<title>` is cut from the Epic branch, never from the base branch.
4. Before any code is written, the full test suite, the seven static checks and the
   existing Playwright suite all run, so that problems already present are never blamed on this story.
5. The implementation plan is written to `spec/spec-generation/story-N.M-code-generation.md`,
   with every step tagged to the requirements and acceptance criteria it serves.
6. Application code goes into `src/` and tests into `tests/`.
7. Unit tests and coverage: Coverage of the changed lines must reach `unitTestCoverageMin` (90 percent
   by default). The raw output and a machine-readable coverage report are saved as evidence.
8. Behaviour tests, in Podman: this story's scenarios (B1), then every other story that is implemented
   (B2), then, on the last story of the Epic only, the whole set plus `spec/behavior.feature` (B3).
9. API and contract tests, when the story adds or changes an endpoint: happy path, every documented
    response code, 401 versus 403, the error format, request validation and the response schema.
10. Test placement check, which confirms every new test sits in the right folder.
11. Full regression: The whole suite runs again and is compared with the baseline. Any new failure was
    caused by this story and is fixed in the same run.
12. Static checks, compared with the baseline. Only new findings in changed files count, and a finding
    is fixed.
13. Playwright: For frontend stories, Playwright's own agents plan, generate and repair the browser
    tests, which then run with a visible browser. For every story, frontend or not, the existing
    Playwright suite runs again and is compared with the baseline.
14. Automated code review: It checks each acceptance criterion and covered requirement, runs a
    Security Baseline review on the changed code, and scores two judge checks: J1 (architecture, against
    the Section 10 rubric) and J2 (security, against the OWASP rubric). Both must reach their minimum
    (0.85 by default). Any blocker or high finding, or a score below the minimum, is fixed and
    re-reviewed automatically, for up to three rounds.
15. Evidence check: Every required evidence file must exist, follow its format and agree with the
    scorecard (`eval.json` and `eval-summary.md`).
16. Commit and pull request: The commit carries an `AIRE-Version` trailer. If CI is on, the manifest
    file is written and the CI preflight checkpoint runs first. `pr-generator` then opens the story pull
    request into the Epic branch, titled with a `[STORY]` prefix, labelled `ai-generated` and
    `aire-v<version>`, with the full Eval scorecard in its description. `pr-review` then posts an automatic review comment.

The story stays In Development after its pull request is raised.

Self heal loop above is capped at three attempts. When a loop runs out, the run stops at that check
and tells you what is failing, why it stopped, what it tried, and how to fix it yourself .

Developer reviews the story pull request with the Verification Engineer and the PR is merged manually.

### Step 6: verify each story

As each story pull request merges, the Verification Engineer runs `/ve-list-work` on the Epic branch,
executes that story's test plan against the merged code, and approves or rejects the story.

### Step 7: close the cycle with `pr-generator` and `archive-epic`

When every story is merged and approved, run `/pr-generator` on the Epic branch. It raises (or updates)
the Epic pull request into the base branch and then starts `archive-epic` automatically. That skill:

1. Writes the cycle's delta to `spec/plans/delta/<EPIC-ID>-<name>/delta.md`: what shipped, with
   path-level evidence.
2. Folds every per-story state folder back into the shared state files.
3. Copies `spec/`, `reports/`, `runtime-artifacts/` and `tests/.evals/rubrics/` into
   `aire-archives/epics/<EPIC-ID>-<name>/` and verifies the copy is complete.
4. Merges the per-unit CI manifest files into `tests/.evals/config.json`.
5. Removes the archived `spec/`, `reports/`, `runtime-artifacts/` and `tests/.evals/rubrics/`.
6. Commits and pushes, so all of this lands in the open Epic pull request.

Merge the Epic pull request manually.

### Step 8: update Atlas with `stitch-delta`

On the base branch, after the Epic pull request has merged, run `/stitch-delta`. It finds every cycle
delta in the archives that has not been stitched yet, then refreshes the whole Atlas deep
dive document against the latest merged code.

The next cycle reads its existing-system truth from Atlas, which by then already includes this one.

---

## The Bug-Fix Journey

Every existing ticket starts with `ticket-implement <TICKET-ID>`. The router fetches the ticket and asks
what it is about, with exactly two choices: A) Bug fix or B) Enhancement. It shows a recommendation
based on the issue type and labels, but your answer decides. If the state file already records this
ticket, the router skips the question and resumes where you stopped.

The router may also ask whether to set up the CI pipeline and the
context question. For Local, it asks you to describe the bug and gives it an identifier such
as `BUG-LOCAL-1`.

### Part 1: analysis (`bug-fix`)

All work happens on one branch, `bug/<TICKET-ID>-<title>`, cut from the base branch.

1. Ticket capture: The ticket is copied into `spec/plans/bug-brief.md`, and the state records
   `Workflow Type: bug`.
2. Workspace detection.
3. Existing-system documentation is read from Atlas, reverse engineering runs only if
   Deep dive from Atlas is not available.
4. Requirements analysis, scoped to the reported bug. User approves it, and it
   is committed on the bug branch.
5. Impact analysis and AI-origin detection: The affected files and defective lines are identified in
   `spec/plans/impact-analysis.md`. The Defect Provenance Analyst then traces each defective line back
   to the commit that introduced it, skipping commits that only moved or reformatted code. If that
   commit was AI-generated (its pull request carries the `ai-generated` label, or the commit has a
   Claude co-author trailer or an `AIRE-Version:` trailer), the label `ai-generated-defect` is added to
   the ticket automatically, with the evidence logged. The bug is also linked automatically to the
   story, bug or enhancement ticket that introduced it.
6. One story is written from the bug ticket, and user approves it. There is no tracker
   push (the ticket already exists) and no dependency graph.
7. Workflow planning and any design stages the bug fix needs are executed.
8. The design handoff checkpoint, as in the Epic journey: the architecture document and rubrics if they
   are missing, the CI pipeline if you asked for it, and the bug's Gherkin contract and test plan. The
   contract includes a scenario that reproduces the defect. You approve the contract and plan once.
9. The analysis and design documents are committed and pushed on the bug branch. If CI was just set up, the smoke test runs. You are then asked:
   "Continue to bug fix implementation now? (yes / no)". Yes continues in the same session. No stops
   with everything saved; type `ticket-implement <TICKET-ID>` later to resume.

#### How the bug is linked to its cause

The link type is looked up from your tracker at run time and matched on its inward description. Only
"is caused by" qualifies.

| Your tracker has | What AIRE does |
|------------------|----------------|
| An "is caused by" link type | Creates a link from the bug, "is caused by", to the originating ticket, and checks its direction. |
| No "is caused by" link type | Creates a "relates to" link and adds a comment to the bug recording the real direction. |

The fallback comment reads:

```
Is caused by: PROJ-102, PROJ-456

The "is caused by" link type is not available on this Jira instance, so this defect has
been linked to the above work item(s) as "relates to" instead. The direction of causation
is recorded here: this defect is caused by the work item(s) listed above.

Traced from the commit that introduced the defective line(s).
```

Jira users should add an "is caused by" link type to their board so the link itself carries the
direction. Azure DevOps uses a Related link plus a comment, GitHub uses a comment, and Local records a
note.

### Part 2: the fix (`bug-fix-implement`)

This runs straight after the yes answer, on the same bug branch. Type `bug-fix-implement` only to
resume a run that was stopped.

1. The ticket moves to In Development, is assigned to the developer, and receives the `aire-v<version>` label and the implementation plan is written.
2. Baselines run before any change: the full test suite, the static checks and the Playwright suite.
3. The fix plan is written and announced. It is not an approval step.
4. The fix is written, with unit tests that reproduce the defect and coverage of the changed lines at
   or above the configured minimum.
5. The same checks as `dev-implement` follow: behaviour tests, API and contract tests when an endpoint
   is touched, full regression against the baseline, static checks against the baseline, Playwright,
   and the Playwright regression. Only new failures block.
6. Automated code review, with automatic fixes and re-review until the result is clean.
7. The fix is committed on the bug branch, and `pr-generator` opens a `[BUG]` pull request into the
   base branch, followed by an automatic review. The test plan was already committed on the bug branch,
   so it travels in the same pull request.
8. The ticket stays In Development.

### Part 3: sign-off and close

The order matters:

1. Any test plan edits made with `ve-list-work` Option C are committed and pushed.
2. The Verification Engineer builds the bug branch locally, runs the test steps, and records the
   decision with `/ve-list-work` Option B on the bug branch: approve moves the ticket to Ready for
   Testing; reject leaves it In Development. `ve-list-work` never runs on the base branch.
3. You run `/archive-epic` on the bug branch, while the `[BUG]` pull request is still open. It archives
   into `aire-archives/bugs/<BUG-ID>-<name>/` and removes the live cycle folders, and its commit lands
   in the open pull request. A rejected ticket can still be archived; the skill shows a notice about the
   open pull request.
4. You merge the `[BUG]` pull request.
5. On the base branch, you run `/stitch-delta`. The cycle is not closed until it lands.

---

## The Enhancement Journey

For an existing story or task that changes the current system, as opposed to fixing a defect.

Type `ticket-implement <TICKET-ID>` and answer B) Enhancement. If you point it at a Bug-type ticket, it
warns you and suggests the bug flow.

### Phase A: analysis

All work happens on one branch, `enhancement/<TICKET-ID>-<title>`, cut from the base branch.

1. Ticket capture into `spec/plans/enhancement-brief.md`; the state records `Workflow Type:
   enhancement`.
2. Workspace detection, and the enhancement branch is created before anything else is written.
3. Existing-system documentation from Atlas, or reverse engineering if none is available.
4. Requirements analysis scoped to the enhancement. You approve it.
5. Impact analysis: the affected files and components and how far the change reaches, with file and
   line evidence. There is no AI-origin detection.
6. One story, covering every requirement in this cycle's requirements document. You approve it.
7. Workflow planning and any design stages needed.
8. The design handoff checkpoint, with the enhancement's Gherkin contract and test plan approved once.
9. The documents are committed and pushed, the smoke test runs if CI was just set up, and you are asked
   "Ready to implement now? (yes / no)". No stops with everything saved; `ticket-implement
   <TICKET-ID>` resumes it later.

### Phase B: implementation

1. The ticket moves to In Development, is assigned to the developer, and receives the version label.
2. Baselines run before any change.
3. The implementation plan is written.
4. The code is written with unit tests that reach the coverage minimum.
5. The same checks as `dev-implement` follow, and only new failures block.
6. Automated code review, with automatic fixes until clean.
7. An `[ENH]` pull request into the base branch, followed by an automatic review. The ticket stays In
   Development.

Sign-off and close follow the same order as the bug journey, on the enhancement branch, with the archive
written to `aire-archives/enhancements/<ENH-ID>-<name>/`.

---

## Changes While an Epic Is Still Open

Three workflows handle a change that arrives while an Epic cycle is still running. Each runs on the Epic
branch, reuses the Epic's state, specifications, rubrics and CI, and starts by checking that the Epic is still open and not archived, and that the working tree is clean.

To start, open Claude Code on the Epic branch and type the keyword that matches your requirement:

| Situation | Workflow |
|-----------|----------|
| "Make it do X": Small enhancement | `epic-enhance <TICKET-ID or description>` |
| "X is broken": a defect in work the Epic already built | `epic-bugfix <TICKET-ID or description>` |
| "We agreed X, now we agree Y": the requirement itself has changed | `epic-change-request <TICKET-ID, description, or path to a PRD>` |

Just type the correct keyword according to your requirement and give it a ticket ID or describe the change in plain words. For a change request you
can also give the path to a PRD or another document that describes the new requirement. 

---

## Fixing a Rejected Pull Request

When the developer or the Verification Engineer rejects an open `[STORY]`, `[BUG]` or `[ENH]` pull
request, through comments, type `pr-fix`.

- It asks which pull request. That is normally the only question.
- It reads every unresolved human comment and sorts each into fix, answer, decline or defer, citing the
  acceptance criterion, requirement, architecture constraint or security rule behind each decision.
- It fixes the work on the pull request's own branch and re-runs the complete set of checks of the
  workflow that built it.
- It pushes to the same pull request, refreshes the eval scorecard on PR description, replies to each
  comment.
- It asks one more question only when a comment would change an approved acceptance criterion or when
  two reviewers disagree.

It never merges, approves, resolves threads or dismisses reviews.


---

## Dependency Graph

The dependency graph keeps story development in the right order. Every story has a `requires` list:
the stories whose code must exist before it can start. The framework works these out from the
acceptance criteria and from which files and components each story creates or uses.

---

## Keyword Workflows

Type these in the chat. Each one loads its own rules and can resume from the state file.

| Keyword | Use it for |
|---------|------------|
| `dev-implement` | Building one story of an Epic. It asks which story; everything after that is automatic. |
| `ticket-implement <TICKET-ID>` | Any existing ticket, bug or enhancement. Omit the ID for Local and describe the work instead. |
| `epic-enhance <TICKET-ID or description>` | New or changed behaviour while an Epic is open |
| `epic-bugfix <TICKET-ID or description>` | A defect in work an open Epic already built |
| `epic-change-request <TICKET-ID, description, or  <path> to a prd>` | A changed requirement while an Epic is open |
| `pr-fix [PR-NUMBER]` | Fixing a rejected `[STORY]`, `[BUG]` or `[ENH]` pull request |
| `code-review` | A read-only review of one story or all stories |
| `remediate` | Fixing the findings in a review report. When run on its own, it asks you to confirm the scope first. |

`code-review` and `remediate` also run automatically inside every implementation workflow. When run on
their own, they never start automatically; you type them.

---

## Claude Code Skills

Skills live in `.claude/skills/`. Start one with `/<skill-name>` or by describing what you want.

| Skill | What it does |
|-------|--------------|
| `intent-intake` | Turns an idea or a document into a six-field baseline intent and creates an Epic in Jira, Azure DevOps or GitHub, labelled `intent-intake`. It writes no local files. |
| `intent-refinement` | Fetches an Epic, runs focused question batches until it is verifiable (measurable criteria with thresholds, scope, constraints, domain model, risks), then updates the Epic and adds the `intake-refined` label. |
| `story-audit` | Scores an existing story or Epic against the AIRE quality checklist as Ready, Needs Work or Incomplete, offers to fill the gaps through questions, and updates the item after you confirm. Works with every tracker, including Local. |
| `ve-implement` | Writes the manual test plan for each story from its acceptance criteria and the design documents, never from source code. The framework runs it at the design handoff to write every story's plan. |
| `ve-list-work` | The Verification Engineer's queue: list merged work, approve or reject it, or edit a test plan. It makes exactly one status change, In Development to Ready for Testing. |
| `raise-defect` | Asks for five fields (title, description, severity, environment found, discovery activity), shows the drafted defect, and after approval creates it in the configured tracker, labelled `bug`, `defect`, `ai-generated` and `aire-v<version>` (plus `aire` on Jira and Azure DevOps). On Jira, Components is always Default and Associated Org is always All. The developer picks it up with `ticket-implement`. |
| `playwright-implement` | Turns the interface steps of an approved test plan into Playwright automation using Playwright's own Planner, Generator and Healer agents. Runs automatically inside the implementation workflows for interface work, or on its own after the fact. |
| `pr-generator` | Raises a pull request from the current branch, titled with `[EPIC]`, `[STORY]`, `[BUG]` or `[ENH]`, labelled `ai-generated` and `aire-v<version>`, with an `AIRE Framework` line in the description. Inside a workflow it runs without asking. Run on its own from an Epic, bug or enhancement branch, it targets the recorded base branch; from any other branch it asks for the target and confirms before pushing. An Epic pull request into the base branch starts `archive-epic` automatically; bug and enhancement pull requests only print a reminder to archive. |
| `pr-review` | Reviews a pull request with inline comments tagged Blocker, Issue, Nit, Question or Praise, a verdict and a "Suggested for human review" section. Inside a workflow it posts a plain comment review automatically; on its own it confirms first and lets you choose the review type. |
| `code-security-review` | Audits the whole codebase against the 16 Security Baseline rules (SECURITY-01 to SECURITY-16) and writes a dated report in `reports/code-security-reviews/`. |
| `reverse-engineering-root` | Generates one set of existing-system documents for the whole repository, covering every module of a monorepo, flat in `spec/plans/`. Useful when Atlas has no deep dive for the system. |
| `archive-epic` | Closes an Epic, bug or enhancement cycle: writes the change record, archives `spec/`, `reports/`, `runtime-artifacts/` and `tests/.evals/rubrics/` into `aire-archives/epics/`, `bugs/` or `enhancements/`, then removes the live folders. Started automatically for Epic cycles by `pr-generator`; run by hand for bug and enhancement cycles, before their pull request merges. It never publishes to Atlas and never writes the stitch ledger. |
| `stitch-delta` | Runs on the base branch after a cycle's pull request has merged. Reads each unpublished change record from the archives and refreshes the whole Atlas deep dive against the merged code, then raises a `[STITCH]` pull request containing the ledger row. |

---

## Agents

Agents are detailed procedures that a skill or workflow follows. They always run inside the current
session, never as separate background agents.

| Agent | Used by | What it does |
|-------|---------|--------------|
| `code-security-review-agent` | `/code-security-review`, and the security pass inside every code review | Maps the attack surface, checks every file in scope against the 16 Security Baseline rules, grades findings Critical, High, Medium or Low, and writes a report with evidence, fixes and an OWASP mapping. |
| `ve-implement-agent` | `ve-implement`, at the design handoff | Writes manual test plans for one story from its acceptance criteria and design documents, never from source code, with every acceptance criterion covered. |
| `playwright-implement-agent` | `/playwright-implement`, and the Playwright step inside the implementation workflows | Calls the installed Playwright Planner, Generator and Healer agents by name, one scenario at a time, and wraps them in the approval and push checkpoints. It never writes their output itself. |
| `archive-epic-agent` | `/archive-epic` | Writes the change record, archives the cycle, folds the per-unit state, merges the CI manifest files, removes the live cycle folders and commits so the result lands in the open cycle pull request. It defines the change record format for the whole framework. |
| `stitch-delta-agent` | `/stitch-delta` | Refreshes the whole Atlas deep dive against the merged code, checks the Atlas version before writing, confirms the write by reading it back, appends the ledger row and raises the stitch pull request. |
| `defect-provenance-analyst` | `bug-fix`, `bug-fix-implement` and `epic-bugfix` | Traces each defective line to the commit that introduced it and decides, on positive evidence only, whether that commit was AI-generated. It also finds the ticket that shipped the line, so the bug can be linked to it. |
| `change-request-analyst` | `epic-change-request` | Reads the requirement change, compares requirements by identifier, and lists the affected stories, acceptance criteria, code and tests with evidence. It decides nothing; the workflow does. |

---
