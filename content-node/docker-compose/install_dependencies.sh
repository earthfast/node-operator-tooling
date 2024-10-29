#!/bin/bash

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
else
    echo "Docker is already installed."
fi

# Set up Docker to run without sudo
if ! groups $USER | grep -q "\bdocker\b"; then
    sudo usermod -aG docker $USER
    echo "Added $USER to the docker group."
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

# Function to prompt for environment selection
select_environment() {
    echo "Please select the environment:"
    echo "1) Testnet Sepolia"
    echo "2) Testnet Sepolia Staging"
    read -p "Enter your choice (1-2): " env_choice

    case $env_choice in
        1)
            echo "Selected: Testnet Sepolia"
            CONTRACT_ADDRESS="0x172CEb125F6C86B7920fD391407aca0B5F416648"
            ;;
        2)
            echo "Selected: Testnet Sepolia Staging"
            CONTRACT_ADDRESS="0xD2362B76f79a0AbeF38E961a28E452683691890C"
            ;;
        *)
            echo "Invalid choice. Defaulting to Testnet Sepolia"
            CONTRACT_ADDRESS="0x172CEb125F6C86B7920fD391407aca0B5F416648"
            ;;
    esac
}

# Function to create .env file
create_env_file() {
    echo "Configuring environment variables..."
    # Collect required information
    read -p "Enter your server name (e.g., content-1.us-east-1.sepolia.earthfastnodes.com): " server_name
    read -p "Enter your node ID (e.g., 0xa80a8fcc...): " node_id
    read -p "Do you want to set up SSL? (true/false): " setup_ssl
    read -p "Enter your certbot email: " certbot_email

    # Create .env file
    cat > .env << EOF
# Server configuration
SERVER_NAME=$server_name
NODE_ID=$node_id
SETUP_SSL=$setup_ssl
CERTBOT_EMAIL=$certbot_email

# Content node configuration
RPC_URL=https://eth-sepolia.g.alchemy.com/v2/7xFp9qkRZTVC7CvUHODk7TgyemLtkzxt

# Contract address for EarthFast Registry
CONTRACT_ADDRESS=$CONTRACT_ADDRESS

# Data directories
HOSTING_CACHE_DIR=/hosting_cache
DATABASE_DIR=/db_data
EOF

    echo ".env file created successfully!"
}

# Function to launch content node
launch_content_node() {
    read -p "Would you like to launch the content node now? (y/n): " launch_choice
    case $launch_choice in
        [Yy]*)
            echo "Launching content node..."
            docker compose up -d
            echo "Content node launched successfully!"
            ;;
        *)
            echo "Content node setup complete. You can launch it later using 'docker compose up -d'"
            ;;
    esac
}

# Execute the remaining commands in a new shell with the docker group
sg docker -c "
    select_environment
    create_env_file
    launch_content_node
"
