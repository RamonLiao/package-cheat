#!/bin/bash

################################################################################
# Artifact Search Core Library - Project-aware artifact search with pruning
#
# Description:
#   Implements two-phase search algorithm:
#   1. Project discovery - find and categorize project roots
#   2. Artifact collection - find artifacts with intelligent pruning
################################################################################

set -eo pipefail

# Source project detection library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/project-detection.sh"

# Artifact registry (parallel arrays for Bash 3.2)
ARTIFACT_PATHS=()          # /path/to/artifact
ARTIFACT_TYPES=()          # "node_modules", ".venv", etc.
ARTIFACT_PROJECTS=()       # Associated project path
ARTIFACT_SIZES=()          # Calculated size

# Artifact type definitions
NODE_ARTIFACTS=("node_modules" "bower_components" ".pnpm-store")
PYTHON_ARTIFACTS=(".venv" "venv" "env" ".virtualenv")

# Check if artifact type matches project type
# Args: artifact_name, project_type
# Returns: 0 if valid match, 1 otherwise
artifact_matches_project() {
    local artifact_name="$1"
    local project_type="$2"
    local artifact

    # Universal markers (.git) match any artifact
    if [[ "$project_type" == "git" ]] || [[ "$project_type" == "mixed" ]]; then
        return 0
    fi

    # Check if artifact is a Node artifact and project is JS
    if [[ "$project_type" == "js" ]]; then
        for artifact in "${NODE_ARTIFACTS[@]}"; do
            if [[ "$artifact_name" == "$artifact" ]]; then
                return 0
            fi
        done
    fi

    # Check if artifact is a Python artifact and project is Python
    if [[ "$project_type" == "python" ]]; then
        for artifact in "${PYTHON_ARTIFACTS[@]}"; do
            if [[ "$artifact_name" == "$artifact" ]]; then
                return 0
            fi
        done
    fi

    return 1  # No match
}
