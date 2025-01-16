import subprocess
import json
import requests

def exec_shell_command(command):
    output = subprocess.run(command, shell=True, check=True, stdout=subprocess.PIPE, universal_newlines=True)
    print(output)
    if output.returncode != 0:
        raise Exception("Command failed: " + command)
    return output


def parse_json_str(string):
    return json.loads(string)

def run_command(command, parse_json=False):
    output = exec_shell_command(command)
    if parse_json:
        return parse_json_str(output.stdout)
    return output

def main():
    network = input("Enter Network: ")

    if network not in ["staging", "testnet", "testnet-sepolia"]:
        print("Network is invalid. Network must be either staging, testnet, or testnet-sepolia")
        exit(1)

    private_key = input("Enter Private Key: ")
    hostname = input("Enter hostname: ")
    operator_id = input("Enter Operator ID: ")
    region = input("Enter region: ")

    # if region is not "us", "eu", "emea", or "apac", exit
    if region not in ["us", "eu", "emea", "apac"]:
        print("region is invalid. region must be either us, eu, emea, or apac")
        exit(1)

    # stake 100 tokens for the node
    STAKE_AMOUNT = 100
    run_command(f"npx earthfast-cli operator stake {operator_id} {STAKE_AMOUNT} --key {private_key} --network {network}")

    # make sure that host is available
    response = requests.get(f"{hostname}/statusz")
    if response.status_code != 200:
        print(f"Host is not available. Please make sure that the host is available at {hostname}")
        exit(1)

    ENABLED = False
    PRICE = 1.0
    run_command(f"npx earthfast-cli node create {operator_id} {hostname}:{region}:{ENABLED}:{PRICE} --key {private_key} --network {network}")

    print("Node created successfully. Please save the 'nodeId' value from the output above. You can always retrieve this value by running 'npx earthfast-cli node list --network $NETWORK'")

    nodes=run_command(f"npx earthfast-cli node list --network {network} --json", True)

    nodeId = None
    for node in nodes:
        if node.get("hostname") == hostname:
            nodeId = node.get("id")
            break
    
    run_command(f"npx earthfast-cli node enable {nodeId} true --key {private_key} --network {network}")


if __name__ == "__main__":
    main()
