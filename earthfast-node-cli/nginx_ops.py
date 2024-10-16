import os
from .utils import run_command, get_os

def setup_nginx(domain_node_url, domain_to_project_mapping):
    os_type = get_os()
    
    if os_type == "macos":
        nginx_conf_dir = "/usr/local/etc/nginx"
        sites_available_dir = f"{nginx_conf_dir}/servers"
        sites_enabled_dir = sites_available_dir  # macOS nginx doesn't use sites-enabled
    else:  # linux
        nginx_conf_dir = "/etc/nginx"
        sites_available_dir = f"{nginx_conf_dir}/sites-available"
        sites_enabled_dir = f"{nginx_conf_dir}/sites-enabled"

    # Ensure directories exist
    os.makedirs(sites_available_dir, exist_ok=True)
    os.makedirs(sites_enabled_dir, exist_ok=True)

    # Setup main domain
    config = create_nginx_config(domain_node_url)
    write_and_link_config(domain_node_url, config, sites_available_dir, sites_enabled_dir)

    # Setup project domains
    domains = [domain.split('=')[0] for domain in domain_to_project_mapping.split(',')]
    for domain in domains:
        config = create_nginx_config(domain)
        write_and_link_config(domain, config, sites_available_dir, sites_enabled_dir)

    # Increase server_names_hash_bucket_size
    nginx_conf_path = f"{nginx_conf_dir}/nginx.conf"
    with open(nginx_conf_path, "r") as f:
        content = f.read()
    if "server_names_hash_bucket_size 128;" not in content:
        content = content.replace("http {", "http {\n    server_names_hash_bucket_size 128;")
        with open(nginx_conf_path, "w") as f:
            f.write(content)

    # Restart nginx
    if os_type == "macos":
        run_command("brew services restart nginx")
    else:
        run_command("sudo systemctl restart nginx")

def create_nginx_config(domain):
    return f"""
server {{
    listen 80;
    listen [::]:80;
    server_name {domain};

    location / {{
        proxy_pass http://0.0.0.0:30080;
        proxy_set_header   X-Forwarded-For $remote_addr;
        proxy_set_header   Host $http_host;
    }}
}}
"""

def write_and_link_config(domain, config, available_dir, enabled_dir):
    available_path = os.path.join(available_dir, domain)
    with open(available_path, "w") as f:
        f.write(config)
    
    if available_dir != enabled_dir:  # Only create symlink on Linux
        enabled_path = os.path.join(enabled_dir, domain)
        if not os.path.exists(enabled_path):
            os.symlink(available_path, enabled_path)

def update_nginx_config(server_name, http_port):
    nginx_config = f"""
server {{
    listen 80;
    listen [::]:80;
    server_name {server_name};
    return 301 https://$server_name$request_uri;
}}

server {{
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name {server_name};

    ssl_certificate /etc/letsencrypt/live/{server_name}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/{server_name}/privkey.pem;

    location / {{
        proxy_pass http://127.0.0.1:{http_port};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }}
}}
"""
    with open("/etc/nginx/sites-available/default", "w") as f:
        f.write(nginx_config)
    run_command("nginx -s reload")

def setup_domain_nginx(domain_node_url, domain_to_project_mapping):
    config = f"""
server {{
    listen 80;
    listen [::]:80;
    server_name {domain_node_url};

    location / {{
        proxy_pass http://0.0.0.0:30080;
        proxy_set_header   X-Forwarded-For $remote_addr;
        proxy_set_header   Host $http_host;
    }}
}}
"""
    with open(f"/etc/nginx/sites-available/{domain_node_url}", "w") as f:
        f.write(config)
    os.symlink(f"/etc/nginx/sites-available/{domain_node_url}", f"/etc/nginx/sites-enabled/{domain_node_url}")

    domains = [domain.split('=')[0] for domain in domain_to_project_mapping.split(',')]
    for domain in domains:
        config = f"""
server {{
    listen 80;
    listen [::]:80;
    server_name {domain};

    location / {{
        proxy_pass http://0.0.0.0:30080;
        proxy_set_header   X-Forwarded-For $remote_addr;
        proxy_set_header   Host $http_host;
    }}
}}
"""
        with open(f"/etc/nginx/sites-available/{domain}", "w") as f:
            f.write(config)
        os.symlink(f"/etc/nginx/sites-available/{domain}", f"/etc/nginx/sites-enabled/{domain}")

    # Increase server_names_hash_bucket_size
    with open("/etc/nginx/nginx.conf", "r") as f:
        content = f.read()
    content = content.replace("# server_names_hash_bucket_size 64;", "server_names_hash_bucket_size 128;")
    with open("/etc/nginx/nginx.conf", "w") as f:
        f.write(content)
