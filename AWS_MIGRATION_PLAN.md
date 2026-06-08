# AWS Migration Plan

This plan is scoped for the current Black Tickets project deadline. It focuses on the smallest set of changes needed to make the existing application deployable on AWS with S3, RDS, and SQS-based booking notifications.

## 1. Final application features to keep

Keep the current user-facing feature set:

- User registration.
- User login with JWT authentication.
- Seeded admin login.
- Public event listing.
- Public event detail page.
- Admin-only event creation.
- User-only ticket booking.
- User dashboard with profile and booking list.
- Event assistant/chatbot for event-specific questions.
- Seat availability decrement during booking.

Keep the current service boundaries:

- `frontend`: React/Vite single-page app.
- `identity-service`: registration, login, token validation, profile.
- `event-service`: event catalog, admin create event, seat reservation.
- `booking-service`: booking creation and booking lookup.
- `chatbot-service`: event Q&A using event-service data.
- PostgreSQL as the relational database.

Keep these deployment concepts:

- Public frontend.
- Public API routes through one edge entry point.
- Backend services private behind the public edge.
- PostgreSQL not publicly exposed.

## 2. Bugs to fix before AWS

These should be fixed before deployment because they can break the app or weaken the AWS demo.

### Required fixes

1. `DB_NAME` is missing from `.env.production`.
   - Backend services read `process.env.DB_NAME`.
   - `.env.production` defines `IDENTITY_DB_NAME`, `EVENT_DB_NAME`, and `BOOKING_DB_NAME`, but the code does not use them.
   - Docker Compose services may fail or connect incorrectly unless each service receives a correct `DB_NAME`.

2. Kubernetes sets global `DB_NAME=identity_db`.
   - Event and booking services may create their tables in `identity_db`.
   - For AWS/RDS deployment, each service must receive its own database name or the code must support service-specific DB env vars.

3. Chatbot route mismatch.
   - Frontend calls `/chatbot/chat`.
   - Chatbot service defines `POST /chat`.
   - Ingress/nginx forwards `/chatbot` without path rewrite, so `/chatbot/chat` can reach the service as `/chatbot/chat` and return `404`.

4. `POST /events/:id/reserve` is unauthenticated.
   - This endpoint is intended for booking-service only.
   - It should not be publicly callable after AWS deployment.

5. Production secrets are committed.
   - `.env.production` and `k8s/secrets.yaml` contain real-looking secrets.
   - For AWS, use environment variables from AWS Secrets Manager, SSM Parameter Store, ECS task secrets, or deployment-time config.

6. Backend ports are publicly exposed in Docker Compose.
   - For AWS, only the public load balancer/API entry point should be exposed.
   - Backend service ports should remain private.

### Recommended if time allows

7. Use `JWT_EXPIRES_IN` instead of hardcoded `"2h"`.
8. Restrict CORS to the deployed frontend origin.
9. Add request size limits to `express.json()`.
10. Stop returning raw error messages in production.
11. Improve health checks to verify database connectivity.

## 3. App changes needed for S3

The frontend should be built as static files and hosted from S3, preferably behind CloudFront.

### Required frontend changes

1. Build the React app with Vite:

```bash
npm run build
```

This generates `frontend/dist/`.

2. Do not run the Vite dev server in production.
   - Current `frontend/Dockerfile` runs `npm run dev`.
   - For S3 hosting, the Dockerfile is not needed for frontend production hosting.

3. Ensure API base URL works from S3.
   - Current frontend uses:

```js
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || "";
```

   - For S3, set `VITE_API_BASE_URL` at build time to the public API/ALB/CloudFront URL.
   - Example:

```text
VITE_API_BASE_URL=https://api.example.com
```

4. Add SPA fallback behavior in S3/CloudFront.
   - Routes like `/events/1`, `/login`, and `/dashboard` are frontend routes.
   - S3/CloudFront must return `index.html` for unknown routes.

5. Keep API paths unchanged from the frontend perspective:
   - `${VITE_API_BASE_URL}/auth`
   - `${VITE_API_BASE_URL}/users`
   - `${VITE_API_BASE_URL}/events`
   - `${VITE_API_BASE_URL}/bookings`
   - `${VITE_API_BASE_URL}/chatbot`

### S3 deadline approach

- Build frontend locally or in CI.
- Upload `frontend/dist/` to S3.
- Put CloudFront in front if available within the deadline.
- Configure `VITE_API_BASE_URL` to the backend ALB/API URL.
- Avoid changing UI features.

## 4. App changes needed for SQS booking notification

The deadline-friendly SQS integration should be added after booking creation. It should not change the booking result shown to the user.

### Target behavior

1. User creates a booking.
2. Booking service reserves seats through event-service.
3. Booking service inserts a confirmed booking into PostgreSQL.
4. Booking service sends a message to SQS with booking notification data.
5. API still returns booking success even if notification sending is non-critical.

### Message contents

Use a compact JSON payload:

```json
{
  "type": "BOOKING_CONFIRMED",
  "bookingId": 123,
  "userId": 45,
  "eventId": 6,
  "seats": 2,
  "status": "confirmed",
  "createdAt": "2026-06-08T05:30:00.000Z"
}
```

### Required booking-service changes

1. Add AWS SDK dependency.
   - Use AWS SDK v3:

```text
@aws-sdk/client-sqs
```

2. Add SQS environment variables:

```text
AWS_REGION=us-east-1
BOOKING_NOTIFICATION_QUEUE_URL=https://sqs.us-east-1.amazonaws.com/account-id/queue-name
```

3. Add an SQS notification service module.
   - Example target file:

```text
booking-service/src/services/notificationQueue.js
```

4. Call the SQS sender after `createBooking()` succeeds.

5. Do not fail booking creation if SQS send fails during the deadline demo.
   - Log the failure.
   - Return the successful booking response.

### Optional consumer

For the deadline, the SQS producer may be enough if the requirement is integration proof.

If a consumer is required, add a small worker service later:

- Poll SQS.
- Log or send email notification.
- Delete message after processing.

Do not add the worker unless the deadline explicitly requires notification delivery, because it adds deployment and operational scope.

## 5. App changes needed for RDS environment variables

Use RDS PostgreSQL instead of the local/containerized PostgreSQL.

### Required env vars

Each backend service should receive:

```text
DB_HOST=<rds-endpoint>
DB_PORT=5432
DB_USER=<service-db-user-or-shared-deadline-user>
DB_PASS=<from-secrets-manager-or-env>
DB_NAME=<service-database-name>
```

### Deadline-friendly database mapping

Keep the existing three-database design:

| Service | `DB_NAME` |
| --- | --- |
| `identity-service` | `identity_db` |
| `event-service` | `event_db` |
| `booking-service` | `booking_db` |

Use one RDS instance with three databases to minimize migration effort.

### Required code/config decision

Choose one of these approaches.

Recommended for deadline:

- Keep service code reading `DB_NAME`.
- Set `DB_NAME` separately per service in ECS/EKS/task config.
- Do not introduce new service-specific env var names in code.

Alternative:

- Change code to read `IDENTITY_DB_NAME`, `EVENT_DB_NAME`, and `BOOKING_DB_NAME`.
- This requires source edits in all three backend `src/config/db.js` files and more testing.

### RDS setup requirements

- RDS must be in private subnets.
- Backend services must be allowed to connect to RDS security group on `5432`.
- RDS should not be publicly accessible.
- Create databases before service startup:

```sql
CREATE DATABASE identity_db;
CREATE DATABASE event_db;
CREATE DATABASE booking_db;
```

- Existing services create their own tables at startup.

## 6. What NOT to change

To protect the deadline, do not change these unless a bug directly blocks deployment:

- Do not redesign the frontend UI.
- Do not rewrite services into a different framework.
- Do not merge microservices.
- Do not add a full API gateway rewrite.
- Do not add payment service.
- Do not add cancellation/refund workflows.
- Do not replace JWT auth with Cognito for this deadline.
- Do not change database schema beyond what is needed for deployment.
- Do not add a full migration framework unless required.
- Do not add event-driven booking orchestration beyond SQS notification publishing.
- Do not implement distributed transactions.
- Do not change the existing public API contract unless fixing the chatbot route mismatch.
- Do not add a complex notification consumer unless explicitly required.
- Do not containerize the frontend for production if S3 hosting is the target.

## 7. Exact file-wise implementation plan

No source code should be modified until this plan is approved. The following is the implementation sequence.

### Root config

#### `.env.production`

Purpose:

- Remove committed real secrets before production use.
- Add/clarify service-specific deployment values.

Planned changes:

- Replace hardcoded secret values with placeholders.
- Add examples for per-service `DB_NAME`.
- Add:

```text
AWS_REGION=us-east-1
BOOKING_NOTIFICATION_QUEUE_URL=
```

Notes:

- For actual AWS deployment, prefer AWS Secrets Manager/SSM over this file.
- Do not commit real production values.

#### `docker-compose.yml`

Purpose:

- Local/deadline testing only.

Planned changes if Compose is still used:

- Set `DB_NAME` per backend service:
  - identity-service: `identity_db`
  - event-service: `event_db`
  - booking-service: `booking_db`
- Avoid exposing backend ports for production-like mode.

Do not spend time converting Compose into final AWS infrastructure if ECS/EKS deployment config is handled separately.

### Identity service

#### `identity-service/src/config/db.js`

Purpose:

- Connect identity-service to RDS `identity_db`.

Planned changes:

- Prefer no code change.
- Keep using `process.env.DB_NAME`.
- Ensure AWS task/deployment config sets `DB_NAME=identity_db`.

Optional cleanup:

- Add startup validation for missing `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASS`, and `DB_NAME`.

#### `identity-service/src/controllers/authController.js`

Purpose:

- Token generation.

Planned changes:

- Optional: use `process.env.JWT_EXPIRES_IN || "2h"`.

Deadline decision:

- Skip unless there is time. Current hardcoded expiry works.

### Event service

#### `event-service/src/config/db.js`

Purpose:

- Connect event-service to RDS `event_db`.

Planned changes:

- Prefer no code change.
- Keep using `process.env.DB_NAME`.
- Ensure AWS task/deployment config sets `DB_NAME=event_db`.

#### `event-service/src/routes/eventRoutes.js`

Purpose:

- Protect internal seat reservation.

Planned changes:

- Add protection for `POST /events/:id/reserve`.
- Deadline-simple option:
  - Require an internal service token header, such as `x-service-token`.
  - Booking service sends the same token.
  - Token value comes from env var `INTERNAL_SERVICE_TOKEN`.

Alternative:

- Keep route private only through security groups and no public routing.

Recommended:

- Do both if time permits: network-private plus internal token.

#### `event-service/src/controllers/eventController.js`

Purpose:

- Seat reservation behavior.

Planned changes:

- No required deadline change.
- Keep atomic SQL decrement.

### Booking service

#### `booking-service/package.json`

Purpose:

- Add SQS client dependency.

Planned changes:

- Add dependency:

```json
"@aws-sdk/client-sqs": "<latest compatible v3 version>"
```

Use the same install approach as the project currently uses.

#### `booking-service/src/services/notificationQueue.js`

Purpose:

- Encapsulate SQS publishing.

Planned changes:

- New file.
- Create `SQSClient` using `AWS_REGION`.
- Export `sendBookingNotification(payload)`.
- If `BOOKING_NOTIFICATION_QUEUE_URL` is missing, log and skip sending.
- Send JSON body to SQS.

#### `booking-service/src/controllers/bookingController.js`

Purpose:

- Send booking notification after successful booking insert.

Planned changes:

- Import `sendBookingNotification`.
- After `createBooking()` succeeds, send SQS message.
- Wrap SQS send in `try/catch`.
- Log SQS failure but still return booking success.
- Add internal token header when calling event-service reserve endpoint if event-service reserve protection is implemented.

#### `booking-service/src/config/db.js`

Purpose:

- Connect booking-service to RDS `booking_db`.

Planned changes:

- Prefer no code change.
- Keep using `process.env.DB_NAME`.
- Ensure AWS task/deployment config sets `DB_NAME=booking_db`.

### Chatbot service

#### `chatbot-service/src/app.js` or `chatbot-service/src/routes/chatRoutes.js`

Purpose:

- Fix external route mismatch.

Recommended deadline fix:

- Support both:
  - `POST /chat`
  - `POST /chatbot/chat`

This avoids needing path rewrites in every deployment target.

Alternative:

- Configure ALB/ingress/nginx path rewrite so `/chatbot/chat` becomes `/chat`.

Preferred:

- App-level support for both paths because it is simple and robust for S3 + API URL deployments.

#### `chatbot-service/src/services/eventClient.js`

Purpose:

- Fetch event details from event-service.

Planned changes:

- No required change.
- Ensure `EVENT_SERVICE_URL` points to the private event-service URL in AWS.

### Frontend

#### `frontend/src/api.js`

Purpose:

- API base URL for S3-hosted frontend.

Planned changes:

- Prefer no code change.
- Keep using `VITE_API_BASE_URL`.
- Ensure build environment sets `VITE_API_BASE_URL` to public backend URL.

Potential issue:

- If the public API routes differ from current paths, update only this file.

#### `frontend/package.json`

Purpose:

- Build static assets for S3.

Planned changes:

- No required change.
- Use existing `npm run build`.

#### `frontend/Dockerfile`

Purpose:

- Current dev-server container image.

Planned changes:

- No required change if frontend is hosted on S3.
- Do not use this Dockerfile for production S3 hosting.

### Nginx / ingress

#### `nginx/nginx.conf`

Purpose:

- Local/reverse proxy routing.

Planned changes if nginx is used in AWS:

- Fix `/chatbot/` path routing or rely on chatbot service supporting `/chatbot/chat`.
- Stop routing public traffic to internal-only reserve endpoint if possible.
- Enable HTTPS only if using nginx directly.

Deadline AWS preference:

- Use ALB/CloudFront/ACM instead of maintaining nginx TLS manually.

#### `k8s/ingress.yaml`

Purpose:

- Kubernetes routing.

Planned changes if EKS is used:

- Ensure `/chatbot/chat` works.
- Ensure `/auth`, `/users`, `/events`, and `/bookings` route correctly.
- Do not expose internal-only routes if using separate internal services.

### Kubernetes config

#### `k8s/configmap.yaml`

Purpose:

- Non-secret runtime config.

Planned changes if EKS is used:

- Remove global `DB_NAME=identity_db`.
- Set service-specific `DB_NAME` in each deployment instead.
- Add:

```text
AWS_REGION: "us-east-1"
EVENT_SERVICE_URL: "http://event-service:4002"
```

Do not store secrets here.

#### `k8s/secrets.yaml`

Purpose:

- Current Kubernetes secret manifest.

Planned changes:

- Do not commit real secrets.
- Remove plaintext comments.
- Prefer External Secrets Operator connected to AWS Secrets Manager.

#### `k8s/identity-deployment.yaml`

Planned changes if EKS is used:

- Set `DB_NAME=identity_db` for this deployment.
- Source DB password and JWT secret from AWS-backed secret integration.

#### `k8s/event-deployment.yaml`

Planned changes if EKS is used:

- Set `DB_NAME=event_db` for this deployment.
- Add `INTERNAL_SERVICE_TOKEN` if reserve endpoint token protection is implemented.

#### `k8s/booking-deployment.yaml`

Planned changes if EKS is used:

- Set `DB_NAME=booking_db` for this deployment.
- Add:

```text
AWS_REGION
BOOKING_NOTIFICATION_QUEUE_URL
INTERNAL_SERVICE_TOKEN
```

#### `k8s/chatbot-deployment.yaml`

Planned changes if EKS is used:

- Ensure `EVENT_SERVICE_URL=http://event-service:4002`.

### PostgreSQL bootstrap

#### `postgres/init.sql`

Purpose:

- Local database initialization.

Planned changes:

- No required app change.
- For RDS, run equivalent SQL manually or through a one-time migration/admin task:

```sql
CREATE DATABASE identity_db;
CREATE DATABASE event_db;
CREATE DATABASE booking_db;
```

Do not rely on Docker entrypoint scripts for RDS.

### Scripts

#### `scripts/generate-secrets.js`

Purpose:

- Local generation of secret values.

Planned changes:

- Optional.
- Could add `INTERNAL_SERVICE_TOKEN`.
- Could output `AWS_REGION` and `BOOKING_NOTIFICATION_QUEUE_URL` placeholders.

#### `scripts/setup-production.sh` and `scripts/setup-dynamic-env.sh`

Purpose:

- EC2/Docker production helper scripts.

Planned changes:

- Do not prioritize unless the deadline deployment uses EC2 with Docker Compose.
- If using ECS/EKS/S3/RDS/SQS, these scripts are secondary.

## Deadline implementation order

1. Fix RDS env mapping with correct per-service `DB_NAME`.
2. Fix chatbot route mismatch.
3. Protect or hide event reserve endpoint.
4. Add SQS publish after booking creation.
5. Build frontend for S3 with `VITE_API_BASE_URL`.
6. Move secrets out of committed files and into AWS-managed configuration.
7. Deploy backend services privately with access to RDS and SQS.
8. Upload frontend `dist/` to S3 and verify SPA routing.
9. Smoke test:
   - Register.
   - Login.
   - List events.
   - Create event as admin.
   - Book event as user.
   - Verify seat count decreases.
   - Verify SQS message is sent.
   - Verify dashboard shows booking.
   - Verify chatbot responds.

