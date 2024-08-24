### Domain Node

The domain node is the gateway for you application served using EarthFast by provididing the initial service worker to user browsers that subsequently loads website content from content nodes.

Domain nodes are a bit more complex to run that content nodes because they require paying careful attention to managing SSL termination for one (or more) URLs. The earthfast/domain-node docker container supports multiple projects and terminates SSL between all of them as long as the SSL certificates are created. Domain node run via cloudflare pages (or any other static asset serve) can only serve a single project and domain.

There's two examples here for running Domain Nodes: Ubuntu VM and Cloudflare Pages

The difference between these two nodes is that an Ubuntu VM could be provisioned to serve a single project domain, or optionally configured for multiple projects across different domains. Cloudflare pages only serve a single domain and do SSL termination for a single URL.

##### Ubuntu VMs
Ubuntu VMs can be used to run your own node from scratch. For example if you're a node operator or trying to run your own hardware. This can be run on any on-prem or self hosted system as well as the major cloud hosting services like AWS, GCP, Azure etc.

##### Cloudflare Pages
This is a serverless way to run the Domain Node at the edge. Github can be connected to Cloudflare so new updates to the site automatically get published to Cloudflare.

While the example is for Cloudflare Pages, it's possible to run this on Github Pages, CloudFront, Vercel or anywhere else you can run static assets.