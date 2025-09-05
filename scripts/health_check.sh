#!/bin/bash

# Kari Ajuda - Health Check Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "================================================"
echo "   Running Health Checks"
echo "================================================"

# Function to check endpoint
check_endpoint() {
    local name=$1
    local url=$2
    local expected_code=${3:-200}
    
    echo -n "Checking $name... "
    
    response=$(curl -s -o /dev/null -w "%{http_code}" $url)
    
    if [ "$response" = "$expected_code" ]; then
        echo -e "${GREEN}OK${NC} (HTTP $response)"
        return 0
    else
        echo -e "${RED}FAILED${NC} (HTTP $response)"
        return 1
    fi
}

# Check all endpoints
FAILED=0

# API endpoints
check_endpoint "API Health" "https://api.kariajuda.com/health" || FAILED=1
check_endpoint "API Docs" "https://api.kariajuda.com/docs" || FAILED=1
check_endpoint "API Campaigns" "https://api.kariajuda.com/api/v1/campaigns/" || FAILED=1

# Site
check_endpoint "Site Homepage" "https://kariajuda.com" || FAILED=1
check_endpoint "WWW Redirect" "https://www.kariajuda.com" "301" || FAILED=1

# Admin
check_endpoint "Admin Panel" "https://admin.kariajuda.com" || FAILED=1

# Database connection
echo -n "Checking Database connection... "
if docker-compose exec -T postgres pg_isready -U ${DB_USER:-kariajuda} > /dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
    FAILED=1
fi

# Redis connection
echo -n "Checking Redis connection... "
if docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
    FAILED=1
fi

# Check Docker containers
echo ""
echo "Container Status:"
docker-compose ps

echo ""
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All health checks passed!${NC}"
    exit 0
else
    echo -e "${RED}Some health checks failed!${NC}"
    exit 1
fi