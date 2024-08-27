### Domain Node

The domain node is the gateway for you application served using EarthFast by provididing the initial service worker to user browsers that subsequently loads website content from content nodes.

Domain nodes are a bit more complex to run that content nodes because they require paying careful attention to managing SSL termination for one (or more) URLs. The earthfast/domain-node docker container supports multiple projects and terminates SSL between all of them as long as the SSL certificates are created. Domain node run via Static Asset Hosting can only serve a single project and domain.

There's two examples here for running Domain Nodes: Ubuntu VM and Static Asset Hosting

The difference between these two nodes is that an Ubuntu VM could be provisioned to serve a single project domain, or optionally configured for multiple projects across different domains. Static Asset Hosting only serve a single domain and do SSL termination for a single URL.

##### Ubuntu VMs
Ubuntu VMs can be used to run your own node from scratch. For example if you're a node operator or trying to run your own hardware. This can be run on any on-prem or self hosted system as well as the major cloud hosting services like AWS, GCP, Azure etc.

##### Static Asset Hosting
This is a serverless way to run the Domain Node at the edge. Github can be connected to Cloudflare (or Github pages or CloudFront etc) so new updates to the site automatically get published.
