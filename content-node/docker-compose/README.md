# Content Node Deployment

This repository contains the necessary files to deploy a Content Node using Docker Compose.

This README assumes you have followed the [Content Node Setup Guide](https://docs.earthfast.com/node-operators/content-node-setup) and satisfied all prerequisites & registered your Content Node.

## Setup

Clone this repository and run the setup script:
```sh
> git clone https://github.com/earthfast/node-operator-tooling
> cd node-operator-tooling/content-node/docker-compose
> ./setup.sh
```

The `setup.sh` script will prompt you for environment variables:
* `SERVER_NAME` = your node's FQDN (details in [Setup Docs – Create the FQDN](https://docs.earthfast.com/node-operators/content-node-setup#create-the-fqdn-fully-qualified-domain-name), eg. `content0.us-east-2.testnet-sepolia.earthfast.operator.com`)
* `NODE_ID` = the `NodeID` generated in [Setup Docs – Register your Node(s) onchain](https://docs.earthfast.com/node-operators/content-node-setup#register-your-node-s-onchain)
* `SETUP_SSL` = if you have configured HTTPS/SSL externally, set this to `false`. Setting it to true will locally configure SSL with Let's Encrypt. Make sure the url from SERVER_NAME is correctly pointed to your server's IP address before enabling this option.
* `CERTBOT_EMAIL` = If SETUP_SSL=true, this email will be used for SSL certificate renewal / management emails

Confirm success by curling the `/statusz` endpoint:
```sh
# From inside the VM
> curl localhost:5000/statusz
# From outside the VM
> curl <FQDN>:5000/statusz
```

> Note: you may need to log out and log back in for your user to be able to run `docker compose`.

## Updates

To update your Content Node, pull the latest changes and restart:
```sh
git pull
docker compose up -d
```

## Useful Docker Compose Commands

```sh
# Check container status
docker compose ps

# Check all container logs
# if running from same directory as docker-compose.yml file:
docker compose logs
# if running from different directory:
docker compose logs -f <path/to/docker-compose.yml>

# Check logs of a specific container
docker compose logs nginx
docker compose logs certbot
docker compose logs content-node

# Stop all containers
docker compose down
```
