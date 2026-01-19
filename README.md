# Package Manager Cheatsheet (pkgcheat)

Interactive bash tool that detects installed package managers on macOS and provides quick command references, side-by-side comparisons, and search functionality.

**New**: Project artifact discovery - find all `node_modules`, `.venv`, and other dependency directories across your filesystem!

**Bonus**: `list-all-packages.sh` - list all installed packages from all managers in one command!

## Quick Start

```bash
git clone git@github.com:RamonLiao/package-cheat.git
cd package-cheat
./install.sh
```

Then run `pkgcheat` to launch, or `./list-all-packages.sh` for a quick package list.

## Features

- **Package Manager Cheatsheets** - Quick command reference for all detected managers
- **Side-by-Side Comparison** - Compare equivalent commands across managers
- **Search Functionality** - Find commands by keyword
- **Global Package Lists** - View all installed packages system-wide
- **Project Artifact Discovery** - Find node_modules, .venv, and other project dependencies
- **Export to Markdown** - Save cheatsheets for offline reference

## Supported Package Managers

- **JavaScript**: npm, pnpm, yarn, bun
- **macOS**: brew, port
- **Python**: pip, uv, poetry
- **Other**: cargo (Rust), go (Go), gem (Ruby)

## Usage

### Interactive Mode

```bash
pkgcheat
```

Opens a menu where you can:
- View cheatsheets for any detected manager
- Compare equivalent commands across managers
- Search for commands by keyword
- List all globally installed packages
- Export cheatsheets to markdown

### Command Line

**Format**: `pkgcheat [OPTIONS] [MANAGER]`

```bash
pkgcheat npm                # Show npm cheatsheet
pkgcheat -l                 # List detected managers
pkgcheat -s cache           # Search for "cache" commands
pkgcheat -c                 # Compare managers
pkgcheat -e npm             # Export npm cheatsheet
pkgcheat -a ~/Projects      # Find all artifacts in ~/Projects
pkgcheat -a-node .          # Find node_modules only
pkgcheat -a-python .        # Find Python venvs only
pkgcheat --help             # Show all options
```

### Artifact Discovery

Find project dependencies and virtual environments across your filesystem.

**New in v2.0**: Smart artifact search with project-aware detection and monorepo grouping!

**Interactive Mode:**
```bash
pkgcheat
# Select "Show project artifacts (node_modules, .venv, etc.)"
```

**Command Line:**
```bash
pkgcheat -a [path]           # List all artifacts (smart mode)
pkgcheat -a-node [path]      # List node_modules only
pkgcheat -a-python [path]    # List Python venvs only
```

**Standalone Scripts:**
```bash
./list-all-artifacts.sh ~/Projects                  # Smart search with monorepo detection
./list-all-artifacts.sh ~/Projects --legacy-mode    # v1.0 behavior
./list-all-artifacts.sh ~/Projects --verbose        # Show detailed progress
./list-node-modules.sh ~/Projects
./list-python-venvs.sh ~/Projects
```

**V2.0 Features:**

**Smart Search** (default):
- Project-aware: Only shows artifacts that match their project type (e.g., node_modules only in JavaScript projects)
- Monorepo detection: Automatically detects and groups artifacts by monorepo workspace
- Intelligent pruning: Stops searching at artifact boundaries for better performance

**Monorepo Support:**
Automatically detects and groups artifacts in monorepos:
- npm workspaces
- pnpm workspaces
- lerna
- nx
- turborepo

Example output for monorepos:
```
Monorepo: /path/to/monorepo (5 artifacts, 2.3GB)
  ├─ /path/to/monorepo/node_modules (1.2GB)
  ├─ /path/to/monorepo/packages/app1/node_modules (500MB)
  └─ /path/to/monorepo/packages/app2/node_modules (600MB)
```

**CLI Flags:**
```bash
--legacy-mode           # Use v1.0 behavior (no project detection or monorepo grouping)
--verbose, -v           # Show detailed search progress and diagnostics
--follow-symlinks       # Follow symbolic links during search
--sort=METHOD           # Sort by: size, path, or date
```

**Configuration:**

Customize which artifacts to search for:
```bash
pkgcheat
# Navigate to: Show project artifacts → Configure artifact types
```

Or edit `~/.pkgcheat/artifacts.conf` directly.

**Examples:**

Find all artifacts in your projects directory:
```bash
pkgcheat -a ~/Projects
```

Find large node_modules directories:
```bash
pkgcheat -a-node ~ --sort=size
```

Find recently modified Python virtual environments:
```bash
pkgcheat -a-python ~/Projects --sort=date
```

Quick inventory of current project:
```bash
cd my-project
pkgcheat -a .
```

Use legacy mode for simple flat list:
```bash
./list-all-artifacts.sh ~/Projects --legacy-mode
```

Export results to Excel:
```bash
./list-all-artifacts.sh ~/Projects
# Prompts: "Export results to Excel? [y/N]:"
# Creates: ./artifacts-2026-01-19.xlsx
```

## list-all-packages.sh

Standalone script to quickly list all installed packages from all detected managers.

```bash
# Run directly (no installation needed)
./list-all-packages.sh

# Or make it globally available
sudo ln -s "$(pwd)/list-all-packages.sh" /usr/local/bin/list-all-packages
list-all-packages
```

**Features**:
- Zero configuration
- Auto-detects installed managers
- Auto-skips missing managers (e.g., if you don't have cargo, it's automatically skipped)
- Clean, color-coded output

## Common Commands Quick Reference

| Task | npm | pnpm | yarn | brew |
|------|-----|------|------|------|
| Install | `npm install <pkg>` | `pnpm add <pkg>` | `yarn add <pkg>` | `brew install <pkg>` |
| Install globally | `npm install -g <pkg>` | `pnpm add -g <pkg>` | `yarn global add <pkg>` | N/A |
| Update all | `npm update` | `pnpm update` | `yarn upgrade` | `brew upgrade` |
| Remove | `npm uninstall <pkg>` | `pnpm remove <pkg>` | `yarn remove <pkg>` | `brew uninstall <pkg>` |
| List global | `npm list -g --depth=0` | `pnpm list -g` | `yarn global list` | `brew list` |
| Clear cache | `npm cache clean --force` | `pnpm store prune` | `yarn cache clean` | `brew cleanup` |

Use `pkgcheat` to explore more commands!

## Manual Installation

If the installer doesn't work, manually add to PATH:

```bash
# Clone and enter directory
git clone git@github.com:RamonLiao/package-cheat.git
cd package-cheat

# Make executable
chmod +x bin/pkgcheat

# Option 1: Symlink to /usr/local/bin (requires sudo)
sudo ln -s "$(pwd)/bin/pkgcheat" /usr/local/bin/pkgcheat

# Option 2: Add to PATH in shell config
echo "export PATH=\"$(pwd)/bin:\$PATH\"" >> ~/.zshrc
source ~/.zshrc

# Verify
pkgcheat --version
```

## Troubleshooting

**Command not found**:
```bash
# Check if executable
ls -la bin/pkgcheat

# Re-source shell config
source ~/.zshrc  # or ~/.bash_profile for Bash

# Or run directly
./bin/pkgcheat
```

**Permission denied**:
```bash
chmod +x bin/pkgcheat
```

**No managers detected**:
```bash
# Verify you have at least one installed
which npm pnpm yarn brew pip
```

**No artifacts found**:
- Check search path is correct
- Enable more artifact types in configuration
- Verify you have projects with dependencies in the search location

**Permission denied warnings (artifacts)**:
- Normal when searching system directories
- Results show accessible artifacts only
- Use specific project paths to avoid system directories

**Slow artifact searches**:
- Searching home directory can take time with many projects
- Use more specific paths (e.g., `~/Projects` instead of `~`)
- Progress indicator shows search is working

**Config file issues**:
- Delete `~/.pkgcheat/artifacts.conf` to reset
- Or use the "Reset to defaults" option in configuration menu

## License

MIT License

---

**Need help?** Run `pkgcheat --help` or open an issue on GitHub.
