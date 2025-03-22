#!/bin/bash
# Auto-upgrade script for cron jobs - automatically updates to latest version
set -e

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Call update.sh without any parameters to update to latest version
"$SCRIPT_DIR/update.sh"
