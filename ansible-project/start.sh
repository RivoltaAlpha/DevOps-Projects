#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Ansible Configuration Manager${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command_exists docker; then
    echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

if ! command_exists docker-compose; then
    echo -e "${RED}❌ Docker Compose is not installed. Please install Docker Compose first.${NC}"
    exit 1
fi

if ! command_exists ansible; then
    echo -e "${RED}❌ Ansible is not installed. Please install Ansible first.${NC}"
    echo -e "${YELLOW}Install with: pip install ansible${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All prerequisites installed!${NC}"
echo ""

# Start Docker container
echo -e "${YELLOW}Starting Docker container...${NC}"
docker-compose up -d

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to start Docker container${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Container started!${NC}"
echo ""

# Wait for container to be ready
echo -e "${YELLOW}Waiting for container to be ready...${NC}"
sleep 5

# Test connection
echo -e "${YELLOW}Testing Ansible connection...${NC}"
ansible -i inventory.ini webservers -m ping

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to connect to the server${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✓ Connection successful!${NC}"
echo ""

# Ask user if they want to run the playbook
echo -e "${YELLOW}Do you want to run the full playbook now? (y/n)${NC}"
read -r response

if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo ""
    echo -e "${YELLOW}Running Ansible playbook...${NC}"
    ansible-playbook -i inventory.ini setup.yml
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}   🎉 Setup Complete!${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo ""
        echo -e "${GREEN}Your website is now available at:${NC}"
        echo -e "${BLUE}http://localhost:8080${NC}"
        echo ""
        echo -e "${YELLOW}Useful commands:${NC}"
        echo -e "  View logs:       ${BLUE}docker-compose logs -f${NC}"
        echo -e "  Stop server:     ${BLUE}docker-compose down${NC}"
        echo -e "  Restart server:  ${BLUE}docker-compose restart${NC}"
        echo -e "  Run specific role: ${BLUE}ansible-playbook -i inventory.ini setup.yml --tags \"app\"${NC}"
        echo ""
    else
        echo -e "${RED}❌ Playbook execution failed${NC}"
        exit 1
    fi
else
    echo ""
    echo -e "${YELLOW}Playbook not run. You can run it manually with:${NC}"
    echo -e "${BLUE}ansible-playbook -i inventory.ini setup.yml${NC}"
    echo ""
fi


echo ""
read -p "Press Enter to exit..."