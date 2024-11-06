#!/bin/bash

# Color definitions (same as in setup.sh)
RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
BLUE='\\033[0;34m'
NC='\\033[0m'

# Source the .env file
if [ -f .env ]; then
    source .env
else
    echo -e "${RED}[ERROR]${NC} No .env file found!"
    exit 1
fi

# Function to handle updates
handle_updates() {
    local mode=$1
    
    case $mode in
        "enable")
            # Enable auto-updates
            sed -i 's/AUTO_UPDATES=.*/AUTO_UPDATES=true/' .env
            docker compose --profile autoupdate up -d
            echo -e "${GREEN}[SUCCESS]${NC} Auto-updates enabled"
            ;;
        "disable")
            # Disable auto-updates
            sed -i 's/AUTO_UPDATES=.*/AUTO_UPDATES=false/' .env
            docker compose stop watchtower
            docker compose rm -f watchtower
            echo -e "${GREEN}[SUCCESS]${NC} Auto-updates disabled"
            ;;
        "manual")
            # Perform manual update
            echo -e "${BLUE}[INFO]${NC} Pulling latest images..."
            docker compose pull
            echo -e "${BLUE}[INFO]${NC} Restarting services..."
            docker compose up -d
            echo -e "${GREEN}[SUCCESS]${NC} Manual update completed"
            ;;
        *)
            echo -e "${RED}[ERROR]${NC} Invalid update mode"
            exit 1
            ;;
    esac
}

# Main script
case "$1" in
    "enable")
        handle_updates "enable"
        ;;
    "disable")
        handle_updates "disable"
        ;;
    "manual")
        handle_updates "manual"
        ;;
    *)
        echo "Usage: $0 {enable|disable|manual}"
        echo "  enable  - Enable automatic updates"
        echo "  disable - Disable automatic updates"
        echo "  manual  - Perform manual update"
        exit 1
        ;;
esac
