#!/bin/bash

################################################################################
# List All Packages - Standalone Script
#
# Description:
#   Lists all installed packages from all detected package managers
#   Automatically skips package managers that aren't installed
#
# Usage:
#   ./list-all-packages.sh
################################################################################

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}${CYAN}  Listing All Installed Packages${RESET}"
echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════${RESET}"
echo ""

# Counter for detected managers
detected=0

# Check and list npm packages
if command -v npm >/dev/null 2>&1; then
    echo -e "${BOLD}${CYAN}━━━ npm ($(npm --version 2>/dev/null)) ━━━${RESET}"
    echo ""
    npm list -g --depth=0 2>/dev/null
    echo ""
    echo -e "${GREEN}────────────────────────────────────────────────────────${RESET}"
    echo ""
    ((detected++))
fi

# Check and list pnpm packages
if command -v pnpm >/dev/null 2>&1; then
    echo -e "${BOLD}${CYAN}━━━ pnpm ($(pnpm --version 2>/dev/null)) ━━━${RESET}"
    echo ""
    pnpm list -g 2>/dev/null
    echo ""
    echo -e "${GREEN}────────────────────────────────────────────────────────${RESET}"
    echo ""
    ((detected++))
fi

# Check and list yarn packages
if command -v yarn >/dev/null 2>&1; then
    echo -e "${BOLD}${CYAN}━━━ yarn ($(yarn --version 2>/dev/null)) ━━━${RESET}"
    echo ""
    yarn global list 2>/dev/null
    echo ""
    echo -e "${GREEN}────────────────────────────────────────────────────────${RESET}"
    echo ""
    ((detected++))
fi

# Check and list bun packages
if command -v bun >/dev/null 2>&1; then
    echo -e "${BOLD}${CYAN}━━━ bun ($(bun --version 2>/dev/null)) ━━━${RESET}"
    echo ""
    bun pm ls -g 2>/dev/null
    echo ""
    echo -e "${GREEN}────────────────────────────────────────────────────────${RESET}"
    echo ""
    ((detected++))
fi

# Check and list brew packages
if command -v brew >/dev/null 2>&1; then
    echo -e "${BOLD}${CYAN}━━━ brew ($(brew --version 2>/dev/null | head -1 | awk '{print $2}')) ━━━${RESET}"
    echo ""
    brew list 2>/dev/null
    echo ""
    echo -e "${GREEN}────────────────────────────────────────────────────────${RESET}"
    echo ""
    ((detected++))
fi

# Check and list port packages
if command -v port >/dev/null 2>&1; then
    echo -e "${BOLD}${CYAN}━━━ port ($(port version 2>/dev/null | awk '{print $2}')) ━━━${RESET}"
    echo ""
    port installed 2>/dev/null
    echo ""
    echo -e "${GREEN}────────────────────────────────────────────────────────${RESET}"
    echo ""
    ((detected++))
fi

# Check and list pip packages
if command -v pip >/dev/null 2>&1; then
    echo -e "${BOLD}${CYAN}━━━ pip ($(pip --version 2>/dev/null | awk '{print $2}')) ━━━${RESET}"
    echo ""
    pip list 2>/dev/null
    echo ""
    echo -e "${GREEN}────────────────────────────────────────────────────────${RESET}"
    echo ""
    ((detected++))
fi

# Check and list uv packages
if command -v uv >/dev/null 2>&1; then
    echo -e "${BOLD}${CYAN}━━━ uv ($(uv --version 2>/dev/null | awk '{print $2}')) ━━━${RESET}"
    echo ""
    uv pip list 2>/dev/null
    echo ""
    echo -e "${GREEN}────────────────────────────────────────────────────────${RESET}"
    echo ""
    ((detected++))
fi

# Check and list poetry packages
if command -v poetry >/dev/null 2>&1; then
    echo -e "${BOLD}${CYAN}━━━ poetry ($(poetry --version 2>/dev/null | awk '{print $3}')) ━━━${RESET}"
    echo ""
    poetry show 2>/dev/null
    echo ""
    echo -e "${GREEN}────────────────────────────────────────────────────────${RESET}"
    echo ""
    ((detected++))
fi

# Check and list cargo packages
if command -v cargo >/dev/null 2>&1; then
    echo -e "${BOLD}${CYAN}━━━ cargo ($(cargo --version 2>/dev/null | awk '{print $2}')) ━━━${RESET}"
    echo ""
    cargo install --list 2>/dev/null
    echo ""
    echo -e "${GREEN}────────────────────────────────────────────────────────${RESET}"
    echo ""
    ((detected++))
fi

# Check and list go packages
if command -v go >/dev/null 2>&1; then
    echo -e "${BOLD}${CYAN}━━━ go ($(go version 2>/dev/null | awk '{print $3}' | sed 's/go//')) ━━━${RESET}"
    echo ""
    if [[ -n "$GOPATH" ]]; then
        echo "Go binaries in \$GOPATH/bin:"
        ls -1 "$GOPATH/bin" 2>/dev/null || echo "No binaries found"
    else
        echo -e "${YELLOW}GOPATH not set - cannot list Go packages${RESET}"
    fi
    echo ""
    echo -e "${GREEN}────────────────────────────────────────────────────────${RESET}"
    echo ""
    ((detected++))
fi

# Check and list gem packages
if command -v gem >/dev/null 2>&1; then
    echo -e "${BOLD}${CYAN}━━━ gem ($(gem --version 2>/dev/null)) ━━━${RESET}"
    echo ""
    gem list 2>/dev/null
    echo ""
    echo -e "${GREEN}────────────────────────────────────────────────────────${RESET}"
    echo ""
    ((detected++))
fi

# Summary
echo ""
if [[ $detected -eq 0 ]]; then
    echo -e "${YELLOW}⚠ No package managers detected on this system${RESET}"
else
    echo -e "${BOLD}${GREEN}✓ Complete! Listed packages from $detected package manager(s)${RESET}"
fi
echo ""
