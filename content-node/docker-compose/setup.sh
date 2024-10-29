#!/bin/bash

# Parse command line arguments
ENVIRONMENT="testnet"  # Default environment
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --staging) ENVIRONMENT="staging";;
        *) echo "Unknown parameter: $1"; exit 1;;
    esac
    shift
done

# Update package list
sudo apt update

# Install Docker if not already installed
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    sudo apt install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
    echo "Docker installed successfully."
    DOCKER_GROUP_ADDED=true
else
    echo "Docker is already installed."
fi

# Set up Docker to run without sudo
if ! groups $USER | grep -q "\bdocker\b"; then
    sudo usermod -aG docker $USER
    echo "Added $USER to the docker group."
    DOCKER_GROUP_ADDED=true
else
    echo "User $USER is already in the docker group."
fi

# Install Docker Compose V2 if not already installed
if ! docker compose version &> /dev/null; then
    echo "Installing Docker Compose V2..."
    DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
    mkdir -p $DOCKER_CONFIG/cli-plugins
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d '"' -f 4)
    sudo curl -SL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o $DOCKER_CONFIG/cli-plugins/docker-compose
    sudo chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
    echo "Docker Compose V2 installed successfully."
else
    echo "Docker Compose V2 is already installed."
fi

# Set environment
if [ "$ENVIRONMENT" = "staging" ]; then
    echo "Selected: Testnet Sepolia Staging"
    CONTRACT_ADDRESS="0xD2362B76f79a0AbeF38E961a28E452683691890C"
else
    echo "Selected: Testnet Sepolia"
    CONTRACT_ADDRESS="0x172CEb125F6C86B7920fD391407aca0B5F416648"
fi

# Validation functions
validate_domain() {
    [[ $1 =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]
}

validate_node_id() {
    [[ $1 =~ ^0x[a-fA-F0-9]{64}$ ]]
}

validate_email() {
    [[ $1 =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]
}

validate_boolean() {
    [[ $1 =~ ^(true|false)$ ]]
}

# Get and validate inputs
echo "Configuring environment variables..."

# Server Name
while true; do
    read -p "Enter your server name (e.g., content-1.us-east-1.sepolia.earthfastnodes.com): " SERVER_NAME
    SERVER_NAME=$(echo "$SERVER_NAME" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    if validate_domain "$SERVER_NAME"; then
        break
    else
        echo "Invalid domain format. Please enter a valid domain name."
    fi
done

# Node ID
while true; do
    read -p "Enter your node ID (e.g., 0xa80a8fcc...): " NODE_ID
    NODE_ID=$(echo "$NODE_ID" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    if validate_node_id "$NODE_ID"; then
        break
    else
        echo "Invalid node ID format. Must be a 64-character hex string starting with 0x."
    fi
done

# SSL Setup
while true; do
    read -p "Do you want to set up SSL? (true/false): " SETUP_SSL
    SETUP_SSL=$(echo "$SETUP_SSL" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    if validate_boolean "$SETUP_SSL"; then
        break
    else
        echo "Please enter either 'true' or 'false'."
    fi
done

# Certbot Email
while true; do
    read -p "Enter your certbot email: " CERTBOT_EMAIL
    CERTBOT_EMAIL=$(echo "$CERTBOT_EMAIL" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    if validate_email "$CERTBOT_EMAIL"; then
        break
    else
        echo "Invalid email format. Please enter a valid email address."
    fi
done

# Create .env file
cat > .env << EOF
# Server configuration
SERVER_NAME=$SERVER_NAME
NODE_ID=$NODE_ID
SETUP_SSL=$SETUP_SSL
CERTBOT_EMAIL=$CERTBOT_EMAIL

# Content node configuration
RPC_URL=https://eth-sepolia.g.alchemy.com/v2/7xFp9qkRZTVC7CvUHODk7TgyemLtkzxt

# Contract address for EarthFast Registry
CONTRACT_ADDRESS=$CONTRACT_ADDRESS

# Data directories
HOSTING_CACHE_DIR=/hosting_cache
DATABASE_DIR=/db_data
EOF

echo ".env file created successfully!"

# Launch content node
if [ "$DOCKER_GROUP_ADDED" = true ]; then
    echo "Docker group was just added to your user account."
    echo "Please log out and log back in for the changes to take effect."
    echo "After logging back in, run 'docker compose up -d' to start the content node."
else
    read -p "Would you like to launch the content node now? (y/n): " launch_choice
    case $launch_choice in
        [Yy]*)
            echo "Launching content node..."
            sg docker -c "docker compose up -d"
            echo "Content node launched successfully!"
            ;;
        *)
            echo "Content node setup complete. You can launch it later using 'docker compose up -d'"
            ;;
    esac
fi
