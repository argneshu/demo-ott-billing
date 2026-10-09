#!/usr/bin/env bash
# preflight-clean-room.sh — CI-SPLIT-JOBS-PLAN.md Section 5. Replaces the previously inline, loosely
# worded P2 instructions in common/ci-pipeline-generation.md Section 4.0i.1 with one concrete script
# dev-implement.md Step 2.5 (SH-LOOP-9) calls directly, so a work unit proves its manifest fragment is
# EXECUTABLE — on the exact same pinned Ubuntu image the real CI job runs on — before the PR exists.
#
# 🔴 This script only makes the ENVIRONMENT explicit and reproducible. It does not change what counts
#    as a failure (4.0i.2) or how a failure is repaired (4.0i.3) — those rules are unchanged.
#
# Usage: bash tests/.evals/scripts/preflight-clean-room.sh <integration-branch>
#   e.g. bash tests/.evals/scripts/preflight-clean-room.sh epic/PROJ-100-title
set -uo pipefail

INTEGRATION_BRANCH="${1:-}"
WF=".github/workflows/agentic-eval-pipeline.yml"
RUN_DIR="tests/.evals/_run"
mkdir -p "$RUN_DIR"

if [ -z "$INTEGRATION_BRANCH" ]; then
  echo "preflight-clean-room: ERROR: integration branch argument is required (e.g. epic/PROJ-100-title)" >&2
  exit 2
fi

# ── Resolve the EXACT SAME base image the generated CI job runs on. `runs-on:` in the committed
#    workflow is the single source of truth — never a hardcoded/unpinned guess. Mapped to a pinned
#    container tag rather than a bare `ubuntu:latest`, so the local clean room actually matches the
#    hosted runner's package set (Section 4.0.1a's own "clean-room, matching the CI runner exactly"
#    requirement, made concrete here instead of restated in prose). ──
resolve_image() {
  local runs_on=""
  if [ -f "$WF" ]; then
    runs_on="$(grep -m1 'runs-on:' "$WF" | sed -E 's/.*runs-on:[[:space:]]*//; s/"//g' | tr -d '\r')"
  fi
  case "$runs_on" in
    ubuntu-latest|ubuntu-24.04|"") echo "catthehacker/ubuntu:act-24.04" ;;
    ubuntu-22.04) echo "catthehacker/ubuntu:act-22.04" ;;
    ubuntu-20.04) echo "catthehacker/ubuntu:act-20.04" ;;
    *) echo "catthehacker/ubuntu:act-24.04" ;;
  esac
}

# A story that touched the behavioural Containerfile gets ITS base image instead — the behavioural
# tier's own clean room is the more faithful match for that unit's change (Section 4.0i.1 P3).
BEHAVIOR_TOUCHED=0
if [ -n "${BASE_SHA:-}" ]; then
  if git diff --name-only "${BASE_SHA}" -- tests/.evals/behavior/Containerfile tests/.evals/behavior/run.sh 2>/dev/null | grep -q .; then
    BEHAVIOR_TOUCHED=1
  fi
fi

if [ "$BEHAVIOR_TOUCHED" -eq 1 ] && [ -f tests/.evals/behavior/Containerfile ]; then
  IMAGE="$(grep -m1 '^FROM' tests/.evals/behavior/Containerfile | awk '{print $2}')"
  echo "preflight-clean-room: behaviour Containerfile touched — using its own base image ${IMAGE} (P3), never a generic pin"
else
  IMAGE="$(resolve_image)"
fi

if ! command -v podman >/dev/null 2>&1; then
  echo "preflight-clean-room: NOTE — podman not installed; falling back to venv/node_modules isolation in the AMBIENT shell (same one permitted exception the behavioural gate already uses). This is a WEAKER guarantee than a true clean room (V23-class drift may go undetected) and is logged as such." | tee -a "$RUN_DIR/preflight-clean-room.log"
  FALLBACK=1
else
  FALLBACK=0
fi

BASE_SHA="${BASE_SHA:-$(git merge-base "origin/${INTEGRATION_BRANCH}" HEAD 2>/dev/null || echo "")}"
if [ -z "$BASE_SHA" ]; then
  echo "preflight-clean-room: ERROR: could not resolve BASE_SHA = git merge-base origin/${INTEGRATION_BRANCH} HEAD — is '${INTEGRATION_BRANCH}' fetched locally?" >&2
  exit 2
fi

run_p1() {
  echo "preflight-clean-room: P1 — declaration completeness (no environment needed)"
  if [ ! -f tests/.evals/_run/merged-manifest.json ] && [ -f tests/.evals/scripts/read-manifest.sh ]; then
    bash tests/.evals/scripts/read-manifest.sh > /dev/null || true
  fi
  if [ ! -f tests/.evals/_run/merged-manifest.json ]; then
    echo "preflight-clean-room: P1 FAILURE — merged-manifest.json could not be derived" >&2
    return 1
  fi
  local missing=""
  while IFS=$'\t' read -r tool_name has_install; do
    [ -z "$tool_name" ] && continue
    if [ "$has_install" != "true" ]; then
      missing="${missing}${missing:+, }${tool_name}"
    fi
  done < <(jq -r '.[] | .tools[]? as $t | [$t, ((.toolInstallCommands[$t] // "") != "")] | @tsv' tests/.evals/_run/merged-manifest.json 2>/dev/null | tr -d '\r')
  if [ -n "$missing" ]; then
    echo "preflight-clean-room: P1 FAILURE — tool(s) declared in 'tools' with no matching 'toolInstallCommands' entry: ${missing}" >&2
    return 1
  fi
  echo "preflight-clean-room: P1 passed"
  return 0
}

run_p2_commands() {
  set -e
  bash tests/.evals/scripts/ci-manifest-runner.sh install "$BASE_SHA"
  bash tests/.evals/scripts/ci-manifest-runner.sh build "$BASE_SHA"
  bash tests/.evals/scripts/run-static-evals.sh "$BASE_SHA"
  bash tests/.evals/scripts/ci-manifest-runner.sh coverage "$BASE_SHA"
}

run_p2() {
  echo "preflight-clean-room: P2 — clean-room execution of the real CI entrypoints (image: ${IMAGE:-ambient fallback})"
  if [ "$FALLBACK" -eq 1 ]; then
    ( run_p2_commands ) 2>&1 | tee "$RUN_DIR/preflight-clean-room-p2.log"
    return "${PIPESTATUS[0]}"
  fi
  podman run --rm \
    -v "$PWD:/work:Z" -w /work \
    "$IMAGE" \
    bash -lc "bash tests/.evals/scripts/ci-manifest-runner.sh install '$BASE_SHA' && \
              bash tests/.evals/scripts/ci-manifest-runner.sh build '$BASE_SHA' && \
              bash tests/.evals/scripts/run-static-evals.sh '$BASE_SHA' && \
              bash tests/.evals/scripts/ci-manifest-runner.sh coverage '$BASE_SHA'" \
    2>&1 | tee "$RUN_DIR/preflight-clean-room-p2.log"
  return "${PIPESTATUS[0]}"
}

# P3 — behavioural provisioning: reuse already-clean-room evidence per the existing dedup rule (Section
# 4.0i.1 P3) — never re-run it here. Only note whether it ran containerised and whether this unit
# touched the image itself (which routes back to P2 running INSIDE that same image above, not to a
# second, separate P3 run).
run_p3_note() {
  if [ "$BEHAVIOR_TOUCHED" -eq 1 ]; then
    echo "preflight-clean-room: P3 — behaviour Containerfile/run.sh touched by this unit; its own behavioural gate run (Podman) IS this unit's clean-room evidence for the image change. Not re-run here."
  else
    echo "preflight-clean-room: P3 — behaviour image untouched; reusing this unit's own already-containerised behavioural gate evidence, never re-run (dedup rule, Section 4.0i.1 P3)."
  fi
}

P1_LOG="$RUN_DIR/preflight-clean-room-p1.log"
run_p1 > "$P1_LOG" 2>&1; p1_rc=$?
cat "$P1_LOG"
if [ "$p1_rc" -ne 0 ]; then
  echo "preflight-clean-room: FAILED at P1 — fix the declaration gap (Section 4.0i.3), never the gate." >&2
  exit 1
fi

run_p2; p2_rc=$?
if grep -qE 'is not installed on this runner|command not found|No such file or directory|ModuleNotFoundError|ImportError|RuntimeError: .* requires the .* package|Cannot find module|ResolutionImpossible|ERESOLVE|no findings at base or head.*zero output at BOTH ends' "$RUN_DIR/preflight-clean-room-p2.log"; then
  echo "preflight-clean-room: FAILED at P2 — provisioning/declaration gap detected in the clean-room output above (Section 4.0i.2). Fix the declaration, never the gate, and re-run." >&2
  exit 1
fi
if [ "$p2_rc" -ne 0 ]; then
  echo "preflight-clean-room: P2 exited non-zero, but no provisioning-gap signature was found — this looks like a REAL gate finding, not a preflight failure (Section 4.0i.2's own distinction: a gate that runs correctly and reports a real finding is not a preflight failure). Confirm manually before treating this as clean."
fi

run_p3_note

echo "preflight-clean-room: PASSED — manifest is executable on ${IMAGE:-the ambient fallback}."
exit 0
