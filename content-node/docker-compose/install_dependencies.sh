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
    echo "Please log out and log back in for the changes to take effect."
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

# Verify installations
echo "Verifying installations..."
docker --version
docker compose version

echo "All dependencies installed."
