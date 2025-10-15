# Simplicity IT - ELK Stack Deployment

This repository contains customized deployment scripts and branding for ELK Stack deployments at Simplicity IT.

## Repository Structure

```
ELK/
├── README.md                           # This file
├── quick-deploy.sh                     # Automated deployment script
├── branding/                           # Simplicity IT branding files
│   ├── kibana-branding.yml            # Kibana custom branding config
│   ├── dashboard-header.md            # Markdown header template
│   ├── dashboard-footer.md            # Markdown footer template
│   └── simplicity-it-colors.json      # Brand color palette
└── dashboards/                         # Pre-built dashboard templates
    ├── security-dashboard.ndjson      # Security Operations Dashboard
    └── system-health-dashboard.ndjson # System Health Dashboard
```

## Quick Deployment

### One-Line Deploy

```bash
curl -fsSL https://raw.githubusercontent.com/Trusted360/ELK/main/quick-deploy.sh | bash
```

This script will:
1. ✅ Clone the official docker-elk repository
2. ✅ Install Docker if needed
3. ✅ Configure system requirements (vm.max_map_count)
4. ✅ Deploy ELK stack
5. ✅ Apply Simplicity IT branding
6. ✅ Import custom dashboards
7. ✅ Configure Kibana with company logo and colors

### Manual Deployment

```bash
# Clone this repo
git clone https://github.com/Trusted360/ELK.git
cd ELK

# Run deployment script
chmod +x quick-deploy.sh
./quick-deploy.sh
```

## What Gets Deployed

### Base Stack (Official docker-elk)
- **Elasticsearch**: 9200, 9300
- **Logstash**: 5044 (Beats), 50000 (TCP), 9600 (API)
- **Kibana**: 5601

### Simplicity IT Customizations
- Custom branding (logo, colors, page title)
- Pre-configured security dashboard
- System health monitoring dashboard
- Branded Markdown templates
- Company contact information

## Access Information

After deployment completes:

- **Kibana UI**: http://YOUR_SERVER_IP:5601
- **Elasticsearch API**: http://YOUR_SERVER_IP:9200
- **Default Credentials**: 
  - Username: `elastic`
  - Password: `changeme` (change this immediately!)

## Branding Details

### Company Information
- **Company**: Simplicity IT
- **Website**: https://simplicity-it.com/
- **Phone**: (856) 236-2301
- **Email**: help@simplicity-it.com
- **Tagline**: "Easy to use, easy to manage, and easy to trust."

### Brand Colors
- **Primary Blue**: #1E88E5
- **Light Blue**: #42A5F5
- **Teal Accent**: #26C6DA
- **Success Green**: #66BB6A
- **Warning Orange**: #FFA726
- **Danger Red**: #EF5350

## Post-Deployment Steps

### 1. Change Default Password

```bash
cd ~/elk-stack/dev-cluster
docker compose exec elasticsearch bin/elasticsearch-reset-password --batch --user elastic
```

### 2. Import Additional Dashboards

```bash
# Copy dashboards to running container
docker compose cp ../dashboards/security-dashboard.ndjson kibana:/tmp/

# Import via Kibana UI: Management → Stack Management → Saved Objects → Import
```

### 3. Configure Data Sources

Add your log sources in Kibana:
- Fleet: http://localhost:5601/app/fleet
- Logstash pipelines: Edit `~/elk-stack/dev-cluster/logstash/pipeline/logstash.conf`

## Customization

### Update Branding

```bash
# Edit branding files in your local repo
cd ELK/branding
nano kibana-branding.yml

# Apply changes (requires Kibana restart)
cd ~/elk-stack/dev-cluster
docker compose restart kibana
```

### Add New Dashboards

1. Create dashboard in Kibana UI
2. Export: Management → Stack Management → Saved Objects → Export
3. Save to `dashboards/` folder in this repo
4. Commit and push

```bash
git add dashboards/my-new-dashboard.ndjson
git commit -m "Add custom dashboard for X"
git push
```

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Simplicity IT ELK                  │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌─────────────┐    ┌──────────────┐              │
│  │   Kibana    │───▶│ Elasticsearch │              │
│  │   :5601     │    │   :9200      │              │
│  └─────────────┘    └──────────────┘              │
│         ▲                   ▲                      │
│         │                   │                      │
│  ┌─────────────┐    ┌──────────────┐              │
│  │  Logstash   │───▶│  Data Store  │              │
│  │   :5044     │    │   Volumes    │              │
│  └─────────────┘    └──────────────┘              │
│         ▲                                          │
│         │                                          │
│  ┌─────────────┐                                   │
│  │ Log Sources │ (Beats, Apps, Systems)           │
│  └─────────────┘                                   │
└─────────────────────────────────────────────────────┘
```

## Maintenance

### View Logs

```bash
cd ~/elk-stack/dev-cluster
docker compose logs -f kibana
docker compose logs -f elasticsearch
docker compose logs -f logstash
```

### Restart Services

```bash
docker compose restart kibana
docker compose restart elasticsearch
docker compose restart logstash
```

### Update Stack

```bash
# Pull latest docker-elk changes
cd ~/elk-stack/dev-cluster
git pull

# Rebuild and restart
docker compose build
docker compose up -d
```

### Backup Configuration

```bash
# Backup Elasticsearch data
docker compose exec elasticsearch \
  elasticsearch-snapshot-repo create my_backup --location /backups

# Export Kibana objects
# Use Kibana UI: Management → Stack Management → Saved Objects → Export All
```

## Troubleshooting

### Elasticsearch won't start
```bash
# Check vm.max_map_count
sysctl vm.max_map_count

# Should be 262144 or higher
# Fix: sudo sysctl -w vm.max_map_count=262144
```

### Can't access Kibana
```bash
# Check if Kibana is running
docker compose ps

# Check logs
docker compose logs kibana

# Verify ports
sudo netstat -tlnp | grep 5601
```

### Branding not showing
```bash
# Verify you're on trial/platinum license
curl -u elastic:changeme http://localhost:9200/_license

# Restart Kibana
docker compose restart kibana
```

## Support

- **Technical Issues**: help@simplicity-it.com
- **Phone Support**: (856) 236-2301
- **Service Portal**: https://sos.simplicity-it.com/

## Contributing

1. Fork this repository
2. Create feature branch: `git checkout -b feature/new-dashboard`
3. Commit changes: `git commit -am 'Add new dashboard'`
4. Push: `git push origin feature/new-dashboard`
5. Create Pull Request

## License

This customization layer is maintained by Simplicity IT for internal use.
The underlying docker-elk stack is licensed under the Elastic License.

## Resources

- **Official docker-elk**: https://github.com/deviantony/docker-elk
- **Elastic Documentation**: https://www.elastic.co/guide/
- **Simplicity IT**: https://simplicity-it.com/

---

**Simplicity IT** - Easy to use, easy to manage, and easy to trust.
