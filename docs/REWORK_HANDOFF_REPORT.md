# BlackTickets Rework Handoff Report

## Purpose

This document summarizes the current status of the BlackTickets AWS/Terraform project so another LLM or engineer can safely understand and rework it.

The project has two major parts:

- A microservices ticket booking application.
- Terraform infrastructure for deploying and operating it on AWS.

## Current Repository Status

Repository root:

```text
D:\project\blacktickets_aws
```

Important current git status:

```text
D terraform/cloudwatch.tf
D terraform/ec2-launch-template.tf
D terraform/ecr.tf
?? terraform.tfstate
```

Notes:

- `terraform/cloudwatch.tf`, `terraform/ec2-launch-template.tf`, and `terraform/ecr.tf` are tracked as deleted in the working tree. Earlier versions of some of these files were empty or unused, but do not assume deletion is intentional without checking history.
- There is an untracked root-level `terraform.tfstate`. It is empty and should not be treated as the real infrastructure state.
- Terraform state handling is currently sensitive because the backend was changed to S3.

## Terraform Backend and State Status

`terraform/provider.tf` now contains an S3 backend:

```hcl
backend "s3" {
  bucket         = "blacktickets-dev-tfstate"
  key            = "blacktickets/dev/terraform.tfstate"
  region         = "us-east-1"
  dynamodb_table = "blacktickets-dev-terraform-locks"
  encrypt        = true
}
```

Local backend metadata exists at:

```text
terraform/.terraform/terraform.tfstate
```

It points to:

- S3 bucket: `blacktickets-dev-tfstate`
- State key: `blacktickets/dev/terraform.tfstate`
- DynamoDB lock table: `blacktickets-dev-terraform-locks`

There are also local backup state files:

```text
terraform/terraform.tfstate.pre-backend-backup
terraform/terraform.tfstate.backup.pre-backend-backup
terraform/terraform.tfstate.backup
```

The root-level file:

```text
terraform.tfstate
```

contains an empty state:

```json
{
  "outputs": {},
  "resources": []
}
```

Do not use that root-level state file for infrastructure decisions.

## Important Warning About Destroy

Remote state infrastructure is managed by the same Terraform project:

- `aws_s3_bucket.tfstate`
- `aws_dynamodb_table.terraform_locks`

If running `terraform destroy` while using the S3 backend, be very careful. Terraform may attempt to destroy the state bucket and lock table that it is actively using. A safe destroy workflow usually needs planning around backend state preservation, state backup, and possibly excluding backend resources until everything else is destroyed.

Do not blindly delete:

- `blacktickets-dev-tfstate`
- `blacktickets-dev-terraform-locks`

until the real state is safely backed up and no longer needed.

## Current Terraform Architecture

Terraform files currently define:

### Core Network

Files:

- `vpc.tf`
- `subnets.tf`
- `route-tables.tf`
- `nat-gateway.tf`
- `vpc-endpoints.tf`
- `security-groups.tf`

Resources:

- VPC: `aws_vpc.main`
- Internet Gateway
- Public subnets
- Private app subnets
- Private DB subnets
- NAT Gateway
- Route tables and associations
- VPC endpoints:
  - S3 Gateway endpoint
  - ECR API
  - ECR Docker
  - Secrets Manager
  - CloudWatch Logs
  - SSM
  - SSM Messages
  - EC2 Messages

Purpose:

- Public ALB is internet-facing.
- EC2 app instances run in private app subnets.
- RDS runs in private DB subnets.
- VPC endpoints allow private instances to reach AWS services without relying fully on public internet paths.

### Load Balancers

File:

- `alb.tf`

Resources:

- Public ALB: `aws_lb.public`
- Private ALB: `aws_lb.private`
- Target groups:
  - frontend: port `80`
  - identity: port `4001`
  - event: port `4002`
  - booking: port `4003`
  - chatbot: port `4004`
- Public listener:
  - HTTP `80`, forwards to frontend target group.
- Private listener:
  - HTTP `80`, default fixed 404.
  - Path rules for `/auth`, `/users`, `/events`, `/bookings`, `/chatbot`.

Purpose:

- Public ALB receives user traffic.
- Private ALB routes internal API traffic from frontend nginx to backend services.

### EC2 and Auto Scaling

Files:

- `launch-template.tf`
- `asg.tf`

Resources:

- Launch template: `aws_launch_template.app`
- Auto Scaling Group: `aws_autoscaling_group.app`

The launch template user data:

1. Installs Docker, AWS CLI, PostgreSQL client.
2. Reads Secrets Manager app config.
3. Waits for RDS.
4. Creates databases if missing:
   - `identity_db`
   - `event_db`
   - `booking_db`
5. Logs in to ECR.
6. Pulls Docker images:
   - `blacktickets-identity-service`
   - `blacktickets-event-service`
   - `blacktickets-booking-service`
   - `blacktickets-chatbot-service`
   - `blacktickets-frontend`
7. Runs all containers on the same EC2 instance.

Important design note:

- This is not ECS/EKS. It is EC2 plus Docker via user data.
- Every ASG instance runs all containers.

### IAM

File:

- `iam.tf`

Resources:

- EC2 app role and instance profile.
- ECR read-only policy attachment.
- Secrets Manager read/write policy attachment.
- SSM managed instance core policy.
- Inline S3 poster upload policy.
- Inline SQS send policy.

Risk:

- EC2 role currently has `SecretsManagerReadWrite`, which is broader than ideal. Runtime usually only needs read access to the specific app config secret.

### RDS and Secrets Manager

File:

- `rds.tf`

Resources:

- RDS PostgreSQL instance.
- DB subnet group.
- Secrets Manager secret and secret version.

Secret contains:

- DB host, port, user, password.
- JWT secret.
- Internal service token.
- Booking SQS queue URL.
- Seed admin/user credentials.

Risk:

- `terraform.tfvars` contains real-looking plaintext secrets.
- RDS config is dev-oriented:
  - `multi_az = false`
  - `skip_final_snapshot = true`
  - `deletion_protection = false`

### S3 and CloudFront

File:

- `s3.tf`

Resources:

- Poster S3 bucket.
- Public access block.
- AES256 server-side encryption.
- Lifecycle rule for incomplete multipart uploads.
- CloudFront distribution for private poster delivery.
- Origin Access Control.
- S3 bucket policy allowing CloudFront read access.

Purpose:

- Event posters are uploaded to private S3 and served through CloudFront.

### SQS, Lambda, SNS Notification Pipeline

Files:

- `sqs.tf`
- `lambda.tf`
- `sns.tf`
- Lambda code: `lambda/booking-notification-consumer/index.js`

Flow:

```text
Booking Service -> SQS -> Lambda -> SNS -> Email
```

Resources:

- SQS queue: `blacktickets-dev-booking-notifications`
- Lambda function: `blacktickets-dev-booking-notification-consumer`
- SNS topic: `blacktickets-dev-booking-notifications`
- SNS email subscription from `var.notification_email`

Application flow:

- Booking service publishes `BOOKING_CONFIRMED` to SQS.
- Lambda consumes the SQS message.
- Lambda publishes an email notification to SNS.

Important:

- Booking service should not fail if SQS notification fails.
- Lambda intentionally throws if SNS publish fails so SQS can retry.

### CloudWatch Dashboard and Alarms

Files:

- `cloudwatch-dashboard.tf`
- `cloudwatch-alarms.tf`

Dashboard:

- `BlackTickets-Operations`

Widgets:

- Public ALB
- Private ALB
- ASG
- EC2
- RDS
- Lambda
- SQS
- CloudFront

Alarms:

- Public ALB 5XX
- Private ALB target 5XX
- EC2 CPU high
- RDS CPU high
- RDS free storage low
- Lambda errors
- SQS queue depth high

Alarm action:

- Existing SNS topic.

### WAF

File:

- `waf.tf`

Resources:

- WAFv2 Web ACL: `blacktickets-dev-web-acl`
- Public ALB association.

Rules:

- AWS managed common rule set.
- AWS managed SQLi rule set.
- Rate limit rule: 100 requests per 5 minutes by IP.

Recent tuning:

- `SizeRestrictions_BODY` is overridden to `count {}` because it was blocking valid application requests and causing 403 responses.

Known drift from earlier investigation:

- Terraform state listed `aws_wafv2_web_acl_association.public_alb`, but AWS CLI previously reported no associated resources for the WAF ACL.
- A refreshed plan may attempt to create the association again.
- A no-refresh targeted plan showed only in-place Web ACL update.

Any rework should verify WAF association carefully before applying.

### CloudTrail

File:

- `cloudtrail.tf`

Resources:

- CloudTrail log S3 bucket: `blacktickets-dev-cloudtrail-logs`
- Bucket public access block.
- Bucket encryption.
- Bucket versioning.
- Lifecycle rule:
  - Standard-IA after 30 days.
  - Expire after 365 days.
- CloudTrail: `blacktickets-dev-trail`
- CloudWatch log group: `/aws/cloudtrail/blacktickets-dev`
- IAM role and policy for CloudTrail to write CloudWatch Logs.

Events:

- Multi-region trail.
- Global service events.
- Log file validation.
- Management read/write events.
- S3 object data events for the poster bucket.

### Remote State Infrastructure

File:

- `remote-state.tf`

Resources:

- S3 bucket: `blacktickets-dev-tfstate`
- Public access block.
- AES256 encryption.
- Versioning.
- Lifecycle:
  - noncurrent versions expire after 90 days.
- DynamoDB table: `blacktickets-dev-terraform-locks`
  - Billing: `PAY_PER_REQUEST`
  - Hash key: `LockID`

Backend block has already been added in `provider.tf`.

## Application Architecture

Services:

- `frontend`: React/Vite app, production Dockerfile serves static build with nginx.
- `identity-service`: authentication, user profile, JWT issuing.
- `event-service`: event catalog, admin event creation, poster upload, seat reservation.
- `booking-service`: booking creation and booking lookup.
- `chatbot-service`: rule-based event assistant.
- PostgreSQL: three logical databases.

Runtime flow:

1. User reaches public ALB.
2. Public ALB forwards frontend traffic to EC2 target group.
3. Frontend nginx serves SPA.
4. Frontend nginx proxies API routes to private ALB using `PRIVATE_ALB_DNS`.
5. Private ALB routes backend paths to service target groups.
6. Backend services use RDS PostgreSQL.
7. Event service uploads posters to S3.
8. CloudFront serves poster images.
9. Booking service sends SQS notification messages.
10. Lambda consumes SQS and publishes SNS email.

## Important Application Details

### Booking and Seat Reservation

Booking flow:

1. Booking service checks user role.
2. Checks duplicate booking.
3. Calls event service reserve endpoint:
   - `POST /events/:id/reserve`
   - sends `x-service-token`
4. Event service decrements seats atomically.
5. Booking service inserts booking.
6. Booking service sends SQS message.

Risk:

- Seat reservation and booking insert are not transactional across services. If reservation succeeds but booking insert fails, seats may be reduced without a booking.

### Internal Service Token

Event reserve endpoint is protected by:

```text
requireServiceToken
```

Booking service sends:

```text
x-service-token: INTERNAL_SERVICE_TOKEN
```

### Frontend Routing

Production frontend nginx routes:

- `/auth/` -> private ALB
- `/users/` -> private ALB
- `/events` and `/events/` -> private ALB
- `/bookings` and `/bookings/` -> private ALB
- `/chatbot/` -> private ALB
- `/` -> static SPA fallback

## Kubernetes Status

There is a `k8s/` folder, but it appears older/stale compared with the Terraform/EC2 deployment path.

Known issues from earlier analysis:

- K8s config had global `DB_NAME=identity_db`.
- Frontend K8s port likely mismatched older frontend dev server assumptions.
- K8s secrets include base64 values and plaintext comments.

Unless explicitly reworking Kubernetes, prefer focusing on Terraform.

## Docker Compose Status

`docker-compose.yml` exists and can run local/prod-ish containers.

Notes:

- Postgres password is hardcoded in compose.
- Backends expose ports to host.
- It is not the main AWS path.

## Documentation Created During Rework

Docs now include:

- `docs/terraform-aws-services-guide.md`
- `docs/terraform-remote-state.md`
- `docs/cloudtrail.md`
- `docs/sns-booking-notifications.md`
- `docs/sqs-booking-notifications.md`

These are useful for project understanding, but validate them against current code before using them as source of truth.

## Security Risks

High-priority issues:

1. `terraform/terraform.tfvars` contains real-looking secrets:
   - DB password.
   - JWT secret.
   - internal service token.
   - admin/user passwords.
2. `.env.production` also contains production-like credentials.
3. K8s secrets contain base64 secrets plus plaintext comments.
4. EC2 IAM role uses broad Secrets Manager read/write access.
5. JWTs are stored in frontend localStorage.
6. CORS is open in backend services.
7. Docker images run as root by default.
8. No package lockfiles were found earlier, so builds may drift.

## Terraform Validation and Plan Notes

Terraform backend was changed to S3. `terraform init` previously hit registry network timeout once, but local provider cache exists.

`terraform state list` succeeded and showed many remote-managed resources, including:

- VPC/network resources.
- ALBs and target groups.
- ASG and launch template.
- RDS.
- poster S3/CloudFront.
- SQS/Lambda/SNS.
- dashboard/alarms.
- WAF.
- CloudTrail.
- remote state bucket and DynamoDB lock table.

This suggests the S3 backend has real state available.

Do not rely on root-level `terraform.tfstate`; it is empty.

## Rework Recommendations

For a clean rework, another LLM should:

1. Confirm desired goal:
   - destroy all AWS resources,
   - rebuild architecture,
   - refactor Terraform,
   - or preserve some components.
2. Back up remote state before any destructive operation.
3. Decide what to do with backend resources:
   - preserve state bucket/table until the very end,
   - or migrate state elsewhere before destroying them.
4. Resolve git working tree:
   - investigate deleted tracked files.
   - decide whether to restore or remove them intentionally.
5. Rotate all committed secrets.
6. Replace broad IAM policies with least privilege.
7. Consider moving from EC2 user-data Docker orchestration to ECS if this project is being redesigned.
8. If keeping EC2, improve:
   - Docker service supervision.
   - health checks.
   - deployment strategy.
   - image version pinning instead of `latest`.
9. Add lockfiles and CI validation.
10. Treat Kubernetes manifests as stale unless K8s becomes the target.

## Quick Mental Model

Current AWS shape:

```text
Internet
  -> WAF
  -> Public ALB
  -> EC2 frontend container
  -> Private ALB
  -> EC2 backend containers
  -> RDS PostgreSQL

Booking service
  -> SQS
  -> Lambda
  -> SNS
  -> Email

Event service
  -> S3 poster bucket
  -> CloudFront

AWS activity
  -> CloudTrail
  -> S3 logs + CloudWatch Logs

Metrics
  -> CloudWatch Dashboard + Alarms
```

## Final Handoff Notes

This repo is not in a pristine state. It has real AWS state, a configured S3 backend, local backup state files, committed secrets, and some tracked Terraform files deleted in the working tree.

Before applying or destroying anything, a new assistant should:

- run `git status --short`;
- run `terraform init` only if needed and understand backend migration state;
- run `terraform state list`;
- run `terraform plan` or `terraform plan -destroy`;
- inspect whether remote state bucket and lock table are included in the destroy plan;
- avoid deleting state infrastructure before preserving state.
