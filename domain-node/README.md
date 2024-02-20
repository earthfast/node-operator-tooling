### Domain Node

The domain node is the gateway for you application served using Armada, for more information check out the [official docs](https://docs.armadanetwork.com/armada-network-docs/overview/architecture-overview#domain-node). Domain nodes are a bit more complex to run that content nodes because they require paying careful attention to managing SSL termination for one (or more) URLs. A domain node for a single project will serve a service worker script but not any actual website content, but domain nodes can easily multiplex between multiple projects and terminate SSL between all of them as long as the SSL certificates are created.

There's two examples here for running Domain Nodes: Ubuntu VM and Cloudflare Pages

The difference between these two nodes is that an Ubuntu VM could be provisioned to serve a single project domain, or optionally configured for multiple projects across different domains. Cloudflare pages only serve a single domain and do SSL termination for a single URL.

##### Ubuntu VMs
Ubuntu VMs can be used to run your own node from scratch. For example if you're a node operator or trying to run your own hardware. This can be run on any on-prem or self hosted system as well as the major cloud hosting services like AWS, GCP, Azure etc.

##### Cloudflare Pages
This is a serverless way to run the Domain Node at the edge. Github can be connected to Cloudflare so new updates to the site automatically get published to Cloudflare