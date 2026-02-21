# Beads -- Dolt database discovery crosses repo boundaries in shared git root

When multiple logical repos live under a shared git root (monorepo, megarepo, or similar composition tools), `bd` discovers and uses `.beads/dolt/` databases from sibling repos instead of the local one.

## Reproduction

```bash
# Requires bd on PATH (tested with v0.55.4)
bash repro.sh
```

## Expected

`bd list` from `repo-b/` shows only `beta-*` issues from `repo-b/.beads/issues.jsonl`.

## Actual

`bd list` from `repo-b/` discovers `repo-a/.beads/` and shows `alpha-*` issues (or a mix), because `findDatabaseInTree()` walks up to `git rev-parse --show-toplevel` which encompasses both repos.

## Root Cause

`findDatabaseInTree()` in `internal/beads/beads.go` uses the git root as the boundary for its upward directory walk. In a shared-root structure (monorepo, composition tools), the git root is the monorepo root, not the individual project root. The walk crosses project boundaries and finds `.beads/` directories from sibling projects.

Config-based mitigations don't help because `config.Initialize()` also walks the tree:
- `no-db: true` -- ignored when Dolt is discovered from sibling
- `db: ".beads/beads.db"` -- overridden by sibling's Dolt
- `BEADS_DB` env var -- same issue
- `--sandbox` -- only disables daemon/flush, not DB discovery

## Workaround

Set `BEADS_DIR` explicitly to prevent the tree walk:

```bash
export BEADS_DIR="$PWD/.beads"  # in .envrc
```

Or use the `--db` CLI flag which bypasses auto-discovery entirely.

## Suggested Fix

`findDatabaseInTree()` should stop at the **nearest** `.beads/` directory rather than walking all the way to git root. If the CWD is inside `repo-b/subdir/`, and `repo-b/.beads/` exists, the walk should stop there -- it should not continue up to find `repo-a/.beads/`.

## Versions

- beads: v0.55.4
- OS: macOS (Darwin 25.2.0)

## Related Issues

- [steveyegge/beads#1833](https://github.com/steveyegge/beads/issues/1833) -- `no-db: true` broken in v0.50+ (related: config override doesn't prevent Dolt discovery)
- [steveyegge/beads#437](https://github.com/steveyegge/beads/issues/437) -- Multi-repo mode writes foreign issues to non-primary repo (related: cross-repo contamination)
