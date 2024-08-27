## EarthFast Domain Node using Static Asset Hosting

This example shows how you can use Github Actions to generate static assets that can serve the service worker similar to a EarthFast Domain Node.

This can also be adapted to work with any static site stack (Vercel, CloudFlare, CloudFront, Github Pages etc).

These assets should live independely of your front end repo.

#### How it works
A Github Action runs on a cron to build the latest version of the EarthFast service worker. The latest files for the Domain Node Service Worker get committed to your repository that has the Github Action running in it. The service worker loads website content by querying the set of content nodes directly in the browser. For more information see the [docs](https://docs.earthfast.com/overview/architecture-overview).

#### Examples

For the earthfast.com site running using this method, see https://github.com/earthfast/ef-on-ef.