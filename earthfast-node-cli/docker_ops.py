from .utils import run_command, is_tool, install_package

def ensure_docker():
    if not is_tool("docker"):
        print("Docker is not installed. Attempting to install...")
        install_package("docker")

def start_docker_container(container_type, env):
    ensure_docker()
    
    if container_type == 'content-node':
        image = "earthfast/content-node:latest"
        command = f"""
        docker run \
          -e CONTRACT_ADDRESS={env['CONTRACT_ADDRESS']} \
          -e DATABASE_DIR={env['DATABASE_DIR']} \
          -e ETH_RPC_ENDPOINT={env['ETH_RPC_ENDPOINT']} \
          -e HOSTING_CACHE_DIR={env['HOSTING_CACHE_DIR']} \
          -e HTTP_PORT={env['HTTP_PORT']} \
          -e NODE_ID={env['NODE_ID']} \
          -p {env['HTTP_PORT']}:{env['HTTP_PORT']} \
          --restart unless-stopped \
          -d \
          {image}
        """
    elif container_type == 'domain-node':
        image = "docker.io/earthfast/domain-node:latest"
        command = f"""
        docker run \
          -e CONTRACT_ADDRESS={env['CONTRACT_ADDRESS']} \
          -e ETH_RPC_ENDPOINT={env['ETH_RPC_ENDPOINT']} \
          -e HTTP_PORT=30080 \
          -e IP_LOOKUP_API_KEY={env['IP_LOOKUP_API_KEY']} \
          -e DOMAIN_TO_PROJECT_MAPPING={env['DOMAIN_TO_PROJECT_MAPPING']} \
          -p 30080:30080 \
          --restart unless-stopped \
          -d \
          {image}
        """
    else:
        raise ValueError(f"Unsupported container type: {container_type}")

    run_command(command)
