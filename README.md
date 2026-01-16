# Package Manager Cheatsheet (pkgcheat)

Interactive bash tool that detects installed package managers on macOS and provides quick command references, side-by-side comparisons, and search functionality.

**Bonus**: `list-all-packages.sh` - list all installed packages from all managers in one command!

## Quick Start

```bash
git clone git@github.com:RamonLiao/package-cheat.git
cd package-cheat
./install.sh
```

Then run `pkgcheat` to launch, or `./list-all-packages.sh` for a quick package list.

## Supported Package Managers

**JavaScript**: npm, pnpm, yarn, bun
**macOS**: brew, port
**Python**: pip, uv, poetry
**Other**: cargo (Rust), go (Go), gem (Ruby)

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

```bash
pkgcheat npm                # Show npm cheatsheet
pkgcheat -l                 # List detected managers
pkgcheat -s cache           # Search for "cache" commands
pkgcheat -c                 # Compare managers
pkgcheat -e npm             # Export npm cheatsheet
pkgcheat --help             # Show all options
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

## License

MIT License

---

**Need help?** Run `pkgcheat --help` or open an issue on GitHub.
