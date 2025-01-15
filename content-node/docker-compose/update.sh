#!/bin/bash

# Script to update content node
# Usage: ./update.sh [commit_hash]
# If commit_hash is not provided, pulls latest changes and uses existing hash

set -e # Exit on any error

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check if command succeeded
check_status() {
    if [ $? -eq 0 ]; then
        log "✓ $1"
    else
        log "✗ $1"
        exit 1
    fi
}

# Update git repository
log "Updating git repository..."
git checkout -- docker-compose.yml || true # Reset any local changes
check_status "Reset docker-compose file"

git checkout main
check_status "Checkout main branch"

git pull
check_status "Pull latest changes"

if [ -n "$1" ]; then
    # Use provided commit hash
    COMMIT_HASH=$1
    log "Using provided commit hash: $COMMIT_HASH"
    
    # Update docker-compose.yml with new image tag
    log "Updating docker-compose.yml with new image tag..."
    sed -i "s|earthfast/content-node:.*|earthfast/content-node:${COMMIT_HASH}|" docker-compose.yml
    check_status "Update image tag in docker-compose.yml"
else
    # Extract current hash from docker-compose.yml
    CURRENT_HASH=$(grep "earthfast/content-node:" docker-compose.yml | sed 's/.*earthfast\/content-node:\([^ ]*\).*/\1/')
    log "Using existing commit hash: $CURRENT_HASH"
fi

# Verify the image tag
HASH_TO_USE=${COMMIT_HASH:-$CURRENT_HASH}
log "Verifying image tag..."
grep "earthfast/content-node:${HASH_TO_USE}" docker-compose.yml > /dev/null
check_status "Verify image tag in docker-compose.yml"

# Pull new image
log "Pulling docker image..."
docker compose pull
check_status "Pull docker image"

# Restart services
log "Restarting services..."
docker compose down
check_status "Stop services"

docker compose up -d --remove-orphans
check_status "Start services"

# Verify service is running
sleep 5
if docker compose ps | grep -q "Up"; then
    log "✓ Service is running"
else
    log "✗ Service failed to start"
    docker compose logs
    exit 1
fi

log "Update completed successfully with hash: $HASH_TO_USE"
