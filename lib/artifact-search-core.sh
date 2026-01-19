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

# Find the nearest parent directory that is a project root
# Args: directory_path
# Returns: project_path or empty string if none found
find_parent_project() {
    local current_path="$1"

    # Walk up directory tree
    while [[ "$current_path" != "/" ]]; do
        local project_type=$(get_project_type "$current_path")

        if [[ "$project_type" != "none" ]]; then
            echo "$current_path"
            return 0
        fi

        # Move to parent directory
        current_path="$(dirname "$current_path")"
    done

    # No project found
    echo ""
    return 1
}

# Build find command that prunes artifact directories
# Args: search_path, artifact_names_array
# Outputs: paths to artifacts (one per line)
find_artifacts_with_pruning() {
    local search_path="$1"
    shift
    local artifact_names=("$@")

    # Build find command
    local find_cmd="find \"$search_path\" -type d ! -type l"

    # Add artifact name patterns
    local first=true
    find_cmd="$find_cmd \\("
    for artifact in "${artifact_names[@]}"; do
        if [[ "$first" == "true" ]]; then
            find_cmd="$find_cmd -name \"$artifact\""
            first=false
        else
            find_cmd="$find_cmd -o -name \"$artifact\""
        fi
    done
    find_cmd="$find_cmd \\) -print -prune"

    # Add exclusions for system directories
    find_cmd="$find_cmd ! -path '*/Library/*' ! -path '*/Applications/*' ! -path '*/System/*'"
    find_cmd="$find_cmd ! -path '*/.Trash/*' ! -path '*/Downloads/*'"
    find_cmd="$find_cmd 2>/dev/null"

    # Execute find
    eval "$find_cmd"
}

# Search for artifacts of a specific type with project validation
# Args: search_path, artifact_type ("node" or "python")
search_artifacts_by_type() {
    local search_path="$1"
    local artifact_type="$2"
    local artifacts_array=()

    # Determine which artifacts to search for
    if [[ "$artifact_type" == "node" ]]; then
        artifacts_array=("${NODE_ARTIFACTS[@]}")
    elif [[ "$artifact_type" == "python" ]]; then
        artifacts_array=("${PYTHON_ARTIFACTS[@]}")
    else
        echo "Error: Unknown artifact type: $artifact_type" >&2
        return 1
    fi

    # Find artifacts with pruning
    while IFS= read -r artifact_path; do
        [[ -z "$artifact_path" ]] && continue

        # Get artifact name
        local artifact_name="$(basename "$artifact_path")"

        # Find parent project
        local parent_dir="$(dirname "$artifact_path")"
        local parent_project=$(find_parent_project "$parent_dir")

        if [[ -n "$parent_project" ]]; then
            # Get project type
            local project_type=$(get_project_type "$parent_project")

            # Validate artifact matches project type
            if artifact_matches_project "$artifact_name" "$project_type"; then
                # Record artifact
                ARTIFACT_PATHS+=("$artifact_path")
                ARTIFACT_TYPES+=("$artifact_name")
                ARTIFACT_PROJECTS+=("$parent_project")
                echo "$artifact_path"
            fi
        fi

    done < <(find_artifacts_with_pruning "$search_path" "${artifacts_array[@]}")
}
