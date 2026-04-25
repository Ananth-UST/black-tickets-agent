#!/bin/bash

# Dynamic EC2 IP Detection and Environment Setup
# This script automatically detects the EC2 public IP and configures environment

echo "🔍 Detecting EC2 Public IP..."

# Try multiple methods to get the public IP
PUBLIC_IP=""
METADATA_URL="http://169.254.169.254/latest/meta-data/public-ipv4"

# Method 1: EC2 Metadata Service (works on EC2)
if command -v curl &> /dev/null; then
    PUBLIC_IP=$(curl -s --connect-timeout 5 $METADATA_URL 2>/dev/null)
fi

# Method 2: External IP service (fallback)
if [ -z "$PUBLIC_IP" ] || [ "$PUBLIC_IP" = "None" ]; then
    if command -v curl &> /dev/null; then
        PUBLIC_IP=$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null)
    fi
fi

# Method 3: Another external service (fallback)
if [ -z "$PUBLIC_IP" ] || [ "$PUBLIC_IP" = "None" ]; then
    if command -v curl &> /dev/null; then
        PUBLIC_IP=$(curl -s --connect-timeout 5 ipinfo.io/ip 2>/dev/null)
    fi
fi

# Method 4: Local fallback for development
if [ -z "$PUBLIC_IP" ] || [ "$PUBLIC_IP" = "None" ]; then
    PUBLIC_IP="localhost"
    echo "⚠️  Could not detect public IP, using localhost for development"
else
    echo "✅ Detected EC2 Public IP: $PUBLIC_IP"
fi

echo "🔧 Configuring environment files..."

# Update frontend production environment
if [ -f "frontend/.env.production" ]; then
    sed -i "s|http://YOUR_EC2_IP_OR_DOMAIN|http://$PUBLIC_IP|g" frontend/.env.production
    echo "✅ Updated frontend/.env.production"
fi

# Copy production templates to active .env files
cp frontend/.env.production frontend/.env 2>/dev/null || true
cp identity-service/.env.production identity-service/.env 2>/dev/null || true
cp event-service/.env.production event-service/.env 2>/dev/null || true
cp booking-service/.env.production booking-service/.env 2>/dev/null || true
cp chatbot-service/.env.production chatbot-service/.env 2>/dev/null || true

# Generate secure secrets if needed
if [ -f "scripts/generate-secrets.js" ] && command -v node &> /dev/null; then
    echo "🔐 Generating secure secrets..."
    node scripts/generate-secrets.js > /tmp/secrets.tmp
    
    # Update global .env.production with generated secrets
    while IFS='=' read -r key value; do
        case $key in
            POSTGRES_PASSWORD|POSTGRES_USER|JWT_SECRET|ADMIN_EMAIL|ADMIN_PASSWORD|USER_EMAIL|USER_PASSWORD)
                sed -i "s|CHANGE_THIS_STRONG_PASSWORD|$value|g" .env.production
                sed -i "s|CHANGE_THIS_TO_64_CHAR_RANDOM_STRING|$value|g" .env.production
                sed -i "s|admin@yourdomain.com|$value|g" .env.production
                sed -i "s|user@yourdomain.com|$value|g" .env.production
                ;;
        esac
    done < /tmp/secrets.tmp
    rm -f /tmp/secrets.tmp
fi

echo "🚀 Environment setup complete!"
echo "📋 Configuration Summary:"
echo "   Frontend URL: http://$PUBLIC_IP"
echo "   API Base URL: http://$PUBLIC_IP"
echo "   Services will be accessible at:"
echo "     - Identity: http://$PUBLIC_IP:4001"
echo "     - Events: http://$PUBLIC_IP:4002"
echo "     - Bookings: http://$PUBLIC_IP:4003"
echo "     - Chatbot: http://$PUBLIC_IP:4004"
echo ""
echo "🐳 You can now run: docker compose --env-file .env.production up --build -d"
