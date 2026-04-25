#!/bin/bash

# Production Setup Script for Event Ticket Booking System
# This script sets up the production environment with all security configurations

set -e

echo "🚀 Setting up Production Environment..."

# Check if running as root (not recommended)
if [ "$EUID" -eq 0 ]; then
    echo "❌ Please don't run this script as root"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Generate secure secrets
echo "🔐 Generating secure secrets..."
if [ ! -f "scripts/generate-secrets.js" ]; then
    echo "❌ Secret generation script not found"
    exit 1
fi

# Generate secrets and save to temporary file
SECRETS_FILE=$(mktemp)
node scripts/generate-secrets.js > "$SECRETS_FILE"

echo "📝 Creating production environment files..."

# Copy production templates
cp frontend/.env.production frontend/.env
cp identity-service/.env.production identity-service/.env
cp event-service/.env.production event-service/.env
cp booking-service/.env.production booking-service/.env
cp chatbot-service/.env.production chatbot-service/.env
cp .env.production .env

# Replace placeholders with generated secrets
while IFS='=' read -r key value; do
    case $key in
        POSTGRES_PASSWORD|POSTGRES_USER|JWT_SECRET|ADMIN_EMAIL|ADMIN_PASSWORD|USER_EMAIL|USER_PASSWORD)
            echo "🔄 Setting $key..."
            # Update all environment files
            sed -i "s/CHANGE_THIS_STRONG_PASSWORD/$value/g" */.env
            sed -i "s/CHANGE_THIS_TO_64_CHAR_RANDOM_STRING/$value/g" */.env
            sed -i "s/admin@yourdomain.com/$value/g" */.env
            sed -i "s/user@yourdomain.com/$value/g" */.env
            sed -i "s/ticketing_user/$value/g" */.env
            ;;
    esac
done < "$SECRETS_FILE"

# Clean up
rm "$SECRETS_FILE"

echo "🔧 Building and starting production services..."

# Use production docker-compose
if [ -f "docker-compose.prod.yml" ]; then
    docker-compose -f docker-compose.prod.yml --env-file .env up --build -d
else
    docker-compose --env-file .env up --build -d
fi

echo "⏳ Waiting for services to be healthy..."
sleep 30

# Check service health
echo "🏥 Checking service health..."
services=("identity-service" "event-service" "booking-service" "chatbot-service" "frontend")

for service in "${services[@]}"; do
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "$service.*healthy"; then
        echo "✅ $service is healthy"
    else
        echo "⚠️  $service may not be ready yet"
    fi
done

echo "🎉 Production setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Configure your domain and SSL certificates"
echo "2. Set up monitoring and backups"
echo "3. Configure firewall rules"
echo "4. Test the application thoroughly"
echo ""
echo "🌐 Application should be available at:"
echo "   - HTTP: http://your-server-ip"
echo "   - HTTPS: https://your-domain.com (after SSL setup)"
