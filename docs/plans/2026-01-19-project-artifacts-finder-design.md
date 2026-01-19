# Project Artifacts Finder - Design Document

**Date:** 2026-01-19
**Feature:** Unified project artifact discovery (node_modules, Python venvs, etc.)
**Status:** Design Complete - Ready for Implementation

---

## Overview

Add capability to find and list project artifacts (dependency directories, virtual environments, build outputs) across the filesystem. This complements the existing package manager cheatsheet functionality by helping users discover where dependencies are installed at the project level.

**Key Principles:**
- Simple inventory tool (not cleanup/management)
- Configurable search paths (default: current directory)
- Extensible artifact types
- Consistent with existing `list-all-packages.sh` pattern
- Smart performance optimizations

---

## Architecture & File Structure

### New Files

1. **`list-all-artifacts.sh`** - Standalone script for all artifacts
2. **`list-node-modules.sh`** - Standalone script for node_modules only
3. **`list-python-venvs.sh`** - Standalone script for Python venvs only
4. **Updates to `bin/pkgcheat`** - Add submenu system and CLI flags
5. **`~/.pkgcheat/artifacts.conf`** - User configuration file

### Script Pattern

Follow the proven `list-all-packages.sh` structure:
- Same color scheme and visual formatting
- Auto-detection with graceful skipping
- Zero configuration required (config is optional)
- Clean, scannable output

### Integration Points

**Standalone Usage:**
```bash
./list-all-artifacts.sh [path]      # All artifacts
./list-node-modules.sh [path]       # node_modules only
./list-python-venvs.sh [path]       # Python venvs only
```

**pkgcheat Interactive Menu:**
```
Main Menu
└─> Show project artifacts (node_modules, .venv, etc.)
    ├─> List all artifacts
    ├─> List node_modules only
    ├─> List Python virtual environments only
    ├─> Configure artifact types
    ├─> Change search path
    └─> Back to main menu
```

**pkgcheat CLI Flags:**
```bash
pkgcheat -a [path]           # Show all project artifacts (default: current dir)
pkgcheat --artifacts [path]  # Same as -a
pkgcheat -a-node [path]      # Show node_modules only
pkgcheat -a-python [path]    # Show Python venvs only
```

### Extensibility Design

Use associative arrays (bash 4+) to define artifact types:

```bash
declare -A ARTIFACT_TYPES=(
    ["node_modules"]="JavaScript dependencies"
    [".venv"]="Python virtual environment"
    ["venv"]="Python virtual environment"
    ["env"]="Python virtual environment"
    [".virtualenv"]="Python virtual environment"
    ["vendor"]="PHP/Ruby dependencies"
    ["target"]="Rust build output"
)
```

Easy to add more types by editing the array - no logic changes needed.

---

## Main Menu Integration

### Updated Main Menu

```
════════════════════════════════════════════════════════
  Package Manager Cheatsheet
════════════════════════════════════════════════════════

Detected Managers: npm, pnpm, brew, pip (4 total)

1) View cheatsheet for a manager
2) Compare commands across managers
3) Search commands by keyword
4) Show global packages (system-wide)
5) Show project artifacts (node_modules, .venv, etc.)
6) Export cheatsheet to markdown
7) Exit
```

**Rationale for menu labels:**
- Option 4: Clarifies "global packages" are system-wide installations
- Option 5: Parenthetical examples make it clear these are project-level artifacts
- Maintains consistency with existing menu structure

### Artifacts Submenu

```
════════════════════════════════════════════════════════
  Project Artifacts
════════════════════════════════════════════════════════

Search path: /Users/you/Projects (configurable)

1) List all artifacts
2) List node_modules only
3) List Python virtual environments only
4) Configure artifact types
5) Change search path
6) Back to main menu
```

**Submenu Features:**
- Display current search path prominently
- Direct access to filtered views (node_modules only, Python only)
- Interactive configuration without editing files
- Path selection persists for the session

---

## Search Implementation & Performance

### Search Strategy

Use `find` with smart exclusions:

```bash
find "$search_path" \
  -type d \
  ! -type l \
  -name "node_modules" \
  ! -path "*/Library/*" \
  ! -path "*/Applications/*" \
  ! -path "*/.Trash/*" \
  ! -path "*/node_modules/*/node_modules/*" \
  2>/dev/null
```

### Smart Exclusions

**System Directories (always skip):**
- `Library`, `Applications`, `System`, `.Trash`
- Prevents scanning macOS system files

**Nested Artifacts (prevent duplicates):**
- Don't search inside `node_modules` for more `node_modules`
- Skip `.venv/lib` when searching for more venvs

**Hidden System Folders:**
- `.git`, `.cache`, `.npm`, `.local`, `.config`

**Common Non-Project Directories:**
- `Downloads`, `Movies`, `Music`, `Pictures`, `Desktop`
- User can override by specifying explicit path

### Progress Indicator

Since searches can take time, show live feedback:

```bash
echo -e "${YELLOW}🔍 Searching for artifacts in $search_path...${RESET}"

# Show running count during search
found_count=0
while IFS= read -r artifact_path; do
  ((found_count++))
  echo -ne "\r${CYAN}Found: $found_count artifacts...${RESET}"
  # Process artifact...
done < <(find_artifacts)

echo -e "\r${GREEN}✓ Search complete${RESET}                    "
```

**Benefits:**
- Users know the tool is working (not frozen)
- Provides feedback during long searches
- Shows progress without overwhelming output

### Size Calculation

Use `du -sh` for human-readable sizes:

```bash
# Per artifact
artifact_size=$(du -sh "$artifact_path" 2>/dev/null | cut -f1)

# Aggregate total (sum all sizes, convert to human-readable)
total_size=$(du -shc "${all_artifacts[@]}" 2>/dev/null | tail -1 | cut -f1)
```

**Output:** `450MB`, `1.2GB`, `85KB`, etc.

### Performance Estimates

- **Current directory** (5-10 projects): ~1-3 seconds
- **~/Projects** (20-50 projects): ~5-10 seconds
- **Home directory** (50+ projects): ~10-30 seconds

Progress indicator keeps users informed during longer searches.

---

## Output Format & Display

### Output Structure

Grouped by artifact type with size summaries:

```
═══════════════════════════════════════════════════════════════
  Project Artifacts in /Users/you/Projects
═══════════════════════════════════════════════════════════════

🔍 Searching for artifacts in /Users/you/Projects...
✓ Search complete

━━━ node_modules (5 found, 2.1GB total) ━━━

/Users/you/Projects/app1/node_modules                    (450MB)
/Users/you/Projects/api/node_modules                     (620MB)
/Users/you/Projects/web/frontend/node_modules            (520MB)
/Users/you/Projects/app2/node_modules                    (380MB)
/Users/you/Projects/tools/scripts/node_modules           (180MB)

────────────────────────────────────────────────────────

━━━ Python Virtual Environments (3 found, 890MB total) ━━━

/Users/you/Projects/ml-project/.venv                     (450MB)
/Users/you/Projects/api/venv                             (320MB)
/Users/you/Projects/scripts/.venv                        (120MB)

────────────────────────────────────────────────────────

✓ Complete! Found 8 artifacts using 3.0GB total
```

### Color Scheme

Matches `list-all-packages.sh` for consistency:

- **Headers:** Bold Cyan (`${BOLD}${CYAN}`)
- **Paths:** Default white
- **Sizes:** Green (`${GREEN}`)
- **Totals:** Bold Green (`${BOLD}${GREEN}`)
- **Progress/Status:** Yellow (`${YELLOW}`)
- **Separators:** Green (`${GREEN}`)

### Sorting Options

**Configurable via CLI flag and config file:**

```bash
# Default: by size (largest first)
pkgcheat -a

# Sort alphabetically by path
pkgcheat -a --sort=path

# Sort by modification date
pkgcheat -a --sort=date
```

**Config file:**
```ini
[preferences]
sort_by=size
# Options: size, path, date
```

**Sort Methods:**
- **size** (default): Largest first - helps identify space hogs
- **path**: Alphabetical - easier navigation to specific projects
- **date**: Most recently modified first - find active projects

### Empty Results

```
═══════════════════════════════════════════════════════════════
  Project Artifacts in /Users/you/EmptyProject
═══════════════════════════════════════════════════════════════

🔍 Searching for artifacts in /Users/you/EmptyProject...
✓ Search complete

⚠ No artifacts found in /Users/you/EmptyProject

Try:
  • Searching a different directory
  • Enabling more artifact types (pkgcheat → Configure artifacts)
```

---

## Configuration System

### Config File

**Location:** `~/.pkgcheat/artifacts.conf`

**Format (INI-style):**
```ini
# pkgcheat artifact configuration
# Enable/disable artifact types and set preferences

[artifacts]
node_modules=enabled
.venv=enabled
venv=enabled
env=disabled
.virtualenv=disabled
vendor=disabled
target=disabled

[preferences]
sort_by=size
# Options: size, path, date
```

### Default Enabled Artifacts

Start with most common use cases:
- `node_modules` - JavaScript/Node.js dependencies
- `.venv` - Python virtual environment (modern standard)
- `venv` - Python virtual environment (common pattern)

### Available But Disabled by Default

Users can enable via interactive config:
- `env`, `.virtualenv` - Less common Python patterns
- `vendor` - PHP (Composer), Ruby (Bundler) dependencies
- `target` - Rust build output
- `.gradle`, `build` - Java/Android build artifacts
- `__pycache__`, `.pytest_cache` - Python cache directories

### Configuration UI

Interactive menu in "Configure artifact types":

```
════════════════════════════════════════════════════════
  Configure Artifact Types
════════════════════════════════════════════════════════

JavaScript:
  [✓] node_modules

Python:
  [✓] .venv
  [✓] venv
  [ ] env
  [ ] .virtualenv

Other Languages:
  [ ] vendor (PHP/Ruby)
  [ ] target (Rust)

Cache Directories:
  [ ] __pycache__ (Python)
  [ ] .pytest_cache (Python)

Preferences:
  Sort by: [size] path date

Commands:
  1-15) Toggle item
  s) Change sort preference
  r) Reset to defaults
  d) Done (save and exit)
```

### Config Management

**Auto-creation:**
```bash
if [[ ! -f "$CONFIG_FILE" ]]; then
  mkdir -p "$(dirname "$CONFIG_FILE")"
  create_default_config
fi
```

**Validation:**
```bash
# Load config with fallback to defaults
load_config() {
  if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE" 2>/dev/null || {
      echo "Warning: Config file corrupted, using defaults"
      create_default_config
    }
  else
    create_default_config
  fi
}
```

---

## Error Handling & Edge Cases

### Permission Errors

Some directories may not be readable:

```bash
# Suppress permission errors, show warning at end
denied_count=$(find "$path" 2>&1 >/dev/null | grep -c "Permission denied")

if [[ $denied_count -gt 0 ]]; then
  echo -e "${YELLOW}⚠ Warning: $denied_count directories were not accessible (permission denied)${RESET}"
  echo -e "${YELLOW}  Results may be incomplete${RESET}"
fi
```

### Invalid Paths

```bash
if [[ ! -d "$search_path" ]]; then
  echo -e "${RED}✗ Error: Directory not found: $search_path${RESET}"
  echo -e "${YELLOW}  Please check the path and try again${RESET}"
  exit 1
fi
```

### No Results Found

```bash
if [[ $total_found -eq 0 ]]; then
  echo -e "${YELLOW}⚠ No artifacts found in $search_path${RESET}"
  echo ""
  echo "Suggestions:"
  echo "  • Try searching a different directory"
  echo "  • Enable more artifact types (pkgcheat → Configure artifacts)"
  echo "  • Check if you have any projects in this location"
  exit 0
fi
```

### Interrupted Search (Ctrl+C)

```bash
# Trap interrupt signal
trap 'handle_interrupt' INT

handle_interrupt() {
  echo -e "\n${YELLOW}⚠ Search interrupted by user${RESET}"

  if [[ $found_count -gt 0 ]]; then
    echo -e "${YELLOW}Showing partial results (${found_count} artifacts found so far)...${RESET}"
    echo ""
    display_results
  fi

  exit 130
}
```

### Size Calculation Failures

If `du` fails on a directory (permissions, symlinks, etc.):

```bash
size=$(du -sh "$artifact_path" 2>/dev/null | cut -f1)
if [[ -z "$size" ]]; then
  size="unavailable"
fi

# Display with fallback
printf "%-60s %s\n" "$artifact_path" "($size)"
```

### Config File Issues

**Missing config:**
- Create silently with defaults on first run
- No user notification needed

**Corrupted config:**
```bash
if ! source "$CONFIG_FILE" 2>/dev/null; then
  echo -e "${YELLOW}⚠ Config file is corrupted${RESET}"
  echo "Reset to defaults? (y/n)"
  read -r response
  if [[ "$response" == "y" ]]; then
    create_default_config
    echo -e "${GREEN}✓ Config reset to defaults${RESET}"
  fi
fi
```

**Invalid values:**
```bash
# Validate sort preference
if [[ ! "$sort_by" =~ ^(size|path|date)$ ]]; then
  echo "Warning: Invalid sort_by value in config, using 'size'"
  sort_by="size"
fi
```

### Very Large Searches

For searches taking >30 seconds, provide estimate:

```bash
# After 10 seconds, show extended message
if [[ $elapsed_time -gt 10 ]] && [[ ! $long_search_warned ]]; then
  echo -e "${YELLOW}Searching large directory tree. This may take a few minutes...${RESET}"
  long_search_warned=true
fi
```

### Symlink Handling

Skip symlinks to avoid:
- Infinite loops (circular symlinks)
- Duplicate counting
- Following system links outside intended scope

```bash
find "$path" -type d ! -type l -name "node_modules"
#                    ^^^^^^^^^ Ignore symlinks
```

### Empty Artifacts

Some artifacts may exist but be empty (0 bytes):

```bash
# Still list them, but show size as 0
/Users/you/Projects/new-project/node_modules              (0B)
```

This helps users identify incomplete installations.

---

## Implementation Checklist

### Phase 1: Core Functionality
- [ ] Create `list-all-artifacts.sh` with basic search
- [ ] Implement smart exclusions
- [ ] Add size calculation
- [ ] Create output formatting with colors
- [ ] Add progress indicator

### Phase 2: Specialized Scripts
- [ ] Create `list-node-modules.sh`
- [ ] Create `list-python-venvs.sh`
- [ ] Ensure consistent interface across all scripts

### Phase 3: Configuration System
- [ ] Define config file format
- [ ] Implement config creation/loading
- [ ] Add validation and error handling
- [ ] Create interactive config UI

### Phase 4: pkgcheat Integration
- [ ] Add submenu to main menu
- [ ] Create artifacts submenu structure
- [ ] Add CLI flags (-a, -a-node, -a-python)
- [ ] Update help text
- [ ] Wire submenu options to standalone scripts

### Phase 5: Polish & Testing
- [ ] Test with various directory structures
- [ ] Test permission error handling
- [ ] Test interrupt handling (Ctrl+C)
- [ ] Verify sorting options work correctly
- [ ] Test on empty directories
- [ ] Test config corruption scenarios
- [ ] Performance testing on large directories

### Phase 6: Documentation
- [ ] Update README with new features
- [ ] Add examples to help text
- [ ] Document config file format
- [ ] Add troubleshooting section

---

## Future Enhancements (Out of Scope)

These are explicitly NOT part of this design but could be considered later:

- **Cleanup functionality** - Delete artifacts to reclaim space
- **Project analysis** - Identify unused dependencies
- **Export to CSV/JSON** - Machine-readable output
- **Watch mode** - Monitor for new artifacts
- **Duplicate detection** - Find identical node_modules
- **Age-based filtering** - Find artifacts older than X days

Keep the initial implementation focused on discovery and inventory.

---

## Success Criteria

This feature will be considered successful when:

1. ✅ Users can find all project artifacts with a single command
2. ✅ Standalone scripts work without pkgcheat installation
3. ✅ Search completes in reasonable time (<30s for home directory)
4. ✅ Output is clear, scannable, and includes size information
5. ✅ Configuration persists across sessions
6. ✅ Integration feels natural within pkgcheat menu
7. ✅ Error handling gracefully manages edge cases
8. ✅ Performance is acceptable on large directory trees

---

## Technical Notes

### Bash Version Requirement

Requires Bash 4.0+ for associative arrays:
```bash
if ((BASH_VERSINFO[0] < 4)); then
  echo "Error: Bash 4.0 or higher required"
  exit 1
fi
```

macOS ships with Bash 3.2 by default. Users may need to install newer Bash via Homebrew.

**Alternative:** Use indexed arrays with parallel arrays instead of associative arrays for Bash 3.2 compatibility.

### Path Handling

Always quote paths to handle spaces:
```bash
du -sh "$artifact_path"  # Correct
du -sh $artifact_path    # Breaks on paths with spaces
```

### Performance Considerations

- `find` is faster than recursive shell loops
- Use `-print0` and `while IFS= read -r -d ''` for paths with special characters
- Limit search depth if needed: `find -maxdepth 5`

---

**Design Status:** ✅ Complete and ready for implementation

**Next Steps:**
1. Review and approve this design
2. Create implementation plan with detailed task breakdown
3. Begin Phase 1 implementation
