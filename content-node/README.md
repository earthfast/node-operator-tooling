### Content Node

Content nodes can be run almost anywhere that supports docker containers. As long as you can run docker on it and get a URL with SSL, it will function perfectly fine as a content node. For full specs and documentation see [here](https://docs.armadanetwork.com/armada-network-docs/node-operators/content-node-setup).

There's two examples in this repo for different ways to run Content Nodes: Ubuntu VM and Akash Network. 

##### Ubuntu VMs
Ubuntu VMs can be used to run your own node from scratch. For example if you're a node operator or trying to run your own hardware. This can be run on any on-prem or self hosted system as well as the major cloud hosting services like AWS, GCP, Azure etc.

This node type also lets you provision SSL certificates with LetsEncrypt or you can optionally use Cloudflare to proxy with SSL

##### Akash Network
Akash Network also provides great options but is less customizable if the project needs special customization.

#### Register Script
A convenience python script to automate the on-chain registration from [the documentation](https://docs.armadanetwork.com/armada-network-docs/node-operators/content-node-setup). This requires node 18+ and npm 6+ to run.

WARNING - this asks for private key to do a signed tx, this is for use on testnet only. For mainnet use the `armada-cli` built in key manager or better yet a multisig or hardware wallet.