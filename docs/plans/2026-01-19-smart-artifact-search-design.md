# Smart Artifact Search with Project-Aware Pruning

**Date:** 2026-01-19
**Status:** Design
**Author:** Ramon Liao

## Overview

Improve the artifact search algorithm to be project-aware, eliminating nested artifact searches and providing intelligent monorepo handling. The new algorithm will stop at project boundaries, match artifacts to appropriate project markers, and present results in a clean, hierarchical format.

## Problem Statement

**Current Behavior:**
- Searches recursively through all directories
- Finds nested artifacts (e.g., `node_modules/pkg/node_modules`)
- No awareness of project structure or monorepos
- Results are verbose and include irrelevant nested dependencies
- Slow on large directory trees due to exhaustive searching

**Desired Behavior:**
- Stop at project-level artifacts (no nested searching)
- Detect monorepos and group workspace artifacts intelligently
- Match artifacts to appropriate project types (JS artifacts need JS markers)
- Faster execution by pruning search paths
- Clean, hierarchical output format

## Goals

1. **Project-aware search:** Use project markers to identify project roots
2. **Smart pruning:** Stop descending into artifact directories
3. **Monorepo support:** Detect and handle monorepos with workspace awareness
4. **Performance:** Significantly faster than current exhaustive search
5. **Backward compatibility:** Maintain Bash 3.2 support for macOS

## Core Algorithm Strategy

### Two-Phase Approach

**Phase 1: Project Discovery**
- Scan directories for project markers (package.json, pyproject.toml, .git, etc.)
- Build a project registry mapping each project root to its type and configuration
- Detect monorepo patterns by parsing workspace configurations
- Create a hierarchy of projects (root → workspaces)

**Phase 2: Artifact Collection with Pruning**
- Search for artifacts (node_modules, .venv) using the project registry
- When an artifact is found, check if it matches its parent project marker type
- Stop descending into artifact directories (no recursive search inside)
- For monorepos: collect all workspace artifacts and apply grouping rules

**Key Behavior Changes:**
- Current: `find` searches everything, returns all matches
- New: `find` with `-prune` stops at artifact boundaries
- Match artifacts to appropriate project types

## Project Marker Detection

### Marker Definitions by Technology

**JavaScript/Node.js Markers:**
- `package.json` - Primary marker (check for workspaces field)
- `pnpm-workspace.yaml` - PNPM monorepo indicator
- `lerna.json` - Lerna monorepo indicator
- `nx.json` - Nx monorepo indicator
- `turbo.json` - Turborepo indicator
- **Artifacts matched:** `node_modules`, `bower_components`, `.pnpm-store`

**Python Markers:**
- `pyproject.toml` - Primary marker (check for tool.poetry or tool.pdm sections)
- `setup.py` - Traditional Python package
- `requirements.txt` - Basic Python project
- `Pipfile` - Pipenv project
- `poetry.lock` - Poetry project (with pyproject.toml)
- **Artifacts matched:** `.venv`, `venv`, `env`, `.virtualenv`

**Universal Markers:**
- `.git` - Repository root (matches any artifact type)

### Monorepo Detection Logic

1. Parse `package.json` for `workspaces` array (npm/yarn/bun workspaces)
2. Detect `pnpm-workspace.yaml` and parse `packages` globs
3. Check for `lerna.json` with `packages` array
4. Check for `nx.json` and read workspace configuration
5. Identify workspace paths and treat as subprojects

## Pruning Algorithm Implementation

### Enhanced Find Command

**Current approach (searches everything):**
```bash
find /path -type d -name "node_modules"
```

**New approach (stops at artifacts):**
```bash
find /path -type d \( -name "node_modules" -o -name ".venv" \) -prune -o -type d -print
```

### Pruning Strategy

1. **Build exclusion list dynamically:** As artifacts are found, add them to a prune list
2. **Prevent nested searches:** When `node_modules` is found, don't descend into it
3. **Continue lateral searches:** After pruning, continue searching sibling directories

### Algorithm Flow

```
1. Start searching from root path
2. For each directory encountered:
   a. Check if it's an artifact (node_modules, .venv, etc.)
   b. If yes:
      - Check parent directory for matching project markers
      - If matched, record artifact and PRUNE (don't descend)
      - If not matched, skip this artifact (orphaned)
   c. If no, continue descending
3. Build project hierarchy from recorded artifacts
4. Apply monorepo grouping and threshold rules
5. Format and display results
```

### Performance Benefits

- Eliminates redundant nested scans (major time saver)
- Reduces false positives (nested node_modules in dependencies)
- Faster execution on large codebases

## Monorepo Handling and Output Formatting

### Grouping Logic

After collecting artifacts, group them by monorepo:

1. **Identify monorepo roots:** Check for workspace configurations
2. **Match workspace artifacts:** Find artifacts under workspace paths
3. **Count workspace artifacts:** Apply the 3-artifact threshold
4. **Format output accordingly**

### Output Format A (≤3 workspace artifacts)

```
━━━ node_modules - JavaScript dependencies (4 found, 1.2GB total) ━━━

Monorepo: /projects/my-monorepo (3 artifacts, 850MB)
  ├─ /projects/my-monorepo/node_modules (500MB)
  ├─ /projects/my-monorepo/packages/app1/node_modules (200MB)
  └─ /projects/my-monorepo/packages/app2/node_modules (150MB)

/projects/standalone-app/node_modules (350MB)
```

### Output Format C (>3 workspace artifacts)

```
━━━ node_modules - JavaScript dependencies (8 found, 2.1GB total) ━━━

Monorepo: /projects/my-monorepo (850MB total, 7 workspace artifacts)
  Details: Use 'pkgcheat -a-detail /projects/my-monorepo' to see all workspaces

/projects/standalone-app/node_modules (350MB)
```

### Additional Features

- New flag `-a-detail [path]` to expand summarized monorepos
- Monorepo detection persists in cache for faster subsequent runs
- Color coding: monorepo roots in cyan, workspaces indented
- Tree-style indicators (├─, └─) for visual hierarchy

## Data Structures and Caching

### Project Registry Structure

Maintain state during search using parallel arrays (Bash 3.2 compatible):

```bash
# Project registry
PROJECT_PATHS=()           # /path/to/project
PROJECT_TYPES=()           # "js", "python", "mixed", "git"
PROJECT_MONOREPO_STATUS=() # "monorepo-root", "workspace", "standalone"
PROJECT_PARENT_MONO=()     # Parent monorepo path or empty

# Artifact registry
ARTIFACT_PATHS=()          # /path/to/artifact
ARTIFACT_TYPES=()          # "node_modules", ".venv", etc.
ARTIFACT_PROJECTS=()       # Associated project path
ARTIFACT_SIZES=()          # Calculated size
```

### Caching Strategy

Improve performance on repeated runs:

**1. Project marker cache:**
- Store detected projects in `~/.pkgcheat/project-cache.db`
- Format: `path|type|monorepo_status|last_modified`
- Invalidate if directory mtime changes

**2. Workspace configuration cache:**
- Cache workspace glob patterns
- Revalidate on config file changes

**3. Cache benefits:**
- Skip re-parsing package.json files
- Faster monorepo detection on subsequent runs
- Optional `--no-cache` flag to force fresh scan

**Backward Compatibility:**
- Bash 3.2 support maintained (macOS default)
- Graceful degradation if cache directory not writable
- All features work without cache (just slower)

## Error Handling and Edge Cases

### Edge Cases to Handle

**1. Orphaned artifacts** (artifact without matching project marker):
- Report with warning flag: `[orphaned]`
- Example: `node_modules` exists but no `package.json` in parent tree
- User can decide to clean up or investigate

**2. Mixed project types** (both JS and Python markers):
- Mark as `"mixed"` project type
- Report all artifact types found
- Example: Fullstack app with `package.json` + `pyproject.toml`

**3. Nested monorepos** (rare but possible):
- Treat innermost monorepo as primary
- Outer monorepo shows inner one as single aggregated item

**4. Symlinked artifacts**:
- Skip symlinks by default (`find -type d ! -type l`)
- Prevents double-counting and infinite loops
- Optional `--follow-symlinks` flag for special cases

**5. Permission denied errors**:
- Continue search (already handled)
- Track count of inaccessible directories
- Report summary at end

**6. Workspace glob parsing failures**:
- Fall back to treating as standalone project
- Log warning if verbose mode enabled
- Don't crash the entire search

### Error Recovery

- All failures are non-fatal
- Partial results always shown
- Clear error messages with suggestions

## Implementation Impact and Migration

### Files to Modify

1. **list-all-artifacts.sh** - Core rewrite with new algorithm
2. **list-node-modules.sh** - Simplified to use shared core
3. **list-python-venvs.sh** - Simplified to use shared core
4. **New: lib/artifact-search-core.sh** - Shared search logic
5. **New: lib/project-detection.sh** - Project marker detection
6. **New: lib/monorepo-handler.sh** - Monorepo parsing and grouping
7. **bin/pkgcheat** - Update CLI flags for `-a-detail`
8. **README.md** - Document new behavior and flags

### Backward Compatibility

**Output changes:**
- Different format, but same information (more organized)
- Better visual hierarchy with tree indicators

**Performance:**
- Significantly faster (skips nested searches)

**Breaking changes:**
- Old scripts showed all nested artifacts
- New scripts show only project-level artifacts
- Users relying on seeing nested dependencies need migration notice

### Migration Strategy

1. Add `--legacy-mode` flag to preserve old behavior
2. Show migration notice on first run after update
3. Update docs with before/after examples
4. Provide `--verbose` flag to show pruning decisions

### Testing Strategy

**Test scenarios:**
- Monorepos: Nx, Turborepo, pnpm workspaces, Lerna, yarn workspaces
- Standalone projects: Simple JS and Python projects
- Mixed projects: Fullstack apps with both JS and Python
- Large directory trees: Home directory with many projects
- Edge cases: Orphaned artifacts, nested monorepos, symlinks

**Performance testing:**
- Compare execution time: old vs new algorithm
- Verify cache effectiveness on repeated runs
- Test on directories with 1000+ projects

**Correctness testing:**
- Ensure no false negatives (missing valid artifacts)
- Ensure no false positives (reporting irrelevant nested artifacts)
- Verify monorepo grouping logic
- Validate cache invalidation

## New CLI Flags

```bash
pkgcheat -a [path]              # Smart search (new algorithm)
pkgcheat -a-detail [path]       # Expand summarized monorepos
pkgcheat -a --legacy-mode       # Use old exhaustive search
pkgcheat -a --no-cache          # Force fresh scan, ignore cache
pkgcheat -a --verbose           # Show pruning decisions
pkgcheat -a --follow-symlinks   # Follow symlinked artifacts
```

## Success Criteria

1. ✓ Algorithm stops at project-level artifacts
2. ✓ Monorepos are detected and grouped intelligently
3. ✓ Artifacts match appropriate project markers
4. ✓ Search is significantly faster than current implementation
5. ✓ Output is clean, hierarchical, and easy to scan
6. ✓ Backward compatibility maintained (Bash 3.2)
7. ✓ Edge cases handled gracefully
8. ✓ Migration path provided for users

## Future Enhancements

- **Cleanup integration:** Delete orphaned artifacts
- **Analytics:** Show trends (which projects use most space)
- **Interactive mode:** Select artifacts to delete
- **Export:** Generate reports in JSON/CSV format
- **Watch mode:** Monitor for new artifacts in real-time

## References

- Current implementation: `list-all-artifacts.sh`
- Package manager markers: npm, pnpm, yarn, poetry documentation
- Monorepo tools: Nx, Turborepo, Lerna, pnpm workspaces
