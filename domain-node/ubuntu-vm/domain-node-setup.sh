#!/bin/bash

# Check if the .env file argument is provided
env_file="$1"
if [ -f "$env_file" ]; then
  echo "Sourcing $env_file..."
  . "$env_file"
fi

if [ -z "$DOMAIN_NODE_URL" ] || [ -z "$ETH_RPC_ENDPOINT" ] || [ -z "$IP_LOOKUP_API_KEY" ] || [ -z "$DOMAIN_TO_PROJECT_MAPPING" ] || [ -z "$CONTRACT_ADDRESS" ]; then
    echo "Please set the following environment variables in an env file: DOMAIN_NODE_URL, ETH_RPC_ENDPOINT, IP_LOOKUP_API_KEY, DOMAIN_TO_PROJECT_MAPPING, CONTRACT_ADDRESS"
    exit 1
fi

# check if user wants to setup SSL
if [ -z "$SETUP_SSL" ]; then
    read -p "Do you want to provision a LetsEncrypt Certbot SSL certificate for https? (Y/n)" yn
    case $yn in 
        [yY][eE][sS]|[yY] ) SETUP_SSL=true;;
        * ) setup_ssl=false;;
    esac
fi

# install nginx & docker
yes | sudo apt update
yes | sudo apt install nginx
yes | sudo apt install docker.io


# setup domain node
cat > /etc/nginx/sites-available/$DOMAIN_NODE_URL << EOM
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN_NODE_URL;

    location / {
        proxy_pass http://0.0.0.0:30080;
        proxy_set_header   X-Forwarded-For \$remote_addr;
        proxy_set_header   Host \$http_host;
    }
}
EOM
ln -s /etc/nginx/sites-available/$DOMAIN_NODE_URL /etc/nginx/sites-enabled/$DOMAIN_NODE_URL

# raise the server_names_hash_bucket_size, sometimes long hostnames can exceed the default size
sed -i 's/# server_names_hash_bucket_size 64;/server_names_hash_bucket_size 128;/' /etc/nginx/nginx.conf

# setup projects using domain node
# split DOMAIN_TO_PROJECT_MAPPING at commas to get individual records, then equal sign
# to get the key value pair and print $1 which is the domain
domains=$(echo $DOMAIN_TO_PROJECT_MAPPING | tr "," "\n" | tr "=" " " | awk '{ print $1 }')

for domain in $domains
do
    cat > /etc/nginx/sites-available/$domain << EOM
server {
    listen 80;
    listen [::]:80;
    server_name $domain;

    location / {
        proxy_pass http://0.0.0.0:30080;
        proxy_set_header   X-Forwarded-For \$remote_addr;
        proxy_set_header   Host \$http_host;
    }
}
EOM
    ln -s /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/$domain
done



# make sure DNS record exists before requesting SSL certificate
if $SETUP_SSL
then
    apt install -y certbot python3-certbot-nginx
    certbot --nginx -d $DOMAIN_NODE_URL
    for domain in $domains
    do
        certbot --nginx -d $domain
    done
fi

# restart nginx
service nginx restart

if [ -z "$START_CONTAINER" ]; then
    read -p "Do you want to start the domain node docker container? (Y/n)" yn
    case $yn in 
        [yY][eE][sS]|[yY] ) START_CONTAINER=true;;
        * ) START_CONTAINER=false;;
    esac
fi

if ! $START_CONTAINER
then
    exit
fi

# create data dir for docker container and start container
# if all the env vars are in an .env file could also run
docker run \
  -e CONTRACT_ADDRESS=$CONTRACT_ADDRESS \
  -e ETH_RPC_ENDPOINT=$ETH_RPC_ENDPOINT \
  -e HTTP_PORT=30080 \
  -e IP_LOOKUP_API_KEY=$IP_LOOKUP_API_KEY \
  -e DOMAIN_TO_PROJECT_MAPPING=$DOMAIN_TO_PROJECT_MAPPING \
  -p 30080:30080 \
  --restart unless-stopped \
  -d \
  docker.io/earthfast/domain-node:latest