### Content Node on Akash Network

Create a new Deployment on Akash Network with the included Akash definition file. Once the content node boots up make sure it's accessible through an https URL.

If the URL provided by the deployment is https, you can directly register that URL on Armada. If the URL provided by the deployment is not https, you can proxy it through Cloudflare to add SSL:
1. Add a CNAME record 
CNAME   content-node.domain.io  <akash-deployment-url>
2. CHeck that the URL is accessible. If it's not accessible you may need to set the HOST header rewrite in Cloudflare. Instructions are here https://developers.cloudflare.com/rules/page-rules/how-to/rewrite-host-headers/.