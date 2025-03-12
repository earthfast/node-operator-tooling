#!/bin/bash
set -e

# Get the directory where the script is located, regardless of where it's called from
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LOG_FILE="$SCRIPT_DIR/logs/git-auto-upgrade.log"
echo "=== Starting auto-upgrade at $(date) ===" >> "$LOG_FILE"

if [ ! -d "$SCRIPT_DIR" ]; then
  echo "Error: No docker-compose directory found!" >> "$LOG_FILE"
  exit 1
fi

# Backup .env if exists
if [ -f "$SCRIPT_DIR/.env" ]; then
  cp "$SCRIPT_DIR/.env" /tmp/.env.backup
fi

# Update repository
if [ -d .git ]; then
  git fetch origin
  git reset --hard origin/main
else
  git clone "https://github.com/earthfast/node-operator-tooling" .
fi

# Restore .env
if [ -f /tmp/.env.backup ]; then
  mkdir -p "$SCRIPT_DIR"
  cp /tmp/.env.backup "$SCRIPT_DIR/.env"
  rm /tmp/.env.backup
fi

# Docker operations
cd "$SCRIPT_DIR"
COMPOSE_FILE=$(ls docker-compose.y*ml 2>/dev/null | head -n 1)

if [ -z "$COMPOSE_FILE" ]; then
  echo "Error: No docker-compose file found!" >> "$LOG_FILE"
  exit 1
fi

docker compose -f "$COMPOSE_FILE" down --remove-orphans || true
docker container prune -f
docker network prune -f

# Start services and don't fail if certbot has issues
if ! docker compose -f "$COMPOSE_FILE" up -d; then
  echo "Warning: Some services failed to start properly" >> "$LOG_FILE"
  # Check if main services are running
  if docker ps | grep -q "content-node"; then
    echo "Main content-node service is running, continuing..." >> "$LOG_FILE"
  else
    echo "Critical service content-node is not running, exiting with error" >> "$LOG_FILE"
    exit 1
  fi
fi

echo "=== Completed auto-upgrade at $(date) ===" >> "$LOG_FILE"
