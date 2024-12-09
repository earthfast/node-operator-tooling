### About
Ansible playbooks for managing EarthFast Content Nodes. These playbooks provide automation for common operational tasks.

### Available Playbooks

#### git_pull_restart.yml
Updates content nodes to the latest version and restarts services:
- Pulls latest code from the repository
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
These playbooks are designed to be used with a separate inventory configuration.

Example usage (assuming proper inventory setup):
```shell
ansible-playbook -i /path/to/your/inventory playbooks/git_pull_restart.yml
```

### Requirements
- Ansible 2.9+
- Python 3
- Access to target nodes
- Proper SSH key configuration
