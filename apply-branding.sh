#!/bin/bash
#
# Apply Simplicity IT Branding to Existing ELK Deployment
# Use this to update branding on already-deployed instances
#

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════╗"
echo "║  Apply Simplicity IT Branding to ELK Stack   ║"
echo "╚═══════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if ELK is running
ELK_DIR="${1:-$HOME/elk-stack/dev-cluster}"

if [ ! -d "$ELK_DIR" ]; then
    echo -e "${RED}Error: ELK directory not found: $ELK_DIR${NC}"
    echo "Usage: $0 [elk-directory]"
    echo "Example: $0 /home/user/elk-stack/dev-cluster"
    exit 1
fi

cd "$ELK_DIR"

# Check if docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}Error: docker-compose.yml not found in $ELK_DIR${NC}"
    exit 1
fi

echo -e "${CYAN}=== Downloading Branding Files ===${NC}"

BRANDING_DIR="/tmp/simplicity-branding-$(date +%s)"
git clone --depth 1 https://github.com/Trusted360/ELK.git "$BRANDING_DIR"

echo -e "${CYAN}=== Backing Up Current Config ===${NC}"

if [ -f "kibana/config/kibana.yml" ]; then
    cp "kibana/config/kibana.yml" "kibana/config/kibana.yml.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${GREEN}✓ Kibana config backed up${NC}"
fi

echo -e "${CYAN}=== Applying Branding ===${NC}"

# Apply Kibana branding
if [ -f "$BRANDING_DIR/branding/kibana-branding.yml" ]; then
    # Remove old branding if exists
    sed -i '/# ===== Simplicity IT Custom Branding =====/,$d' kibana/config/kibana.yml
    
    # Add new branding
    echo "" >> kibana/config/kibana.yml
    echo "# ===== Simplicity IT Custom Branding =====" >> kibana/config/kibana.yml
    cat "$BRANDING_DIR/branding/kibana-branding.yml" >> kibana/config/kibana.yml
    echo -e "${GREEN}✓ Kibana branding configuration applied${NC}"
fi

# Copy dashboard templates
if [ -d "$BRANDING_DIR/dashboards" ]; then
    mkdir -p dashboards
    cp -r "$BRANDING_DIR/dashboards/"* dashboards/ 2>/dev/null || true
    echo -e "${GREEN}✓ Dashboard templates copied to $ELK_DIR/dashboards/${NC}"
fi

# Copy branding reference files
if [ -d "$BRANDING_DIR/branding" ]; then
    mkdir -p branding
    cp -r "$BRANDING_DIR/branding/"* branding/ 2>/dev/null || true
    echo -e "${GREEN}✓ Branding reference files copied to $ELK_DIR/branding/${NC}"
fi

echo -e "${CYAN}=== Restarting Kibana ===${NC}"

docker compose restart kibana

echo -e "${GREEN}✓ Kibana restarted${NC}"

# Wait for Kibana to be ready
echo -e "${CYAN}Waiting for Kibana to be ready...${NC}"
sleep 10

# Clean up
rm -rf "$BRANDING_DIR"

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        Branding Applied Successfully! 🎉      ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Next Steps:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Access Kibana:"
VM_IP=$(hostname -I | awk '{print $1}')
echo -e "   ${GREEN}http://${VM_IP}:5601${NC}"
echo ""
echo "2. Import Dashboards:"
echo "   • Go to: Management → Stack Management → Saved Objects"
echo "   • Click 'Import'"
echo -e "   • Select files from: ${CYAN}$ELK_DIR/dashboards/${NC}"
echo ""
echo "3. Create Custom Dashboards:"
echo "   • Use header template: $ELK_DIR/branding/dashboard-header.md"
echo "   • Use footer template: $ELK_DIR/branding/dashboard-footer.md"
echo "   • Use color palette: $ELK_DIR/branding/simplicity-it-colors.json"
echo ""
echo -e "${CYAN}Verification:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "• Page title should show: 'Simplicity IT - Security Operations'"
echo "• Logo should appear in top-left navigation"
echo "• Favicon should be custom"
echo ""
echo -e "${GREEN}Easy to use. Easy to manage. Easy to trust. 🔒${NC}"
