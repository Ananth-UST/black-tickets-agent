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

1. From project root:

```bash
docker compose up --build
```

2. Services:

- Frontend: `http://localhost:5173`
- Identity: `http://localhost:4001/health`
- Event: `http://localhost:4002/health`
- Booking: `http://localhost:4003/health`

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
