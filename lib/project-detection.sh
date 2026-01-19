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
