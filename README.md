# Ansible Control Node Container

This repository contains a Docker setup for an Ansible control node that manages QEMU VMs on a MacOS host.

## System Architecture

The setup consists of three main components:

1. **MacOS Host Machine**: Where QEMU VMs actually run
2. **Ansible Control Node**: A Docker container that runs Ansible
3. **QEMU Virtual Machines**: Ubuntu VMs created and managed by the control node

```
┌─────────────────────────────────────────────────────────────┐
│ MacOS Host                                                  │
│                                                            │
│  ┌────────────────────┐         ┌───────────────────┐      │
│  │   Docker Container │         │    QEMU VM        │      │
│  │  (Control Node)    │   SSH   │                   │      │
│  │                    │ ───────►│  - Ubuntu         │      │
│  │  - Ansible        ─┼─┐       │  - SSH Port 2222  │      │
│  │  - Python          │ │       │  - Cloud Init     │      │
│  └────────────────────┘ │       └───────────────────┘      │
│                         │                                   │
│                         │ SSH                              │
│                         └───► Host Machine                 │
│                               (for VM management)          │
└─────────────────────────────────────────────────────────────┘
```

## Goals

1. **Containerized Ansible**: Run Ansible in a Docker container to ensure consistent environment
2. **VM Management**: Create and manage QEMU VMs on the MacOS host
3. **SSH Access**: 
   - Control Node → MacOS Host: For VM management
   - Control Node → VM: For configuration
   - MacOS Host → VM: For direct access
4. **No Password Authentication**: Use SSH keys exclusively for all connections

## Prerequisites

- Docker installed on your system
- Basic understanding of Docker and Ansible
- For VM provisioning on the host machine:
  - QEMU installed via Homebrew
  - SSH key pair exists in `~/.ssh/`

### MacOS-Specific Setup
```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install QEMU
brew install qemu

# Ensure SSH key exists
ssh-keygen -t rsa -b 4096 # if you don't already have one
```

## Initial Setup

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/ansible-qemu-macos-control.git
cd ansible-qemu-macos-control
```

2. **Set up configuration files**
```bash
# Create inventory file from template
cp templates/inventory/hosts.template inventory/hosts
# Edit inventory/hosts and replace YOUR_USERNAME with your MacOS username

# Create group vars (optional)
cp templates/group_vars/macos_hosts/vars.yml.template group_vars/macos_hosts/vars.yml
# Edit vars.yml if you need to customize VM settings

# Create ansible config
cp templates/ansible.cfg.template ansible.cfg
```

3. **Build the container**
```bash
docker build -t ansible-control-node .
```

4. **Run the container**
```bash
docker run -d --name ansible-controller -v "$(pwd)/playbooks:/ansible/playbooks" -v "$(pwd)/inventory:/ansible/inventory" -v "$(pwd)/group_vars:/ansible/group_vars" -v "$(pwd)/ansible.cfg:/ansible/ansible.cfg:ro" -v "$HOME/.ssh:/root/.ssh:ro" ansible-control-node
```

## Using the Container

To execute commands inside the container:

```bash
# Check Ansible version
docker exec -it ansible-controller ansible --version

# Run a playbook
docker exec -it ansible-controller ansible-playbook playbooks/your-playbook.yml
```

### Creating QEMU VMs

The `provision_qemu_vm.yml` playbook will create a new VM on your host machine:

```bash
docker exec -it ansible-controller ansible-playbook playbooks/provision_qemu_vm.yml
```

You can customize the VM settings by editing the variables in `playbooks/provision_qemu_vm.yml`:
- `vm_name`: Name of the VM (default: "test-vm")
- `vm_memory`: RAM in MB (default: "2048")
- `vm_cpus`: Number of CPU cores (default: "2")
- `vm_disk_size`: Disk size (default: "20G")
- `vm_base_dir`: Base directory for VM files (default: "~/vms")

## Security Notes

- SSH keys are used exclusively (no password authentication)
- Host SSH keys are mounted read-only in the container
- The container needs SSH access to the host for VM management
- VMs are configured with cloud-init for secure initial setup
- Sensitive files are excluded via .gitignore

## Directory Structure

- `/ansible/playbooks`: Mount your playbooks here
- `/ansible/inventory`: Mount your inventory files here
- `/ansible/roles`: Directory for Ansible roles
- `/ansible/collections`: Directory for Ansible collections
- `/templates`: Reference templates for configuration files
  - `/templates/inventory`: Inventory file templates
  - `/templates/group_vars`: Group variables templates
  - Other configuration templates

## Playbook Examples

### Setting up MacOS Host
This playbook configures your MacOS host with necessary dependencies and settings:

```bash
docker exec -it ansible-controller ansible-playbook playbooks/setup_macos_host.yml
```

### Provisioning a QEMU VM
Create a new Ubuntu VM with custom settings:

```bash
# Create VM with default settings
docker exec -it ansible-controller ansible-playbook playbooks/provision_qemu_vm.yml

# Create VM with custom settings
docker exec -it ansible-controller ansible-playbook playbooks/provision_qemu_vm.yml \
  -e "vm_name=custom-ubuntu" \
  -e "vm_memory=4096" \
  -e "vm_cpus=4" \
  -e "vm_disk_size=40G"
```

### Testing VM Creation
Run the test playbook to verify VM creation functionality:

```bash
docker exec -it ansible-controller ansible-playbook playbooks/test_vm_creation.yml
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.