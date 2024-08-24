### Content Node on Akash Network

Create a new Deployment on Akash Network with the included Akash definition file. Once the content node boots up make sure it's accessible through an https URL.

While some Akash deployments provide urls with SSL, it's recommended you set up a proxy with SSL and DDoS protection, something like nginx or cloudflare or similar. This is not just for security and attack protection but in the event the underlying node goes down and you need to swap it out, changing urls on chain can be involved.

Here's how you proxy the URL through Cloudflare with SSL

1. When setting up the Akash deployment make sure you set your anticipated URL as the "accept" host in the expose section. Launch deployment
2. Add a CNAME record on Cloudflare
`CNAME   content-node.domain.io  <akash-deployment-url>`
3. Check that the URL is accessible. If so, you can now register this URL on chain