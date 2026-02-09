# Quick Reference - Docker Ansible Commands

## 🚀 Essential Commands

### Start Everything
```bash
docker-compose up -d
```

### Run Ansible Playbook
```bash
docker-compose exec ansible-controller ansible-playbook -i inventory.ini setup.yml
```

### Run Specific Role
```bash
docker-compose exec ansible-controller ansible-playbook -i inventory.ini setup.yml --tags "nginx"
```

### Test Connection
```bash
docker-compose exec ansible-controller ansible -i inventory.ini webservers -m ping
```

### Get Interactive Shell
```bash
docker-compose exec ansible-controller bash
```

### View Website
```
http://localhost:8080
```

### Stop Everything
```bash
docker-compose down
```

---

## 📋 Command Breakdown

### What `docker-compose exec` Does
```
docker-compose exec ansible-controller <command>
                   ↑                    ↑
                   |                    |
            Container name         Command to run
```

Example:
```bash
docker-compose exec ansible-controller ansible-playbook -i inventory.ini setup.yml
                   ↑_______________↑   ↑_______________________________________↑
                   Run this command     Inside this container
```

---

## 🎯 Common Tasks

| Task | Command |
|------|---------|
| Run all roles | `docker-compose exec ansible-controller ansible-playbook -i inventory.ini setup.yml` |
| Run base only | `docker-compose exec ansible-controller ansible-playbook -i inventory.ini setup.yml --tags "base"` |
| Run nginx only | `docker-compose exec ansible-controller ansible-playbook -i inventory.ini setup.yml --tags "nginx"` |
| Run app only | `docker-compose exec ansible-controller ansible-playbook -i inventory.ini setup.yml --tags "app"` |
| Dry run | `docker-compose exec ansible-controller ansible-playbook -i inventory.ini setup.yml --check` |
| Verbose mode | `docker-compose exec ansible-controller ansible-playbook -i inventory.ini setup.yml -vvv` |

---

## 🔧 Container Management

| Task | Command |
|------|---------|
| Start | `docker-compose up -d` |
| Stop | `docker-compose stop` |
| Restart | `docker-compose restart` |
| View logs | `docker-compose logs -f` |
| Remove | `docker-compose down` |
| Rebuild | `docker-compose up -d --build` |
| List containers | `docker ps` |

---

## 🐚 Inside Container Commands

After running `docker-compose exec ansible-controller bash`:

```bash
# You're now inside the container, no need for docker-compose exec!

# Run playbook
ansible-playbook -i inventory.ini setup.yml

# Ping servers
ansible -i inventory.ini webservers -m ping

# Ad-hoc command
ansible -i inventory.ini webservers -a "uptime"

# Exit container
exit
```

---

## 📝 File Editing Workflow

1. Edit files on Windows in `ansible/` folder
2. Changes automatically appear in container (volume mount)
3. Run playbook: `docker-compose exec ansible-controller ansible-playbook -i inventory.ini setup.yml`
4. Check results: `http://localhost:8080`

---

## 🎨 PowerShell Aliases (Optional)

Add to PowerShell profile for shortcuts:

```powershell
# Edit profile
notepad $PROFILE

# Add these functions:
function ap { docker-compose exec ansible-controller ansible-playbook -i inventory.ini $args }
function ac { docker-compose exec ansible-controller ansible -i inventory.ini $args }
function ash { docker-compose exec ansible-controller bash }

# Save and reload
. $PROFILE
```

Now you can use:
```powershell
ap setup.yml                    # Instead of docker-compose exec...
ap setup.yml --tags "nginx"     # Run with tags
ac webservers -m ping           # Ping servers
ash                             # Get shell
```
