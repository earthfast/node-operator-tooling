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

Confirm success by curling the `/statusz` endpoint:
```sh
# On the VM outside the container
> docker exec -it docker-compose-nginx-1 /bin/bash -c "curl http://content-node:5000/statusz"
# From outside the VM using the FQDN
> curl <FQDN>:5000/statusz
```

> Note: you may need to log out and log back in for your user to be able to run `docker compose`.

## Updates

The setup.sh script has an option to enable auto upgrading the content node, it's recommended you enable auto upgrades. You can turn this on by re-running `./setup.sh` or
```
(crontab -l ; echo "* 4 * * * $(pwd)/auto-upgrade.sh")| crontab -
```

If you want to manually update your Content Node, run the following command:
```sh
sh update.sh <optional node-operator-tooling/ sha>
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
