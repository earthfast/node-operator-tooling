#!/bin/bash
# Usage: ./auto-upgrade.sh [commit_hash]
# If commit_hash is not provided, pulls latest changes from main branch
set -e

# Get the directory where the script is located, regardless of where it's called from
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/logs/git-auto-upgrade.log"
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

# Function to check if command succeeded
check_status() {
  if [ $? -eq 0 ]; then
    log "✓ $1"
  else
    log "✗ $1"
    return 1
  fi
}

log "=== Starting auto-upgrade ==="

if [ ! -d "$SCRIPT_DIR" ]; then
  log "Error: No docker-compose directory found!"
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

  log "Successfully updated to commit: $COMMIT_HASH"
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
  fi
fi

# Restore .env
if [ -f /tmp/.env.backup ]; then
  cp /tmp/.env.backup "$SCRIPT_DIR/.env"
  rm /tmp/.env.backup
  log "Restored .env file"
fi

# Pull images first before taking down services
log "Pulling Docker images..."
docker compose -f "$COMPOSE_FILE" pull || log "Warning: Docker pull failed, may use cached images"

# Stop services
log "Stopping services..."
docker compose -f "$COMPOSE_FILE" down --remove-orphans

# Start services
log "Starting services..."
if ! docker compose -f "$COMPOSE_FILE" up -d; then
  log "Warning: Some services failed to start properly"
else
  log "Services started successfully"
fi

# Verify content-node service is running
sleep 5
if docker ps | grep -q "content-node"; then
  log "✓ Content node service is running"
else
  log "✗ Critical service content-node is not running, exiting with error"
  docker compose -f "$COMPOSE_FILE" logs
  exit 1
fi

log "=== Completed auto-upgrade at $(date) ==="
