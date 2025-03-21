#!/bin/bash
# Usage: ./update.sh [commit_hash]
# If commit_hash is provided, updates to that specific commit
# If no commit_hash is provided, updates to the latest commit on main
set -e

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/logs/update.log"
BRANCH_NAME="main"
COMMIT_HASH="$1"

# Create logs directory if it doesn't exist
mkdir -p "$SCRIPT_DIR/logs"
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
fi

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >>"$LOG_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "=== Starting update $([ -n "$COMMIT_HASH" ] && echo "to commit $COMMIT_HASH" || echo "to latest version") ==="

# Verify compose directory exists
if [ ! -d "$SCRIPT_DIR" ]; then
    log "Error: Invalid docker-compose directory!"
    exit 1
fi

# Find docker-compose file
COMPOSE_FILE=$(ls "$SCRIPT_DIR"/docker-compose.y*ml 2>/dev/null | head -n 1)
if [ -z "$COMPOSE_FILE" ]; then
    log "Error: No docker-compose file found!"
    exit 1
fi

# Backup .env if exists
if [ -f "$SCRIPT_DIR/.env" ]; then
    cp "$SCRIPT_DIR/.env" /tmp/.env.backup
    log "Backed up .env file"
fi

# Clean up Docker resources to free disk space
log "Cleaning up Docker resources to free disk space..."
docker system prune -af --volumes=false || log "Warning: Docker cleanup failed, but continuing"

# Update repository
cd "$SCRIPT_DIR"

if [ -n "$COMMIT_HASH" ]; then
    # Using provided commit hash
    log "Using provided commit hash: $COMMIT_HASH"

    git fetch origin
    git checkout main

    # Check if commit exists
    if ! git cat-file -e "$COMMIT_HASH^{commit}" 2>/dev/null; then
        log "Error: Commit hash $COMMIT_HASH does not exist"
        exit 1
    fi

    # Update to specific commit
    git reset --hard "$COMMIT_HASH" || {
        log "Failed to reset to commit $COMMIT_HASH"
        exit 1
    }
else
    # Auto-detect changes
    git fetch origin
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/$BRANCH_NAME)

    if [ "$LOCAL" != "$REMOTE" ]; then
        log "Changes detected, updating repository..."
        git reset --hard origin/$BRANCH_NAME || {
            log "Failed to reset to latest $BRANCH_NAME"
            exit 1
        }
        log "Successfully updated to latest commit"
    else
        log "No changes detected, skipping git update"
        # Early exit if nothing to do
        log "=== Completed update check at $(date) - no changes needed ==="
        # Clean up backup if no changes
        if [ -f /tmp/.env.backup ]; then
            rm /tmp/.env.backup
        fi
        exit 0
    fi
fi

# Restore .env
if [ -f /tmp/.env.backup ]; then
    cp /tmp/.env.backup "$SCRIPT_DIR/.env"
    rm /tmp/.env.backup
    log "Restored .env file"
fi

# Pull images first
log "Pulling Docker images..."
docker compose -f "$COMPOSE_FILE" pull || log "Warning: Docker pull failed, may use cached images"

# Restart services
log "Restarting services..."
docker compose -f "$COMPOSE_FILE" down --remove-orphans
docker compose -f "$COMPOSE_FILE" up -d

# Verify content-node service is running
sleep 5
if docker ps | grep -q "content-node"; then
    log "✓ Content node service is running"
else
    log "✗ Critical service content-node is not running, exiting with error"
    docker compose -f "$COMPOSE_FILE" logs
    exit 1
fi

log "=== Completed update at $(date) ==="
