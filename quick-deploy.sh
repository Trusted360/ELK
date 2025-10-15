#!/bin/bash
#
# Simplicity IT - ELK Stack Quick Deploy with Custom Branding
# This script clones the official docker-elk repo and applies Simplicity IT branding
#
# Usage: 
#   curl -fsSL https://raw.githubusercontent.com/Trusted360/ELK/main/quick-deploy.sh | bash
#   Or: wget -qO- https://raw.githubusercontent.com/Trusted360/ELK/main/quick-deploy.sh | bash
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════╗
║      Simplicity IT - ELK Stack Deploy         ║
║   Easy to use. Easy to manage. Easy to trust. ║
╚═══════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Configuration
ELK_DIR="$HOME/elk-stack/dev-cluster"
REPO_URL="https://github.com/deviantony/docker-elk.git"
BRANDING_REPO="https://github.com/Trusted360/ELK.git"
BRANDING_DIR="/tmp/simplicity-branding"

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

# Apply Simplicity IT Branding
echo ""
echo -e "${CYAN}=== Applying Simplicity IT Branding ===${NC}"

# Clone branding repository
if [ -d "$BRANDING_DIR" ]; then
    echo "Removing old branding files..."
    rm -rf "$BRANDING_DIR"
fi

echo "Downloading Simplicity IT branding files..."
git clone --depth 1 "$BRANDING_REPO" "$BRANDING_DIR" 2>/dev/null || {
    echo -e "${YELLOW}Warning: Could not clone branding repo. Skipping branding step.${NC}"
    echo -e "${YELLOW}Branding can be applied manually later.${NC}"
}

if [ -d "$BRANDING_DIR/branding" ]; then
    echo "Applying branding configuration..."
    
    # Backup original kibana.yml
    if [ -f "$ELK_DIR/kibana/config/kibana.yml" ]; then
        cp "$ELK_DIR/kibana/config/kibana.yml" "$ELK_DIR/kibana/config/kibana.yml.backup"
    fi
    
    # Append branding configuration to kibana.yml
    if [ -f "$BRANDING_DIR/branding/kibana-branding.yml" ]; then
        echo "" >> "$ELK_DIR/kibana/config/kibana.yml"
        echo "# ===== Simplicity IT Custom Branding =====" >> "$ELK_DIR/kibana/config/kibana.yml"
        cat "$BRANDING_DIR/branding/kibana-branding.yml" >> "$ELK_DIR/kibana/config/kibana.yml"
        echo -e "${GREEN}✓ Kibana branding configuration applied${NC}"
    fi
    
    # Copy dashboard templates
    if [ -d "$BRANDING_DIR/dashboards" ]; then
        mkdir -p "$ELK_DIR/dashboards"
        cp -r "$BRANDING_DIR/dashboards/"* "$ELK_DIR/dashboards/" 2>/dev/null || true
        echo -e "${GREEN}✓ Dashboard templates copied${NC}"
    fi
    
    # Copy branding files for reference
    if [ -d "$BRANDING_DIR/branding" ]; then
        mkdir -p "$ELK_DIR/branding"
        cp -r "$BRANDING_DIR/branding/"* "$ELK_DIR/branding/" 2>/dev/null || true
        echo -e "${GREEN}✓ Branding reference files copied${NC}"
    fi
    
    # Restart Kibana to apply branding
    echo "Restarting Kibana to apply branding..."
    docker compose restart kibana
    
    echo -e "${GREEN}✓ Simplicity IT branding applied successfully!${NC}"
    
    # Clean up
    rm -rf "$BRANDING_DIR"
else
    echo -e "${YELLOW}⚠ Branding files not found. Continuing without branding.${NC}"
fi

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          Deployment Complete! 🎉              ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Access Information:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
VM_IP=$(hostname -I | awk '{print $1}')
echo -e "Kibana:        ${GREEN}http://${VM_IP}:5601${NC}"
echo -e "Elasticsearch: ${GREEN}http://${VM_IP}:9200${NC}"
echo ""
echo -e "${CYAN}Default Credentials:${NC}"
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
echo -e "${CYAN}Import Dashboards:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Open Kibana: http://${VM_IP}:5601"
echo "2. Navigate to: Management → Stack Management → Saved Objects"
echo "3. Click 'Import'"
echo "4. Select dashboard files from: $ELK_DIR/dashboards/"
echo ""
echo "Dashboard templates available:"
echo "  • Security Operations Dashboard"
echo "  • System Health Dashboard"
echo ""
echo -e "${CYAN}Branding Files:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "• Header template: $ELK_DIR/branding/dashboard-header.md"
echo "• Footer template: $ELK_DIR/branding/dashboard-footer.md"
echo "• Color palette: $ELK_DIR/branding/simplicity-it-colors.json"
echo ""
echo -e "${CYAN}Useful Commands:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "cd $ELK_DIR"
echo "docker compose ps              # Check status"
echo "docker compose logs -f         # View logs"
echo "docker compose down            # Stop"
echo "docker compose up -d           # Start"
echo ""
echo -e "${CYAN}License Information:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "• Trial license active for 30 days"
echo "• Full Platinum/Enterprise features enabled"
echo "• Automatically converts to Basic (free) after trial"
echo "• Check license: curl -u elastic:changeme http://localhost:9200/_license?pretty"
echo ""
echo -e "${CYAN}Documentation:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "• Official docker-elk: https://github.com/deviantony/docker-elk"
echo "• Simplicity IT branding: https://github.com/Trusted360/ELK"
echo "• Local README: $ELK_DIR/README.md"
echo ""
echo -e "${CYAN}Support:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "• Phone: (856) 236-2301"
echo "• Email: help@simplicity-it.com"
echo "• Website: https://simplicity-it.com/"
echo ""
echo -e "${GREEN}Easy to use. Easy to manage. Easy to trust. �${NC}"
