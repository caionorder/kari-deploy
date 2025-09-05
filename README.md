# Kari Ajuda - Deployment Repository

This repository contains the deployment configuration for the Kari Ajuda platform.

## Architecture

The platform consists of three separate applications:
- **Site** (kariajuda.com) - Public donation platform
- **API** (api.kariajuda.com) - Backend REST API  
- **Admin** (admin.kariajuda.com) - Administrative panel

## Quick Start

### 1. Clone with submodules
```bash
git clone --recursive git@github.com:caionorder/kari-deploy.git
cd kari-deploy
```

### 2. Configure environment
```bash
cp .env.example .env
# Edit .env with your production values
```

### 3. Run setup script
```bash
./setup.sh
```

### 4. Deploy
```bash
docker-compose up -d
```

## Submodule Repositories

The following repositories are configured as git submodules:
- API: `git@github.com:caionorder/kari-api.git`
- Site: `git@github.com:caionorder/kari-site.git`
- Admin: `git@github.com:caionorder/kari-admin.git`

## Services

| Service | URL | Description |
|---------|-----|-------------|
| Site | https://kariajuda.com | Main donation platform |
| API | https://api.kariajuda.com | Backend API |
| Admin | https://admin.kariajuda.com | Admin panel |
| Traefik | https://traefik.kariajuda.com | Reverse proxy dashboard |

## Deployment

### Automatic Deployment
Push to main branch triggers automatic deployment via GitHub Actions.

### Manual Deployment
```bash
./scripts/deploy.sh
```

## Backup & Restore

### Create backup
```bash
./scripts/backup.sh
```

### Restore from backup
```bash
./scripts/restore.sh
```

## Monitoring

Health checks run every 15 minutes via GitHub Actions. Manual check:
```bash
./scripts/health_check.sh
```

## SSL Certificates

SSL certificates are automatically managed by Traefik with Let's Encrypt.

## Required Secrets for GitHub Actions

Configure these in your repository settings:
- `SSH_PRIVATE_KEY` - SSH key for server access
- `SERVER_HOST` - Production server IP/hostname
- `SERVER_USER` - Server username
- `SLACK_WEBHOOK` - Slack webhook for notifications
- `AWS_S3_BUCKET` - S3 bucket for backups
- `AWS_ACCESS_KEY_ID` - AWS access key
- `AWS_SECRET_ACCESS_KEY` - AWS secret key

## Support

For issues or questions, create an issue in this repository.