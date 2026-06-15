#!/bin/bash
# Runs quality checks for each language whose config file is present.
# Presence of the config (e.g. python/.flake8, php/phpmd.xml) is the opt-in signal.
# Exit 0 = pass, exit 1 = violations found (with details on stdout).

ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
VIOLATIONS=""

# ===================== Python =====================
if [ -d "$ROOT/python/src" ] && [ -f "$ROOT/python/.flake8" ]; then
  cd "$ROOT/python" || exit 0

  if command -v flake8 >/dev/null 2>&1; then
    FLAKE=$(flake8 src/ 2>&1)
    [ -n "$FLAKE" ] && VIOLATIONS+="$FLAKE"$'\n'
  fi

  while IFS= read -r f; do
    LINES=$(wc -l < "$f")
    if [ "$LINES" -gt 150 ]; then
      VIOLATIONS+="$f:1:1: FILE-LENGTH File has $LINES lines (max 150)"$'\n'
    fi
  done < <(find src/ -name "*.py" ! -name "__init__.py")

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
fi

# ===================== PHP =====================
if [ -d "$ROOT/php/src" ] && [ -f "$ROOT/php/phpmd.xml" ]; then
  cd "$ROOT/php" || true

  if [ -x vendor/bin/phpmd ]; then
    PHPMD=$(vendor/bin/phpmd src text phpmd.xml 2>/dev/null | grep -v "^Deprecated:" | grep -v "^$")
    [ -n "$PHPMD" ] && VIOLATIONS+="$PHPMD"$'\n'
  fi

  while IFS= read -r f; do
    LINES=$(wc -l < "$f")
    if [ "$LINES" -gt 150 ]; then
      VIOLATIONS+="$f:1:1: FILE-LENGTH File has $LINES lines (max 150)"$'\n'
    fi
  done < <(find src/ -name "*.php")
fi

# ===================== TypeScript =====================
if [ -d "$ROOT/typescript/src" ] && [ -f "$ROOT/typescript/.eslintrc.json" ]; then
  cd "$ROOT/typescript" || true

  if [ -x node_modules/.bin/eslint ]; then
    ESLINT=$(node_modules/.bin/eslint src/ --ext .ts 2>&1)
    [ -n "$ESLINT" ] && VIOLATIONS+="$ESLINT"$'\n'
  fi

  while IFS= read -r f; do
    LINES=$(wc -l < "$f")
    if [ "$LINES" -gt 150 ]; then
      VIOLATIONS+="$f:1:1: FILE-LENGTH File has $LINES lines (max 150)"$'\n'
    fi
  done < <(find src/ -name "*.ts" ! -name "*.d.ts")
fi

if [ -n "$VIOLATIONS" ]; then
  echo "$VIOLATIONS"
  exit 1
fi

exit 0
