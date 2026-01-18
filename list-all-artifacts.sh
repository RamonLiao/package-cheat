#!/bin/bash

################################################################################
# List All Artifacts - Project Dependency Discovery
#
# Description:
#   Finds and lists all project artifacts (node_modules, .venv, etc.)
#   Automatically detects artifacts and displays with size information
#
# Usage:
#   ./list-all-artifacts.sh [path] [--sort=size|path|date]
################################################################################

set -eo pipefail

# Colors (matching list-all-packages.sh)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Version
SCRIPT_VERSION="1.0.0"

################################################################################
# Artifact Type Definitions
################################################################################

# Artifact types to search for (Bash 3.2 compatible - using parallel arrays)
# Enabled by default
ENABLED_ARTIFACT_NAMES=("node_modules" ".venv" "venv")
ENABLED_ARTIFACT_DESCS=("JavaScript dependencies" "Python virtual environment" "Python virtual environment")

# Available but disabled by default
DISABLED_ARTIFACT_NAMES=("env" ".virtualenv" "vendor" "target")
DISABLED_ARTIFACT_DESCS=("Python virtual environment" "Python virtual environment" "PHP/Ruby dependencies" "Rust build output")

# Combined arrays for lookup
ALL_ARTIFACT_NAMES=("${ENABLED_ARTIFACT_NAMES[@]}" "${DISABLED_ARTIFACT_NAMES[@]}")

################################################################################
# Helper Functions
################################################################################

# Get list of enabled artifact names
get_enabled_artifacts() {
    printf '%s\n' "${ENABLED_ARTIFACT_NAMES[@]}"
}

# Get description for an artifact name
get_artifact_description() {
    local name="$1"
    local i

    # Check enabled artifacts
    for i in "${!ENABLED_ARTIFACT_NAMES[@]}"; do
        if [[ "${ENABLED_ARTIFACT_NAMES[$i]}" == "$name" ]]; then
            echo "${ENABLED_ARTIFACT_DESCS[$i]}"
            return
        fi
    done

    # Check disabled artifacts
    for i in "${!DISABLED_ARTIFACT_NAMES[@]}"; do
        if [[ "${DISABLED_ARTIFACT_NAMES[$i]}" == "$name" ]]; then
            echo "${DISABLED_ARTIFACT_DESCS[$i]}"
            return
        fi
    done

    echo "Unknown"
}

################################################################################
# Argument Parsing
################################################################################

# Default values
SEARCH_PATH="."
SORT_BY="size"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --sort=*)
            SORT_BY="${1#*=}"
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [path] [--sort=size|path|date]"
            echo ""
            echo "Options:"
            echo "  path              Directory to search (default: current directory)"
            echo "  --sort=METHOD     Sort by: size, path, or date (default: size)"
            echo "  --help, -h        Show this help message"
            exit 0
            ;;
        *)
            SEARCH_PATH="$1"
            shift
            ;;
    esac
done

# Convert to absolute path
SEARCH_PATH="$(cd "$SEARCH_PATH" 2>/dev/null && pwd)" || {
    echo -e "${RED}✗ Error: Directory not found: $1${RESET}"
    echo -e "${YELLOW}  Please check the path and try again${RESET}"
    exit 1
}

################################################################################
# Search Functions
################################################################################

# Find artifacts with smart exclusions
find_artifacts() {
    local search_path="$1"
    local artifact_name="$2"

    # Build exclusion patterns
    local exclusions=(
        # System directories
        "*/Library/*"
        "*/Applications/*"
        "*/System/*"
        "*/.Trash/*"
        # Nested artifacts (prevent duplicates)
        "*/node_modules/*/node_modules/*"
        "*/.venv/*/.venv/*"
        "*/venv/*/venv/*"
        # Hidden system folders
        "*/.git/*"
        "*/.cache/*"
        "*/.npm/*"
        "*/.local/*"
        "*/.config/*"
        # Common non-project directories
        "*/Downloads/*"
        "*/Movies/*"
        "*/Music/*"
        "*/Pictures/*"
        "*/Desktop/*"
    )

    # Build find command with exclusions
    local find_cmd="find \"$search_path\" -type d ! -type l -name \"$artifact_name\""

    for excl in "${exclusions[@]}"; do
        find_cmd="$find_cmd ! -path \"$excl\""
    done

    find_cmd="$find_cmd 2>/dev/null"

    # Execute find
    eval "$find_cmd"
}

# Calculate size of directory
calculate_size() {
    local dir_path="$1"
    local size

    size=$(du -sh "$dir_path" 2>/dev/null | cut -f1)

    if [[ -z "$size" ]]; then
        size="unavailable"
    fi

    echo "$size"
}

# Calculate total size from multiple directories
calculate_total_size() {
    local dirs=("$@")
    local total

    if [[ ${#dirs[@]} -eq 0 ]]; then
        echo "0B"
        return
    fi

    total=$(du -shc "${dirs[@]}" 2>/dev/null | tail -1 | cut -f1)

    if [[ -z "$total" ]]; then
        echo "unavailable"
    else
        echo "$total"
    fi
}

