#!/bin/bash

################################################################################
# List Node Modules - Find all node_modules directories
#
# Description:
#   Finds and lists all node_modules directories with size information
#   This is a convenience wrapper around list-all-artifacts.sh
#
# Usage:
#   ./list-node-modules.sh [path] [OPTIONS]
################################################################################

set -eo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Temporarily modify config to only search for node_modules
CONFIG_DIR="$HOME/.pkgcheat"
CONFIG_FILE="$CONFIG_DIR/artifacts.conf"
BACKUP_FILE="$CONFIG_FILE.backup.$$"

# Create backup if config exists
if [[ -f "$CONFIG_FILE" ]]; then
    cp "$CONFIG_FILE" "$BACKUP_FILE"
fi

# Create temporary config with only node_modules enabled
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_FILE" <<'EOF'
# Temporary config for list-node-modules.sh
# Only node_modules enabled

[artifacts]
node_modules=enabled
.venv=disabled
venv=disabled
env=disabled
.virtualenv=disabled
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
