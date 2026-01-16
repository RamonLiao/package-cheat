#!/bin/bash

################################################################################
# pkgcheat Installation Script
#
# This script helps you install pkgcheat and add it to your PATH
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PKGCHEAT_BIN="$SCRIPT_DIR/bin/pkgcheat"

echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}${BLUE}  pkgcheat Installation Script${RESET}"
echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════${RESET}"
echo ""

# Check if pkgcheat exists
if [[ ! -f "$PKGCHEAT_BIN" ]]; then
    echo -e "${RED}✗ Error: pkgcheat script not found at $PKGCHEAT_BIN${RESET}"
    exit 1
fi

# Make sure it's executable
chmod +x "$PKGCHEAT_BIN"
echo -e "${GREEN}✓ Made pkgcheat executable${RESET}"

# Detect shell
SHELL_NAME=$(basename "$SHELL")
case "$SHELL_NAME" in
    zsh)
        SHELL_CONFIG="$HOME/.zshrc"
        ;;
    bash)
        SHELL_CONFIG="$HOME/.bash_profile"
        if [[ ! -f "$SHELL_CONFIG" ]]; then
            SHELL_CONFIG="$HOME/.bashrc"
        fi
        ;;
    fish)
        SHELL_CONFIG="$HOME/.config/fish/config.fish"
        ;;
    *)
        SHELL_CONFIG=""
        ;;
esac

echo -e "${BLUE}Detected shell: ${BOLD}$SHELL_NAME${RESET}"
echo ""

# Show installation options
echo -e "${BOLD}Choose installation method:${RESET}"
echo ""
echo -e "  ${GREEN}1)${RESET} Symlink to /usr/local/bin (recommended, requires sudo)"
echo -e "  ${GREEN}2)${RESET} Symlink to ~/bin (no sudo required)"
echo -e "  ${GREEN}3)${RESET} Add to PATH in shell config"
echo -e "  ${GREEN}4)${RESET} Show manual installation instructions"
echo -e "  ${GREEN}5)${RESET} Cancel"
echo ""

read -p "Enter your choice [1-5]: " choice

case $choice in
    1)
        echo ""
        echo -e "${YELLOW}Creating symlink in /usr/local/bin (requires sudo)...${RESET}"

        if ! sudo ln -sf "$PKGCHEAT_BIN" /usr/local/bin/pkgcheat; then
            echo -e "${RED}✗ Failed to create symlink${RESET}"
            exit 1
        fi

        echo -e "${GREEN}✓ Successfully created symlink: /usr/local/bin/pkgcheat${RESET}"
        echo -e "${GREEN}✓ pkgcheat is now available in your PATH${RESET}"
        ;;

    2)
        echo ""
        echo -e "${YELLOW}Creating symlink in ~/bin...${RESET}"

        # Create ~/bin if it doesn't exist
        mkdir -p ~/bin

        # Create symlink
        ln -sf "$PKGCHEAT_BIN" ~/bin/pkgcheat

        echo -e "${GREEN}✓ Successfully created symlink: ~/bin/pkgcheat${RESET}"

        # Check if ~/bin is in PATH
        if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
            echo -e "${YELLOW}⚠ ~/bin is not in your PATH${RESET}"
            echo -e "${BLUE}Adding ~/bin to PATH in $SHELL_CONFIG...${RESET}"

            if [[ "$SHELL_NAME" == "fish" ]]; then
                echo "fish_add_path ~/bin" >> "$SHELL_CONFIG"
            else
                echo 'export PATH="$HOME/bin:$PATH"' >> "$SHELL_CONFIG"
            fi

            echo -e "${GREEN}✓ Added ~/bin to PATH${RESET}"
            echo -e "${YELLOW}⚠ Please run: ${BOLD}source $SHELL_CONFIG${RESET}"
        else
            echo -e "${GREEN}✓ ~/bin is already in your PATH${RESET}"
        fi
        ;;

    3)
        echo ""
        echo -e "${YELLOW}Adding pkgcheat bin directory to PATH...${RESET}"

        if [[ -z "$SHELL_CONFIG" ]]; then
            echo -e "${RED}✗ Could not detect shell configuration file${RESET}"
            exit 1
        fi

        # Check if already in PATH
        if grep -q "package-cheat/bin" "$SHELL_CONFIG" 2>/dev/null; then
            echo -e "${YELLOW}⚠ PATH entry already exists in $SHELL_CONFIG${RESET}"
        else
            if [[ "$SHELL_NAME" == "fish" ]]; then
                echo "fish_add_path $SCRIPT_DIR/bin" >> "$SHELL_CONFIG"
            else
                echo "export PATH=\"$SCRIPT_DIR/bin:\$PATH\"" >> "$SHELL_CONFIG"
            fi
            echo -e "${GREEN}✓ Added to $SHELL_CONFIG${RESET}"
        fi

        echo -e "${YELLOW}⚠ Please run: ${BOLD}source $SHELL_CONFIG${RESET}"
        ;;

    4)
        echo ""
        echo -e "${BOLD}${BLUE}Manual Installation Instructions:${RESET}"
        echo ""
        echo -e "${BOLD}Option A: Create a symlink${RESET}"
        echo -e "  sudo ln -s $PKGCHEAT_BIN /usr/local/bin/pkgcheat"
        echo ""
        echo -e "${BOLD}Option B: Add to PATH (for $SHELL_NAME)${RESET}"
        if [[ "$SHELL_NAME" == "fish" ]]; then
            echo -e "  echo 'fish_add_path $SCRIPT_DIR/bin' >> $SHELL_CONFIG"
        else
            echo -e "  echo 'export PATH=\"$SCRIPT_DIR/bin:\$PATH\"' >> $SHELL_CONFIG"
        fi
        echo -e "  source $SHELL_CONFIG"
        echo ""
        exit 0
        ;;

    5)
        echo -e "${YELLOW}Installation cancelled${RESET}"
        exit 0
        ;;

    *)
        echo -e "${RED}✗ Invalid choice${RESET}"
        exit 1
        ;;
esac

echo ""
echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}${GREEN}  Installation Complete!${RESET}"
echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════${RESET}"
echo ""

# Test if pkgcheat is available
if command -v pkgcheat >/dev/null 2>&1; then
    echo -e "${GREEN}✓ pkgcheat is now available!${RESET}"
    echo ""
    echo -e "Try running: ${BOLD}pkgcheat --version${RESET}"
else
    echo -e "${YELLOW}⚠ pkgcheat command not found in current session${RESET}"
    echo ""
    if [[ $choice -eq 2 ]] || [[ $choice -eq 3 ]]; then
        echo -e "Please run: ${BOLD}source $SHELL_CONFIG${RESET}"
        echo -e "Or open a new terminal window"
    fi
fi

echo ""
echo -e "For help, run: ${BOLD}pkgcheat --help${RESET}"
echo ""
