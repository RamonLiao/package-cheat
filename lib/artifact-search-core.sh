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
