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

# Install Docker Compose if not already installed
if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..."
    DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
    mkdir -p $DOCKER_CONFIG/cli-plugins
    COMPOSE_URL="https://github.com/docker/compose/releases/download/v2.17.2/docker-compose-$(uname -s)-$(uname -m)"
    curl -SL $COMPOSE_URL -o $DOCKER_CONFIG/cli-plugins/docker-compose
    chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
    echo "Docker Compose installed successfully."
else
    echo "Docker Compose is already installed."
fi

# Set up Docker to run without sudo
if ! groups $USER | grep -q "\bdocker\b"; then
    sudo usermod -aG docker $USER
    echo "Added $USER to the docker group."
    echo "Please log out and log back in for the changes to take effect."
else
    echo "User $USER is already in the docker group."
fi

# Verify installations
echo "Verifying installations..."
docker --version
docker-compose --version

echo "All dependencies installed."
echo "If you haven't been prompted to log out and log back in, you should be able to run Docker commands without sudo now."
echo "If you were prompted to log out and log back in, please do so for the changes to take effect."
