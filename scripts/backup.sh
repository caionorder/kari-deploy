#!/bin/bash

# Kari Ajuda - Backup Script

set -e

# Configuration
BACKUP_DIR="/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DB_NAME=${DB_NAME:-kariajuda}
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-7}

echo "Starting backup at $(date)"

# Create backup directory if it doesn't exist
mkdir -p ${BACKUP_DIR}

# Database backup
echo "Backing up database..."
pg_dump -h postgres -U ${PGUSER} ${DB_NAME} | gzip > ${BACKUP_DIR}/kariajuda_backup_${TIMESTAMP}.sql.gz

# Backup media files
echo "Backing up media files..."
tar -czf ${BACKUP_DIR}/media_backup_${TIMESTAMP}.tar.gz /app/media 2>/dev/null || true

# Clean old backups
echo "Cleaning old backups (keeping last ${RETENTION_DAYS} days)..."
find ${BACKUP_DIR} -name "kariajuda_backup_*.sql.gz" -mtime +${RETENTION_DAYS} -delete
find ${BACKUP_DIR} -name "media_backup_*.tar.gz" -mtime +${RETENTION_DAYS} -delete

echo "Backup completed at $(date)"
echo "Backup file: ${BACKUP_DIR}/kariajuda_backup_${TIMESTAMP}.sql.gz"

# List current backups
echo ""
echo "Current backups:"
ls -lh ${BACKUP_DIR}/*.gz 2>/dev/null | tail -5