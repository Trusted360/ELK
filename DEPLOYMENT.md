# Simplicity IT ELK Branding Repository

## Repository Purpose

This repository contains **Simplicity IT customizations** for the ELK Stack that are automatically applied during deployment. The official `docker-elk` repository remains the template, while this repo provides the branding layer.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Deployment Flow                                        │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  1. Clone official docker-elk                          │
│     └─ github.com/deviantony/docker-elk                │
│                                                         │
│  2. Deploy base ELK stack                              │
│     └─ Elasticsearch, Logstash, Kibana                 │
│                                                         │
│  3. Clone Simplicity IT branding                       │
│     └─ github.com/Trusted360/ELK                       │
│                                                         │
│  4. Apply customizations                               │
│     ├─ Kibana branding config                          │
│     ├─ Dashboard templates                             │
│     ├─ Header/footer templates                         │
│     └─ Color palette                                   │
│                                                         │
│  5. Restart Kibana                                     │
│     └─ Branding now active                             │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## What Gets Applied

### 1. Kibana Branding (`branding/kibana-branding.yml`)
- **Logo**: Simplicity IT logo in top-left corner
- **Page Title**: "Simplicity IT - Security Operations"
- **Favicon**: Custom favicon
- **UI Settings**: Default route, timezone, dark mode settings

### 2. Dashboard Templates (`dashboards/`)
- Security Operations Dashboard
- System Health Dashboard
- (Add more as you create them)

### 3. Markdown Templates (`branding/`)
- **Header**: Branded header with logo, gradient, status indicator
- **Footer**: Contact info, address, tagline
- **Colors**: JSON palette for consistent styling

## Quick Deployment

### One-Line Command
```bash
curl -fsSL https://raw.githubusercontent.com/Trusted360/ELK/main/quick-deploy.sh | bash
```

This will:
1. ✅ Install Docker (if needed)
2. ✅ Clone official docker-elk
3. ✅ Configure system requirements
4. ✅ Deploy ELK stack
5. ✅ **Automatically apply Simplicity IT branding**
6. ✅ Copy dashboard templates
7. ✅ Restart Kibana with new branding

### Manual Deployment
```bash
# Clone this repo
git clone https://github.com/Trusted360/ELK.git
cd ELK

# Run deployment script
chmod +x quick-deploy.sh
./quick-deploy.sh
```

## Adding New Customizations

### 1. Create New Dashboard
```bash
# In Kibana UI:
# 1. Create your dashboard
# 2. Management → Stack Management → Saved Objects → Export
# 3. Save the .ndjson file

# Add to repo:
cd ELK/dashboards
# Copy your exported .ndjson file here
git add my-new-dashboard.ndjson
git commit -m "Add new dashboard: XYZ"
git push
```

### 2. Update Branding
```bash
cd ELK/branding

# Edit files:
nano kibana-branding.yml       # Kibana config
nano dashboard-header.md       # Header template
nano dashboard-footer.md       # Footer template
nano simplicity-it-colors.json # Color palette

git add .
git commit -m "Update branding: describe changes"
git push
```

### 3. Test Changes
```bash
# Deploy to test VM
ssh user@test-vm
curl -fsSL https://raw.githubusercontent.com/Trusted360/ELK/main/quick-deploy.sh | bash

# Or apply manually to existing deployment:
cd ~/elk-stack/dev-cluster
docker compose down
# Make changes to kibana/config/kibana.yml
docker compose up -d
```

## File Structure

```
ELK/
├── README.md                           # This file
├── DEPLOYMENT.md                       # Detailed deployment guide
├── quick-deploy.sh                     # Automated deployment script
│
├── branding/                           # Branding configuration files
│   ├── kibana-branding.yml            # Appended to kibana.yml
│   ├── dashboard-header.md            # Copy/paste into dashboards
│   ├── dashboard-footer.md            # Copy/paste into dashboards
│   └── simplicity-it-colors.json      # Brand color reference
│
└── dashboards/                         # Pre-built dashboard exports
    ├── security-dashboard.ndjson      # Security operations
    └── system-health-dashboard.ndjson # System health
```

## Workflow: Official Repo + Custom Branding

### Why This Approach?

1. **Stay Updated**: Official docker-elk gets updates, security patches, new features
2. **Easy Maintenance**: Your branding is separate, no merge conflicts
3. **Reusable**: Same branding for multiple deployments
4. **Version Control**: Track your customizations independently

### The Pattern

```
Official Template (docker-elk)
    ↓
Your Branding Layer (ELK repo)
    ↓
Deployed Instance
```

### Benefits

- ✅ Clone official repo anytime, always latest version
- ✅ Apply your branding automatically
- ✅ Share branding across teams/clients
- ✅ No need to fork and maintain docker-elk
- ✅ Easy to replicate deployments

## Common Tasks

### Deploy New Instance
```bash
curl -fsSL https://raw.githubusercontent.com/Trusted360/ELK/main/quick-deploy.sh | bash
```

### Update Existing Instance with New Branding
```bash
cd ~/elk-stack/dev-cluster

# Backup current config
cp kibana/config/kibana.yml kibana/config/kibana.yml.backup

# Download latest branding
git clone https://github.com/Trusted360/ELK.git /tmp/branding

# Apply branding
cat /tmp/branding/branding/kibana-branding.yml >> kibana/config/kibana.yml

# Restart
docker compose restart kibana

# Clean up
rm -rf /tmp/branding
```

### Export Dashboard from Running Kibana
```bash
# In Kibana UI:
# 1. Management → Stack Management → Saved Objects
# 2. Select dashboard(s)
# 3. Export → Download

# Save to this repo:
mv ~/Downloads/export.ndjson ELK/dashboards/my-dashboard.ndjson
cd ELK
git add dashboards/my-dashboard.ndjson
git commit -m "Add dashboard: My Dashboard"
git push
```

### Apply New Dashboard to Running Instance
```bash
# Option 1: Via Kibana UI
# Management → Stack Management → Saved Objects → Import

# Option 2: Via API (automated)
cd ~/elk-stack/dev-cluster
curl -X POST "localhost:5601/api/saved_objects/_import" \
  -H "kbn-xsrf: true" \
  -u elastic:changeme \
  --form file=@../dashboards/my-dashboard.ndjson
```

## Client-Specific Variations

For different clients, you can create branches or separate repos:

```bash
# Option 1: Branches
git checkout -b client-healthcare
# Modify colors, logos for healthcare client
git push origin client-healthcare

# Option 2: Separate repos
# Fork this repo for each major client variation
```

## Support

- **Simplicity IT Support**: help@simplicity-it.com
- **Phone**: (856) 236-2301
- **Website**: https://simplicity-it.com/

## Resources

- **This Repo**: https://github.com/Trusted360/ELK
- **Official docker-elk**: https://github.com/deviantony/docker-elk
- **Elastic Docs**: https://www.elastic.co/guide/
- **Kibana Custom Branding**: https://www.elastic.co/guide/en/kibana/current/branding.html

---

**Simplicity IT** - Easy to use, easy to manage, and easy to trust.
