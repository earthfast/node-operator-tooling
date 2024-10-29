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

# Function to validate domain name format
validate_domain() {
    local domain=$1
    if [[ ! $domain =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 1
    fi
    return 0
}

# Function to validate node ID format (hex string starting with 0x)
validate_node_id() {
    local node_id=$1
    if [[ ! $node_id =~ ^0x[a-fA-F0-9]{64}$ ]]; then
        return 1
    fi
    return 0
}

# Function to validate email format
validate_email() {
    local email=$1
    if [[ ! $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 1
    fi
    return 0
}

# Function to validate boolean input
validate_boolean() {
    local value=$1
    if [[ ! $value =~ ^(true|false)$ ]]; then
        return 1
    fi
    return 0
}

# Function to get sanitized input with validation
get_sanitized_input() {
    local prompt=$1
    local validation_function=$2
    local error_message=$3
    local value

    while true; do
        read -p "$prompt" value
        value=$(echo "$value" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
        
        if $validation_function "$value"; then
            echo "$value"
            return 0
        else
            echo "$error_message"
        fi
    done
}

# Function to set environment based on parameter
set_environment() {
    if [ "$ENVIRONMENT" = "staging" ]; then
        echo "Selected: Testnet Sepolia Staging"
        CONTRACT_ADDRESS="0xD2362B76f79a0AbeF38E961a28E452683691890C"
    else
        echo "Selected: Testnet Sepolia"
        CONTRACT_ADDRESS="0x172CEb125F6C86B7920fD391407aca0B5F416648"
    fi
}

# Function to create .env file
create_env_file() {
    echo "Configuring environment variables..."
    
    # Collect and validate required information
    SERVER_NAME=$(get_sanitized_input \
        "Enter your server name (e.g., content-1.us-east-1.sepolia.earthfastnodes.com): " \
        validate_domain \
        "Invalid domain format. Please enter a valid domain name.")

    NODE_ID=$(get_sanitized_input \
        "Enter your node ID (e.g., 0xa80a8fcc...): " \
        validate_node_id \
        "Invalid node ID format. Must be a 64-character hex string starting with 0x.")

    SETUP_SSL=$(get_sanitized_input \
        "Do you want to set up SSL? (true/false): " \
        validate_boolean \
        "Please enter either 'true' or 'false'.")

    CERTBOT_EMAIL=$(get_sanitized_input \
        "Enter your certbot email: " \
        validate_email \
        "Invalid email format. Please enter a valid email address.")

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

# Main installation script
main() {
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

    # Set environment and run the configuration steps
    set_environment
    create_env_file
    launch_content_node
}

# Execute the main function with docker group permissions
sg docker "$(declare -f set_environment create_env_file launch_content_node main ENVIRONMENT=\"$ENVIRONMENT\"); main"
