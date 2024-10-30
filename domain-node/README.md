### Domain Node

The domain node is the gateway for you application served using EarthFast. It serves DNS requests for a given domain by returning the initial service worker to the user's browser that subsequently loads website content from content nodes.

There's two examples here for running Domain Nodes: Ubuntu VM and Static Asset Hosting

The difference between these two nodes is that an Ubuntu VM could be provisioned to serve one or multiple project domains. Static Asset Hosting only serves a single domain.

##### Ubuntu VMs
Ubuntu VMs can be used to run your own node from scratch. For example if you're a node operator or trying to run your own hardware. This can be run on any on-prem or self hosted system as well as the major cloud hosting services like AWS, GCP, Azure etc.

##### Static Asset Hosting
This is a serverless way to run the Domain Node at the edge. Github can be connected to Cloudflare (or Github pages or CloudFront etc) so new updates to the site automatically get published.
