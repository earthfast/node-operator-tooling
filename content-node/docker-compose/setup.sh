#!/bin/bash

# Function to install Docker using official method
install_docker() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Please install Docker Desktop for Mac from: https://www.docker.com/products/docker-desktop"
        exit 1
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        echo "Please install Docker Desktop for Windows from: https://www.docker.com/products/docker-desktop"
        exit 1
    else
        # Install Docker using convenience script
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -aG docker $USER
        rm get-docker.sh
    fi
}

# Function to verify FQDN points to VM IP
verify_fqdn() {
    local fqdn=$1
    local vm_ip=$(curl -s ifconfig.me)
    local dns_ip=$(dig +short $fqdn)
    
    if [ "$vm_ip" = "$dns_ip" ]; then
        return 0
    else
        echo "Warning: $fqdn does not point to this VM's IP ($vm_ip)"
        echo "DNS currently points to: $dns_ip"
        read -p "Continue anyway? (y/n): " continue
        [[ $continue == "y" ]] && return 0 || return 1
    fi
}

# Parse command line arguments
ENVIRONMENT="testnet"
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --staging) ENVIRONMENT="staging";;
        *) echo "Unknown parameter: $1"; exit 1;;
    esac
    shift
done

# Check and install Docker if needed
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    install_docker
fi

# Install Docker Compose V2 if needed
if ! docker compose version &> /dev/null; then
    DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
    mkdir -p $DOCKER_CONFIG/cli-plugins
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d '"' -f 4)
    sudo curl -SL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o $DOCKER_CONFIG/cli-plugins/docker-compose
    sudo chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
fi

# Set contract address based on environment
CONTRACT_ADDRESS=$([ "$ENVIRONMENT" = "staging" ] && echo "0xD2362B76f79a0AbeF38E961a28E452683691890C" || echo "0x172CEb125F6C86B7920fD391407aca0B5F416648")

# Validation functions
validate_input() {
    local type=$1
    local value=$2
    case $type in
        domain) [[ $value =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]];;
        node_id) [[ $value =~ ^0x[a-fA-F0-9]{64}$ ]];;
        email) [[ $value =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]];;
        boolean) [[ $value =~ ^(true|false)$ ]];;
    esac
}

# Get and validate inputs with a generic function
get_validated_input() {
    local prompt=$1
    local type=$2
    local value
    while true; do
        read -p "$prompt: " value
        value=$(echo "$value" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
        if validate_input "$type" "$value"; then
            echo "$value"
            break
        else
            echo "Invalid input format. Please try again."
        fi
    done
}

# Get inputs
SERVER_NAME=$(get_validated_input "Enter your server name (e.g., content-1.us-east-1.sepolia.earthfastnodes.com)" "domain")
NODE_ID=$(get_validated_input "Enter your node ID (e.g., 0xb10e2d52...)" "node_id")
SETUP_SSL=$(get_validated_input "Do you want to set up SSL? (true/false)" "boolean")
CERTBOT_EMAIL=$(get_validated_input "Enter your certbot email" "email")

# Verify FQDN if SSL is enabled
if [ "$SETUP_SSL" = "true" ]; then
    if ! verify_fqdn "$SERVER_NAME"; then
        echo "FQDN verification failed. Exiting..."
        exit 1
    fi
fi

# Create .env file
cat > .env << EOF
SERVER_NAME=$SERVER_NAME
NODE_ID=$NODE_ID
SETUP_SSL=$SETUP_SSL
CERTBOT_EMAIL=$CERTBOT_EMAIL
RPC_URL=https://eth-sepolia.g.alchemy.com/v2/7xFp9qkRZTVC7CvUHODk7TgyemLtkzxt
CONTRACT_ADDRESS=$CONTRACT_ADDRESS
HOSTING_CACHE_DIR=/hosting_cache
DATABASE_DIR=/db_data
EOF

echo -e "\n.env file created successfully!"
echo "To start the content node, use: docker compose up -d"

# Remind to restart if docker group was added
if groups $USER | grep -q "\bdocker\b"; then
    echo "Please log out and log back in for Docker group changes to take effect."
fi
