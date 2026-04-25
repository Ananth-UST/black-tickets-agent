#!/bin/bash

# One-Click EC2 Deployment Script
# This script handles the complete deployment process

echo "🚀 Starting EC2 Deployment..."

# Step 1: Setup dynamic environment
echo "📋 Step 1: Setting up dynamic environment..."
./scripts/setup-dynamic-env.sh

# Step 2: Stop existing containers
echo "📋 Step 2: Stopping existing containers..."
docker compose --env-file .env.production down 2>/dev/null || true

# Step 3: Build and start containers
echo "📋 Step 3: Building and starting containers..."
docker compose --env-file .env.production up --build -d

# Step 4: Wait for services to be healthy
echo "📋 Step 4: Waiting for services to be healthy..."
sleep 30

# Step 5: Show deployment status
echo "📋 Step 5: Checking deployment status..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Get the actual IP being used
if [ -f "frontend/.env" ]; then
    API_URL=$(grep VITE_API_BASE_URL frontend/.env | cut -d'=' -f2)
    echo ""
    echo "✅ Deployment Complete!"
    echo "🌐 Application is accessible at: $API_URL"
    echo "🔧 API Endpoints:"
    echo "   - Identity: $API_URL:4001"
    echo "   - Events: $API_URL:4002" 
    echo "   - Bookings: $API_URL:4003"
    echo "   - Chatbot: $API_URL:4004"
    echo ""
    echo "📊 To check logs: docker compose logs -f"
    echo "🛑 To stop: docker compose --env-file .env.production down"
else
    echo "❌ Deployment failed - environment files not found"
fi
