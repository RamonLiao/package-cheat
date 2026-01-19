#!/bin/bash

################################################################################
# Monorepo Handler Library - Group and format monorepo artifacts
#
# Description:
#   Handles monorepo detection, workspace grouping, and hierarchical output
################################################################################

set -eo pipefail

# Get the lib directory path
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RESET='\033[0m'

# Monorepo registry
MONOREPO_ROOTS=()          # Paths to monorepo roots
MONOREPO_ARTIFACTS=()      # Comma-separated artifact paths per monorepo

################################################################################
# Grouping Functions
################################################################################

# Group artifacts by monorepo
# Reads from global ARTIFACT_PATHS and ARTIFACT_PROJECTS arrays
group_artifacts_by_monorepo() {
    local i
    local processed_monorepos=()

    for i in "${!ARTIFACT_PATHS[@]}"; do
        local artifact_path="${ARTIFACT_PATHS[$i]}"
        local project_path="${ARTIFACT_PROJECTS[$i]}"

        # Skip if already processed
        [[ " ${processed_monorepos[@]} " =~ " ${project_path} " ]] && continue

        # Check if project is monorepo
        source "$LIB_DIR/project-detection.sh"
        if is_monorepo_root "$project_path"; then
            # Find all artifacts under this monorepo
            local mono_artifacts=()
            local j
            for j in "${!ARTIFACT_PATHS[@]}"; do
                local check_path="${ARTIFACT_PATHS[$j]}"
                # Check if artifact is under this monorepo
                if [[ "$check_path" == "$project_path"* ]]; then
                    mono_artifacts+=("$check_path")
                fi
            done

            # Store monorepo info
            MONOREPO_ROOTS+=("$project_path")
            MONOREPO_ARTIFACTS+=("$(IFS=,; echo "${mono_artifacts[*]}")")
            processed_monorepos+=("$project_path")
        fi
    done
}

# Format monorepo output with expanded artifacts
# Args: monorepo_path, artifacts_csv, total_size
format_monorepo_expanded() {
    local monorepo_path="$1"
    local artifacts_csv="$2"
    local total_size="$3"

    # Split CSV into array
    IFS=',' read -ra artifacts <<< "$artifacts_csv"
    local count=${#artifacts[@]}

    echo -e "${CYAN}Monorepo: $monorepo_path ($count artifacts, $total_size)${RESET}"

    # Display each artifact with tree indicators
    local i
    for i in "${!artifacts[@]}"; do
        local artifact="${artifacts[$i]}"
        local size=$(du -sh "$artifact" 2>/dev/null | cut -f1)

        if [[ $i -eq $((count - 1)) ]]; then
            # Last item
            printf "  └─ %-70s ${GREEN}(%s)${RESET}\\n" "$artifact" "$size"
        else
            # Not last item
            printf "  ├─ %-70s ${GREEN}(%s)${RESET}\\n" "$artifact" "$size"
        fi
    done
    echo ""
}

# Format monorepo output with summary
# Args: monorepo_path, artifacts_csv, total_size
format_monorepo_summary() {
    local monorepo_path="$1"
    local artifacts_csv="$2"
    local total_size="$3"

    # Split CSV into array
    IFS=',' read -ra artifacts <<< "$artifacts_csv"
    local count=${#artifacts[@]}

    echo -e "${CYAN}Monorepo: $monorepo_path ($total_size total, $count workspace artifacts)${RESET}"
    echo -e "  Details: Use 'pkgcheat -a-detail $monorepo_path' to see all workspaces"
    echo ""
}

# Format monorepo output (auto-choose format based on count)
# Args: monorepo_path, artifacts_csv
format_monorepo() {
    local monorepo_path="$1"
    local artifacts_csv="$2"
    local threshold=3

    # Split CSV into array
    IFS=',' read -ra artifacts <<< "$artifacts_csv"
    local count=${#artifacts[@]}

    # Calculate total size
    local total_size=$(du -shc "${artifacts[@]}" 2>/dev/null | tail -1 | cut -f1)

    if [[ $count -le $threshold ]]; then
        format_monorepo_expanded "$monorepo_path" "$artifacts_csv" "$total_size"
    else
        format_monorepo_summary "$monorepo_path" "$artifacts_csv" "$total_size"
    fi
}
