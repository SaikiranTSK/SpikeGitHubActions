#!/usr/bin/env python3
"""
Replace workflow_dispatch.inputs.SystemName.options in one workflow file.

Usage:
  update-runner-options.py <workflow.yml> <systems.txt> <online.txt>

- systems.txt: master list (one system per line, '#' comments allowed), preserves order.
- online.txt : names/labels that are online now (one per line).
Only the first "SystemName:" block (workflow_dispatch) is updated.
"""

from __future__ import annotations
import sys
from pathlib import Path

if len(sys.argv) != 4:
    print("Usage: update-runner-options.py <workflow.yml> <systems.txt> <online.txt>", file=sys.stderr)
    sys.exit(2)

workflow_path = Path(sys.argv[1])
systems_path = Path(sys.argv[2])
online_path = Path(sys.argv[3])

def read_list(path: Path) -> list[str]:
    items: list[str] = []
    for raw in path.read_text(encoding="utf-8").splitlines():
        s = raw.strip()
        if not s or s.startswith("#"):
            continue
        items.append(s)
    return items

systems = read_list(systems_path)
online = set(read_list(online_path))

selected = [s for s in systems if s in online]

if not selected:
    print(f"::warning::{workflow_path}: no known systems are online; leaving file unchanged.")
    sys.exit(0)

text = workflow_path.read_text(encoding="utf-8", newline="")
lines = text.splitlines(keepends=True)

# Preserve file line endings
eol = "\n"
for ln in lines:
    if ln.endswith("\r\n"):
        eol = "\r\n"
        break

# Find first exact "SystemName:" line (workflow_dispatch block)
try:
    i_system = next(i for i, l in enumerate(lines) if l.strip() == "SystemName:")
except StopIteration:
    print(f"::error::{workflow_path}: 'SystemName:' not found.")
    sys.exit(1)

# Find "options:" after SystemName
try:
    i_options = next(i for i in range(i_system + 1, len(lines)) if lines[i].strip() == "options:")
except StopIteration:
    print(f"::error::{workflow_path}: 'options:' under SystemName not found.")
    sys.exit(1)

# Determine list item indentation from first existing item, or default two spaces deeper than options:
# options indentation + two spaces + "- "
opt_indent = lines[i_options][:len(lines[i_options]) - len(lines[i_options].lstrip())]
default_item_indent = opt_indent + "  "

first_item = i_options + 1
if first_item < len(lines) and lines[first_item].lstrip().startswith("- "):
    item_indent = lines[first_item][:len(lines[first_item]) - len(lines[first_item].lstrip())]
else:
    item_indent = default_item_indent

# Consume current "- ..." lines
end = first_item
while end < len(lines):
    s = lines[end]
    # list item at same indent
    if s.startswith(item_indent) and s[len(item_indent):].startswith("- "):
        end += 1
    else:
        break

replacement = [f"{item_indent}- {name}{eol}" for name in selected]
lines[first_item:end] = replacement

workflow_path.write_text("".join(lines), encoding="utf-8", newline="")
print(f"{workflow_path}: updated SystemName options to {len(selected)} online systems (of {len(systems)} known).")
