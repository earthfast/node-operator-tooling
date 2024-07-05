#!/bin/bash

set -e

# Check if the .env file argument is provided
env_file="$1"
if [ -f "$env_file" ]; then
  echo "Sourcing $env_file..."
  . "$env_file"
fi

if [ -z "$SERVER_NAME" ] || [ -z "$RPC_URL" ] || [ -z "$NODE_ID" ] || [ -z "$CONTRACT_ADDRESS" ] || [ -z "$HOSTING_CACHE_DIR" ] || [ -z "$DATABASE_DIR" ] || [ -z "$HTTP_PORT" ]; then
    echo "Please set the following environment variables in an env file: SERVER_NAME, RPC_URL, NODE_ID, CONTRACT_ADDRESS, HOSTING_CACHE_DIR, DATABASE_DIR, HTTP_PORT"
    exit 1
fi

# Install nginx & docker if not already installed
if ! command -v nginx &> /dev/null; then
    yes | sudo apt update
    yes | sudo apt install nginx
fi

if ! command -v docker &> /dev/null; then
    yes | sudo apt update
    yes | sudo apt install docker.io
fi

# Function to check if SSL is properly configured in Nginx
check_ssl_config() {
    if grep -q "listen 443 ssl" "$nginx_config"; then

        return 0
    else
        return 1
    fi
}

nginx_config="/etc/nginx/sites-available/default"
ssl_cert_path="/etc/letsencrypt/live/$SERVER_NAME/fullchain.pem"

# Ensure the Nginx config is correct
desired_config=$(cat << EOM
server {
    listen 80;
    listen [::]:80;

    server_name $SERVER_NAME;

    location / {
        proxy_pass http://0.0.0.0:30080;
        proxy_set_header   X-Forwarded-For \$remote_addr;
        proxy_set_header   Host \$http_host;
    }
}
EOM
)

if ! cmp -s <(echo "$desired_config") "$nginx_config"; then
    echo "$desired_config" | sudo tee "$nginx_config" > /dev/null
    echo "Updated Nginx configuration"
fi

# Raise the server_names_hash_bucket_size only if it's not already set
nginx_default_conf="/etc/nginx/conf.d/default.conf"
if ! grep -q "server_names_hash_bucket_size 128;" "$nginx_default_conf" 2>/dev/null; then
    echo "server_names_hash_bucket_size 128;" | sudo tee -a "$nginx_default_conf" > /dev/null
    echo "Updated server_names_hash_bucket_size"
fi

# Check if SSL needs to be set up or reconfigured
if [ "$SETUP_SSL" = true ] && ([ ! -f "$ssl_cert_path" ] || ! check_ssl_config); then
    if ! command -v certbot &> /dev/null; then
        sudo apt install -y certbot python3-certbot-nginx
    fi
    echo "Running Certbot to set up or reconfigure SSL..."
    sudo certbot --nginx -d "$SERVER_NAME"
    echo "SSL setup completed"
fi

# Restart Nginx
sudo service nginx restart
echo "Nginx restarted"

# Create data directories if they don't exist
sudo mkdir -p "$DATABASE_DIR" "$HOSTING_CACHE_DIR"

# Stop and remove the existing container if it exists
if sudo docker ps -a --format '{{.Names}}' | grep -q "content-node"; then
    echo "Stopping and removing existing content-node container"
    sudo docker stop content-node
    sudo docker rm content-node
fi

# Start the Docker container
echo "Starting content-node container"
sudo docker run \
  -e CONTRACT_ADDRESS="$CONTRACT_ADDRESS" \
  -e DATABASE_DIR="$DATABASE_DIR" \
  -e ETH_RPC_ENDPOINT="$RPC_URL" \
  -e HOSTING_CACHE_DIR="$HOSTING_CACHE_DIR" \
  -e HTTP_PORT="$HTTP_PORT" \
  -e NODE_ID="$NODE_ID" \
  -p "$HTTP_PORT:$HTTP_PORT" \
  --restart unless-stopped \
  -d \
  --name content-node \
  armadanetwork/content-node:latest

echo "Docker container started"