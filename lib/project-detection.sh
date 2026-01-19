#!/bin/bash

################################################################################
# Project Detection Library - Detect project markers and types
#
# Description:
#   Scans directories for project markers (package.json, pyproject.toml, etc.)
#   and identifies project types and monorepo configurations
################################################################################

set -eo pipefail

# Project registry (parallel arrays for Bash 3.2)
PROJECT_PATHS=()           # /path/to/project
PROJECT_TYPES=()           # "js", "python", "mixed", "git"
PROJECT_MONOREPO_STATUS=() # "monorepo-root", "workspace", "standalone"
PROJECT_PARENT_MONO=()     # Parent monorepo path or empty

################################################################################
# Project Marker Definitions
################################################################################

# JavaScript markers
JS_MARKERS=("package.json" "pnpm-workspace.yaml" "lerna.json" "nx.json" "turbo.json")

# Python markers
PYTHON_MARKERS=("pyproject.toml" "setup.py" "requirements.txt" "Pipfile" "poetry.lock")

# Universal markers
UNIVERSAL_MARKERS=(".git")

# Check if directory contains JavaScript project markers
has_js_markers() {
    local dir_path="$1"
    local marker

    for marker in "${JS_MARKERS[@]}"; do
        if [[ -f "$dir_path/$marker" ]]; then
            return 0  # Found JS marker
        fi
    done

    return 1  # No JS markers found
}

# Check if directory contains Python project markers
has_python_markers() {
    local dir_path="$1"
    local marker

    for marker in "${PYTHON_MARKERS[@]}"; do
        if [[ -f "$dir_path/$marker" ]]; then
            return 0  # Found Python marker
        fi
    done

    return 1  # No Python markers found
}

# Check if directory contains universal markers (like .git)
has_universal_markers() {
    local dir_path="$1"
    local marker

    for marker in "${UNIVERSAL_MARKERS[@]}"; do
        if [[ -d "$dir_path/$marker" ]] || [[ -f "$dir_path/$marker" ]]; then
            return 0  # Found universal marker
        fi
    done

    return 1  # No universal markers found
}

# Determine project type for a directory
# Returns: "js", "python", "mixed", "git", or "none"
get_project_type() {
    local dir_path="$1"
    local has_js=false
    local has_python=false
    local has_git=false

    if has_js_markers "$dir_path"; then
        has_js=true
    fi

    if has_python_markers "$dir_path"; then
        has_python=true
    fi

    if has_universal_markers "$dir_path"; then
        has_git=true
    fi

    # Determine type based on markers found
    if [[ "$has_js" == "true" ]] && [[ "$has_python" == "true" ]]; then
        echo "mixed"
    elif [[ "$has_js" == "true" ]]; then
        echo "js"
    elif [[ "$has_python" == "true" ]]; then
        echo "python"
    elif [[ "$has_git" == "true" ]]; then
        echo "git"
    else
        echo "none"
    fi
}
