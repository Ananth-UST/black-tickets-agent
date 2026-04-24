const { Pool } = require("pg");
const bcrypt = require("bcryptjs");

const pool = new Pool({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT),
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME
});

const initDb = async () => {
  const query = `
    CREATE TABLE IF NOT EXISTS users (
      id SERIAL PRIMARY KEY,
      email VARCHAR(255) UNIQUE NOT NULL,
      password_hash VARCHAR(255) NOT NULL,
      name VARCHAR(255) NOT NULL,
      role VARCHAR(50) NOT NULL DEFAULT 'user',
      created_at TIMESTAMP NOT NULL DEFAULT NOW()
    );
  `;
  await pool.query(query);

  const adminEmail = process.env.ADMIN_EMAIL || "admin@bookish.com";
  const adminPassword = process.env.ADMIN_PASSWORD || "Admin@123";
  const userEmail = process.env.USER_EMAIL || "user@bookish.com";
  const userPassword = process.env.USER_PASSWORD || "User@123";

  const adminHash = await bcrypt.hash(adminPassword, 10);
  const userHash = await bcrypt.hash(userPassword, 10);

  await pool.query(
    `INSERT INTO users (email, password_hash, name, role)
     VALUES ($1, $2, $3, 'admin')
     ON CONFLICT (email) DO NOTHING`,
    [adminEmail, adminHash, "Default Admin"]
  );

  await pool.query(
    `INSERT INTO users (email, password_hash, name, role)
     VALUES ($1, $2, $3, 'user')
     ON CONFLICT (email) DO NOTHING`,
    [userEmail, userHash, "Default User"]
  );
};

module.exports = { pool, initDb };
