#!/bin/bash
# Usage: ./update.sh [tag_or_hash]
# If tag_or_hash is provided, updates the docker-compose file to use that specific image tag
# If no tag_or_hash is provided, updates to the latest commit on main
set -e

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/logs/update.log"
BRANCH_NAME="main"
IMAGE_TAG="$1"  # This can be either a commit hash or a custom image tag

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

log "=== Starting update $([ -n "$IMAGE_TAG" ] && echo "to image tag/commit $IMAGE_TAG" || echo "to latest version") ==="

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

# Check if services are running
if docker compose -f "$COMPOSE_FILE" ps 2>/dev/null | grep -q "Up"; then
    SERVICES_RUNNING=true
else
    SERVICES_RUNNING=false
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

if [ -n "$IMAGE_TAG" ]; then
    # Using provided image tag or commit hash
    log "Using provided tag/hash: $IMAGE_TAG"

    # Check if it looks like a commit hash (40 hex characters)
    if [[ $IMAGE_TAG =~ ^[0-9a-f]{40}$ ]]; then
        log "Appears to be a commit hash, checking if it exists..."
        
        git fetch origin
        git checkout main

        # Check if commit exists
        if git cat-file -e "$IMAGE_TAG^{commit}" 2>/dev/null; then
            log "Valid commit hash confirmed"
        else
            log "Warning: $IMAGE_TAG looks like a commit hash but doesn't exist in the repository"
            log "Will still attempt to use it as an image tag"
        fi
    else
        log "Using as a custom image tag"
    fi

    # Update docker-compose.yml with new image tag
    log "Updating docker-compose.yml to use image with tag: $IMAGE_TAG"
    sed -i "s|earthfast/content-node:.*|earthfast/content-node:${IMAGE_TAG}|" "$COMPOSE_FILE"
    
    # Verify the image tag was updated correctly
    if grep -q "earthfast/content-node:${IMAGE_TAG}" "$COMPOSE_FILE"; then
        log "✓ Successfully updated image tag in docker-compose file"
    else
        log "✗ Failed to update image tag in docker-compose file"
        exit 1
    fi
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

        # Check if we can exit early - only if services are also running
        if [ "$SERVICES_RUNNING" = true ]; then
            log "No changes needed and services are already running"
            log "=== Completed update check at $(date) - no changes needed ==="
            # Clean up backup if no changes
            if [ -f /tmp/.env.backup ]; then
                rm /tmp/.env.backup
            fi
            exit 0
        else
            log "No git changes, but services need to be started"
        fi
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
