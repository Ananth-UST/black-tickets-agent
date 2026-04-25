const crypto = require('crypto');

// Generate secure random values
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
  POSTGRES_PASSWORD: generateSecurePassword(32),
  POSTGRES_USER: 'postgres',
  JWT_SECRET: generateSecureRandom(64),
  ADMIN_EMAIL: 'admin@bookish.com',
  ADMIN_PASSWORD: generateSecurePassword(24),
  USER_EMAIL: 'user@bookish.com', 
  USER_PASSWORD: generateSecurePassword(16),
};

console.log('POSTGRES_PASSWORD=' + secrets.POSTGRES_PASSWORD);
console.log('POSTGRES_USER=' + secrets.POSTGRES_USER);
console.log('JWT_SECRET=' + secrets.JWT_SECRET);
console.log('ADMIN_EMAIL=' + secrets.ADMIN_EMAIL);
console.log('ADMIN_PASSWORD=' + secrets.ADMIN_PASSWORD);
console.log('USER_EMAIL=' + secrets.USER_EMAIL);
console.log('USER_PASSWORD=' + secrets.USER_PASSWORD);
