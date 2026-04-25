# Event Ticket Booking Microservices (Reduced Stack)

This setup includes only:

- `frontend` (React + Vite)
- `identity-service` (auth + user merged)
- `event-service`
- `booking-service`
- `postgres` (shared container with separate DBs)

Excluded as requested: API gateway, queue service, payment service, notification service.

## Tech

- Node.js + Express (MVC style)
- PostgreSQL (separate DB per service)
- JWT auth (identity-service)
- Docker + docker-compose (local development)

## Folder Structure

```text
.
├── docker-compose.yml
├── postgres/
│   └── init.sql
├── identity-service/
├── event-service/
├── booking-service/
└── frontend/
```

## Environment

Each backend service has `.env.example` with:

- `PORT`
- `DB_HOST`
- `DB_PORT`
- `DB_USER`
- `DB_PASS`
- `DB_NAME`
- `JWT_SECRET` (identity-service, event-service, booking-service)

Frontend `.env.example` contains:

- `VITE_IDENTITY_SERVICE_URL`
- `VITE_EVENT_SERVICE_URL`
- `VITE_BOOKING_SERVICE_URL`

## Run with Docker

### Local Development

1. From project root:

```bash
docker compose up --build
```

2. Services:

- Frontend: `http://localhost:5173`
- Identity: `http://localhost:4001/health`
- Event: `http://localhost:4002/health`
- Booking: `http://localhost:4003/health`

### EC2 Deployment

#### Quick Production Setup (Recommended)

1. On EC2 instance, install Docker & Docker Compose

2. Clone repository and navigate to project folder

3. Run production setup script:
```bash
chmod +x scripts/setup-production.sh
./scripts/setup-production.sh
```

4. Access application: `http://your-ec2-ip`

#### Manual Setup

1. Generate secure secrets:
```bash
node scripts/generate-secrets.js
```

2. Configure environment files:
```bash
# Copy production environment templates
cp frontend/.env.production frontend/.env
cp identity-service/.env.production identity-service/.env
cp event-service/.env.production event-service/.env
cp booking-service/.env.production booking-service/.env
cp chatbot-service/.env.production chatbot-service/.env
cp .env.production .env

# Edit frontend/.env and replace YOUR_EC2_IP_OR_DOMAIN with your actual EC2 public IP
nano frontend/.env

# Replace all placeholder values with generated secure secrets
```

3. Run with production configuration:
```bash
# With Nginx reverse proxy (recommended)
docker-compose -f docker-compose.prod.yml up --build -d

# Or basic setup
docker compose up --build -d
```

4. Access application: `http://your-ec2-ip`

#### Security Requirements

**EC2 Security Group Configuration:**
- **HTTP (80)**: Open to all (for web access)
- **HTTPS (443)**: Open to all (for SSL)
- **SSH (22)**: Your IP only (for administration)
- **Database (5432)**: CLOSED (internal only)
- **Backend ports (4001-4004)**: CLOSED (internal only)

**Production Security Features:**
- ✅ Secure random passwords and JWT secrets
- ✅ Health checks for all services
- ✅ Rate limiting and security headers
- ✅ Internal-only database access
- ✅ No hardcoded credentials
- ✅ Environment variable validation

**Important**: Never commit actual secrets to version control. Use the provided scripts to generate secure values.

## APIs

### identity-service

- `POST /auth/register`
- `POST /auth/login`
- `GET /auth/validate`
- `GET /users/me`
- `PUT /users/me`

### event-service

- `GET /events`
- `GET /events/:id`
- `POST /events` (admin only; requires JWT)

### booking-service

- `POST /bookings`
- `GET /bookings`
- `GET /bookings/:id`

## Notes

- Stateless service design (no in-memory state dependency).
- `event-service` and `booking-service` validate JWT locally using shared `JWT_SECRET`.
- Seat availability is reduced via `event-service` reserve endpoint.
- Databases created automatically: `identity_db`, `event_db`, `booking_db`.
- Event seed content and frontend visual style are aligned to your reference repo: [Ananth-UST/bookishtickets](https://github.com/Ananth-UST/bookishtickets.git).

## Role-Specific Credentials

Seed users are auto-created by `identity-service` on startup:

- Admin: `admin@bookish.com` / `Admin@123` (can create events)
- User: `user@bookish.com` / `User@123` (can book tickets)

Registration endpoint always creates `user` role accounts only.
