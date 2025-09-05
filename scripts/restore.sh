#!/bin/bash

# Kari Ajuda - Database Restore Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "================================================"
echo "   Kari Ajuda - Database Restore"
echo "================================================"
echo ""

BACKUP_DIR="./backups"

# Check if backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    echo -e "${RED}Error: Backup directory not found!${NC}"
    exit 1
fi

# List available backups
echo "Available backups:"
echo ""
ls -lh $BACKUP_DIR/*.sql.gz 2>/dev/null || {
    echo -e "${RED}No backups found!${NC}"
    exit 1
}

echo ""
echo -e "${YELLOW}Enter the backup filename to restore (or 'latest' for most recent):${NC}"
read BACKUP_FILE

if [ "$BACKUP_FILE" = "latest" ]; then
    BACKUP_FILE=$(ls -t $BACKUP_DIR/*.sql.gz | head -1)
    BACKUP_FILE=$(basename $BACKUP_FILE)
fi

if [ ! -f "$BACKUP_DIR/$BACKUP_FILE" ]; then
    echo -e "${RED}Error: Backup file not found!${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}WARNING: This will replace all current data!${NC}"
echo -e "${YELLOW}Are you sure you want to restore from $BACKUP_FILE? (yes/no)${NC}"
read CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Restore cancelled."
    exit 0
fi

# Create a backup before restore
echo -e "${GREEN}Creating safety backup before restore...${NC}"
./scripts/backup.sh

# Stop the application
echo -e "${GREEN}Stopping application services...${NC}"
docker-compose stop api site admin

# Restore database
echo -e "${GREEN}Restoring database...${NC}"
gunzip < $BACKUP_DIR/$BACKUP_FILE | docker-compose exec -T postgres psql -U ${DB_USER:-kariajuda} ${DB_NAME:-kariajuda}

# Run migrations (in case backup is from older version)
echo -e "${GREEN}Running database migrations...${NC}"
docker-compose run --rm api alembic upgrade head

# Restart services
echo -e "${GREEN}Restarting services...${NC}"
docker-compose start api site admin

# Wait for services to be healthy
sleep 10

# Run health check
echo -e "${GREEN}Running health checks...${NC}"
./scripts/health_check.sh

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}   Restore completed successfully!${NC}"
echo -e "${GREEN}================================================${NC}"