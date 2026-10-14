"""Coverage of the lines and branches a work unit added or changed.

Usage: python changed-lines-coverage.py <key> <base-sha> <threshold> <coverage.xml> <out.json> <source-prefix>
Intersects `git diff --unified=0 <base>` with a Cobertura report (line and branch hits).
"""
import json
import re
import subprocess
import sys
import xml.etree.ElementTree as ET

key, base, threshold, xml_path, out_path, prefix = sys.argv[1:7]
threshold = float(threshold)

diff = subprocess.run(
    ["git", "diff", "--unified=0", "--diff-filter=ACMR", base, "--", prefix],
    capture_output=True, text=True, check=True,
).stdout
changed = {}
current = None
for line in diff.splitlines():
    if line.startswith("+++ b/"):
        current = line[6:]
        changed[current] = set()
    elif line.startswith("@@") and current:
        m = re.match(r"@@ -\S+ \+(\d+)(?:,(\d+))? @@", line)
        start, count = int(m.group(1)), int(m.group(2) or 1)
        changed[current].update(range(start, start + count))

root = ET.parse(xml_path).getroot()
reports = {}
for cls in root.iter("class"):
    lines = {}
    for ln in cls.find("lines"):
        number = int(ln.get("number"))
        cond = ln.get("condition-coverage")
        covered_b = total_b = 0
        if cond:
            m = re.search(r"\((\d+)/(\d+)\)", cond)
            covered_b, total_b = int(m.group(1)), int(m.group(2))
        lines[number] = (int(ln.get("hits")) > 0, covered_b, total_b)
    reports[cls.get("filename")] = lines

files = []
tl = cl = tb = cb = 0
for path, lines_changed in changed.items():
    name = path.split("/", 2)[-1] if path.startswith("src/") else path
    report = next((v for k, v in reports.items() if path.endswith(k) or k.endswith(name)), None)
    if report is None:
        continue
    exe = [n for n in lines_changed if n in report]
    c_lines = sum(1 for n in exe if report[n][0])
    t_br = sum(report[n][2] for n in exe)
    c_br = sum(report[n][1] for n in exe)
    files.append({"path": path, "changedExecutableLines": len(exe), "coveredLines": c_lines,
                  "changedBranches": t_br, "coveredBranches": c_br})
    tl += len(exe); cl += c_lines; tb += t_br; cb += c_br

line_pct = round(100.0 * cl / tl, 2) if tl else 100.0
branch_pct = round(100.0 * cb / tb, 2) if tb else 100.0
result = {"key": key, "base": base, "threshold": threshold, "files": files,
          "lineCoverage": line_pct, "branchCoverage": branch_pct,
          "status": "PASS" if line_pct >= threshold and branch_pct >= threshold else "FAIL"}
with open(out_path, "w") as handle:
    json.dump(result, handle, indent=2)
print(json.dumps(result, indent=2))
sys.exit(0 if result["status"] == "PASS" else 1)
