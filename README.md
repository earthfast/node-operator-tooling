# EarthFast Node Operator Tooling

This repo provides examples for different ways to run nodes on EarthFast.

For more information about each node type, please see
- [The Docs Site](https://docs.earthfast.com)
- [Architecture Overview](https://docs.earthfast.com/overview/architecture-overview)

### Content Nodes
Content nodes are responsible for storing and serving content to browsers as requested

Examples [here](/content-node)


### Domain Nodes
The domain node is the gateway for you application served using EarthFast. It serves DNS requests for a given domain by returning the initial service worker to the user's browser that subsequently loads website content from content nodes.

Examples [here](/domain-node)
