#!/bin/bash
# Stop hook: hard-blocks the agent from finishing if quality violations exist.
# Exit 2 = block (stderr sent to agent), exit 0 = allow.

ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
VIOLATIONS=$("$ROOT/.claude/hooks/check-quality.sh" 2>&1)

if [ -n "$VIOLATIONS" ]; then
  echo "QUALITY GATE FAILED — fix these violations before finishing:" >&2
  echo "" >&2
  echo "$VIOLATIONS" >&2
  echo "" >&2
  echo "Refactor: extract methods, reduce nesting, split files, introduce constants." >&2
  exit 2
fi

exit 0
