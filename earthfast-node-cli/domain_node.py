from .docker_ops import start_docker_container, ensure_docker
from .nginx_ops import setup_nginx
from .ssl_ops import setup_ssl
from .utils import install_package, get_os

class DomainNode:
    def __init__(self, env, setup_ssl, start_container):
        self.env = env
        self.setup_ssl = setup_ssl
        self.start_container = start_container

    def deploy(self):
        os_type = get_os()

        # Install Nginx
        install_package("nginx")

        # Ensure Docker is installed
        ensure_docker()

        # Setup Nginx
        setup_nginx(self.env['DOMAIN_NODE_URL'], self.env['DOMAIN_TO_PROJECT_MAPPING'])

        # Setup SSL if requested
        if self.setup_ssl:
            if os_type == "linux":
                install_package("certbot")
                install_package("python3-certbot-nginx")
            setup_ssl(self.env['DOMAIN_NODE_URL'])
            for domain in self.env['DOMAIN_TO_PROJECT_MAPPING'].split(','):
                domain = domain.split('=')[0]
                setup_ssl(domain)

        # Start Docker container if requested
        if self.start_container:
            start_docker_container('domain-node', self.env)

        print("Domain Node deployment completed successfully.")
