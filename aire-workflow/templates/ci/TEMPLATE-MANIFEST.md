# CI templates — the static, versioned source the generator COPIES

> These files are the canonical CI pipeline. The AIRE pipeline generator does **not** author YAML or
> shell any more — it **detects the stack, fills the `ci` manifest block in `tests/.evals/config.json`,
> copies these files into the target repo, and substitutes a small fixed set of `${SLOT}` markers.**
> That deletes the whole class of "the model re-wrote a constant and it drifted / broke the parser".
>
> Read `common/ci-pipeline-generation.md` Section 4 for the generation procedure and
> `common/eval-framework.md` Section 1 for the `ci` manifest schema these files read.

## What copies where

| Template | Copied to | Substitution |
|---|---|---|
| `agentic-eval-pipeline.yml.template` | `.github/workflows/agentic-eval-pipeline.yml` | `${SLOT}` markers only |
| `config.schema.json` | `tests/.evals/config.schema.json` | none — the JSON Schema for `tests/.evals/config.json`, validated by V37 (`validate-pipeline.{sh,ps1}`) before a generated pipeline is committed |
| `lib-manifest.sh` / `.ps1` | `tests/.evals/scripts/lib-manifest.{sh,ps1}` | none — the shared primitives (`build_merged_manifest`, `resolve_and_verify_root`, `root_touched`), sourced by every other script below. **#7a's foundation**: this is the ONE place the merge/verify/diff-scope logic lives |
| `read-manifest.sh` / `.ps1` | `tests/.evals/scripts/read-manifest.{sh,ps1}` | none — emits `has_<stack>`/`<stack>_version` for the `setup` job's `Read manifest` step |
| `detect-stage-scopes.sh` / `.ps1` | `tests/.evals/scripts/detect-stage-scopes.{sh,ps1}` | none — emits `has_unit_tests`/`has_behavior_tests`/`has_e2e_tests`/`manifest_resolved` for the `setup` job's `Detect stage scopes` step, which every per-stage gate job's own `if:` reads via `needs.setup.outputs.*` (CI-SPLIT-JOBS-PLAN.md Section 1/2, common/ci-pipeline-generation.md Section 4.0j) |
| `ci-manifest-runner.sh` / `.ps1` | `tests/.evals/scripts/ci-manifest-runner.{sh,ps1}` | none — reads the merged manifest at RUN TIME and executes install/build/coverage per root, diff-scoped. What `${INSTALL_STEPS}`/`${BUILD_COMMAND}`/`${COVERAGE_COMMAND}` called until #7a; the generated workflow now calls this fixed script instead. Also exposes a standalone `eval-tools` mode — installs ONLY `ci.roots[].toolInstallCommands`, unconditionally, for a gate job (today: `static-evals`) that needs a tool `setup`'s own `install` mode already installed on a DIFFERENT runner |
| `run-static-evals.sh` / `.ps1` | `tests/.evals/scripts/run-static-evals.{sh,ps1}` | none — reads the manifest |
| `run-evals.sh` / `.ps1` | `tests/.evals/scripts/run-evals.{sh,ps1}` | none — reads the manifest. Runs INSIDE the `judge-gates` job only; its non-J1/J2 entries are discarded by `merge-verdict.*` (see below) |
| `merge-verdict.sh` / `.ps1` | `tests/.evals/scripts/merge-verdict.{sh,ps1}` | none — runs inside the `verdict` job, downloads every `gate-<name>` artifact from `tests/.evals/_run/downloaded/gate-<name>/`, and reproduces the single-job pipeline's exact `eval.json`/`eval-summary.md`/`failed-gates.txt` shape from them plus each gate job's own `needs.<job>.result` (CI-SPLIT-JOBS-PLAN.md Section 3). `auto-fix-agent.*` reads its output unchanged |
| `preflight-clean-room.sh` / `.ps1` | `tests/.evals/scripts/preflight-clean-room.{sh,ps1}` | none — invoked by `dev-implement.md` Step 2.5 (SH-LOOP-9), never by the committed workflow itself. Runs the Section 4.0i.1 P1/P2/P3 preflight contract inside a pinned Ubuntu container resolved from the workflow's own `runs-on:` (CI-SPLIT-JOBS-PLAN.md Section 5) |
| `auto-fix-agent.sh` / `.ps1` | `tests/.evals/scripts/auto-fix-agent.{sh,ps1}` | none — reads the manifest |
| `validate-pipeline.sh` / `.ps1` | `tests/.evals/scripts/validate-pipeline.{sh,ps1}` | none — reads the manifest |
| `smoke-test-epic.sh` / `.ps1` | `tests/.evals/scripts/smoke-test-epic.{sh,ps1}` | none — reads the manifest. Run ONCE at the STOP CHECKPOINT (ci-pipeline-generation.md Section 4.0.6), never per story |
| `resolve-eval-key.sh` / `.ps1` | `tests/.evals/scripts/resolve-eval-key.{sh,ps1}` | none — maps the PR head branch to its evidence key (`story-<N.M>` / `bug-<ID>` / `enhancement-<ID>`); called by the `setup` and `self-repair` jobs |
| `behavior/run.sh` | `tests/.evals/behavior/run.sh` | none |
| `behavior/Containerfile` | `tests/.evals/behavior/Containerfile` | `${SLOT}` for the base image |
| `sonar-project.properties.tmpl` | `sonar-project.properties` | `${SLOT}` markers only |

Ship the `.sh` variant for POSIX-primary repos and the `.ps1` variant for Windows-primary repos. Pick
by the repo's primary shell; when in doubt ship `.sh` (GitHub-hosted runners are Linux).

## Multi-job artifact handoff — two new, FIXED artifact-naming conventions

🔴 These names are **structural, like job ids** — never a `${SLOT}` and never renamed per repo
(CI-SPLIT-JOBS-PLAN.md Section 1's "avoiding the 6x install/build cost" note, Section 3):

- **`workspace-<key>`** (`<key>` = the resolved `EVAL_KEY`) — uploaded once by the `setup` job
  (`tar -czf` the whole checkout, `.git` INCLUDED, already installed and built). Every one of the six
  gate jobs (`static-evals`, `unit-coverage`, `behavior-gherkin`, `playwright-e2e`, `judge-gates`,
  `sonarqube`) downloads and extracts this SAME artifact — only the fast, cached `actions/setup-*`
  runtime-install steps re-run, gated on the same `needs.setup.outputs.has_<stack>` facts `setup`
  itself used. 🔴 `.git` is deliberately NOT stripped: `static-evals` (`run-static-evals.sh`'s
  `delta_diff()`), `unit-coverage` (`ci-manifest-runner.sh`'s own `git diff` + `lib-manifest.sh`'s
  `git rev-parse`), and `judge-gates` (`run-evals.sh`'s `git diff` building the judge prompt) all diff
  against `BASE_SHA` and require real git history in the extracted workspace — a `.git`-less tarball
  makes the first two hard-fail ("fatal: not a git repository") and silently mis-scores the third (its
  `git diff ... \|\| true` swallows the failure into an empty diff, scored as an incorrect J1/J2
  "N/A — nothing to score"). Observed in production exactly this way before this fix.
  🔴 **`static-evals` ALSO runs `ci-manifest-runner.sh eval-tools` before its own gate step** — the
  ONE place the "install once" optimization does not fully hold. `ci.roots[].toolInstallCommands`
  (semgrep, gitleaks, mypy, pip-audit, pip-licenses, radon, etc.) install to SYSTEM locations (global
  pip site-packages, `npm install -g`, `curl | tar xz -C /usr/local/bin`) that live OUTSIDE the
  checkout `setup` tars — a fresh runner extracting that tarball genuinely does not have those tools,
  and D3_sast/D7_secrets fail with "tool ... not installed on this runner" without this step. Observed
  in production exactly this way. `eval-tools` is a standalone, unconditional mode
  (`ci-manifest-runner.sh` — see that file) that installs ONLY the tools, never the diff-scoped
  project-dependency `installCommands` `install` mode also runs.
  🔴 **`unit-coverage` ALSO re-runs `Setup other toolchains` + `Install dependencies` (full `install`
  mode, unchanged) before its own gate step** — a DIFFERENT gap from the eval-tools one above, for the
  same underlying reason: a package manager whose default install location is OUTSIDE the repo tree
  leaves nothing for the tarball to have captured. Node's `node_modules/` is repo-local by default
  (safe), and Go/Maven-Gradle/.NET auto-restore missing dependencies from a registry at test-run time
  (self-healing, just slower) — but a bare `pip install` (no venv) or a bare `bundle install` (no
  local vendor path) resolves to the Python/Ruby interpreter's OWN install tree, confirmed empirically
  (pip's `site.getsitepackages()` never resolves under the cwd on any machine, GH-hosted runner
  included), never the checkout. Without this, the FIRST real story PR that actually exercises a
  Python/Ruby unit-test root fails with the test runner itself "not installed" — the identical failure
  shape as the eval-tools gap, just for the project's own test runner instead of a linter/scanner.
  `install` mode stays correctly diff-scoped here (unlike `eval-tools`), so a root this PR did not
  touch is skipped, exactly as `coverage` mode will skip it right after for the same reason — no
  wasted reinstall on a root this run won't test anyway. `behavior-gherkin`/`playwright-e2e`/
  `judge-gates`/`sonarqube` don't invoke `ci.roots[].tools`- or `installCommands`-backed commands and
  don't need either re-provisioning step.
- **`gate-static`, `gate-unit`, `gate-behavior`, `gate-playwright`, `gate-judge`, `gate-sonar`** — one
  per gate job, each uploading only the small evidence slice that job produced, at the SAME
  repo-relative `path:` the single-job pipeline always wrote to (e.g.
  `reports/eval-evidence/${EVAL_KEY}/static/`, `tests/.evals/_run/behavior*.status`). 🔴 **The
  DOWNLOADED shape is FLAT, not nested, even though the uploaded `path:` looks repo-relative** —
  `actions/upload-artifact@v4` strips the least-common-ancestor of whatever `path:` it is given, so
  what survives to the artifact's OWN root is that directory's (or file list's) CONTENTS, never the
  original prefix. `merge-verdict.sh` reads accordingly: `tests/.evals/_run/downloaded/gate-<name>/
  <flat-filename>` (e.g. `gate-static/static-results.json.gates`, `gate-judge/eval.json`,
  `gate-behavior/behaviorB1.status`) — never a path that re-adds the pre-upload repo-relative prefix.
  Observed in production before this fix: `merge-verdict.sh` assumed the nested paths, never found ANY
  gate's file at the (wrong) path it looked for, and every single gate id — including ones from jobs
  that genuinely PASSED — fell back to "declared but never run," which for a passing job manifested as
  a real success being reported as a phantom failure. Keep the upload `path:` values and
  `merge-verdict.*`'s read paths in sync with each other, never "fixed" independently.
- The final **`eval-results`** artifact name is unchanged from the single-job pipeline — it is now
  uploaded by the `verdict` job instead of `verify-and-evaluate`, and `self-repair`'s own
  `actions/download-artifact` step needs no change at all.
- **`coverage-reports-<key>`** — uploaded by `unit-coverage` ("Collect coverage reports" + "Upload
  coverage reports"), downloaded and restored by `sonarqube` ("Read manifest" + "Download coverage
  reports" + "Restore coverage reports", `continue-on-error: true` since the artifact may genuinely
  not exist — `unit-coverage` skipped, or produced no coverage report at all). 🔴 **Why this exists**:
  `sonarqube` extracts its own SEPARATE copy of the pre-test `setup` tarball, which never has a
  coverage report; `unit-coverage` generates one fresh, in its own extracted copy, which `sonarqube`
  can never see without an explicit handoff. Staged flat (root-tag + basename, same LCA-stripping
  reasoning as the `gate-*` artifacts — never assume a repo-relative path across multiple different
  root directories survives the round trip) and restored to each root's real `coverageReportPath` by
  re-reading `tests/.evals/_run/merged-manifest.json` (rebuilt fresh via "Read manifest" in the
  `sonarqube` job — a scratch file, never packaged in the tarball). This is also why `sonarqube`
  declares `needs: [setup, unit-coverage]` (never `needs: setup` alone) with `if: always()` —
  `common/ci-pipeline-generation.md`'s V42 checks both.

## The `${SLOT}` markers in `agentic-eval-pipeline.yml.template`

🔴 **#7a — the YAML holds NO stack facts.** `${SETUP_STEPS}`, `${INSTALL_STEPS}`, `${BUILD_COMMAND}`,
`${COVERAGE_COMMAND}` and `${SELF_REPAIR_SETUP_STEPS}` no longer exist. Every install/build/coverage
command and every `actions/setup-*` block is now **fixed text**, present in every generated repo
identically — the five slots that used to carry per-repo stack facts are replaced by:

- A **`Read manifest`** step (`bash tests/.evals/scripts/read-manifest.sh >> "$GITHUB_OUTPUT"`) that
  builds the merged manifest fresh, every run, and emits `has_<stack>`/`<stack>_version` for
  `node`/`python`/`java`/`go`/`dotnet`.
- **All five `actions/setup-*` blocks, permanently present**, each `if: steps.readmanifest.outputs.has_<stack>
  == 'true'`, using `steps.readmanifest.outputs.<stack>_version` for the pinned version. Nothing is ever
  added or removed from this file for a new stack — only **enabled**, by a fact the manifest already
  carries (`common/eval-framework.md` Section 1.1's `stack`/`runtimeVersion` fields).
- **`Install dependencies`**, **`Compile / build`** and (the `unit-coverage` job only) **`Stage 2: unit + coverage`**
  each call the ONE fixed `tests/.evals/scripts/ci-manifest-runner.sh {install,build,coverage}
  "${{ steps.basesha.outputs.sha }}"` — which reads the merged manifest at RUN TIME (`config.json`'s
  `ci.roots[]` + every `tests/.evals/ci-manifest.d/*.json` fragment), iterates every root, diff-scopes
  it (`common/ci-pipeline-generation.md` Section 4.0g), verifies it (`cd`+marker check, Section 4.0d.1),
  and runs its command — or reports an earned `N/A`. `Install dependencies` also installs the merged,
  deduped eval tools from every root's `toolInstallCommands`, replacing the old separately-generated
  "Install eval tools" block.
- **This is byte-identical in the `self-repair` job** — there is no longer a separate
  `${SELF_REPAIR_SETUP_STEPS}` slot to keep in sync with the gate jobs' copy, because there is no
  per-repo generated text left in either job to diverge. Section 3.1's "same tools" rule is now
  structural, not a runtime check (validated by V27's structural-fidelity check instead of a separate
  slot-equality diff).

**A later work unit's brand-new root or stack** (a story that introduces the repo's first frontend code,
say) needs **zero edits to this committed workflow file** — its own `ci-manifest.d/<unit>.json` fragment
is enough; `Read manifest` and `ci-manifest-runner.sh` pick it up on that work unit's own PR, the very
first time they run. This is what #7a actually fixes: under the old model, a new root's install/build
commands were frozen at generation time and a human had to hand-edit the YAML to add them.

Only these two slots remain, because `on:` triggers cannot be dynamic:

| Slot | Filled from | Example |
|---|---|---|
| `${BASE_BRANCH}` | `ci.baseBranch` | `main` |
| `${PR_BRANCH_FILTERS}` | `ci.integrationBranchPrefixes` → one `- 'prefix/**'` line each | `- 'epic/**'` … |

Three more slots remain because they are **structural**, not stack, facts — SonarQube configuration, the
behaviour-tier image tag, and the pinned Claude Code CLI version are the same regardless of which stack
roots a repo has:

| Slot | Filled from | Example |
|---|---|---|
| `${BEHAVIOR_IMAGE_TAG}` | `tests/.evals/config.json` `behavior.image` | `aire-behavior:ci` |
| `${SONAR_STEPS}` | Section 4.1 — active block, or a commented skip note | see template |
| `${CLAUDE_CODE_VERSION}` | the exact `@anthropic-ai/claude-code` version resolved at generation time (`npm view @anthropic-ai/claude-code version`), the SAME moment `claude --help` is read to resolve the CLAUDE_REPAIR_INVOCATION/CLAUDE_JUDGE_INVOCATION flags (Section 6.0) — never `npm install -g @anthropic-ai/claude-code` unpinned. This package ships multiple releases per DAY; an unpinned install can silently resolve to a different CLI version than the one the flags were verified against, breaking a previously-working invocation with no code change in the repo (ci-pipeline-generation.md Section 6.0.2) | `2.1.258` |

🔴 After substitution, `validate-pipeline.{sh,ps1}` MUST pass before the file is committed. It greps for
any leftover `${` slot, runs `actionlint`, dry-runs the scripts, and asserts every `ci.gates[]` id
appears in both the verdict tally and the `eval.json` schema. A non-zero exit means NOT committed.

## The three script bugs these templates fix permanently

1. **`mkdir -p` precedes every write** — no more `No such file or directory` on a clean CI checkout.
2. **Self-repair never exits 0 on a real failure** — `failed-gates.txt` is the PRIMARY input; a missing
   `eval.json` is a supplementary-input finding, not a free pass.
3. **`EVAL_KEY` handles every integration prefix including `ci/**`** — the resolver reads
   `ci.integrationBranchPrefixes` and fails loudly (never falls through to `unknown`) if the key is
   still unresolved.
