# How Ansible works:
Ansible can manage virtually anything on Linux/Unix systems:

```bash
1. Package Management
yaml# Install/remove software
- apt:
    name: nginx
    state: present
1. File & Directory Management
yaml# Create files, directories, set permissions
- file:
    path: /var/www/html
    state: directory
    owner: www-data
    mode: '0755'
1. Service Management
yaml# Start/stop/restart services
- systemd:
    name: nginx
    state: started
    enabled: yes
1. User & Group Management
yaml# Create users, manage SSH keys
- user:
    name: john
    groups: sudo
    shell: /bin/bash
1. Configuration Files
yaml# Deploy config files from templates
- template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
1. Network Configuration
yaml# Firewall rules, DNS settings
- ufw:
    rule: allow
    port: '80'
1. Database Setup
yaml# MySQL, PostgreSQL databases
- mysql_db:
    name: myapp
    state: present
1. Cloud Resources
yaml# AWS, Azure, DigitalOcean
- ec2_instance:
    name: webserver
    instance_type: t2.micro

    ```

``` bash
# One command for all servers
ansible-playbook setup.yml
```

### Architecture
```
Your Computer (Control Node)
    |
    | SSH Connection
    ↓
Target Servers (Managed Nodes)
```

**Key Components:**

1. **Control Node** (your laptop/workstation)
   - Has Ansible installed
   - Contains playbooks and roles
   - Initiates all commands

2. **Managed Nodes** (servers you're configuring)
   - Need SSH access
   - Need Python installed
   - Don't need Ansible installed!

3. **Inventory** (`inventory.ini`)
   - List of servers to manage
   - Groups them logically (webservers, databases, etc.)

4. **Playbooks** (`setup.yml`)
   - YAML files describing desired state
   - "Make sure nginx is installed and running"

5. **Roles** (folders in `roles/`)
   - Reusable bundles of tasks
   - Like building blocks you can mix and match

### How It Actually Works (Step by Step)
```
1. You run: ansible-playbook setup.yml
   ↓
2. Ansible reads setup.yml and inventory.ini
   ↓
3. For each server in inventory:
   - Connects via SSH
   - Transfers Python modules temporarily
   - Executes tasks in order
   - Reports back success/failure
   ↓
4. Shows you summary of what changed
```

## Ansible Configuration Management Project

This project demonstrates configuration management using Ansible with Docker containers for local development.

## 🎯 Project Overview

This Ansible playbook configures a Linux server with:
- **Base configuration**: Essential utilities, system updates, and fail2ban
- **SSH security**: Public key authentication setup
- **Nginx web server**: Installed and configured
- **Web application**: Static HTML website deployment

## 📋 Prerequisites

Before you begin, ensure you have:
- Docker and Docker Compose installed
- Ansible installed on your host machine
- Basic understanding of YAML and command line

### Install Ansible

**On Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install ansible -y
```

**On other systems or using pip:**
```bash
pip install ansible
```

### How to Create SSH Keys

Step 1: Generate Keys (if you don't have them)

```bash
# Generate a new SSH key pair
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# When prompted:
# - Press Enter to save in default location (~/.ssh/id_rsa)
# - Enter a passphrase (optional but recommended)
# - Press Enter again
```

You now have:

~/.ssh/id_rsa - Private key (never share!)
~/.ssh/id_rsa.pub - Public key (safe to share)

Step 2: Copy Public Key to Project
```bash
# Copy your public key to the ansible project
cp ~/.ssh/id_rsa.pub /path/to/ansible-project/files/public_key.pub
```



## 🚀 Quick Start

### 1. Start the Docker Container

```bash
# Navigate to the project directory
cd ansible-project

# Start the container
docker-compose up -d

# Verify the container is running
docker ps
```

### 2. Test Ansible Connection

```bash
# Test connectivity to the server
ansible -i inventory.ini webservers -m ping
```

You should see a SUCCESS message.

### 3. Run the Full Playbook

```bash
# Run all roles
ansible-playbook -i inventory.ini setup.yml
```

### 4. View Your Website

Open your browser and visit:
```
http://localhost:8080
```

You should see the deployed website!

## 🏷️ Using Tags

Run specific roles using tags:

```bash
# Run only the base configuration
ansible-playbook -i inventory.ini setup.yml --tags "base"

# Run only nginx setup
ansible-playbook -i inventory.ini setup.yml --tags "nginx"

# Run only app deployment
ansible-playbook -i inventory.ini setup.yml --tags "app"

# Run only SSH configuration
ansible-playbook -i inventory.ini setup.yml --tags "ssh"

# Run multiple tags
ansible-playbook -i inventory.ini setup.yml --tags "nginx,app"
```

## 📁 Project Structure

```
ansible-project/
├── setup.yml              # Main playbook
├── inventory.ini          # Server inventory
├── docker-compose.yml     # Docker orchestration
├── Dockerfile            # Container definition
├── roles/                # Ansible roles
│   ├── base/             # Base system configuration
│   ├── nginx/            # Web server setup
│   ├── app/              # Application deployment
│   └── ssh/              # SSH security configuration
└── files/                # Static files (website, keys)
```

## 🔧 Customization

### Add Your Own Website

1. Create a tarball of your static website:
```bash
cd your-website-directory
tar -czf website.tar.gz *
mv website.tar.gz /path/to/ansible-project/files/
```

2. Re-run the app role:
```bash
ansible-playbook -i inventory.ini setup.yml --tags "app"
```

### Add SSH Public Key

1. Generate an SSH key pair (if you don't have one):
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/ansible_key
```

2. Copy your public key:
```bash
cp ~/.ssh/ansible_key.pub files/public_key.pub
```

3. Run the SSH role:
```bash
ansible-playbook -i inventory.ini setup.yml --tags "ssh"
```

## 🐛 Troubleshooting

### Container won't start
```bash
# Check logs
docker-compose logs

# Rebuild the container
docker-compose down
docker-compose up -d --build
```

### Ansible can't connect
```bash
# Verify container is running
docker ps

# Check SSH is accessible
ssh -p 2222 root@localhost
# Password: ansible123

# Test with verbose mode
ansible -i inventory.ini webservers -m ping -vvv
```

### Website not showing
```bash
# Check nginx status inside container
docker exec ansible-target service nginx status

# Check nginx logs
docker exec ansible-target tail -f /var/log/nginx/error.log

# Verify files were deployed
docker exec ansible-target ls -la /var/www/html/
```

## 🎓 Learning Points

### What You've Learned:
1. **Ansible Basics**: Playbooks, roles, tasks, and handlers
2. **Inventory Management**: Defining and managing hosts
3. **Idempotency**: Running the same playbook multiple times safely
4. **Tags**: Selective execution of tasks
5. **Role Organization**: Structuring Ansible code properly
6. **Docker Integration**: Using containers for development

### From Docker to Production

The same playbook works on real servers! Just update `inventory.ini`:

```ini
[webservers]
production-server ansible_host=192.168.1.100 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/production_key
```

Then run:
```bash
ansible-playbook -i inventory.ini setup.yml
```

## 🏢 Real-World Usage

In organizations, this setup typically looks like:

1. **Development**: Docker containers (what you're doing now)
2. **Staging**: Cloud VMs that mirror production
3. **Production**: Cloud servers managed by the same playbooks

The workflow:
```
Developer writes playbook → Test in Docker → Test in staging → Deploy to production
```

## 📚 Next Steps

1. Add more roles (database, monitoring, etc.)
2. Use Ansible Vault for secrets
3. Implement variables and templates
4. Try deploying to a real cloud server
5. Set up CI/CD pipeline integration

## 🧹 Cleanup

When you're done:

```bash
# Stop and remove containers
docker-compose down

# Remove all project containers and volumes
docker-compose down -v
```

## 📖 Resources

- [Ansible Documentation](https://docs.ansible.com/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Docker Documentation](https://docs.docker.com/)

## ✨ Stretch Goals Completed

- ✅ All roles with proper tags
- ✅ Idempotent playbook design
- ✅ Docker containerization for local testing
- ✅ Proper role organization
- ✅ Security configurations (fail2ban, SSH)

Happy Learning! 🎉
