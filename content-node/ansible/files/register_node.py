#!/usr/bin/env python3

import subprocess
import sys
import re

def run_command(command):
    try:
        output = subprocess.run(command, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
        print(output.stdout)
        return output.stdout
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {e.stderr}", file=sys.stderr)
        sys.exit(1)

def main():
    if len(sys.argv) != 6:
        print("Usage: register_node.py <network> <private_key> <hostname> <operator_id> <region>")
        sys.exit(1)

    network = sys.argv[1]
    private_key = sys.argv[2]
    hostname = sys.argv[3]
    operator_id = sys.argv[4]
    region = sys.argv[5]

    network_map = {
        "staging": "testnet-sepolia-staging",
        "testnet": "testnet-sepolia",
        "testnet-sepolia": "testnet-sepolia"
    }
    
    cli_network = network_map.get(network)
    if not cli_network:
        print(f"Invalid network: {network}")
        sys.exit(1)

    if region not in ["us", "eu", "emea", "apac"]:
        print(f"Invalid region: {region}")
        sys.exit(1)

    command = f"npx earthfast-cli node create {operator_id} {hostname}:{region}:true:1.0 --key {private_key} --network {cli_network}"
    output = run_command(command)
    
    node_id_match = re.search(r'nodeId: \'(0x[a-fA-F0-9]+)\'', output)
    if node_id_match:
        node_id = node_id_match.group(1)
        print(f"ANSIBLE_NODE_ID={node_id}")
    else:
        print("Failed to extract nodeId from output", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
