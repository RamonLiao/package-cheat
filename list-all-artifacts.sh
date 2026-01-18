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

