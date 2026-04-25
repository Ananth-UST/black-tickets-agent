#!/usr/bin/env node

const crypto = require('crypto');

// Generate secure random values for production
function generateSecureRandom(bytes) {
  return crypto.randomBytes(bytes).toString('base64');
}

function generateSecurePassword(length = 32) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*';
  let password = '';
  for (let i = 0; i < length; i++) {
    password += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return password;
}

const secrets = {
  // Database credentials
  POSTGRES_PASSWORD: generateSecurePassword(32),
  POSTGRES_USER: 'ticketing_user',
  
  // JWT secrets (64+ characters recommended)
  JWT_SECRET: generateSecureRandom(64),
  
  // Admin credentials
  ADMIN_EMAIL: 'admin@yourdomain.com',
  ADMIN_PASSWORD: generateSecurePassword(24),
  
  // User credentials
  USER_EMAIL: 'user@yourdomain.com', 
  USER_PASSWORD: generateSecurePassword(16),
  
  // Service passwords
  IDENTITY_DB_PASS: generateSecurePassword(24),
  EVENT_DB_PASS: generateSecurePassword(24),
  BOOKING_DB_PASS: generateSecurePassword(24),
};

console.log('=== PRODUCTION SECRETS ===');
console.log('Copy these values to your environment files:\n');

Object.entries(secrets).forEach(([key, value]) => {
  console.log(`${key}=${value}`);
});

console.log('\n=== SECURITY REMINDERS ===');
console.log('1. Store these values securely (password manager, vault, etc.)');
console.log('2. Never commit actual secrets to version control');
console.log('3. Rotate secrets regularly');
console.log('4. Use different passwords for different services');
