#!/bin/bash

# Kari Ajuda - Production Deployment Script
# This script deploys the application with zero downtime

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "================================================"
echo "   Kari Ajuda - Production Deployment"
echo "================================================"
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found!${NC}"
    echo "Please create .env file from .env.example"
    exit 1
fi

# Load environment variables
export $(grep -v '^#' .env | xargs)

# Function to check service health
check_health() {
    local service=$1
    local max_attempts=30
    local attempt=1
    
    echo -n "Checking health of $service..."
    
    while [ $attempt -le $max_attempts ]; do
        if docker-compose ps | grep $service | grep -q "healthy"; then
            echo -e " ${GREEN}Healthy${NC}"
            return 0
        fi
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo -e " ${RED}Failed${NC}"
    return 1
}

# 1. Update git submodules
echo -e "${GREEN}Updating git submodules...${NC}"
git submodule update --remote --merge

# 2. Build new images
echo -e "${GREEN}Building Docker images...${NC}"
docker-compose build --no-cache api site admin

# 3. Run database migrations
echo -e "${GREEN}Running database migrations...${NC}"
docker-compose run --rm api alembic upgrade head

# 4. Deploy with zero downtime
echo -e "${GREEN}Starting deployment...${NC}"

# Start new containers
docker-compose up -d --no-deps --scale api=2 api
check_health "api"

docker-compose up -d --no-deps --scale site=2 site
check_health "site"

docker-compose up -d --no-deps --scale admin=2 admin
check_health "admin"

# Remove old containers
echo -e "${GREEN}Removing old containers...${NC}"
docker-compose up -d --no-deps --remove-orphans api site admin

# 5. Clear caches
echo -e "${GREEN}Clearing caches...${NC}"
docker-compose exec redis redis-cli FLUSHALL

# 6. Run health checks
echo -e "${GREEN}Running health checks...${NC}"
./scripts/health_check.sh

# 7. Create backup
echo -e "${GREEN}Creating post-deployment backup...${NC}"
./scripts/backup.sh

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}   Deployment completed successfully!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "Services available at:"
echo "  - Site: https://kariajuda.com"
echo "  - API: https://api.kariajuda.com"
echo "  - Admin: https://admin.kariajuda.com"
echo ""