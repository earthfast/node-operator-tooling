#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to install Docker using official method
install_docker() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        log_error "Please install Docker Desktop for Mac from: https://www.docker.com/products/docker-desktop"
        exit 1
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        log_error "Please install Docker Desktop for Windows from: https://www.docker.com/products/docker-desktop"
        exit 1
    else
        # Check if it's Amazon Linux
        if grep -q "Amazon Linux" /etc/os-release; then
            log_info "Installing Docker on Amazon Linux..."
            sudo yum update -y
            sudo yum install -y docker
            sudo service docker start
            sudo usermod -a -G docker $USER
            sudo chkconfig docker on
        else
            # Original Docker installation for other Linux distributions
            log_info "Installing Docker using convenience script..."
            curl -fsSL https://get.docker.com -o get-docker.sh
            sudo sh get-docker.sh
            sudo systemctl start docker
            sudo systemctl enable docker
            sudo usermod -aG docker $USER
            rm get-docker.sh
        fi
    fi
}

# Function to verify FQDN points to VM IP
verify_fqdn() {
    local fqdn=$1
    local vm_ip=$(curl -s ifconfig.me)
    local dns_ip=$(dig +short $fqdn)
    
    if [ "$vm_ip" = "$dns_ip" ]; then
        log_success "FQDN verification successful!"
        return 0
    else
        log_warning "$fqdn does not point to this VM's IP ($vm_ip)"
        log_warning "DNS currently points to: $dns_ip"
        read -p "Continue anyway? (y/n): " continue
        [[ $continue == "y" ]] && return 0 || return 1
    fi
}

# Parse command line arguments
ENVIRONMENT="testnet"
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --staging) ENVIRONMENT="staging";;
        *) log_error "Unknown parameter: $1"; exit 1;;
    esac
    shift
done

log_info "Starting setup process..."

# Check and install Docker if needed
if ! command -v docker &> /dev/null; then
    log_info "Docker not found. Installing..."
    install_docker
else
    log_success "Docker is already installed"
fi

# Install Docker Compose V2 if needed
if ! docker compose version &> /dev/null; then
    log_info "Installing Docker Compose V2..."
    DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
    mkdir -p $DOCKER_CONFIG/cli-plugins
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d '"' -f 4)
    sudo curl -SL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o $DOCKER_CONFIG/cli-plugins/docker-compose
    sudo chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
    log_success "Docker Compose V2 installed successfully!"
else
    log_success "Docker Compose V2 is already installed"
fi

# Set contract address based on environment
CONTRACT_ADDRESS=$([ "$ENVIRONMENT" = "staging" ] && echo "0xD2362B76f79a0AbeF38E961a28E452683691890C" || echo "0x172CEb125F6C86B7920fD391407aca0B5F416648")
log_info "Using contract address: $CONTRACT_ADDRESS"

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
        printf "${BLUE}%s${NC}: " "$prompt"
        read -r value || return 1
        value=$(echo "$value" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
        if validate_input "$type" "$value"; then
            echo "$value"
            break
        else
            log_error "Invalid input format. Please try again."
        fi
    done
}

log_info "Please provide the following information:"
printf "\n"

# Get inputs - with explicit prompts
printf "${BLUE}Enter your server name (e.g., content-1.us-east-1.sepolia.earthfastnodes.com)${NC}: "
read -r SERVER_NAME
SERVER_NAME=$(echo "$SERVER_NAME" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')

printf "${BLUE}Enter your node ID (e.g., 0xb10e2d52...)${NC}: "
read -r NODE_ID
NODE_ID=$(echo "$NODE_ID" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')

printf "${BLUE}Do you want to set up SSL? (true/false)${NC}: "
read -r SETUP_SSL
SETUP_SSL=$(echo "$SETUP_SSL" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')

printf "${BLUE}Enter your certbot email${NC}: "
read -r CERTBOT_EMAIL
CERTBOT_EMAIL=$(echo "$CERTBOT_EMAIL" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')

# Verify FQDN if SSL is enabled
if [ "$SETUP_SSL" = "true" ]; then
    log_info "Verifying FQDN..."
    if ! verify_fqdn "$SERVER_NAME"; then
        log_error "FQDN verification failed. Exiting..."
        exit 1
    fi
fi

# Create .env file
log_info "Creating .env file..."
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

log_success ".env file created successfully!"
echo
log_info "To start the content node, use: ${GREEN}docker compose up -d${NC}"

# Remind to restart if docker group was added
if groups $USER | grep -q "\bdocker\b"; then
    log_warning "Please log out and log back in for Docker group changes to take effect."
fi
