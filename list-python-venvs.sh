#!/bin/bash

################################################################################
# List Python Virtual Environments - Find all .venv, venv directories
#
# Description:
#   Finds and lists all Python virtual environments with size information
#   This is a convenience wrapper around list-all-artifacts.sh
#
# Usage:
#   ./list-python-venvs.sh [path] [OPTIONS]
################################################################################

set -eo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Temporarily modify config to only search for Python venvs
CONFIG_DIR="$HOME/.pkgcheat"
CONFIG_FILE="$CONFIG_DIR/artifacts.conf"
BACKUP_FILE="$CONFIG_FILE.backup.$$"

# Create backup if config exists
if [[ -f "$CONFIG_FILE" ]]; then
    cp "$CONFIG_FILE" "$BACKUP_FILE"
fi

# Create temporary config with only Python venvs enabled
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_FILE" <<'EOF'
# Temporary config for list-python-venvs.sh
# Only Python virtual environments enabled

[artifacts]
node_modules=disabled
.venv=enabled
venv=enabled
env=enabled
.virtualenv=enabled
vendor=disabled
target=disabled

[preferences]
sort_by=size
EOF

# Trap to restore config on exit
cleanup() {
    if [[ -f "$BACKUP_FILE" ]]; then
        mv "$BACKUP_FILE" "$CONFIG_FILE"
    fi
}
trap cleanup EXIT INT TERM

# Call list-all-artifacts.sh with all arguments
"$SCRIPT_DIR/list-all-artifacts.sh" "$@"
