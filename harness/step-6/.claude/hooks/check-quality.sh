#!/bin/bash
# Runs quality checks on python/src and outputs violations.
# Exit 0 = pass, exit 1 = violations found (with details on stdout).

ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
cd "$ROOT/python" 2>/dev/null || exit 0

VIOLATIONS=""

# 1. flake8 checks (function length, complexity, magic numbers, class attrs, etc.)
FLAKE=$(flake8 src/ 2>&1)
[ -n "$FLAKE" ] && VIOLATIONS+="$FLAKE"$'\n'

# 2. File length check (max 150 lines per file)
while IFS= read -r f; do
  LINES=$(wc -l < "$f")
  if [ "$LINES" -gt 150 ]; then
    VIOLATIONS+="$f:1:1: FILE-LENGTH File has $LINES lines (max 150)"$'\n'
  fi
done < <(find src/ -name "*.py" ! -name "__init__.py")

# 3. Class instance attribute count (max 6, including private)
#    WPS230 only counts public attrs — this catches all self.* assignments in __init__
ATTR_CHECK=$(python3 -c "
import ast, sys, os
max_attrs = 6
for root, dirs, files in os.walk('src'):
    for fname in files:
        if not fname.endswith('.py') or fname == '__init__.py':
            continue
        path = os.path.join(root, fname)
        with open(path) as f:
            try:
                tree = ast.parse(f.read())
            except SyntaxError:
                continue
        for node in ast.walk(tree):
            if not isinstance(node, ast.ClassDef):
                continue
            init_attrs = set()
            for child in ast.walk(node):
                if isinstance(child, ast.FunctionDef) and child.name == '__init__':
                    for n in ast.walk(child):
                        if (isinstance(n, ast.Attribute)
                            and isinstance(n.ctx, ast.Store)
                            and isinstance(n.value, ast.Name)
                            and n.value.id == 'self'):
                            init_attrs.add(n.attr)
            if len(init_attrs) > max_attrs:
                print(f'{path}:{node.lineno}:1: CLASS-ATTRS Class {node.name} has {len(init_attrs)} instance attributes (max {max_attrs}): {sorted(init_attrs)}')
" 2>&1)
[ -n "$ATTR_CHECK" ] && VIOLATIONS+="$ATTR_CHECK"$'\n'

if [ -n "$VIOLATIONS" ]; then
  echo "$VIOLATIONS"
  exit 1
fi

exit 0
