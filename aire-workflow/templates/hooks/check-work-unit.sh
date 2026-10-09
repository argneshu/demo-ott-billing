#!/usr/bin/env sh
# AIRE work-unit guard — refuses a work-unit commit whose gates or evidence are incomplete.
#
# Contract: aire-workflow/common/work-unit-artifacts.md Section 6.
#
# Usage:
#   sh aire-workflow/templates/hooks/check-work-unit.sh <unit-key>   # explicit run (the workflows call this
#                                                                     # right before `git commit`)
#   sh aire-workflow/templates/hooks/check-work-unit.sh --hook       # from the git pre-commit hook: reads
#                                                                     # the unit key recorded for THIS branch
#   sh aire-workflow/templates/hooks/check-work-unit.sh --install <unit-key>
#                                                                     # install the hook + record the key
#
# Exit 0 = every gate is PASS or a legitimate N/A and every required evidence file is present and staged.
# Exit 1 = commit refused; one line per violation. Never bypass it with `git commit --no-verify`.
#
# <unit-key> = story-<N.M> | bug-<TICKET-ID> | enhancement-<TICKET-ID>

set -u

UNIT_FILE="$(git rev-parse --git-path aire-work-unit 2>/dev/null)"
BRANCH="$(git branch --show-current 2>/dev/null)"

# ---------------------------------------------------------------- install mode
if [ "${1:-}" = "--install" ]; then
  KEY="${2:-}"
  [ -n "$KEY" ] || { echo "check-work-unit: --install needs the unit key" >&2; exit 2; }
  printf 'branch=%s\nkey=%s\n' "$BRANCH" "$KEY" > "$UNIT_FILE"
  if [ -n "$(git config --get core.hooksPath 2>/dev/null)" ]; then
    echo "check-work-unit: core.hooksPath is set; the hook was NOT installed (that folder may be versioned)."
    echo "check-work-unit: the workflow runs this check explicitly before every commit instead."
    exit 0
  fi
  HOOK="$(git rev-parse --git-path hooks/pre-commit)"
  if [ -f "$HOOK" ] && ! grep -q "AIRE work-unit guard" "$HOOK"; then
    mv "$HOOK" "$HOOK.local"
    echo "check-work-unit: the existing pre-commit hook was kept as pre-commit.local and still runs first."
  fi
  cat > "$HOOK" <<'HOOK_EOF'
#!/bin/sh
# AIRE work-unit guard (installed by the implement workflows — aire-workflow/common/work-unit-artifacts.md Section 6)
HOOK_DIR="$(dirname "$0")"
if [ -x "$HOOK_DIR/pre-commit.local" ]; then "$HOOK_DIR/pre-commit.local" "$@" || exit $?; fi
if [ -f aire-workflow/templates/hooks/check-work-unit.sh ]; then
  exec sh aire-workflow/templates/hooks/check-work-unit.sh --hook
fi
exit 0
HOOK_EOF
  chmod +x "$HOOK" 2>/dev/null || true
  echo "check-work-unit: guard installed for branch '$BRANCH' (unit $KEY)."
  exit 0
fi

# ---------------------------------------------------------------- resolve the unit key
if [ "${1:-}" = "--hook" ]; then
  [ -f "$UNIT_FILE" ] || exit 0                                  # not an AIRE work-unit repo state
  REC_BRANCH="$(sed -n 's/^branch=//p' "$UNIT_FILE")"
  KEY="$(sed -n 's/^key=//p' "$UNIT_FILE")"
  [ "$REC_BRANCH" = "$BRANCH" ] || exit 0                        # a different branch: not guarded
  [ -n "$KEY" ] || exit 0
else
  KEY="${1:-}"
  [ -n "$KEY" ] || { echo "usage: check-work-unit.sh <unit-key> | --hook | --install <unit-key>" >&2; exit 2; }
fi

EVAL="reports/eval-evidence/$KEY/eval.json"
VIOLATIONS=""
add() { VIOLATIONS="${VIOLATIONS}  - $1
"; }

# A required file must exist, be non-empty, and be staged or already committed (it rides the commit).
need() {
  if [ ! -s "$1" ]; then add "missing or empty: $1"; return; fi
  git ls-files --cached --error-unmatch "$1" >/dev/null 2>&1 || add "not staged (git add it): $1"
}
need_glob() { # $1 = description, $2... = candidate paths from a glob
  desc="$1"; shift
  for f in "$@"; do [ -s "$f" ] && { git ls-files --cached --error-unmatch "$f" >/dev/null 2>&1 || add "not staged (git add it): $f"; return; }; done
  add "missing: $desc"
}
need_dir() { # a folder with at least one file in it
  if [ -z "$(ls -A "$1" 2>/dev/null)" ]; then add "missing or empty folder: $1"; fi
}
absent_dir() { [ -d "$1" ] && add "folder must not exist for an N/A gate: $1"; }

# ---------------------------------------------------------------- gates (eval.json)
GATES=""
if [ ! -s "$EVAL" ]; then
  add "missing: $EVAL — no gate results, so nothing can be committed"
else
  CHANGE_DOC=""
  N="${KEY#story-}"
  if [ "$N" != "$KEY" ]; then
    # A change/bugfix story, or a Change Request story, must also satisfy the testImpact gate.
    if [ -f "spec/plans/change-story-$N.md" ] || [ -f "spec/plans/bugfix-story-$N.md" ]; then
      CHANGE_DOC=1
    else
      # epic-change-request: the plan lives in the CR bundle, addressed by glob (CR-<n> is unknown here).
      # Match ONLY the explicit build-unit marker, never a story merely listed as affected —
      # an affected story does not run testImpact and must not be required to.
      for _crdoc in spec/plans/change-requests/CR-*/change-request.md; do
        [ -f "$_crdoc" ] || continue
        if grep -qE "^CR-BUILDS-STORY:[[:space:]]*$N[[:space:]]*$" "$_crdoc" 2>/dev/null; then
          CHANGE_DOC=1; break
        fi
      done
      unset _crdoc
    fi
  fi
  PYCODE='
import json, re, sys
path, change = sys.argv[1], sys.argv[2] == "1"
try:
    d = json.load(open(path, encoding="utf-8"))
except Exception as e:
    print("VIOL eval.json does not parse: %s" % e); sys.exit(0)
g = d.get("gates") or {}
req = ["D1_lint","D2_types","D3_sast","D4_deps","D5_licenses","D6_complexity","D7_secrets",
       "unitCoverage","behaviorB1","behaviorB2","behaviorB3","apiContract","playwright",
       "playwrightRegression","regression","J1_architecture","J2_security"]
if change: req.append("testImpact")
never_na = {"unitCoverage","behaviorB1","regression","J2_security"}
bad = re.compile(r"\byet\b|todo|not wired|not bootstrapped|not implemented|pending|future|time.?box|not run|"
                 r"this (pass|session|run)|follow.?up|defer|no tool configured|not installed|not available|"
                 r"later|scope|keep (the )?session|manual check|by inspection|by hand|skipp?", re.I)
for gid in req:
    v = g.get(gid)
    if not isinstance(v, dict) or "status" not in v:
        print("VIOL eval.json gate missing: %s" % gid); continue
    st = str(v.get("status")).strip()
    print("STATUS %s %s" % (gid, st.replace(" ", "_")))
    if st == "PASS":
        continue
    if st == "N/A":
        reason = str(v.get("reason") or "").strip()
        if gid in never_na:
            print("VIOL gate %s can never be N/A" % gid)
        elif not reason:
            print("VIOL gate %s is N/A with no reason" % gid)
        elif bad.search(reason):
            print("VIOL gate %s N/A reason is on the forbidden list (eval-framework.md Section 2.5.2): %s" % (gid, reason))
        continue
    print("VIOL gate %s is %s — only PASS or a legitimate N/A may be committed" % (gid, st))
if str(d.get("verdict", "")).strip() != "PASS":
    print("VIOL eval.json verdict is %r, not PASS" % d.get("verdict"))
'
  JSCODE='
const fs = require("fs"); const [path, changeArg] = process.argv.slice(1);
let d; try { d = JSON.parse(fs.readFileSync(path, "utf8")); } catch (e) { console.log("VIOL eval.json does not parse: " + e.message); process.exit(0); }
const g = d.gates || {};
const req = ["D1_lint","D2_types","D3_sast","D4_deps","D5_licenses","D6_complexity","D7_secrets","unitCoverage","behaviorB1","behaviorB2","behaviorB3","apiContract","playwright","playwrightRegression","regression","J1_architecture","J2_security"];
if (changeArg === "1") req.push("testImpact");
const neverNA = new Set(["unitCoverage","behaviorB1","regression","J2_security"]);
const bad = /\byet\b|todo|not wired|not bootstrapped|not implemented|pending|future|time.?box|not run|this (pass|session|run)|follow.?up|defer|no tool configured|not installed|not available|later|scope|keep (the )?session|manual check|by inspection|by hand|skipp?/i;
for (const id of req) {
  const v = g[id];
  if (!v || typeof v !== "object" || !("status" in v)) { console.log("VIOL eval.json gate missing: " + id); continue; }
  const st = String(v.status).trim(); console.log("STATUS " + id + " " + st.replace(/ /g, "_"));
  if (st === "PASS") continue;
  if (st === "N/A") {
    const r = String(v.reason || "").trim();
    if (neverNA.has(id)) console.log("VIOL gate " + id + " can never be N/A");
    else if (!r) console.log("VIOL gate " + id + " is N/A with no reason");
    else if (bad.test(r)) console.log("VIOL gate " + id + " N/A reason is on the forbidden list (eval-framework.md Section 2.5.2): " + r);
    continue;
  }
  console.log("VIOL gate " + id + " is " + st + " — only PASS or a legitimate N/A may be committed");
}
if (String(d.verdict || "").trim() !== "PASS") console.log("VIOL eval.json verdict is " + JSON.stringify(d.verdict) + ", not PASS");
'
  if command -v python3 >/dev/null 2>&1 && python3 -c "" >/dev/null 2>&1; then
    OUT="$(python3 -c "$PYCODE" "$EVAL" "${CHANGE_DOC:-0}")"
  elif command -v python >/dev/null 2>&1 && python -c "" >/dev/null 2>&1; then
    OUT="$(python -c "$PYCODE" "$EVAL" "${CHANGE_DOC:-0}")"
  elif command -v node >/dev/null 2>&1; then
    OUT="$(node -e "$JSCODE" "$EVAL" "${CHANGE_DOC:-0}")"
  else
    OUT="VIOL cannot read eval.json: neither python nor node is available to parse it"
  fi
  GATES="$(printf '%s\n' "$OUT" | sed -n 's/^STATUS //p')"
  printf '%s\n' "$OUT" | sed -n 's/^VIOL //p' | while IFS= read -r line; do printf '%s\n' "$line"; done > "${TMPDIR:-/tmp}/aire-viol.$$" 2>/dev/null || true
  while IFS= read -r line; do [ -n "$line" ] && add "$line"; done < "${TMPDIR:-/tmp}/aire-viol.$$"
  rm -f "${TMPDIR:-/tmp}/aire-viol.$$"
fi
status_of() { printf '%s\n' "$GATES" | awk -v id="$1" '$1 == id { print $2; exit }'; }

# ---------------------------------------------------------------- evidence files
U="reports/unit-test-evidence/$KEY"
need "$U/baseline-regression.log"; need "$U/unit-test-run.log"; need "$U/full-regression.log"
need "$U/evidence-manifest.md"; need "$U/coverage/changed-lines-coverage.json"

B="reports/behavior-test-evidence/$KEY"
need "$B/b1/behavior-test-run.log"; need "$B/b1/evidence-manifest.md"
for tier in B2 B3; do
  t="$(printf '%s' "$tier" | tr 'B' 'b')"
  case "$(status_of "behavior$tier")" in
    PASS) need "$B/$t/behavior-test-run.log"; need "$B/$t/evidence-manifest.md" ;;
    N/A)  absent_dir "$B/$t" ;;
  esac
done

case "$(status_of apiContract)" in
  PASS) A="reports/api-contract-test-evidence/$KEY"; need "$A/api-contract-test-run.log"; need "$A/evidence-manifest.md" ;;
  N/A)  absent_dir "reports/api-contract-test-evidence/$KEY" ;;
esac
P="reports/playwright-test-evidence/$KEY"
case "$(status_of playwright)" in
  PASS) need "$P/playwright-test-run.log"; need "$P/evidence-manifest.md" ;;
esac
case "$(status_of playwrightRegression)" in
  PASS) need "$P/regression/playwright-baseline-regression.log"; need "$P/regression/playwright-full-regression.log"
        need "$P/regression/evidence-manifest.md" ;;
  N/A)  absent_dir "$P/regression" ;;
esac

E="reports/eval-evidence/$KEY"
need "$E/eval-summary.md"; need "$E/artifact-check.md"; need "$E/judge/security-score.json"
[ "$(status_of J1_architecture)" = "PASS" ] && need "$E/judge/architecture-score.json"
D_RAN=0
for d in D1_lint D2_types D3_sast D4_deps D5_licenses D6_complexity D7_secrets; do
  [ "$(status_of "$d")" = "PASS" ] && D_RAN=$((D_RAN + 1))
done
if [ "$D_RAN" -gt 0 ]; then
  need_dir "$E/static"; need_dir "$E/static/baseline"
  base_n="$(find "$E/static/baseline" -type f 2>/dev/null | wc -l | tr -d ' ')"
  [ "${base_n:-0}" -lt "$D_RAN" ] && add "static/baseline holds $base_n tool output(s) for $D_RAN D-gates that ran — one baseline output per D-gate (work-unit-artifacts.md E6)"
fi

# shellcheck disable=SC2086
need_glob "reports/reviews/$KEY-code-review-v<X>.md" reports/reviews/"$KEY"-code-review-v*.md
need_glob "reports/code-security-reviews/$KEY-security-review-v<X>.md" reports/code-security-reviews/"$KEY"-security-review-v*.md
need "runtime-artifacts/stories/$KEY/audit.md"; need "runtime-artifacts/stories/$KEY/state.md"
case "$KEY" in bug-*|enhancement-*) need "reports/ticket-summary/$KEY-summary.md" ;; esac

# ---------------------------------------------------------------- tracker claim (## Claim in the unit state)
ST="runtime-artifacts/stories/$KEY/state.md"
if [ -s "$ST" ]; then
  CLAIM="$(awk '/^## Claim/{f=1; next} /^## /{f=0} f' "$ST")"
  if [ -z "$CLAIM" ]; then
    add "no '## Claim' block in $ST — make the tracker claim (In Development + assignee), verify it, record it"
  else
    TLINE="$(printf '%s
' "$CLAIM" | grep -m1 '^- Tracker:' || true)"
    ALINE="$(printf '%s
' "$CLAIM" | grep -m1 '^- Assignee:' || true)"
    if [ -z "$TLINE" ]; then
      add "## Claim has no '- Tracker:' line ($ST)"
    elif ! printf '%s' "$TLINE" | grep -q 'LOCAL'; then
      printf '%s' "$TLINE" | grep -q 'verified' || add "tracker claim not verified — transition the issue to In Development and verify it: $TLINE"
      if [ -z "$ALINE" ]; then
        add "## Claim has no '- Assignee:' line — assign the operator and verify it ($ST)"
      elif ! printf '%s' "$ALINE" | grep -Eq 'verified|unresolved'; then
        add "assignee not verified — assign the operator and verify it: $ALINE"
      fi
    fi
  fi
fi

# ---------------------------------------------------------------- verdict
if [ -n "$VIOLATIONS" ]; then
  echo "AIRE work-unit guard: commit REFUSED for $KEY."
  printf '%s' "$VIOLATIONS"
  echo "Run the missing gates and write their evidence (work-unit-artifacts.md Sections 1 and 5), then commit again."
  echo "Never bypass this check with --no-verify. If a gate truly cannot run, HALT with the Self-Heal Limit message."
  exit 1
fi
echo "AIRE work-unit guard: $KEY — every gate PASS or legitimate N/A, evidence complete."
exit 0
