#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Usage function
usage() {
    echo "Usage: $0 [--staging]"
    echo "  --staging        Use staging environment"
    echo "  --auto-upgrade   Enable automatic updates"
    echo "  --skip-env-setup Skip the .env setup process"
    exit 1
}

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

install_dependencies() {
    if command -v apt-get &>/dev/null; then
        sudo apt-get update
        sudo apt-get install -y net-tools curl
    elif command -v yum &>/dev/null; then
        sudo yum install -y net-tools curl
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y net-tools curl
    else
        log_warning "Could not install dependencies automatically. Please ensure net-tools and curl are installed."
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

# Check ports
check_ports() {
    local ports=("80" "443")
    local success=true
    for port in "${ports[@]}"; do
        if netstat -tuln | grep -q ":$port "; then
            log_error "Port $port is already in use"
            success=false
        else
            log_success "Port $port is available"
        fi
    done

    # TODO: Check if ports are accessible from outside

    return $([[ "$success" == "true" ]] && echo 0 || echo 1)
}

# Parse command line arguments
ENVIRONMENT="testnet"
ENV_SETUP="true"

while [[ "$#" -gt 0 ]]; do
    case $1 in
    --help | -h) usage ;;
    --staging) ENVIRONMENT="staging" ;;
    --auto-upgrade) AUTO_UPGRADE="true" ;;
    --skip-env-setup) ENV_SETUP="false" ;;
    *)
        log_error "Unknown parameter: $1"
        usage
        ;;
    esac
    shift
done

log_info "Starting setup process..."

install_dependencies

# Check and install Docker if needed
if ! command -v docker &>/dev/null; then
    log_info "Docker not found. Installing..."
    install_docker
else
    log_success "Docker is already installed"
fi

# Install Docker Compose V2 if needed
if ! docker compose version &>/dev/null; then
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
CONTRACT_ADDRESS=$([ "$ENVIRONMENT" = "staging" ] && echo "0x69e4aa095489E8613B4C4d396DD916e66D66aE23" || echo "0xb1c5F9914648403cb32a4f83B0fb946E5f7702CC")
# log_info "Using contract address: $CONTRACT_ADDRESS"

# Check if .env file exists and handle setup process
if [ -f ".env" ] && [ "$ENV_SETUP" = "true" ]; then
    log_info "Current .env file contents:"
    echo "----------------------------------------"
    cat .env
    echo "----------------------------------------"

    log_warning "An .env file already exists!"
    read -p "Would you like to go through the .env setup process again? (y/n): " setup_again

    if [[ $setup_again =~ ^[Yy]$ ]]; then
        # Backup existing .env file
        backup_file=".env.backup.$(date +%Y%m%d_%H%M%S)"
        mv .env "$backup_file"
        log_info "Existing .env file backed up to $backup_file"
        log_info "Proceeding with new .env setup..."
    else
        ENV_SETUP="false"
    fi
fi

if [ "$ENV_SETUP" = "true" ]; then
    log_info "Please provide the following information:"
    printf "\n"

    printf "${BLUE}Enter your server name (e.g., content-1.us-east-1.sepolia.earthfastnodes.com)${NC}: "
    read -r SERVER_NAME
    SERVER_NAME=$(echo "$SERVER_NAME" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')

    printf "${BLUE}Enter your node ID (e.g., 0xb10e2d52...)${NC}: "
    read -r NODE_ID
    NODE_ID=$(echo "$NODE_ID" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')

# Verify FQDN points to correct IP
    log_info "Verifying FQDN..."
    if ! verify_fqdn "$SERVER_NAME"; then
        log_error "FQDN verification failed. Exiting..."
        exit 1
    fi


    log_info "Checking ports..."
    if ! check_ports; then
        log_error "Port check failed. Please ensure ports 80 and 443 are open and available."
        read -p "Continue anyway? (y/n): " continue
        if [[ ! $continue =~ ^[Yy]$ ]]; then
            log_error "Setup cancelled due to port verification failure."
            exit 1
        fi
    fi

    # Create .env file
    log_info "Creating .env file..."
cat >.env <<EOF
SERVER_NAME=$SERVER_NAME
NODE_ID=$NODE_ID
RPC_URL=https://eth-sepolia.g.alchemy.com/v2/5opzBW-mCA1jMP0Z5mC1NIDJn_O3edas
CONTRACT_ADDRESS=$CONTRACT_ADDRESS
HOSTING_CACHE_DIR=/hosting_cache
DATABASE_DIR=/db_data
EOF

    log_success ".env file created successfully!"
fi

CRONTAB_EXISTS=$(crontab -l | grep -q "$(pwd)/auto-upgrade.sh"; echo $?) # 0 means it's set up

# if user didn't specify auto-upgrade flag and crontab is not set up, ask if they want it
if [ "$AUTO_UPGRADE" != "true" ] && [ "$CRONTAB_EXISTS" -ne 0 ]; then
    read -p "Would you like to enable auto-upgrade? (y/n): " auto_upgrade 
    if [[ $auto_upgrade =~ ^[Yy]$ ]]; then
        # will check at the top of every hour between minutes 0 and 10
        (crontab -l ; echo "$((RANDOM % 10)) * * * * $(pwd)/auto-upgrade.sh")| crontab -
        log_success "Auto-upgrade set up successfully!"
    fi
elif [ "$AUTO_UPGRADE" = "true" ] && [ "$CRONTAB_EXISTS" -ne 0 ]; then
    (crontab -l ; echo "$((RANDOM % 10)) * * * * $(pwd)/auto-upgrade.sh")| crontab -
    log_success "Auto-upgrade set up successfully!"
fi

log_info "To start the content node, use: ${GREEN}docker compose up -d${NC}"

# Remind to restart if docker group was added
if groups $USER | grep -q "\bdocker\b"; then
    log_warning "Please log out and log back in for Docker group changes to take effect."
fi
