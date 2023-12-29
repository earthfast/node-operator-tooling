### Domain Node
Domain nodes can be run in two ways: Ubuntu VM and Cloudflare Pages

The difference between these two nodes is that an Ubuntu VM could be provisioned to serve a single project domain, or optionally configured for multiple project domains across multiple projects. Cloudflare pages acts as the domain node for a single domain only.

##### Ubuntu VMs
Ubuntu VMs can be used to run your own node from scratch. For example if you're a node operator or trying to run your own hardware. This can be run on any on-prem or self hosted system as well as the major cloud hosting services like AWS, GCP, Azure etc.

##### Cloudflare Pages
This is a serverless way to run the Domain Node at the edge. Github can be connected to Cloudflare so new updates to the site automatically get published to Cloudflare