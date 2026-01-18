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

set -euo pipefail

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
