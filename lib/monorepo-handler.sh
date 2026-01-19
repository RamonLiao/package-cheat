#!/bin/bash

################################################################################
# Monorepo Handler Library - Group and format monorepo artifacts
#
# Description:
#   Handles monorepo detection, workspace grouping, and hierarchical output
################################################################################

set -eo pipefail

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
        source "$(dirname "${BASH_SOURCE[0]}")/project-detection.sh"
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
