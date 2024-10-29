# Content Node Deployment

This repository contains the necessary files to deploy a Content Node using Docker Compose.

## Prerequisites

- A Linux-based system (preferably Ubuntu)
- An internet-connected server with a static public IP address
- A DNS record pointing to your server's IP address eg `content1.us-central1-a.testnet-sepolia.earthfastnodes.com`

## Quick Start

#### 1. Clone this repository:
```sh
git clone https://github.com/earthfast/earthfast-node-setup-examples.git
cd earthfast-node-setup-examples/content-node/docker-compose
```

#### 2. Run the install script to set up dependencies:
```sh
./install_dependencies.sh
```

You will need to log out and log back in for docker compose to have the necessary permissions for this user.

#### 3. Setup the .env file
```sh
cp .env.example .env
vi .env
```

Edit the `.env` file to configure your Content Node.

If you have not yet created a content node on chain, you can do that with the CLI --> https://github.com/earthfast/earthfast-cli

##### SSL Configuration

If `SETUP_SSL` is set to 'true', the setup will automatically configure SSL using Let's Encrypt. Make sure the url from `SERVER_NAME` correctly pointed to your server's IP address before enabling this option.


#### 4. Start the Content Node:
```sh
docker compose up -d
```

#### 5. Check the status of your services:
```sh
docker compose ps
```

## Maintenance

#### To update your Content Node, pull the latest changes and restart:
```sh
git pull
docker compose up -d
```

#### To view logs:
```sh
docker compose logs
```

#### To stop the Content Node:
```sh
docker compose down
```

## Troubleshooting

If you encounter issues, check the logs of individual services:
```sh
docker compose logs nginx
docker compose logs certbot
docker compose logs content-node
```
