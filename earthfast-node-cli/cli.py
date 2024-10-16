import argparse
from .config import load_env, check_required_vars
from .node_factory import create_node
from .utils import get_os

def main():
    parser = argparse.ArgumentParser(description="Earthfast Node Setup CLI")
    parser.add_argument("--env-file", required=True, help="Path to the environment file")
    parser.add_argument("--setup-ssl", action="store_true", help="Setup SSL with Certbot")
    parser.add_argument("--node-type", choices=['content', 'domain'], required=True, help="Type of node to deploy")
    parser.add_argument("--start-container", action="store_true", help="Start the Docker container after setup")
    args = parser.parse_args()

    os_type = get_os()
    print(f"Detected operating system: {os_type}")

    env = load_env(args.env_file)
    check_required_vars(env, args.node_type)

    node = create_node(args.node_type, env, args.setup_ssl, args.start_container)
    node.deploy()

    print(f"{args.node_type.capitalize()} Node setup completed successfully!")

if __name__ == "__main__":
    main()

