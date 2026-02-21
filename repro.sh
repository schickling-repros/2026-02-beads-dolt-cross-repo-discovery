#!/usr/bin/env bash
set -euo pipefail

echo "=== Beads BEADS_DIR env var overrides local .beads directory ==="
echo "bd version: $(bd --version)"
echo ""

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

cd "$TMPDIR"
git init monorepo >/dev/null 2>&1
cd monorepo

# Create two projects with different beads prefixes
mkdir -p project-a/.beads
cat > project-a/.beads/config.yaml << 'YAML'
issue-prefix: "alpha"
no-db: true
YAML
cat > project-a/.beads/issues.jsonl << 'JSONL'
{"id":"alpha-abc","title":"Alpha issue one","status":"open","created_at":"2026-01-01T00:00:00Z","updated_at":"2026-01-01T00:00:00Z"}
{"id":"alpha-def","title":"Alpha issue two","status":"open","created_at":"2026-01-01T00:00:00Z","updated_at":"2026-01-01T00:00:00Z"}
JSONL

mkdir -p project-b/.beads
cat > project-b/.beads/config.yaml << 'YAML'
issue-prefix: "beta"
no-db: true
YAML
cat > project-b/.beads/issues.jsonl << 'JSONL'
{"id":"beta-xyz","title":"Beta issue one","status":"open","created_at":"2026-01-01T00:00:00Z","updated_at":"2026-01-01T00:00:00Z"}
JSONL

echo "--- 1. Without BEADS_DIR: bd correctly finds local .beads ---"
echo ""
echo "From project-a:"
(cd project-a && env -u BEADS_DIR bd where 2>&1)
echo ""
echo "From project-b:"
(cd project-b && env -u BEADS_DIR bd where 2>&1)
echo ""

echo "--- 2. With BEADS_DIR pointing to project-a: project-b is broken ---"
echo ""
echo "Simulating direnv setting BEADS_DIR for project-a:"
export BEADS_DIR="$PWD/project-a/.beads"
echo "  BEADS_DIR=$BEADS_DIR"
echo ""
echo "From project-b (should find beta, but finds alpha instead):"
(cd project-b && bd where 2>&1)
echo ""

echo "=== Bug: BEADS_DIR from parent environment overrides local .beads ==="
echo "=== This happens when direnv sets BEADS_DIR in a parent project ==="
echo "=== and child processes (agents, scripts) inherit it.           ==="
