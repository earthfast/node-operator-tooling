from .utils import run_command, is_tool, install_package, get_os

def setup_ssl(domain):
    os_type = get_os()
    
    if not is_tool("certbot"):
        print("Certbot is not installed. Attempting to install...")
        if os_type == "macos":
            install_package("certbot")
        else:  # linux
            run_command("sudo snap install --classic certbot")
            run_command("sudo ln -s /snap/bin/certbot /usr/bin/certbot")

    if os_type == "macos":
        run_command(f"sudo certbot --nginx -d {domain} --non-interactive --agree-tos")
    else:  # linux
        run_command(f"sudo certbot --nginx -d {domain}")
