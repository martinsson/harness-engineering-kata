#!/bin/bash
# Sets up the Step 7 mechanical quality gate for a chosen language.
# Installs quality tools, copies harness configs, and creates the setup commits/tags.
#
# Usage: ./setup.sh <language>
#   ./setup.sh php
#   ./setup.sh typescript
#
# After running: restart your Claude Code session, then:
#   implement the feature from feature.md

set -euo pipefail

LANG="${1:-}"

usage() {
  echo "Usage: $0 <language>"
  echo "  Languages: php, typescript"
  exit 1
}

[ -z "$LANG" ] && usage
[ "$LANG" != "php" ] && [ "$LANG" != "typescript" ] && usage

ROOT=$(git rev-parse --show-toplevel)
cd "$ROOT"

echo "==> Setting up Step 7 kata for: $LANG"

# ---- Install language tools ----
echo ""
echo "--- Installing $LANG tools ---"
case "$LANG" in
  php)
    (cd php && composer install --no-interaction)
    ;;
  typescript)
    (cd typescript && pnpm install)
    ;;
esac

# ---- Step 6: copy harness files ----
echo ""
echo "--- Activating step 6 harness ---"

mkdir -p .claude/hooks
cp harness/step-6/.claude/hooks/*.sh .claude/hooks/
chmod +x .claude/hooks/*.sh

# Copy only the quality config for the chosen language.
# Its presence is what tells check-quality.sh which language to check.
case "$LANG" in
  php)
    cp harness/step-6/php/phpmd.xml php/phpmd.xml
    ;;
  typescript)
    cp harness/step-6/typescript/.eslintrc.json typescript/.eslintrc.json
    ;;
esac

# Step 6 uses a reviewer agent stop hook
cp harness/step-6/settings.json .claude/settings.json

git add -A
git commit -m "step 6 setup ($LANG)"
git tag -f step-6-setup
echo "Tagged: step-6-setup"

# ---- Step 7: switch to mechanical hard block ----
echo ""
echo "--- Switching to step 7 mechanical gate ---"

cp harness/step-7/settings.json .claude/settings.json

git add -A
git commit -m "step 7 setup ($LANG)"
git tag -f step-7-setup
echo "Tagged: step-7-setup"

# ---- Done ----
echo ""
echo "==> Ready! Restart your Claude Code session, then run:"
echo ""
echo "    implement the feature from feature.md"
echo ""
