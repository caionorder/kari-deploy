#!/bin/bash

# Kari Ajuda Deploy Setup Script
# This script sets up the deployment environment with git submodules

set -e

echo "================================================"
echo "   Kari Ajuda - Deployment Setup"
echo "================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if git is initialized
if [ ! -d .git ]; then
    echo -e "${YELLOW}Initializing git repository...${NC}"
    git init
fi

# Add submodules for each repository
echo -e "${GREEN}Adding git submodules for repositories...${NC}"

# API Repository
if [ ! -d api/.git ]; then
    if [ -d api ]; then
        echo "Removing existing api directory..."
        rm -rf api
    fi
    echo "Adding API submodule..."
    git submodule add -f git@github.com:caionorder/kari-api.git api
else
    echo "API submodule already exists"
fi

# Site Repository
if [ ! -d site/.git ]; then
    if [ -d site ]; then
        echo "Removing existing site directory..."
        rm -rf site
    fi
    echo "Adding Site submodule..."
    git submodule add -f git@github.com:caionorder/kari-site.git site
else
    echo "Site submodule already exists"
fi

# Admin Repository
if [ ! -d admin/.git ]; then
    if [ -d admin ]; then
        echo "Removing existing admin directory..."
        rm -rf admin
    fi
    echo "Adding Admin submodule..."
    git submodule add -f git@github.com:caionorder/kari-admin.git admin
else
    echo "Admin submodule already exists"
fi

# Update submodules
echo -e "${GREEN}Updating submodules...${NC}"
git submodule update --init --recursive

# Create necessary directories
echo -e "${GREEN}Creating necessary directories...${NC}"
mkdir -p backups
mkdir -p logs
mkdir -p letsencrypt
mkdir -p scripts
mkdir -p init

# Create environment file if it doesn't exist
if [ ! -f .env ]; then
    echo -e "${YELLOW}Creating .env file from template...${NC}"
    cp .env.example .env
    echo -e "${RED}Please edit .env file with your production values!${NC}"
fi

# Create Dockerfiles for each service
echo -e "${GREEN}Creating Dockerfiles...${NC}"

# API Dockerfile
cat > api/Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    gcc \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

COPY . .

RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

# Site Dockerfile
cat > site/Dockerfile << 'EOF'
FROM node:18-alpine AS builder

# Accept build args
ARG REACT_APP_API_URL

# Set environment variable for build
ENV REACT_APP_API_URL=$REACT_APP_API_URL

WORKDIR /app

COPY package*.json ./
RUN npm install --legacy-peer-deps

COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

# Admin Dockerfile
cat > admin/Dockerfile << 'EOF'
FROM node:18-alpine AS builder

# Accept build args
ARG REACT_APP_API_URL

# Set environment variable for build
ENV REACT_APP_API_URL=$REACT_APP_API_URL

WORKDIR /app

COPY package*.json ./
RUN npm install --legacy-peer-deps

COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

# Create nginx configs
echo -e "${GREEN}Creating nginx configurations...${NC}"

# Site nginx config
cat > site/nginx.conf << 'EOF'
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    gzip on;
    gzip_types text/plain text/css text/javascript application/javascript application/json;
}
EOF

# Admin nginx config
cat > admin/nginx.conf << 'EOF'
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    gzip on;
    gzip_types text/plain text/css text/javascript application/javascript application/json;
}
EOF

# Set execute permissions
chmod +x scripts/*.sh 2>/dev/null || true

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}   Setup completed successfully!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "Next steps:"
echo "1. Edit .env file with your production values"
echo "2. Update git submodule URLs in this script"
echo "3. Run: docker-compose up -d"
echo ""
echo "Domains configuration:"
echo "  - Site: kariajuda.com"
echo "  - API: api.kariajuda.com"
echo "  - Admin: admin.kariajuda.com"
echo ""