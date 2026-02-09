# Ansible in Docker - Complete Guide

## 🎯 What This Is

This is a **100% Docker-based** Ansible learning environment. **No local Ansible installation needed!**

Everything runs in containers:
```
Docker Network
  ├── ansible-controller (runs Ansible commands)
  └── ansible-target (the server being configured)
```

## 🚀 Why This Approach?

### ❌ What You DON'T Need:
- ❌ Ansible installed on Windows
- ❌ WSL (Windows Subsystem for Linux)
- ❌ Python environment setup
- ❌ SSH key configuration on your machine

### ✅ What You DO Need:
- ✅ Docker Desktop (that's it!)

## 📦 Project Structure

```
ansible-docker-setup/
├── docker-compose.yml           # Orchestrates both containers
├── Dockerfile.controller        # Ansible control node
├── Dockerfile.target           # Target server
└── ansible/                    # Your playbooks (mounted into controller)
    ├── setup.yml
    ├── inventory.ini
    ├── roles/
    │   ├── base/
    │   ├── nginx/
    │   ├── app/
    │   └── ssh/
    └── files/
```

## 🎬 Quick Start

### Step 1: Start Both Containers

```bash
# In PowerShell or Command Prompt
cd ansible-docker-setup
docker-compose up -d
```

This starts:
- `ansible-controller` - has Ansible installed
- `ansible-target` - empty Ubuntu server to configure

### Step 2: Run Ansible Playbook

```bash
# Execute Ansible from the controller container
docker-compose exec ansible-controller ansible-playbook -i inventory.ini setup.yml
```

### Step 3: View Your Website

```bash
# Open in browser
start http://localhost:8080
```

## 🎮 Common Commands

### Running Playbooks

```bash
# Run entire playbook
docker-compose exec ansible-controller ansible-playbook -i inventory.ini setup.yml

# Run specific role with tags
docker-compose exec ansible-controller ansible-playbook -i inventory.ini setup.yml --tags "nginx"

# Dry run (check what would change)
docker-compose exec ansible-controller ansible-playbook -i inventory.ini setup.yml --check

# Verbose output for debugging
docker-compose exec ansible-controller ansible-playbook -i inventory.ini setup.yml -vvv
```

### Testing Connectivity

```bash
# Ping test
docker-compose exec ansible-controller ansible -i inventory.ini webservers -m ping

# Run ad-hoc command
docker-compose exec ansible-controller ansible -i inventory.ini webservers -a "uptime"
```

### Interactive Shell

```bash
# Get a bash shell in the controller (where Ansible lives)
docker-compose exec ansible-controller bash

# Now you're inside the container, run Ansible directly:
ansible-playbook -i inventory.ini setup.yml
```

### Container Management

```bash
# View logs
docker-compose logs -f

# Stop containers
docker-compose stop

# Start containers
docker-compose start

# Restart everything
docker-compose restart

# Stop and remove containers
docker-compose down

# Rebuild containers (after Dockerfile changes)
docker-compose up -d --build
```

## 🔍 How It Works

### The Flow

```
1. You edit files in: ansible-docker-setup/ansible/
   ↓
2. Files are mounted into: ansible-controller container
   ↓
3. You run: docker-compose exec ansible-controller ansible-playbook ...
   ↓
4. Ansible connects via SSH to: ansible-target container
   ↓
5. Configuration happens on: ansible-target
   ↓
6. You see results at: http://localhost:8080
```

### Container Communication

Both containers are on the same Docker network (`ansible-net`), so they can talk to each other using container names:

```yaml
# In inventory.ini
ansible-target ansible_host=ansible-target  # Uses container name!
```

No need for IP addresses or port forwarding for SSH between containers!

## 📝 Editing Playbooks

### On Windows

Simply edit files in the `ansible/` folder with your favorite editor:
- VS Code
- Notepad++
- Sublime Text
- etc.

Changes are **immediately available** in the controller container (via volume mount).

### Workflow

```bash
# 1. Edit playbook on Windows
# Open ansible/setup.yml in VS Code, make changes, save

# 2. Run from controller
docker-compose exec ansible-controller ansible-playbook -i inventory.ini setup.yml

# 3. See results
start http://localhost:8080
```

## 🎯 Understanding the Architecture

### Why Two Containers?

This simulates a real-world setup:

**Real World:**
```
Your Laptop (Ansible installed)
    ↓ SSH
Production Server (no Ansible needed)
```

**This Setup:**
```
ansible-controller (Ansible installed)
    ↓ SSH (over Docker network)
ansible-target (no Ansible needed)
```

### What Each Container Does

| Container | Role | Has Ansible? | Purpose |
|-----------|------|--------------|---------|
| `ansible-controller` | Control Node | ✅ Yes | Runs playbooks |
| `ansible-target` | Managed Node | ❌ No | Gets configured |

## 🔧 Customization

### Add Your Own Website

```bash
# 1. Create your website files
mkdir my-website
echo "<h1>My Site</h1>" > my-website/index.html

# 2. Create tarball
cd my-website
tar -czf ../website.tar.gz *

# 3. Move to project
mv ../website.tar.gz ansible-docker-setup/ansible/files/

# 4. Deploy
docker-compose exec ansible-controller ansible-playbook -i inventory.ini setup.yml --tags "app"
```

### Modify Roles

Edit any file in `ansible/roles/`:
- `ansible/roles/base/tasks/main.yml` - base configuration
- `ansible/roles/nginx/tasks/main.yml` - web server
- `ansible/roles/app/tasks/main.yml` - application deployment
- `ansible/roles/ssh/tasks/main.yml` - SSH security

Changes take effect immediately!

## 🐛 Troubleshooting

### Container Won't Start

```bash
# Check logs
docker-compose logs

# Rebuild from scratch
docker-compose down
docker-compose up -d --build
```

### Can't Connect to ansible-target

```bash
# Verify both containers are running
docker ps

# Check if target is accessible
docker-compose exec ansible-controller ping -c 3 ansible-target

# Test SSH manually
docker-compose exec ansible-controller ssh root@ansible-target
# Password: ansible123
```

### Playbook Fails

```bash
# Run with verbose output
docker-compose exec ansible-controller ansible-playbook -i inventory.ini setup.yml -vvv

# Check what changed
docker-compose exec ansible-controller ansible-playbook -i inventory.ini setup.yml --check --diff
```

### Website Not Loading

```bash
# Check nginx status in target
docker-compose exec ansible-target service nginx status

# Check nginx logs
docker-compose exec ansible-target cat /var/log/nginx/error.log

# Verify files deployed
docker-compose exec ansible-target ls -la /var/www/html/
```

## 🎓 Learning Path

### Beginner

1. ✅ Run the full playbook: `docker-compose exec ansible-controller ansible-playbook -i inventory.ini setup.yml`
2. ✅ Run individual roles with tags
3. ✅ Modify the app role to deploy your own website
4. ✅ Check results in browser

### Intermediate

1. Edit existing roles
2. Add new tasks to roles
3. Use variables in playbooks
4. Create new roles from scratch

### Advanced

1. Use Ansible Vault for secrets
2. Create templates with Jinja2
3. Add more target servers to inventory
4. Create complex multi-tier applications

## 🌐 Real-World Transition

When you're ready to use this on real servers:

### Current Setup (Docker)
```yaml
[webservers]
ansible-target ansible_host=ansible-target
```

### Production Setup (Real Servers)
```yaml
[webservers]
web1 ansible_host=192.168.1.10 ansible_user=ubuntu
web2 ansible_host=192.168.1.11 ansible_user=ubuntu
```

**Same playbooks, different inventory!** That's the power of Ansible.

## 💡 Pro Tips

1. **Keep controller running**: The controller container just needs to run once, then use `exec` for all commands

2. **Use shell aliases**: Add to your PowerShell profile:
   ```powershell
   function ansible-play { docker-compose exec ansible-controller ansible-playbook -i inventory.ini $args }
   function ansible-cmd { docker-compose exec ansible-controller ansible -i inventory.ini $args }
   ```

3. **Version control**: Put the `ansible/` folder in Git to track changes

4. **Multiple environments**: Create different inventory files:
   - `inventory-dev.ini`
   - `inventory-staging.ini`
   - `inventory-prod.ini`

## 📚 Additional Resources

- [Ansible Documentation](https://docs.ansible.com/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Docker Documentation](https://docs.docker.com/)

## 🎉 Summary

You now have a **complete Ansible environment** without installing Ansible on Windows!

**Key takeaway**: Ansible doesn't need to be on your local machine. It just needs to be somewhere that can SSH to your servers. In this case, that "somewhere" is a Docker container.

Happy automating! 🚀
