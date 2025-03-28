### About
This repository contains Ansible playbooks for managing EarthFast Content Nodes. These playbooks provide automation for common operational tasks and require a separate inventory configuration.

### Requirements
- Ansible 2.9+ 
- Python 3
- Access to target nodes
- Proper SSH key configuration

### Installation
#### For MacOS
If you're on MacOS, you can quickly install Ansible via Homebrew:

```shell
brew install ansible
```

#### For Other Platforms
Ensure Python 3 is installed on your system. Set up a virtual environment and install Ansible using pip:

```shell
# Create and activate a virtual environment
python3 -m venv ansible-venv
source ansible-venv/bin/activate

# Install Ansible
pip3 install ansible
```

### Available Playbooks
Below are the available playbooks and their descriptions:

#### git_pull_restart.yml
Updates content nodes to the latest version and restarts services:
- Pulls the latest code from the repository
- Performs Docker Compose restart
- Displays operation results

#### env_edit.yml
Manages environment variable updates:
- Adds or updates properties in .env files
- Preserves existing configurations
- Supports variable injection

#### setup_auto_upgrade.yml
Configures automatic updates:
- Sets up periodic git pull via cron
- Preserves local configurations
- Includes logging and rotation

### Usage
These playbooks should be used with a properly configured inventory file that specifies your target nodes. Here’s how you can use each playbook:

#### Update to Latest Version of Content Nodes
To pull the latest code and restart services, execute:

```shell
ansible-playbook -i /path/to/your/inventory git_pull_restart.yml
```

#### Update Environment Variables
To update or add environment variables, run:

```shell
ansible-playbook -i /path/to/your/inventory env_edit.yml
```

#### Configure Automatic Git Pulls
To set up automatic updates using cron jobs, use:

```shell
ansible-playbook -i /path/to/your/inventory setup_auto_upgrade.yml
```
