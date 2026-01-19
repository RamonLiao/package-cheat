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

# Check if package.json contains workspaces configuration
# Returns: 0 if workspaces found, 1 otherwise
has_npm_workspaces() {
    local dir_path="$1"
    local package_json="$dir_path/package.json"

    if [[ ! -f "$package_json" ]]; then
        return 1
    fi

    # Check for workspaces field using grep (avoid jq dependency for now)
    if grep -q '"workspaces"' "$package_json" 2>/dev/null; then
        return 0
    fi

    return 1
}

# Check if directory has pnpm-workspace.yaml
has_pnpm_workspaces() {
    local dir_path="$1"

    if [[ -f "$dir_path/pnpm-workspace.yaml" ]]; then
        return 0
    fi

    return 1
}

# Check if directory has lerna.json
has_lerna_workspaces() {
    local dir_path="$1"

    if [[ -f "$dir_path/lerna.json" ]]; then
        return 0
    fi

    return 1
}

# Check if directory has nx.json
has_nx_workspaces() {
    local dir_path="$1"

    if [[ -f "$dir_path/nx.json" ]]; then
        return 0
    fi

    return 1
}

# Check if directory has turbo.json
has_turbo_workspaces() {
    local dir_path="$1"

    if [[ -f "$dir_path/turbo.json" ]]; then
        return 0
    fi

    return 1
}

# Check if directory is a monorepo root
# Returns: 0 if monorepo, 1 otherwise
is_monorepo_root() {
    local dir_path="$1"

    if has_npm_workspaces "$dir_path" || \
       has_pnpm_workspaces "$dir_path" || \
       has_lerna_workspaces "$dir_path" || \
       has_nx_workspaces "$dir_path" || \
       has_turbo_workspaces "$dir_path"; then
        return 0
    fi

    return 1
}
