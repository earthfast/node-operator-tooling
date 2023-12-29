#!/bin/bash

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

# install nginx & docker
yes | sudo apt update
yes | sudo apt install nginx
yes | sudo apt install docker.io

# replace default server block with the following
cat > /etc/nginx/sites-available/default << EOM
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

# raise the server_names_hash_bucket_size, sometimes long hostnames can exceed the default size
cat > /etc/nginx/conf.d/default.conf << EOM
server_names_hash_bucket_size 128;
EOM

# make sure DNS record exists before requesting SSL certificate
if $setup_ssl
then
    sudo apt install -y certbot python3-certbot-nginx
    sudo certbot --nginx -d $SERVER_NAME
fi

# restart nginx
sudo service nginx restart

# create data dir for docker container and start container
sudo mkdir -p $DATABASE_DIR $HOSTING_CACHE_DIR
sudo docker run \
  -e CONTRACT_ADDRESS=$CONTRACT_ADDRESS \
  -e DATABASE_DIR=$DATABASE_DIR \
  -e ETH_RPC_ENDPOINT=$RPC_URL \
  -e HOSTING_CACHE_DIR=$HOSTING_CACHE_DIR \
  -e HTTP_PORT=$HTTP_PORT \
  -e NODE_ID=$NODE_ID \
  -p $HTTP_PORT:$HTTP_PORT \
  --restart unless-stopped \
  -d \
  ghcr.io/armada-network/content-node:latest