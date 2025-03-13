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

Confirm success by curling the `/statusz` endpoint:
```sh
# On the VM outside the container
> curl localhost/statusz
```

> Note: you may need to log out and log back in for your user to be able to run `docker compose`.

## Updates

There's an option to enable auto upgrades for the content node, it's recommended you enable this so the latest features, bug fixes and updates will be deployed automatically. You can turn this on by running
```
./setup.sh --auto-upgrade
```

You can manually update your Content Node. Please monitor for new updates and run the following command:
```sh
sh update.sh <optional sha>
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
docker compose logs <container-name>

# Stop all containers
docker compose down
```
