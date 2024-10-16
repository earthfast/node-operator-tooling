import os
import sys

def load_env(env_file):
    env = {}
    with open(env_file, 'r') as f:
        for line in f:
            if line.strip() and not line.startswith('#'):
                key, value = line.strip().split('=', 1)
                env[key] = value
                os.environ[key] = value
    return env

def check_required_vars(env, node_type):
    common_vars = ['CONTRACT_ADDRESS', 'ETH_RPC_ENDPOINT']
    content_vars = ['SERVER_NAME', 'NODE_ID', 'HOSTING_CACHE_DIR', 'DATABASE_DIR', 'HTTP_PORT']
    domain_vars = ['DOMAIN_NODE_URL', 'IP_LOOKUP_API_KEY', 'DOMAIN_TO_PROJECT_MAPPING']

    required_vars = common_vars + (content_vars if node_type == 'content' else domain_vars)

    for var in required_vars:
        if var not in env:
            print(f"Error: {var} is not set in the environment file")
            sys.exit(1)
