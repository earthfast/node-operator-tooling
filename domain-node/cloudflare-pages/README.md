## EarthFast Domain Node using Cloudflare Pages

This example shows how you can use Cloudflare Pages + Github Actions instead of a Ubuntu VM to host the EarthFast Domain Node.

This can also be adapted to work with any static site stack (Vercel, CloudFront, Github Pages etc)

#### How it works
A Github Action runs on a cron to build the latest version of the EarthFast service worker. The latest files for the Domain Node Service Worker get committed to your repository that has the Github Action running in it. These assets should live independely of your front end repo. The website content is loaded by the set of content nodes directly by the browser. For more information see the [docs](https://docs.earthfast.com/overview/architecture-overview).

#### Setup
1. Create a new repo with the .github/workflows/generate-service-worker.yml workflow
2. Set these variables in your Github settings
    `PROJECT_ID` (Repository Variable) - EarthFast ProjectID
3. Connect to [Cloudflare Pages using Git](https://developers.cloudflare.com/pages/framework-guides/deploy-anything/#deploy-with-cloudflare-pages) (or your front end serving stack of choice) and setup a DNS record for the page.
4. The cron action will auto update the service worker and Cloudflare Pages will be updated


#### Extensions

##### Custom Loading Screen

By default you'll see the default EarthFast loading screen. If you want to change the content, modify the build/index.html file but that might require some Github Action customization to make sure your files are not overwritten.

##### SEO considerations

You can use the combination of Cloudflare Pages + Workers to serve a SEO friendly version of your site to web crawlers while allowing users to load the service worke.