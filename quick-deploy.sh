#!/bin/bash
#
# Quick Deploy ELK Stack - Uses Official docker-elk Repository
# This script clones the official repo and deploys it with minimal setup
#
# Usage: 
#   curl -fsSL https://raw.githubusercontent.com/deviantony/docker-elk/main/scripts/quick-deploy.sh | bash
#   Or: wget -qO- https://raw.githubusercontent.com/deviantony/docker-elk/main/scripts/quick-deploy.sh | bash
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════╗
║   ELK Stack Quick Deployment (Ubuntu)         ║
║   Uses: github.com/deviantony/docker-elk      ║
╚═══════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Configuration
ELK_DIR="$HOME/elk-stack/dev-cluster"
REPO_URL="https://github.com/deviantony/docker-elk.git"

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Error: Do not run as root. Run as regular user with sudo privileges.${NC}"
    exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

echo -e "${GREEN}=== Checking Prerequisites ===${NC}"

# Check Docker
if ! command_exists docker; then
    echo -e "${YELLOW}Docker is not installed. Installing...${NC}"
    read -p "Install Docker automatically? (Y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        echo "Installing Docker..."
        # Add Docker's official GPG key
        sudo apt update
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
        
        # Add Docker repository
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # Install Docker Engine
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        
        # Add current user to docker group
        sudo usermod -aG docker $USER
        
        echo -e "${GREEN}✓ Docker installed successfully${NC}"
        echo -e "${YELLOW}⚠️  You may need to log out and back in for Docker group changes to take effect${NC}"
        echo -e "${YELLOW}⚠️  Or run: newgrp docker${NC}"
        echo ""
        read -p "Continue? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Please log out and back in, then run this script again."
            exit 0
        fi
    else
        echo -e "${RED}Docker is required. Install it manually and run again.${NC}"
        echo "Quick install: curl -fsSL https://get.docker.com | sh"
        exit 1
    fi
fi

# Check Docker Compose
if ! docker compose version &> /dev/null; then
    echo -e "${RED}Error: Docker Compose v2 is not installed${NC}"
    echo "Docker Compose plugin should have been installed with Docker."
    echo "Try: sudo apt install docker-compose-plugin"
    exit 1
fi

echo "✓ Docker: $(docker --version)"
echo "✓ Docker Compose: $(docker compose version)"

# Check git
if ! command_exists git; then
    echo "Installing git..."
    sudo apt update
    sudo apt install -y git
fi

# Check vm.max_map_count
CURRENT_MAX_MAP=$(sysctl -n vm.max_map_count)
if [ "$CURRENT_MAX_MAP" -lt 262144 ]; then
    echo "Setting vm.max_map_count=262144 (required for Elasticsearch)..."
    echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
fi

echo ""
echo -e "${GREEN}=== Cloning Repository ===${NC}"

if [ -d "$ELK_DIR" ]; then
    echo -e "${YELLOW}Directory $ELK_DIR already exists${NC}"
    read -p "Remove and re-clone? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$ELK_DIR"
    else
        echo "Using existing directory"
        cd "$ELK_DIR"
    fi
fi

if [ ! -d "$ELK_DIR" ]; then
    mkdir -p "$(dirname "$ELK_DIR")"
    echo "Cloning from $REPO_URL..."
    git clone "$REPO_URL" "$ELK_DIR"
    cd "$ELK_DIR"
fi

cd "$ELK_DIR"

# Detect available RAM
TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
echo ""
echo "Detected: ${TOTAL_RAM}GB RAM"

# Suggest heap sizes based on RAM
if [ "$TOTAL_RAM" -ge 16 ]; then
    ES_HEAP="4g"
    LS_HEAP="1g"
    echo "Recommended: ES=4GB, LS=1GB"
elif [ "$TOTAL_RAM" -ge 8 ]; then
    ES_HEAP="2g"
    LS_HEAP="512m"
    echo "Recommended: ES=2GB, LS=512MB"
elif [ "$TOTAL_RAM" -ge 4 ]; then
    ES_HEAP="1g"
    LS_HEAP="256m"
    echo "Recommended: ES=1GB, LS=256MB"
else
    echo -e "${RED}Warning: Less than 4GB RAM detected. ELK stack may not run properly.${NC}"
    ES_HEAP="512m"
    LS_HEAP="256m"
fi

read -p "Adjust heap sizes? (Y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    sed -i "s/ES_JAVA_OPTS: -Xms[^ ]* -Xmx[^ ]*/ES_JAVA_OPTS: -Xms${ES_HEAP} -Xmx${ES_HEAP}/" docker-compose.yml
    sed -i "s/LS_JAVA_OPTS: -Xms[^ ]* -Xmx[^ ]*/LS_JAVA_OPTS: -Xms${LS_HEAP} -Xmx${LS_HEAP}/" docker-compose.yml
    echo "✓ Heap sizes updated in docker-compose.yml"
fi

echo ""
echo -e "${GREEN}=== Building Images ===${NC}"
docker compose build

echo ""
echo -e "${GREEN}=== Initializing Stack ===${NC}"
echo "Running setup to create users and roles..."
docker compose up setup

echo ""
echo -e "${YELLOW}=== Optional: Generate Kibana Encryption Keys ===${NC}"
read -p "Generate Kibana encryption keys? (recommended) (Y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo ""
    echo -e "${YELLOW}Copy these keys and add them to kibana/config/kibana.yml:${NC}"
    echo ""
    docker compose up kibana-genkeys
    echo ""
    echo -e "${YELLOW}Press Enter after copying the keys (or skip for now)...${NC}"
    read
fi

echo ""
echo -e "${GREEN}=== Starting ELK Stack ===${NC}"
docker compose up -d

echo ""
echo "Waiting for services to start (30 seconds)..."
sleep 30

echo ""
echo "Service Status:"
docker compose ps

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          Deployment Complete! 🎉              ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Access Information:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
VM_IP=$(hostname -I | awk '{print $1}')
echo -e "Kibana:        ${GREEN}http://${VM_IP}:5601${NC}"
echo -e "Elasticsearch: ${GREEN}http://${VM_IP}:9200${NC}"
echo ""
echo -e "${BLUE}Default Credentials:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Username: elastic"
echo "Password: changeme"
echo ""
echo -e "${RED}⚠️  IMPORTANT: Change default passwords!${NC}"
echo ""
echo "1. Reset elastic password:"
echo "   docker compose exec elasticsearch bin/elasticsearch-reset-password --batch --user elastic"
echo ""
echo "2. Reset other users:"
echo "   docker compose exec elasticsearch bin/elasticsearch-reset-password --batch --user logstash_internal"
echo "   docker compose exec elasticsearch bin/elasticsearch-reset-password --batch --user kibana_system"
echo ""
echo "3. Update .env file with new passwords"
echo ""
echo "4. Restart services:"
echo "   docker compose up -d logstash kibana"
echo ""
echo -e "${BLUE}Useful Commands:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "cd $ELK_DIR"
echo "docker compose ps              # Check status"
echo "docker compose logs -f         # View logs"
echo "docker compose down            # Stop"
echo "docker compose up -d           # Start"
echo ""
echo -e "${BLUE}License Information:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "• Trial license active for 30 days"
echo "• Full Platinum/Enterprise features enabled"
echo "• Automatically converts to Basic (free) after trial"
echo "• Check license: curl -u elastic:changeme http://localhost:9200/_license?pretty"
echo ""
echo -e "${BLUE}Documentation:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "• README: https://github.com/deviantony/docker-elk"
echo "• Local: $ELK_DIR/README.md"
echo ""
echo -e "${GREEN}Happy logging! 📊${NC}"
