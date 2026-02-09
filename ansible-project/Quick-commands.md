# Ansible Cheat Sheet

## 🚀 Quick Commands

### Running Playbooks

```bash
# Run the entire playbook
ansible-playbook -i inventory.ini setup.yml

# Run with verbose output (helpful for debugging)
ansible-playbook -i inventory.ini setup.yml -v
ansible-playbook -i inventory.ini setup.yml -vv
ansible-playbook -i inventory.ini setup.yml -vvv

# Dry run (check mode - doesn't make changes)
ansible-playbook -i inventory.ini setup.yml --check

# Run specific tags
ansible-playbook -i inventory.ini setup.yml --tags "base"
ansible-playbook -i inventory.ini setup.yml --tags "nginx,app"

# Skip specific tags
ansible-playbook -i inventory.ini setup.yml --skip-tags "base"

# List all tags
ansible-playbook -i inventory.ini setup.yml --list-tags

# List all tasks
ansible-playbook -i inventory.ini setup.yml --list-tasks
```

### Ad-hoc Commands

```bash
# Ping all hosts
ansible -i inventory.ini all -m ping

# Run a command on all hosts
ansible -i inventory.ini webservers -a "uptime"
ansible -i inventory.ini webservers -a "df -h"

# Install a package
ansible -i inventory.ini webservers -m apt -a "name=htop state=present" --become

# Copy a file
ansible -i inventory.ini webservers -m copy -a "src=/local/file dest=/remote/file"

# Restart a service
ansible -i inventory.ini webservers -m service -a "name=nginx state=restarted" --become

# Gather facts about hosts
ansible -i inventory.ini webservers -m setup
```

## 📋 Common Modules

### Package Management
```yaml
# Install package
- apt:
    name: nginx
    state: present

# Remove package
- apt:
    name: nginx
    state: absent

# Install multiple packages
- apt:
    name:
      - nginx
      - curl
      - git
    state: present
```

### File Operations
```yaml
# Create directory
- file:
    path: /var/www/html
    state: directory
    mode: '0755'

# Create file with content
- copy:
    dest: /etc/config.conf
    content: |
      line 1
      line 2

# Copy file from local
- copy:
    src: files/myfile.txt
    dest: /remote/path/

# Delete file
- file:
    path: /tmp/oldfile
    state: absent
```

### Service Management
```yaml
# Start and enable service
- systemd:
    name: nginx
    state: started
    enabled: yes

# Restart service
- systemd:
    name: nginx
    state: restarted

# Stop service
- systemd:
    name: nginx
    state: stopped
```

## 🏷️ Tags Best Practices

```yaml
# Multiple tags on a role
- role: nginx
  tags: ['nginx', 'web', 'infrastructure']

# Tag individual tasks
- name: Install nginx
  apt:
    name: nginx
    state: present
  tags: ['nginx', 'packages']

# Always run certain tasks
- name: Update apt cache
  apt:
    update_cache: yes
  tags: ['always']

# Never run certain tasks by default
- name: Dangerous operation
  command: rm -rf /tmp/*
  tags: ['never']
```

## 🔍 Debugging

```bash
# Show all variables for a host
ansible -i inventory.ini webservers -m debug -a "var=hostvars[inventory_hostname]"

# Debug in playbook
- debug:
    msg: "The value is {{ my_variable }}"

- debug:
    var: ansible_facts

# Step through playbook
ansible-playbook -i inventory.ini setup.yml --step

# Start at specific task
ansible-playbook -i inventory.ini setup.yml --start-at-task="Install nginx"
```

## 🎯 Inventory Tips

### Basic Inventory
```ini
[webservers]
server1 ansible_host=192.168.1.10
server2 ansible_host=192.168.1.11

[databases]
db1 ansible_host=192.168.1.20

[webservers:vars]
ansible_user=ubuntu
ansible_port=22
```

### Group of Groups
```ini
[production:children]
webservers
databases

[production:vars]
env=production
```

## 📦 Role Structure

```
roles/
└── rolename/
    ├── tasks/
    │   └── main.yml          # Main task list
    ├── handlers/
    │   └── main.yml          # Handlers
    ├── templates/
    │   └── config.j2         # Jinja2 templates
    ├── files/
    │   └── static_file       # Static files
    ├── vars/
    │   └── main.yml          # Variables
    ├── defaults/
    │   └── main.yml          # Default variables
    └── meta/
        └── main.yml          # Role metadata
```

## 🔐 Security

### Using SSH Keys
```ini
[servers]
server1 ansible_host=192.168.1.10 ansible_ssh_private_key_file=~/.ssh/id_rsa
```

### Using Ansible Vault
```bash
# Create encrypted file
ansible-vault create secrets.yml

# Edit encrypted file
ansible-vault edit secrets.yml

# Encrypt existing file
ansible-vault encrypt vars.yml

# Decrypt file
ansible-vault decrypt vars.yml

# Run playbook with vault
ansible-playbook -i inventory.ini setup.yml --ask-vault-pass
```

## 📝 Variables

### Precedence (highest to lowest)
1. Extra vars (-e in command line)
2. Task vars
3. Block vars
4. Role and include vars
5. Play vars
6. Host facts
7. Host vars
8. Group vars
9. Role defaults

### Using Variables
```yaml
# Define in playbook
vars:
  app_name: myapp
  app_port: 8080

# Use in tasks
- name: Create directory for {{ app_name }}
  file:
    path: /opt/{{ app_name }}
    state: directory

# Command line
ansible-playbook setup.yml -e "app_name=newapp"
```

## 🔄 Loops

```yaml
# Simple loop
- name: Install packages
  apt:
    name: "{{ item }}"
    state: present
  loop:
    - nginx
    - curl
    - git

# Loop with dictionary
- name: Create users
  user:
    name: "{{ item.name }}"
    state: present
    groups: "{{ item.groups }}"
  loop:
    - { name: 'john', groups: 'admin' }
    - { name: 'jane', groups: 'users' }
```

## ✅ Conditionals

```yaml
# When condition
- name: Install nginx on Debian
  apt:
    name: nginx
    state: present
  when: ansible_os_family == "Debian"

# Multiple conditions
- name: Run on production webservers
  debug:
    msg: "This is production"
  when:
    - env == "production"
    - inventory_hostname in groups['webservers']
```

## 🎓 Best Practices

1. **Use roles** for organizing code
2. **Tag everything** for selective execution
3. **Make tasks idempotent** (safe to run multiple times)
4. **Use variables** for configuration values
5. **Use templates** for config files
6. **Check mode first** before production
7. **Version control** your playbooks
8. **Document** your roles and variables
9. **Test in staging** before production
10. **Use vault** for sensitive data

## 🐳 Docker-Specific Commands

```bash
# View container logs
docker-compose logs -f

# Execute command in container
docker exec -it ansible-target bash

# Restart container
docker-compose restart

# Stop and remove
docker-compose down

# Rebuild container
docker-compose up -d --build

# View running containers
docker ps
```

## 📚 Useful Links

- [Ansible Documentation](https://docs.ansible.com/)
- [Ansible Galaxy](https://galaxy.ansible.com/) - Community roles
- [Ansible Lint](https://ansible-lint.readthedocs.io/) - Linting tool
- [Molecule](https://molecule.readthedocs.io/) - Testing framework
