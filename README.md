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
  - QEMU/KVM installed
  - libvirt and related tools
  - cloud-image-utils

### Host Machine Setup (for VM provisioning)
```bash
# For Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y \
  qemu-kvm \
  libvirt-daemon-system \
  libvirt-clients \
  virtinst \
  bridge-utils \
  cloud-image-utils

# Add your user to the libvirt group
sudo usermod -aG libvirt $USER
sudo usermod -aG kvm $USER

# Verify KVM installation
virt-host-validate
```

### Check KVM Support
```bash
# Check if your CPU supports hardware virtualization
egrep -c '(vmx|svm)' /proc/cpuinfo

# Check if KVM module is loaded
lsmod | grep kvm

# Verify KVM device exists
ls -l /dev/kvm
```

### MacOS-Specific Setup
For MacOS hosts, the setup is simplified:
- Install Docker Desktop for Mac
- Install Homebrew
- Install QEMU via Homebrew: `brew install qemu`
- Ensure SSH key pair exists in `~/.ssh/`

## Initial Setup

### 1. SSH Key Setup
```bash
# Check if you already have an SSH key
ls -la ~/.ssh/id_rsa.pub

# If no SSH key exists, create one (accept default location and add optional passphrase)
ssh-keygen -t rsa -b 4096

# Verify the key was created
ls -la ~/.ssh/id_rsa.pub
```

### 2. Building the Container

```bash
docker build -t ansible-control-node .
```

### 3. Running the Container

```bash
docker run -d --name ansible-controller \
  -v $(pwd)/playbooks:/ansible/playbooks \
  -v $(pwd)/inventory:/ansible/inventory \
  -v ~/.ssh:/root/.ssh:ro \
  -v /var/run/libvirt/libvirt-sock:/var/run/libvirt/libvirt-sock \
  ansible-control-node
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

The `provision_qemu_vm.yml` playbook will create a new VM on your host machine and automatically add it to your inventory:

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

## Directory Structure

- `/ansible/playbooks`: Mount your playbooks here
- `/ansible/inventory`: Mount your inventory files here
- `/ansible/roles`: Directory for Ansible roles
- `/ansible/collections`: Directory for Ansible collections

## Notes

- The container uses Python 3.9 as the base image
- SSH keys are mounted from your host system as read-only
- Host key checking is disabled by default for convenience
- The SSH key at `~/.ssh/id_rsa.pub` is used for VM provisioning
- VMs are created on the host machine, not inside the container
- The libvirt socket is mounted to allow container to control host's libvirt