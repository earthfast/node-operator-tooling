## Armada Domain Node using Cloudflare Pages

This example shows how you can use Cloudflare Pages + Github Actions instead of a Ubuntu VM to host a domain node. The domain node is the gateway for you application served using Armada, for more information check out the [official docs](https://docs.armadanetwork.com/armada-network-docs/overview/architecture-overview#domain-node).

#### How it works
A Github Action runs a job every day at midnight to build the latest version of the Armada service worker. The latest files for the domain node get committed to your repository that has the Github Action running in it.

Don't I need to connect this to my front end repo? No, the domain node does not serve any website content. That's handled separately by a combination of the on chain project registry + Armada's content nodes. For more information see the [docs](https://docs.armadanetwork.com/armada-network-docs/overview/architecture-overview).

#### Setup
1. Clone (or fork) this repo
2. Set these variables in your Github settings
    `PROJECT_ID` (Repository Variable) - Armada ProjectID
    `GH_TOKEN` (Repository Secret) - Github access token
3. Connect to [Cloudflare Pages using Git](https://developers.cloudflare.com/pages/framework-guides/deploy-anything/#deploy-with-cloudflare-pages) and setup a DNS record for the page.
4. The cron action will auto update your site and Cloudflare Pages will be updated


#### Custom Loading Screen

By default you'll see the default Armada loading screen. If you want to change the content, modify the build/index.html file but that might require some Github Action customization to make sure your files are not overwritten.