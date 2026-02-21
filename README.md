# Beads — BEADS_DIR env var overrides local .beads directory

When `BEADS_DIR` is set in the environment (e.g. via direnv in a parent project), `bd` always uses that directory regardless of CWD or the presence of a local `.beads/` directory. This causes cross-contamination when working across multiple beads-enabled projects.

## Reproduction

```bash
# Requires bd on PATH (tested with v0.55.4)
bash repro.sh
```

## Expected

When `bd` is run from `project-b/` which has its own `.beads/config.yaml`, it should use `project-b/.beads/` — the local `.beads/` directory should take precedence over the inherited `BEADS_DIR` environment variable.

## Actual

`bd where` from `project-b/` reports `project-a/.beads/` because `BEADS_DIR` (inherited from the parent environment) takes unconditional precedence over the local `.beads/` directory.

## Root Cause

`BEADS_DIR` is checked first in `FindBeadsDir()` and `FindDatabasePath()`, before any local directory walk. When a project configures `BEADS_DIR` via direnv (or similar), all child processes inherit it — including `bd` invocations in other repos with their own `.beads/` directories.

## Suggested Fix

When a local `.beads/` directory exists at or above CWD (within git root), it should take precedence over `BEADS_DIR`. The env var should only serve as a fallback when no local `.beads/` is found.

Alternatively, document that `BEADS_DIR` is a per-project setting that should not leak to child processes, and recommend `env -u BEADS_DIR bd ...` or project-specific overrides.

## Workaround

Unset `BEADS_DIR` before running `bd` in other projects:

```bash
env -u BEADS_DIR bd list
```

Or set `BEADS_DIR` per-project in each project's `.envrc`.

## Versions

- beads: v0.55.4
- OS: macOS (Darwin 25.2.0)

## Related Issues

- #1833 — `no-db: true` config option broken in v0.50+
- steveyegge/beads#1951

## Related Issue

- https://github.com/steveyegge/beads/issues/1951
