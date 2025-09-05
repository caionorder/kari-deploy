#!/bin/bash

# Script para atualizar e rebuildar um submodule específico

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if submodule name was provided
if [ -z "$1" ]; then
    echo -e "${RED}Erro: Especifique o submodule (api, site, ou admin)${NC}"
    echo "Uso: ./scripts/update_submodule.sh [api|site|admin]"
    exit 1
fi

SUBMODULE=$1

# Validate submodule name
if [[ ! "$SUBMODULE" =~ ^(api|site|admin)$ ]]; then
    echo -e "${RED}Erro: Submodule inválido. Use: api, site, ou admin${NC}"
    exit 1
fi

echo "================================================"
echo "   Atualizando submodule: $SUBMODULE"
echo "================================================"
echo ""

# Navigate to submodule directory
cd $SUBMODULE

# Show current commit
echo -e "${YELLOW}Commit atual:${NC}"
git log --oneline -1
echo ""

# Reset local changes
echo -e "${GREEN}Resetando mudanças locais...${NC}"
git reset --hard HEAD
git clean -fd

# Fetch and pull latest changes
echo -e "${GREEN}Baixando últimas mudanças...${NC}"
git fetch origin
git pull origin main

# Show new commit
echo -e "${YELLOW}Novo commit:${NC}"
git log --oneline -1
echo ""

# Go back to root directory
cd ..

# Rebuild the specific container
echo -e "${GREEN}Reconstruindo container $SUBMODULE...${NC}"
docker-compose build $SUBMODULE

# Restart the specific container
echo -e "${GREEN}Reiniciando container $SUBMODULE...${NC}"
docker-compose up -d $SUBMODULE

# Wait for container to be healthy
echo -e "${GREEN}Aguardando container ficar saudável...${NC}"
sleep 10

# Check container status
docker-compose ps $SUBMODULE

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}   Submodule $SUBMODULE atualizado com sucesso!${NC}"
echo -e "${GREEN}================================================${NC}"