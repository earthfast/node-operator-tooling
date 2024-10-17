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

# Verify installations
echo "Verifying installations..."
docker --version

echo "All dependencies installed."
