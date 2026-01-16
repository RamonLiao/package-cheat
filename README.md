# Package Manager Cheatsheet (pkgcheat)

An interactive bash script that detects installed package managers on macOS and provides a comprehensive command reference with cheatsheets, comparison views, search functionality, and markdown export capabilities.

**Bonus:** Includes `list-all-packages` - a simple script to quickly list all installed packages from all detected package managers.

## Quick Start

Just cloned the repo? Get started in 3 commands:

```bash
git clone git@github.com:RamonLiao/package-cheat.git
cd package-cheat
./install.sh
```

That's it! The installer will guide you through the setup. Once installed:
- Type `pkgcheat` to launch the interactive cheatsheet
- Type `list-all-packages` to quickly list all your installed packages

## Features

- 🔍 **Auto-detection** - Automatically detects all installed package managers on your system
- 📚 **Comprehensive Cheatsheets** - Quick reference for common commands across multiple package managers
- 🔄 **Side-by-Side Comparison** - Compare equivalent commands across different JavaScript package managers
- 🔎 **Search Functionality** - Search for commands across all detected package managers
- 📦 **Global Package Listing** - List all globally installed packages from all package managers in one view
- 📄 **Markdown Export** - Export cheatsheets to markdown files for offline reference
- 🎨 **Color-Coded Output** - Easy-to-read color-coded terminal output
- 🌐 **Multi-Language Support** - Covers package managers for JavaScript, Python, Rust, Go, Ruby, and macOS system packages

## Supported Package Managers

### JavaScript/Node.js
- **npm** - Node Package Manager
- **pnpm** - Performant npm
- **yarn** - Package manager by Facebook
- **bun** - All-in-one JavaScript runtime and toolkit

### macOS System
- **brew** - Homebrew package manager
- **port** - MacPorts package manager

### Python
- **pip** - Python package installer
- **uv** - Ultra-fast Python package installer
- **poetry** - Python dependency management and packaging

### Other Languages
- **cargo** - Rust package manager
- **go** - Go module manager
- **gem** - RubyGems package manager

## Installation

### Prerequisites

- macOS (tested on macOS 10.15+)
- Bash 4.0+ (macOS default bash or newer)
- At least one package manager installed

### Quick Install (Automated)

The easiest way to install pkgcheat is using the automated installation script:

```bash
# Clone the repository (you can clone it anywhere)
git clone git@github.com:RamonLiao/package-cheat.git
cd package-cheat

# Run the installer
./install.sh
```

The installation script will:
- Detect your shell (zsh, bash, or fish)
- Offer multiple installation methods
- Automatically configure your PATH
- Verify the installation

### Manual Installation

If you prefer to install manually:

1. **Clone the repository:**

```bash
# Clone to any location you prefer
git clone git@github.com:RamonLiao/package-cheat.git
cd package-cheat
```

2. **Make the script executable:**

```bash
chmod +x bin/pkgcheat
```

3. **Add to PATH** (choose one method):

#### Option A: Create a symlink in a directory already in PATH

```bash
# Get the full path to the script (run this from the package-cheat directory)
PKGCHEAT_PATH="$(pwd)/bin/pkgcheat"

# Most common location (requires sudo)
sudo ln -s "$PKGCHEAT_PATH" /usr/local/bin/pkgcheat

# Alternative: User-local bin directory (no sudo required)
mkdir -p ~/bin
ln -s "$PKGCHEAT_PATH" ~/bin/pkgcheat
```

#### Option B: Add the bin directory to your PATH

**For Zsh (macOS Catalina and later default):**

```bash
# From the package-cheat directory
echo "export PATH=\"$(pwd)/bin:\$PATH\"" >> ~/.zshrc
source ~/.zshrc
```

**For Bash:**

```bash
# From the package-cheat directory
echo "export PATH=\"$(pwd)/bin:\$PATH\"" >> ~/.bash_profile
source ~/.bash_profile
```

**For Fish:**

```bash
# From the package-cheat directory
fish_add_path "$(pwd)/bin"
```

4. **Verify installation:**

```bash
pkgcheat --version
# Should output: pkgcheat version 1.0.0
```

### Uninstallation

**If you created a symlink:**
```bash
sudo rm /usr/local/bin/pkgcheat
# OR
rm ~/bin/pkgcheat
```

**If you added to PATH:**
Edit your shell configuration file (`~/.zshrc`, `~/.bash_profile`, or `~/.config/fish/config.fish`) and remove the line that adds the package-cheat bin directory to PATH.

## Usage

### Interactive Mode (Recommended)

Launch the interactive menu by running the command without arguments:

```bash
pkgcheat
```

You'll see a menu with the following options:

```
1) Show detected package managers    - View all package managers found on your system
2) View cheatsheet for a manager     - Browse detailed command reference for a specific manager
3) Compare managers side-by-side     - Compare equivalent commands across JS package managers
4) Search for commands               - Search for commands by keyword across all managers
5) Export cheatsheet to markdown     - Export cheatsheets to .md files
6) Help / Usage information          - Display help and usage information
7) List all global packages          - List globally installed packages from all managers
8) Exit                              - Exit the application
```

### Command-Line Mode

Run specific operations directly from the command line:

#### Display a specific manager's cheatsheet

```bash
pkgcheat npm
pkgcheat brew
pkgcheat pnpm
```

#### List detected package managers

```bash
pkgcheat --list
# OR
pkgcheat -l
```

#### Search for commands

```bash
pkgcheat --search cache
pkgcheat -s install
```

Search results will show matching commands across all detected package managers.

#### Show all supported managers

```bash
pkgcheat --all
# OR
pkgcheat -a
```

This shows all package managers (both installed and not installed).

#### Export cheatsheets to markdown

```bash
# Export all detected managers
pkgcheat --export all
pkgcheat -e

# Export specific manager
pkgcheat --export npm
pkgcheat -e brew
```

Exported files are saved to your home directory with a timestamp:
- `~/pkgcheat-export-all-YYYYMMDD_HHMMSS.md`
- `~/pkgcheat-export-npm-YYYYMMDD_HHMMSS.md`

#### Compare commands

```bash
pkgcheat --compare
# OR
pkgcheat -c
```

This launches an interactive comparison tool for JavaScript package managers.

#### Display help

```bash
pkgcheat --help
# OR
pkgcheat -h
```

#### Display version

```bash
pkgcheat --version
# OR
pkgcheat -v
```

## list-all-packages - Quick Package Listing

A simple companion script that quickly lists all installed packages from all detected package managers. Perfect for when you just want to see what's installed without the interactive menu.

### Usage

```bash
# List all packages from all detected managers
list-all-packages

# Show help
list-all-packages --help

# Show version
list-all-packages --version
```

### Features

- **Automatic Detection**: Only lists from installed package managers
- **Smart Skipping**: Automatically skips package managers that aren't installed (e.g., if you don't have cargo, it won't try to list Rust packages)
- **Clean Output**: Color-coded output with clear sections for each package manager
- **No Interaction Required**: Just run and see all your packages
- **Version Display**: Shows the version of each package manager

### Example Output

```bash
$ list-all-packages

═══════════════════════════════════════════════════════════════
  List All Installed Packages
═══════════════════════════════════════════════════════════════

━━━ npm (11.7.0) ━━━

/Users/username/.nvm/versions/node/v24.12.0/lib
├── corepack@0.34.5
└── npm@11.7.0

✓ Listed successfully
────────────────────────────────────────────────────────

━━━ brew (5.0.10) ━━━

uv
antigravity-tools
claude-code

✓ Listed successfully
────────────────────────────────────────────────────────

✓ Complete! Listed packages from 6 package manager(s).
```

### Supported Package Managers

Same as `pkgcheat`: npm, pnpm, yarn, bun, brew, port, pip, uv, poetry, cargo, go, gem

## Examples

### Example 1: Quick Reference for npm

```bash
$ pkgcheat npm

═══════════════════════════════════════════════════════════════
  npm Cheatsheet
═══════════════════════════════════════════════════════════════

Operation            Command                                            Description
────────────────────────────────────────────────────────────────────────────────────────────────────
install              npm install <package>                              Install a package locally
install_global       npm install -g <package>                           Install a package globally
update               npm update                                         Update all packages
list_global          npm list -g --depth=0                              List global packages
cache_clean          npm cache clean --force                            Clear npm cache
...
```

### Example 2: Search for Cache Commands

```bash
$ pkgcheat -s cache

═══════════════════════════════════════════════════════════════
  Search Results for: cache
═══════════════════════════════════════════════════════════════

[npm]
  cache_clean          npm cache clean --force                     Clear npm cache

[pnpm]
  cache_clean          pnpm store prune                            Clear pnpm store/cache

[yarn]
  cache_clean          yarn cache clean                            Clear yarn cache

[pip]
  cache_purge          pip cache purge                             Clear pip cache

Found 8 matching command(s)
```

### Example 3: List All Global Packages

```bash
$ pkgcheat
# Select option 7: List all global packages

═══════════════════════════════════════════════════════════════
  Global Packages Across All Package Managers
═══════════════════════════════════════════════════════════════

━━━ npm (11.7.0) ━━━

/Users/username/.nvm/versions/node/v24.12.0/lib
├── corepack@0.34.5
└── npm@11.7.0

✓ Listed successfully

────────────────────────────────────────────────────────────

━━━ pnpm (10.28.0) ━━━

Legend: production dependency, optional only, dev only

/Users/username/Library/pnpm/global/5

dependencies:
eslint 9.39.2
prettier 3.8.0

✓ Listed successfully

────────────────────────────────────────────────────────────
...
```

### Example 4: Export All Cheatsheets

```bash
$ pkgcheat -e all

═══════════════════════════════════════════════════════════════
  Exporting Cheatsheet(s)
═══════════════════════════════════════════════════════════════

✓ Exported successfully!
File: /Users/username/pkgcheat-export-all-20260116_143022.md
```

### Example 5: Compare Package Managers

```bash
$ pkgcheat -c
# Select option 1: install

═══════════════════════════════════════════════════════════════
  Command Comparison: install
═══════════════════════════════════════════════════════════════

Manager      Command
────────────────────────────────────────────────────────────────────────
npm          npm install <package>
pnpm         pnpm add <package>
yarn         yarn add <package>
bun          bun add <package>
```

## Cheatsheet Coverage

Each package manager cheatsheet includes commands for:

- **Installation** - Install packages (local, global, dev dependencies)
- **Updates** - Update packages and the package manager itself
- **Removal** - Uninstall packages
- **Listing** - List installed packages and dependencies
- **Search** - Search for packages in registries
- **Information** - Get package details and metadata
- **Cache Management** - Clear and manage package caches
- **Auditing** - Security audits and vulnerability fixes
- **Project Initialization** - Initialize new projects
- **Script Execution** - Run project scripts
- **Development Tools** - Build, test, and development commands

## File Structure

```
package-cheat/
├── bin/
│   ├── pkgcheat              # Main interactive cheatsheet tool
│   └── list-all-packages     # Simple package listing script
├── install.sh                 # Automated installation script
└── README.md                  # This file
```

## Quick Reference Card

### Most Common Operations

| Task | npm | pnpm | yarn | brew |
|------|-----|------|------|------|
| Install package | `npm install <pkg>` | `pnpm add <pkg>` | `yarn add <pkg>` | `brew install <pkg>` |
| Install globally | `npm install -g <pkg>` | `pnpm add -g <pkg>` | `yarn global add <pkg>` | N/A (all packages are global) |
| Update all | `npm update` | `pnpm update` | `yarn upgrade` | `brew upgrade` |
| Remove package | `npm uninstall <pkg>` | `pnpm remove <pkg>` | `yarn remove <pkg>` | `brew uninstall <pkg>` |
| List installed | `npm list` | `pnpm list` | `yarn list` | `brew list` |
| List global | `npm list -g --depth=0` | `pnpm list -g` | `yarn global list` | `brew list` |
| Search packages | `npm search <pkg>` | `pnpm search <pkg>` | `yarn search <pkg>` | `brew search <pkg>` |
| Clear cache | `npm cache clean --force` | `pnpm store prune` | `yarn cache clean` | `brew cleanup` |
| Check outdated | `npm outdated` | `pnpm outdated` | `yarn outdated` | `brew outdated` |

Use `pkgcheat` to explore more commands and options!

## Troubleshooting

### Command not found

If you get "command not found" after installation:

1. Verify the script is executable:
   ```bash
   # Navigate to your package-cheat directory first
   ls -la bin/pkgcheat
   ```
   Look for `-rwxr-xr-x` permissions.

2. Check if the directory is in your PATH:
   ```bash
   echo $PATH
   ```
   Look for `/usr/local/bin` or `~/bin` or the package-cheat bin directory.

3. If using the PATH method, make sure you sourced your shell config:
   ```bash
   source ~/.zshrc  # for Zsh
   source ~/.bash_profile  # for Bash
   ```

4. Try running with full path:
   ```bash
   # From the package-cheat directory
   ./bin/pkgcheat

   # Or with absolute path
   /path/to/your/package-cheat/bin/pkgcheat
   ```

### No package managers detected

If the script reports "No package managers detected":

1. Verify you have at least one package manager installed:
   ```bash
   which npm pnpm yarn brew pip
   ```

2. Make sure the package manager is in your PATH:
   ```bash
   echo $PATH
   ```

### Permission denied

If you get "Permission denied":

```bash
# Navigate to your package-cheat directory first
chmod +x bin/pkgcheat
```

### Colors not displaying

If colors aren't showing correctly:

1. Ensure your terminal supports ANSI color codes
2. Try a different terminal emulator (iTerm2, Hyper, etc.)
3. Check your terminal's color scheme settings

## Advanced Usage

### Customizing the Script

The script is highly modular and can be customized by editing:

- **Command Definitions** (lines 66-295): Add or modify commands for each package manager
- **Color Schemes** (lines 36-43): Customize colors by modifying ANSI color codes
- **Detection Logic** (lines 408-435): Add new package managers or modify detection

### Adding a New Package Manager

1. Add the manager to the appropriate category array (lines 56-59)
2. Define the commands array following the existing pattern
3. Add version detection logic in `get_version()` (lines 330-365)
4. Add category mapping in `get_category()` (lines 368-402)

## Contributing

Contributions are welcome! Please ensure:

- Commands are accurate and follow best practices
- Code follows the existing bash style
- Changes are tested on macOS
- Documentation is updated

## Version History

- **1.0.0** - Initial release
  - Auto-detection of 12 package managers
  - Interactive menu system
  - Search and comparison features
  - Markdown export
  - Global package listing

## License

MIT License - feel free to use and modify as needed.

## Credits

Developed as part of the Silent Alpha project.

## Support

For issues, questions, or suggestions:
- Check the troubleshooting section above
- Review the help information: `pkgcheat --help`
- Report issues on the project repository

---

**Enjoy your unified package manager reference! 🚀**
