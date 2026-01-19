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
SCRIPT_VERSION="2.0.0"

# Source shared libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/artifact-search-core.sh"
source "$SCRIPT_DIR/lib/monorepo-handler.sh"
source "$SCRIPT_DIR/lib/excel-export.sh"

# Configuration
CONFIG_DIR="$HOME/.pkgcheat"
CONFIG_FILE="$CONFIG_DIR/artifacts.conf"

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

# Global progress tracking
FOUND_COUNT=0
LONG_SEARCH_WARNED=false
SEARCH_START_TIME=0

# Show progress during search
show_progress() {
    local count="$1"
    echo -ne "\r${CYAN}Found: $count artifacts...${RESET}                    "
}

# Clear progress line
clear_progress() {
    echo -ne "\r${GREEN}✓ Search complete${RESET}                              \n"
}

# Check if search is taking too long
check_search_time() {
    local elapsed=$(($(date +%s) - SEARCH_START_TIME))

    if [[ $elapsed -gt 10 ]] && [[ "$LONG_SEARCH_WARNED" == "false" ]]; then
        echo -e "\n${YELLOW}Searching large directory tree. This may take a few minutes...${RESET}"
        LONG_SEARCH_WARNED=true
    fi
}

# Handle Ctrl+C gracefully
handle_interrupt() {
    echo -e "\n${YELLOW}⚠ Search interrupted by user${RESET}"

    if [[ $FOUND_COUNT -gt 0 ]]; then
        echo -e "${YELLOW}Showing partial results ($FOUND_COUNT artifacts found so far)...${RESET}"
        echo ""
        # Will display results before exit
    fi

    exit 130
}

trap 'handle_interrupt' INT

################################################################################
# Configuration Management
################################################################################

# Create default configuration file
create_default_config() {
    mkdir -p "$CONFIG_DIR"

    cat > "$CONFIG_FILE" << 'EOF'
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
EOF
}

# Load configuration file
load_config() {
    # Create if doesn't exist
    if [[ ! -f "$CONFIG_FILE" ]]; then
        create_default_config
    fi

    # Parse INI-style config
    local section=""
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue

        # Parse section headers
        if [[ "$line" =~ ^\[(.+)\]$ ]]; then
            section="${BASH_REMATCH[1]}"
            continue
        fi

        # Parse key=value pairs
        if [[ "$line" =~ ^([^=]+)=(.+)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"

            case "$section" in
                artifacts)
                    # Update enabled/disabled status
                    if [[ "$value" == "enabled" ]]; then
                        # Check if it's in disabled list and move it
                        for i in "${!DISABLED_ARTIFACT_NAMES[@]}"; do
                            if [[ "${DISABLED_ARTIFACT_NAMES[$i]}" == "$key" ]]; then
                                ENABLED_ARTIFACT_NAMES+=("$key")
                                ENABLED_ARTIFACT_DESCS+=("${DISABLED_ARTIFACT_DESCS[$i]}")
                            fi
                        done
                    elif [[ "$value" == "disabled" ]]; then
                        # Remove from enabled list if present
                        local new_enabled_names=()
                        local new_enabled_descs=()
                        for i in "${!ENABLED_ARTIFACT_NAMES[@]}"; do
                            if [[ "${ENABLED_ARTIFACT_NAMES[$i]}" != "$key" ]]; then
                                new_enabled_names+=("${ENABLED_ARTIFACT_NAMES[$i]}")
                                new_enabled_descs+=("${ENABLED_ARTIFACT_DESCS[$i]}")
                            fi
                        done
                        ENABLED_ARTIFACT_NAMES=("${new_enabled_names[@]}")
                        ENABLED_ARTIFACT_DESCS=("${new_enabled_descs[@]}")
                    fi
                    ;;
                preferences)
                    if [[ "$key" == "sort_by" ]]; then
                        SORT_BY="$value"
                    fi
                    ;;
            esac
        fi
    done < "$CONFIG_FILE"

    # Validate loaded config
    validate_sort_method
}

# Validate and set sort method
validate_sort_method() {
    if [[ ! "$SORT_BY" =~ ^(size|path|date)$ ]]; then
        echo -e "${YELLOW}Warning: Invalid sort method '$SORT_BY', using 'size'${RESET}"
        SORT_BY="size"
    fi
}

################################################################################
# Main Search Logic
################################################################################

# Global arrays to store results (needed for display_results function)
artifact_paths=()
artifact_types=()

# Search for all enabled artifacts
search_all_artifacts() {
    local search_path="$1"

    # Reset global arrays
    artifact_paths=()
    artifact_types=()

    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${BOLD}${CYAN}  Project Artifacts in $search_path${RESET}"
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════${RESET}"
    echo ""

    echo -e "${YELLOW}🔍 Searching for artifacts in $search_path...${RESET}"

    SEARCH_START_TIME=$(date +%s)

    # Search for each enabled artifact type
    while IFS= read -r artifact_name; do
        [[ -z "$artifact_name" ]] && continue

        local type_paths=()

        while IFS= read -r artifact_path; do
            [[ -z "$artifact_path" ]] && continue

            artifact_paths+=("$artifact_path")
            artifact_types+=("$artifact_name")
            type_paths+=("$artifact_path")
            ((FOUND_COUNT++))
            show_progress $FOUND_COUNT
            check_search_time

        done < <(find_artifacts "$search_path" "$artifact_name")

        if [[ ${#type_paths[@]} -gt 0 ]]; then
            artifact_counts+=("${#type_paths[@]}")
        fi
    done < <(get_enabled_artifacts)

    clear_progress
    echo ""

    # Check if any artifacts found
    if [[ $FOUND_COUNT -eq 0 ]]; then
        echo -e "${YELLOW}⚠ No artifacts found in $search_path${RESET}"
        echo ""
        echo "Try:"
        echo "  • Searching a different directory"
        echo "  • Enabling more artifact types"
        echo ""
        exit 0
    fi

    # Display results
    display_results "$search_path"
}

# Display formatted results with monorepo grouping
display_results() {
    local search_path="$1"
    local total_size="0B"
    local all_paths=()

    # Group artifacts by monorepo
    group_artifacts_by_monorepo

    # Track which artifacts are displayed as part of monorepo
    local displayed_artifacts=()

    # Display monorepos first
    if [[ ${#MONOREPO_ROOTS[@]} -gt 0 ]]; then
        local i
        for i in "${!MONOREPO_ROOTS[@]}"; do
            local mono_root="${MONOREPO_ROOTS[$i]}"
            local mono_artifacts="${MONOREPO_ARTIFACTS[$i]}"

            format_monorepo "$mono_root" "$mono_artifacts"

            # Mark these artifacts as displayed
            IFS=',' read -ra arts <<< "$mono_artifacts"
            displayed_artifacts+=("${arts[@]}")
        done
    fi

    # Display standalone artifacts (not in monorepos)
    echo -e "${BOLD}${CYAN}━━━ Standalone Projects ━━━${RESET}"
    echo ""

    local i
    for i in "${!artifact_paths[@]}"; do
        local path="${artifact_paths[$i]}"

        # Skip if already displayed in monorepo
        if [[ " ${displayed_artifacts[@]} " =~ " ${path} " ]]; then
            continue
        fi

        local size=$(calculate_size "$path")
        printf "%-70s ${GREEN}(%s)${RESET}\\n" "$path" "$size"
        all_paths+=("$path")
    done

    echo ""

    # Calculate and display total
    all_paths+=("${displayed_artifacts[@]}")
    total_size=$(calculate_total_size "${all_paths[@]}")
    echo -e "${BOLD}${GREEN}✓ Complete! Found ${#all_paths[@]} artifacts using $total_size total${RESET}"
    echo ""

    # Display permission warnings if any
    if [[ $PERMISSION_ERRORS -gt 0 ]]; then
        echo -e "${YELLOW}⚠ Warning: $PERMISSION_ERRORS directories were not accessible (permission denied)${RESET}"
        echo -e "${YELLOW}  Results may be incomplete${RESET}"
        echo ""
    fi
}

# Display a single artifact type group
display_artifact_type() {
    local artifact_name="$1"
    shift
    local paths=("$@")
    local count=${#paths[@]}

    # Calculate total size for this type
    local type_total=$(calculate_total_size "${paths[@]}")

    # Display header
    local description=$(get_artifact_description "$artifact_name")
    echo -e "${BOLD}${CYAN}━━━ $artifact_name - $description ($count found, $type_total total) ━━━${RESET}"
    echo ""

    # Display each path with size
    local display_path
    for display_path in "${paths[@]}"; do
        local size=$(calculate_size "$display_path")
        printf "%-70s ${GREEN}(%s)${RESET}\n" "$display_path" "$size"
    done

    echo ""
    echo -e "${GREEN}────────────────────────────────────────────────────────${RESET}"
    echo ""
}

# Global error tracking
PERMISSION_ERRORS=0

################################################################################
# Main Execution
################################################################################

main() {
    load_config
    validate_sort_method

    # Prompt for Excel export before search
    local export_requested=false
    if prompt_excel_export; then
        export_requested=true
    fi

    # Perform search
    search_all_artifacts "$SEARCH_PATH"

    # Export to Excel if requested
    if [[ "$export_requested" == "true" ]]; then
        local timestamp=$(date +%Y-%m-%d)
        local output_file="./artifacts-$timestamp.xlsx"

        echo ""
        echo -e "${CYAN}Exporting to Excel...${RESET}"
        local exported_file=$(export_to_excel "$output_file")
        echo -e "${GREEN}✓ Export complete: $exported_file${RESET}"
        echo ""
    fi
}

main

