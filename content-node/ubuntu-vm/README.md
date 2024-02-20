### Content Node on Ubuntu VM

1. Rename `values.env.example` to `values.env`
2. Run the script with `sudo sh content-node-setup.sh <absolute-path-to-env-file>`
3. Curl `localhost:30080/statusz` to make sure the server is up and returning a response