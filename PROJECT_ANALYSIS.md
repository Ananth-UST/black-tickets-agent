# Black Tickets Project Analysis

## 1. Project structure

```text
blacktickets/
+-- booking-service/        # Node.js + Express booking API
|   +-- server.js
|   +-- Dockerfile
|   +-- package.json
|   +-- src/
|       +-- app.js
|       +-- config/db.js
|       +-- controllers/bookingController.js
|       +-- middleware/
|       +-- models/bookingModel.js
|       +-- routes/bookingRoutes.js
+-- chatbot-service/        # Node.js + Express event Q&A helper
|   +-- server.js
|   +-- Dockerfile
|   +-- package.json
|   +-- src/
|       +-- app.js
|       +-- controllers/chatController.js
|       +-- middleware/errorHandler.js
|       +-- routes/chatRoutes.js
|       +-- services/
+-- event-service/          # Node.js + Express event catalog API
|   +-- server.js
|   +-- Dockerfile
|   +-- package.json
|   +-- src/
|       +-- app.js
|       +-- config/db.js
|       +-- controllers/eventController.js
|       +-- middleware/
|       +-- models/eventModel.js
|       +-- routes/eventRoutes.js
+-- frontend/               # React + Vite SPA
|   +-- Dockerfile
|   +-- index.html
|   +-- package.json
|   +-- vite.config.js
|   +-- src/
|       +-- api.js
|       +-- App.jsx
|       +-- main.jsx
|       +-- styles.css
+-- identity-service/       # Node.js + Express auth and user API
|   +-- server.js
|   +-- Dockerfile
|   +-- package.json
|   +-- src/
|       +-- app.js
|       +-- config/db.js
|       +-- controllers/
|       +-- middleware/
|       +-- models/userModel.js
|       +-- routes/
+-- k8s/                    # Kubernetes namespace, config, secrets, deployments, ingress, PV/PVC
+-- nginx/                  # Nginx reverse proxy config
+-- postgres/               # Database bootstrap SQL
+-- scripts/                # EC2 and production setup scripts
+-- docker-compose.yml
+-- .env.production
+-- README.md
+-- architecture diagram.png
+-- Black tickets project in the aws.docx
+-- Architectural-Deep-Dive-Decoupled-Multi-AZ-Microservices-on-AWS.pptx
```

Primary stack:

- Backend services: Node.js, Express, PostgreSQL client `pg`.
- Frontend: React 18, Vite, React Router, Axios.
- Data: PostgreSQL 16 Alpine.
- Runtime/deployment: Docker Compose, Kubernetes manifests, nginx ingress/reverse proxy.
- Authentication: JWT signed by `identity-service` and verified locally by other services.

## 2. Services and ports

| Service | Purpose | Local/container port | Exposed by Docker Compose | Kubernetes service |
| --- | --- | ---: | --- | --- |
| `frontend` | React/Vite app | `5173` | `5173:5173` | `frontend-service:5173` |
| `identity-service` | Auth, registration, login, user profile | `4001` | `4001:4001` | `identity-service:4001` |
| `event-service` | Event listing, detail, admin event creation, seat reservation | `4002` | `4002:4002` | `event-service:4002` |
| `booking-service` | Booking creation and lookup | `4003` | `4003:4003` | `booking-service:4003` |
| `chatbot-service` | Rule-based event assistant | `4004` | `4004:4004` | `chatbot-service:4004` |
| `postgres` | Shared PostgreSQL container with service databases | `5432` | Not host-bound in Compose | `postgres-service:5432` |
| `nginx` | Public reverse proxy | `80`, `443` | `80:80`, `443:443` | N/A; Kubernetes uses ingress |

Health endpoints:

- `GET /health` on `identity-service`, `event-service`, `booking-service`, and `chatbot-service`.
- nginx has `GET /health`, but it returns a static `healthy` response and does not verify backend health.

Important routing notes:

- Docker Compose exposes backend ports directly even though comments say backend ports should be closed in production.
- nginx proxies:
  - `/api/auth/` to `identity-service`
  - `/api/` to `identity-service`
  - `/events/` to `event-service`
  - `/bookings/` to `booking-service`
  - `/chatbot/` to `chatbot-service`
- Kubernetes ingress proxies:
  - `/auth` to `identity-service`
  - `/events` to `event-service`
  - `/bookings` to `booking-service`
  - `/chatbot` to `chatbot-service`
  - `/` to `frontend-service`

## 3. API routes

### Identity service

Mounted in `identity-service/src/app.js`.

| Method | Route | Auth | Purpose |
| --- | --- | --- | --- |
| `GET` | `/health` | No | Service health |
| `POST` | `/auth/register` | No | Create a standard `user` account |
| `POST` | `/auth/login` | No | Authenticate and return JWT plus user object |
| `GET` | `/auth/validate` | Bearer JWT | Validate token and return decoded user claims |
| `GET` | `/users/me` | Bearer JWT | Return current user profile |
| `PUT` | `/users/me` | Bearer JWT | Update current user's `name` |

### Event service

Mounted in `event-service/src/app.js`.

| Method | Route | Auth | Purpose |
| --- | --- | --- | --- |
| `GET` | `/health` | No | Service health |
| `GET` | `/events` | No | List events ordered by event date |
| `GET` | `/events/:id` | No | Get one event |
| `POST` | `/events` | Bearer JWT with `role=admin` | Create an event |
| `POST` | `/events/:id/reserve` | No | Reserve seats by decrementing `available_seats` |

### Booking service

Mounted in `booking-service/src/app.js`.

| Method | Route | Auth | Purpose |
| --- | --- | --- | --- |
| `GET` | `/health` | No | Service health |
| `POST` | `/bookings` | Bearer JWT, `role=user` enforced in controller | Create a confirmed booking |
| `GET` | `/bookings` | Bearer JWT | List current user's bookings |
| `GET` | `/bookings/:id` | Bearer JWT | Get current user's booking by id |

### Chatbot service

Mounted in `chatbot-service/src/app.js`.

| Method | Route | Auth | Purpose |
| --- | --- | --- | --- |
| `GET` | `/health` | No | Service health |
| `POST` | `/chat` | No | Reply to event-specific questions using event-service data |

External frontend route expectation:

- `frontend/src/api.js` creates `chatbotApi` with base URL `${VITE_API_BASE_URL}/chatbot`.
- `EventDetailPage` calls `chatbotApi.post("/chat")`.
- Therefore the browser calls `/chatbot/chat`.
- The chatbot service itself only defines `/chat`. Without path rewrite, nginx/Kubernetes may forward `/chatbot/chat` as-is, causing a likely `404`.

## 4. Database tables

### Database bootstrap

`postgres/init.sql` creates three PostgreSQL databases:

```sql
CREATE DATABASE identity_db;
CREATE DATABASE event_db;
CREATE DATABASE booking_db;
```

The Kubernetes `postgres-init` ConfigMap contains the same database creation commands.

### `identity_db`: `users`

Created by `identity-service/src/config/db.js`.

| Column | Type | Constraints |
| --- | --- | --- |
| `id` | `SERIAL` | Primary key |
| `email` | `VARCHAR(255)` | Unique, not null |
| `password_hash` | `VARCHAR(255)` | Not null |
| `name` | `VARCHAR(255)` | Not null |
| `role` | `VARCHAR(50)` | Not null, default `'user'` |
| `created_at` | `TIMESTAMP` | Not null, default `NOW()` |

Seed behavior:

- On startup, identity-service requires `ADMIN_EMAIL`, `ADMIN_PASSWORD`, `USER_EMAIL`, and `USER_PASSWORD`.
- It inserts one admin and one user if those email addresses do not already exist.

### `event_db`: `events`

Created by `event-service/src/config/db.js`.

| Column | Type | Constraints |
| --- | --- | --- |
| `id` | `SERIAL` | Primary key |
| `name` | `VARCHAR(255)` | Not null |
| `description` | `TEXT` | Nullable |
| `venue` | `VARCHAR(255)` | Not null |
| `date` | `TIMESTAMP` | Not null |
| `total_seats` | `INT` | Not null, `CHECK (total_seats > 0)` |
| `available_seats` | `INT` | Not null, `CHECK (available_seats >= 0)` |

Seed behavior:

- If `events` is empty, six sample events are inserted.

### `booking_db`: `bookings`

Created by `booking-service/src/config/db.js`.

| Column | Type | Constraints |
| --- | --- | --- |
| `id` | `SERIAL` | Primary key |
| `user_id` | `INT` | Not null |
| `event_id` | `INT` | Not null |
| `status` | `VARCHAR(50)` | Not null, default `'confirmed'` |
| `seats` | `INT` | Not null, `CHECK (seats > 0)` |
| `created_at` | `TIMESTAMP` | Not null, default `NOW()` |

Additional constraint:

- `UNIQUE(user_id, event_id, status)`

Cross-database note:

- There are no database-level foreign keys from `bookings.user_id` to `users.id` or from `bookings.event_id` to `events.id`, likely because the services are intended to own separate databases.

Configuration issue:

- All three backend services read `process.env.DB_NAME`.
- `.env.production` defines `IDENTITY_DB_NAME`, `EVENT_DB_NAME`, and `BOOKING_DB_NAME`, but service code does not use those variables.
- `.env.production` does not define `DB_NAME`.
- `k8s/configmap.yaml` sets `DB_NAME: "identity_db"` globally, so in Kubernetes all backend services may connect to `identity_db` unless overridden elsewhere.

## 5. Environment variables

### Shared backend variables

| Variable | Used by | Purpose |
| --- | --- | --- |
| `PORT` | All Node services | Optional service port override |
| `DB_HOST` | identity, event, booking | PostgreSQL host |
| `DB_PORT` | identity, event, booking | PostgreSQL port |
| `DB_USER` | identity, event, booking | PostgreSQL user |
| `DB_PASS` | identity, event, booking | PostgreSQL password |
| `DB_NAME` | identity, event, booking | PostgreSQL database name |
| `JWT_SECRET` | identity, event, booking | Sign and verify JWTs |
| `NODE_ENV` | Config/deployment | Runtime mode |

### Identity-specific variables

| Variable | Purpose |
| --- | --- |
| `ADMIN_EMAIL` | Seed admin email |
| `ADMIN_PASSWORD` | Seed admin password |
| `USER_EMAIL` | Seed user email |
| `USER_PASSWORD` | Seed user password |
| `BCRYPT_ROUNDS` | Startup seed-password hash cost |
| `JWT_EXPIRES_IN` | Declared in config but not used by login code |

### Service communication variables

| Variable | Used by | Purpose |
| --- | --- | --- |
| `EVENT_SERVICE_URL` | booking, chatbot | Internal event-service base URL |

### Frontend variables

| Variable | Used by | Purpose |
| --- | --- | --- |
| `VITE_API_BASE_URL` | frontend | Public API base URL prepended to `/auth`, `/users`, `/events`, `/bookings`, `/chatbot` |
| `VITE_IDENTITY_SERVICE_URL` | Config/README only | Not used by current frontend code |
| `VITE_EVENT_SERVICE_URL` | Config/README only | Not used by current frontend code |
| `VITE_BOOKING_SERVICE_URL` | Config/README only | Not used by current frontend code |
| `VITE_CHATBOT_SERVICE_URL` | K8s ConfigMap only | Not used by current frontend code |

### Docker/Postgres variables

| Variable | Purpose |
| --- | --- |
| `POSTGRES_USER` | Initial PostgreSQL superuser/user |
| `POSTGRES_PASSWORD` | PostgreSQL password |
| `POSTGRES_DB` | Initial PostgreSQL database |
| `COMPOSE_PROJECT_NAME` | Compose project naming |
| `COMPOSE_FILE` | Compose file selection |

## 6. Authentication flow

1. User registers through frontend route `/`.
2. Frontend posts to `POST /auth/register` with `email`, `password`, and `name`.
3. Identity service checks required fields, rejects duplicate email, hashes the password with bcrypt, and creates the user with role `user`.
4. User logs in through frontend route `/login`.
5. Frontend posts to `POST /auth/login` with `email` and `password`.
6. Identity service finds the user by email and verifies the password with bcrypt.
7. Identity service signs a JWT with claims:
   - `id`
   - `email`
   - `role`
8. Login response returns `{ token, user }`.
9. Frontend stores both `token` and `user` in `localStorage`.
10. `setAuthToken()` attaches `Authorization: Bearer <token>` to identity, user, event, and booking Axios clients.
11. Protected backend routes verify the JWT locally using the shared `JWT_SECRET`.
12. Admin-only event creation checks `req.user.role === "admin"`.
13. Booking creation rejects non-`user` roles.

Admin flow:

- Admin users are not created through registration.
- The identity service seeds an admin account on startup from environment variables.

Token validation:

- `GET /auth/validate` only verifies the JWT signature and expiry through middleware, then returns decoded claims.

## 7. Booking flow

1. User opens an event detail page from `/events/:id`.
2. User clicks `Book Tickets`, navigating to `/book/:id`.
3. Frontend posts to `POST /bookings` with:
   - `event_id`
   - `seats`
   - `Authorization: Bearer <token>`
4. Booking service verifies JWT.
5. Booking controller rejects admins or other non-`user` roles.
6. Booking controller validates `event_id` and `seats`.
7. Booking service checks whether the same user already has a confirmed booking for that event.
8. Booking service calls event-service:
   - `POST {EVENT_SERVICE_URL}/events/:eventId/reserve`
   - Body: `{ seats }`
9. Event service atomically decrements seats with:
   - `WHERE id = $1 AND available_seats >= $2`
10. If reservation fails, booking service returns `409 Seats unavailable`.
11. If reservation succeeds, booking service inserts a `confirmed` booking.
12. Frontend displays "Booking successful."
13. Dashboard calls `GET /users/me` and `GET /bookings` to show profile and booking list.

Booking risks:

- Seat reservation and booking insert are not part of one distributed transaction.
- If event-service reserves seats but booking insert fails, seats stay reduced without a booking record.
- `POST /events/:id/reserve` is unauthenticated and publicly callable if event-service is reachable.
- There is no cancellation flow to restore seats.
- The database unique constraint prevents duplicate confirmed bookings for one user/event/status, but there is no idempotency key for safe retries.

## 8. Event flow

### Public browsing

1. Frontend `/events` calls `GET /events`.
2. Event service returns all events ordered by date ascending.
3. Frontend renders event cards with date, available seats, description, and venue.
4. Frontend `/events/:id` calls `GET /events/:id`.
5. Event detail page shows venue, date/time, available seats, booking link, and chatbot form.

### Admin event creation

1. Admin logs in with seeded admin credentials.
2. Frontend shows `Create Event` links when `user.role === "admin"`.
3. Admin opens `/events/create`.
4. Frontend posts to `POST /events` with:
   - `name`
   - `description`
   - `venue`
   - `date`
   - `total_seats`
5. Event service verifies JWT and `admin` role.
6. Event service inserts an event with `available_seats = total_seats`.
7. Frontend navigates back to `/events`.

### Chatbot event Q&A

1. User enters a question on `/events/:id`.
2. Frontend posts to `/chatbot/chat` with `message` and `eventId`.
3. Chatbot service expects `POST /chat`.
4. Chatbot service fetches event details from event-service using `EVENT_SERVICE_URL`.
5. Chatbot service uses regex rules to answer questions about description, date, venue, seat availability, or highlights.

## 9. Security issues

### Critical/high

1. Production secrets are committed.
   - `.env.production` contains real-looking database passwords, JWT secret, and seed user passwords.
   - `k8s/secrets.yaml` contains base64-encoded secrets plus comments showing plaintext values.
   - Base64 Kubernetes Secret data is not encryption.

2. Internal reservation endpoint is unauthenticated.
   - `POST /events/:id/reserve` does not require service auth or user auth.
   - If reachable through ingress/nginx or direct port exposure, anyone can decrement event seats.

3. Backend ports are exposed in Docker Compose.
   - Compose maps `4001`, `4002`, `4003`, and `4004` to the host.
   - This conflicts with the README security guidance saying backend ports should be closed.

4. Kubernetes database-name configuration can collapse service isolation.
   - The ConfigMap sets global `DB_NAME=identity_db`.
   - All backend services read `DB_NAME`.
   - Event and booking tables may be created in the identity database in Kubernetes.

5. No HTTPS is active.
   - nginx listens on `443`, but the TLS server block is commented out.
   - HSTS header is sent on HTTP, which does not provide transport encryption.

### Medium

6. CORS is fully open.
   - All services call `cors()` without allowed-origin restrictions.

7. JWT expiry config is inconsistent.
   - `JWT_EXPIRES_IN=2h` exists, but login hardcodes `{ expiresIn: "2h" }`.
   - There is no refresh-token flow or server-side revocation.

8. JWT secret is shared across services.
   - Shared symmetric JWT verification works for a small project, but compromise of any service config enables token forging.
   - Consider asymmetric signing with private key only in identity-service and public key in resource services.

9. Frontend stores JWT in `localStorage`.
   - This is simple but exposes tokens to XSS impact.
   - Consider HttpOnly secure cookies or stronger XSS controls.

10. Error handler returns raw error messages.
    - `errorHandler` returns `err.message` to clients, which can leak internals.

11. Missing request validation and payload limits.
    - Inputs are lightly checked but not schema-validated.
    - `express.json()` uses default limits and no central validation library.

12. No password policy or login rate limit in Express.
    - nginx defines rate limits, but direct backend exposure bypasses them.
    - Kubernetes ingress has coarse rate limiting only.

13. Seed users in production are risky.
    - Startup-created default admin/user accounts can become long-lived backdoors if not rotated or disabled.

14. Docker images run as root by default.
    - Service Dockerfiles do not switch to a non-root user.

15. `npm install` is used instead of reproducible `npm ci`.
    - Docker builds may drift if lockfiles exist or dependency resolution changes.

16. No security headers in Express.
    - nginx sets several headers, but direct service access bypasses them.
    - Consider `helmet` in services or closing direct access completely.

### Low/operational

17. Health checks are shallow.
    - Docker Compose checks `pgrep node`, not HTTP readiness or DB connectivity.
    - nginx `/health` is static.

18. No audit logging.
    - Authentication, booking, and admin event creation are not logged in a structured way.

19. No database migration tool.
    - Tables are created at service startup with `CREATE TABLE IF NOT EXISTS`, which is limited for schema evolution.

20. No payment or notification security boundary.
    - Current booking flow confirms immediately, with no payment authorization or notification confirmation.

## 10. AWS integration opportunities

### Compute and networking

- Run containerized services on Amazon ECS Fargate or Amazon EKS.
- Use an Application Load Balancer for public ingress instead of exposing individual service ports.
- Place backend services and databases in private subnets.
- Keep only ALB ports `80/443` public; restrict SSH or remove SSH by using AWS Systems Manager Session Manager.
- Use AWS Cloud Map or ECS service discovery for internal service URLs.

### Database

- Move PostgreSQL from a container to Amazon RDS for PostgreSQL or Aurora PostgreSQL.
- Use separate databases or schemas per service, with separate DB users and least-privilege permissions.
- Enable Multi-AZ RDS for production availability.
- Enable automated backups, point-in-time recovery, Performance Insights, and enhanced monitoring.
- Store DB credentials in AWS Secrets Manager and rotate them.

### Secrets and configuration

- Replace committed `.env.production` and `k8s/secrets.yaml` secrets with:
  - AWS Secrets Manager for secrets.
  - AWS Systems Manager Parameter Store for non-secret config.
  - External Secrets Operator if running on EKS.
- Use IAM roles for tasks/pods instead of static AWS credentials.
- Keep JWT signing keys in Secrets Manager or AWS KMS-backed secure storage.

### Authentication and authorization

- Consider Amazon Cognito for hosted user pools, login, password policy, MFA, account recovery, and JWT issuance.
- If keeping custom identity-service, add:
  - MFA support for admins.
  - Refresh-token rotation.
  - Asymmetric JWT signing.
  - Role/permission claims with short-lived access tokens.

### API and edge

- Put Amazon CloudFront in front of the frontend and API.
- Serve the built React app from S3 + CloudFront instead of running Vite dev server in production.
- Use AWS WAF on CloudFront/ALB for rate limiting, managed rule sets, IP reputation lists, and bot controls.
- Use ACM certificates for managed HTTPS.
- Use API Gateway if the project needs request validation, usage plans, API keys, or managed auth integration.

### Messaging and reliability

- Use Amazon SQS for asynchronous booking-related work such as notifications, emails, and analytics.
- Use SNS or EventBridge for domain events like `BookingCreated`, `SeatsReserved`, and `EventCreated`.
- Add an outbox pattern so booking creation and event publication remain reliable.
- For seat reservation, consider:
  - One authoritative reservation service.
  - A short-lived reservation hold with expiry.
  - Idempotency keys for booking retries.
  - Compensation logic if booking persistence fails after seat reservation.

### Observability

- Send application logs to Amazon CloudWatch Logs.
- Add structured JSON logs with correlation/request IDs.
- Use AWS X-Ray or OpenTelemetry for tracing cross-service calls.
- Create CloudWatch alarms for:
  - 5xx rate
  - latency
  - failed logins
  - booking failures
  - database CPU/connections/storage

### CI/CD and images

- Store images in Amazon ECR.
- Build and deploy through GitHub Actions, AWS CodePipeline, or CodeBuild.
- Scan container images with Amazon Inspector or ECR enhanced scanning.
- Use immutable tags or image digests instead of mutable version tags.
- Use blue/green or rolling deployments with health gates.

### Static assets and frontend

- Build the frontend with `npm run build`.
- Host `dist/` in S3.
- Put CloudFront in front with cache policies and SPA fallback routing.
- Inject API base URL at build time or use runtime config served as a small JSON file.

### Security hardening on AWS

- Use private subnets for ECS/EKS tasks and RDS.
- Use security groups to allow:
  - ALB to frontend/API targets.
  - Backend services to RDS.
  - Booking/chatbot to event-service internally.
- Use VPC endpoints for Secrets Manager, ECR, CloudWatch, and SSM where appropriate.
- Enable GuardDuty, Security Hub, CloudTrail, and AWS Config.
- Encrypt RDS, logs, and secrets with KMS.
