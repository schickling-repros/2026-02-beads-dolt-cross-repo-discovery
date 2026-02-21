#!/usr/bin/env bash
set -euo pipefail

echo "=== Beads Dolt cross-repo discovery repro ==="
echo "bd version: $(bd --version)"
echo ""

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

# Create a single git repo as the shared root
cd "$TMPDIR"
git init monorepo
cd monorepo

# Create repo-a with alpha prefix
mkdir -p repo-a/.beads
cat > repo-a/.beads/config.yaml << 'YAML'
issue-prefix: "alpha"
no-db: true
YAML

cat > repo-a/.beads/issues.jsonl << 'JSONL'
{"id":"alpha-abc","title":"Alpha issue one","status":"open","created_at":"2026-01-01T00:00:00Z","updated_at":"2026-01-01T00:00:00Z"}
{"id":"alpha-def","title":"Alpha issue two","status":"open","created_at":"2026-01-01T00:00:00Z","updated_at":"2026-01-01T00:00:00Z"}
JSONL

# Create repo-b with beta prefix
mkdir -p repo-b/.beads
cat > repo-b/.beads/config.yaml << 'YAML'
issue-prefix: "beta"
no-db: true
YAML

cat > repo-b/.beads/issues.jsonl << 'JSONL'
{"id":"beta-xyz","title":"Beta issue one","status":"open","created_at":"2026-01-01T00:00:00Z","updated_at":"2026-01-01T00:00:00Z"}
JSONL

echo "=== Expected: repo-b should show only beta-* issues ==="
echo ""

echo "--- bd list from repo-b (no workaround) ---"
cd repo-b
bd list 2>&1 || true
echo ""

echo "--- bd list from repo-b with BEADS_DIR workaround ---"
BEADS_DIR="$PWD/.beads" bd list 2>&1 || true
echo ""

echo "--- bd list from repo-a for comparison ---"
cd ../repo-a
bd list 2>&1 || true
echo ""

echo "=== If bug is present: repo-b picks up alpha-* issues from repo-a ==="
echo "=== Workaround: BEADS_DIR=\$PWD/.beads forces correct local .beads ==="
