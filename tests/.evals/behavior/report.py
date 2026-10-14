"""Turn a pytest-bdd JUnit file into behavior-test-report.json with @AC tag coverage.

Usage: python report.py <tier> <key> <junit.xml> <out.json> <feature> [<feature> ...]
"""
import json
import re
import sys
import xml.etree.ElementTree as ET

tier, key, junit, out, *features = sys.argv[1:]


def norm(text):
    return re.sub(r"[^a-z0-9]+", "_", text.lower()).strip("_")


results = {}
for case in ET.parse(junit).getroot().iter("testcase"):
    name = re.sub(r"\[.*\]$", "", case.get("name"))
    passed = case.find("failure") is None and case.find("error") is None and case.find("skipped") is None
    results.setdefault(name, []).append(passed)

scenarios = []
for feature in features:
    tags = []
    with open(feature) as handle:
        lines = handle.read().splitlines()
    for line in lines:
        s = line.strip()
        if s.startswith("@"):
            tags = s.split()
        elif s.startswith("Scenario"):
            title = s.split(":", 1)[1].strip()
            runs = results.get("test_" + norm(title), [])
            scenarios.append({"feature": feature, "scenario": title, "tags": tags, "runs": len(runs),
                              "result": "PASS" if runs and all(runs) else "FAIL"})
            tags = []
total = len(scenarios)
passed = sum(1 for s in scenarios if s["result"] == "PASS")
ac_tags = sorted({t for s in scenarios for t in s["tags"] if t.startswith("@AC-")})
ac_run = sorted({t for s in scenarios if s["result"] == "PASS" for t in s["tags"] if t.startswith("@AC-")})
report = {"tier": tier, "key": key, "scenarios": scenarios, "scenariosPassed": passed, "scenariosTotal": total,
          "acTags": ac_tags, "acTagsExecuted": ac_run, "status": "PASS" if passed == total and ac_tags == ac_run else "FAIL"}
with open(out, "w") as handle:
    json.dump(report, handle, indent=2)
print(json.dumps({k: report[k] for k in ("tier", "scenariosPassed", "scenariosTotal", "acTags", "acTagsExecuted", "status")}))
sys.exit(0 if report["status"] == "PASS" else 1)
