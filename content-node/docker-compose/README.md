# Content Node Deployment

This repository contains the necessary files to deploy a Content Node using Docker Compose.

## Prerequisites

- A Linux-based system (preferably Ubuntu)
- Docker and Docker Compose
- An internet-connected server with a public IP address
- A domain name pointed to your server's IP address (if using SSL)

## Quick Start

1. Clone this repository:
```sh
git clone https://github.com/earthfast/earthfast-node-setup-examples.git
cd content-node/docker-compose
```

2. Run the install script to set up dependencies:
```sh
./install_dependencies.sh
```

3. Copy the example environment file and edit it with your settings:
```sh
cp .env.example .env
vi .env
```

4. Start the Content Node:
```sh
docker-compose up -d
```

5. Check the status of your services:
```sh
docker-compose ps
```

## Configuration

Edit the `.env` file to configure your Content Node. Here are the key variables:

- `SERVER_NAME`: Your domain name
- `RPC_URL`: Your Ethereum RPC endpoint
- `NODE_ID`: Your unique node identifier
- `CONTRACT_ADDRESS`: The address of the content node contract
- `HOSTING_CACHE_DIR`: Directory for hosting cache
- `DATABASE_DIR`: Directory for the database
- `CERTBOT_EMAIL`: Your email for SSL certificate notifications
- `SETUP_SSL`: Set to 'true' to enable SSL, 'false' to disable

## SSL Configuration

If `SETUP_SSL` is set to 'true', the setup will automatically configure SSL using Let's Encrypt. Make sure your domain is correctly pointed to your server's IP address before enabling this option.

## Maintenance

- To update your Content Node, pull the latest changes and restart:
```sh
git pull
docker-compose up -d
```

- To view logs:
```sh
docker-compose logs
```

- To stop the Content Node:
```sh
docker-compose down
```

## Troubleshooting

If you encounter issues, check the logs of individual services:
```sh
docker-compose logs nginx
docker-compose logs certbot
docker-compose logs content-node
```
