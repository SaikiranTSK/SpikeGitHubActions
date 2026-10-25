"""Replace the SystemName choice options in MainlineTeamTests.yml.

Usage: update-runner-options.py <workflow.yml> <systems.txt> <online.txt>
  systems.txt : master list (one per line, '#' = comment), defines the order
  online.txt  : runner names/labels that are online now (one per line)
Only the lines under 'SystemName: ... options:' are changed; the rest of the file stays byte-identical.
"""
import sys

workflow, systems_file, online_file = sys.argv[1:4]

def read_list(path):
    with open(path, encoding="utf-8") as f:
        return [l.strip() for l in f if l.strip() and not l.strip().startswith("#")]

systems = read_list(systems_file)
online = set(read_list(online_file))
selected = [s for s in systems if s in online]

if not selected:
    print("::warning::No system from runner-systems.txt is online. Dropdown not changed.")
    sys.exit(0)

with open(workflow, encoding="utf-8", newline="") as f:
    lines = f.read().splitlines(keepends=True)
eol = "\r\n" if lines and lines[0].endswith("\r\n") else "\n"

# First 'SystemName:' is the workflow_dispatch one (workflow_call uses the inline { } form).
try:
    start = next(i for i, l in enumerate(lines) if l.strip() == "SystemName:")
    opt = next(i for i in range(start + 1, len(lines)) if lines[i].strip() == "options:")
except StopIteration:
    sys.exit("::error::SystemName options block not found in " + workflow)

first = opt + 1
indent = lines[first][: len(lines[first]) - len(lines[first].lstrip())]
end = first
while end < len(lines) and lines[end].startswith(indent + "- "):
    end += 1

lines[first:end] = [f"{indent}- {s}{eol}" for s in selected]

with open(workflow, "w", encoding="utf-8", newline="") as f:
    f.writelines(lines)

print(f"SystemName options: {len(selected)} online of {len(systems)} known systems.")
for s in systems:
    print(f"  {'online ' if s in online else 'offline'}  {s}")
