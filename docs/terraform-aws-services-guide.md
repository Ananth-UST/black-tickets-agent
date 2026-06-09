# BlackTickets Terraform and AWS Services Guide

## Overview

BlackTickets uses Terraform to define and manage AWS infrastructure as code. Instead of creating resources manually in the AWS Console, Terraform keeps the cloud setup repeatable, reviewable, and easier to rebuild.

The project is a ticket booking microservices application. It includes a React frontend, Node.js backend services, PostgreSQL, event poster uploads, booking notifications, monitoring, security, and auditing.

Terraform helps this project by:

- Creating the network, compute, database, storage, and security resources consistently.
- Reducing manual AWS setup mistakes.
- Making infrastructure changes visible in `terraform plan`.
- Supporting future team collaboration through remote state and locking.
- Making the architecture easier to explain and reproduce.

## Networking

### VPC

A VPC is a private network inside AWS. It defines where the application resources live.

BlackTickets uses a VPC to isolate its infrastructure from other AWS customers and to control traffic between public resources, private services, and the database.

How it helps:

- Gives the project a secure network boundary.
- Allows public and private subnet separation.
- Supports security groups, route tables, NAT, VPC endpoints, ALB, EC2, and RDS.

Use case in this project:

- Public users reach the app through the public ALB.
- Backend services and RDS stay in private network areas.

### Public Subnets

Public subnets are network zones that can route traffic to and from the internet.

How they help:

- Host public-facing infrastructure like the public Application Load Balancer.
- Allow users to access the frontend through HTTP/HTTPS.

Use case:

- The public ALB is placed in public subnets so customers can access BlackTickets.

### Private App Subnets

Private app subnets do not directly expose resources to the internet.

How they help:

- Keep EC2 app instances private.
- Reduce the attack surface.
- Allow traffic only from approved internal/public load balancers.

Use case:

- EC2 instances running Docker containers for frontend and backend services live in private app subnets.

### Private DB Subnets

Private DB subnets are used for database resources.

How they help:

- Keep RDS inaccessible from the public internet.
- Allow only application instances to connect to PostgreSQL.

Use case:

- RDS PostgreSQL is deployed in private DB subnets.

### Internet Gateway

An Internet Gateway allows public subnet resources to communicate with the internet.

How it helps:

- Allows public ALB internet access.
- Enables inbound user traffic to the public entry point.

Use case:

- Users reach BlackTickets through the public ALB.

### NAT Gateway

A NAT Gateway allows private resources to make outbound internet requests without allowing inbound public access.

How it helps:

- Private EC2 instances can download packages or reach external services.
- Instances remain private.

Use case:

- App instances in private subnets can pull updates or connect outward while staying protected from direct inbound internet traffic.

### VPC Endpoints

VPC endpoints allow private AWS resources to access AWS services without going through the public internet.

How they help:

- Improve security and reliability.
- Reduce dependency on public internet paths.

Use case:

- App instances can access ECR, Secrets Manager, CloudWatch Logs, SSM, and S3 through private AWS networking.

## Load Balancing

### Public Application Load Balancer

An Application Load Balancer routes external user traffic to application targets.

How it helps:

- Provides one public entry point.
- Distributes traffic to app instances.
- Supports health checks.
- Can be protected by AWS WAF.

Use case:

- Users access BlackTickets through the public ALB.
- The public ALB routes traffic to the frontend target group.

### Private Application Load Balancer

A private ALB routes internal application traffic inside the VPC.

How it helps:

- Keeps backend APIs private.
- Provides internal routing for services.
- Reduces public exposure of backend services.

Use case:

- The frontend nginx container proxies API routes to the private ALB.
- The private ALB routes `/auth`, `/users`, `/events`, `/bookings`, and `/chatbot` to the correct backend service ports.

### Target Groups

Target groups define where ALB traffic should go.

How they help:

- Separate frontend, identity, event, booking, and chatbot services.
- Enable health checks per service.

Use case:

- Each backend service has its own target group on ports `4001` to `4004`.
- Frontend has a target group on port `80`.

## Compute

### EC2

EC2 provides virtual machines in AWS.

How it helps:

- Runs the BlackTickets Docker containers.
- Gives full control over the runtime environment.
- Works with Auto Scaling Groups.

Use case:

- One or more EC2 instances run frontend, identity-service, event-service, booking-service, and chatbot-service containers.

### Launch Template

A launch template defines how EC2 instances are created.

How it helps:

- Standardizes instance type, AMI, IAM role, security groups, and startup script.
- Makes Auto Scaling repeatable.

Use case:

- The BlackTickets launch template installs Docker, pulls images from ECR, reads secrets, creates databases if needed, and starts containers.

### Auto Scaling Group

An Auto Scaling Group manages EC2 instance count.

How it helps:

- Replaces unhealthy instances.
- Supports scaling from one to more instances.
- Registers instances with target groups.

Use case:

- BlackTickets uses an ASG to run app instances reliably and attach them to ALB target groups.

## Container Registry

### ECR

Amazon ECR stores Docker container images.

How it helps:

- Keeps application images in AWS.
- Allows EC2 instances to pull approved service images.
- Integrates with IAM.

Use case:

- BlackTickets service images are pulled from ECR by the EC2 launch template.

## Database

### RDS PostgreSQL

RDS is AWS managed relational database hosting. PostgreSQL is the relational database engine used by the app.

How it helps:

- Removes the need to manage database installation manually.
- Provides backups, monitoring, security groups, and managed operations.
- Keeps data outside app containers.

Use case:

- `identity_db` stores users and roles.
- `event_db` stores event data and seat availability.
- `booking_db` stores booking records.

## Storage and CDN

### S3 Poster Bucket

S3 stores objects such as images, logs, and files.

How it helps:

- Durable storage for event poster images.
- Decouples uploaded assets from application containers.

Use case:

- Admin-created event posters are uploaded to the private poster bucket.

### CloudFront for Posters

CloudFront is a content delivery network.

How it helps:

- Serves poster images faster to users.
- Keeps the S3 bucket private through Origin Access Control.

Use case:

- Event posters are stored in S3 and delivered through CloudFront URLs.

### S3 CloudTrail Bucket

CloudTrail logs are stored in a dedicated S3 bucket.

How it helps:

- Preserves audit history.
- Supports compliance and incident investigation.
- Uses versioning, encryption, lifecycle rules, and public access blocking.

Use case:

- BlackTickets stores AWS account activity logs in `blacktickets-dev-cloudtrail-logs`.

### S3 Terraform State Bucket

Terraform state records what infrastructure Terraform manages.

How it helps:

- Enables shared state for team collaboration.
- Protects state with versioning and encryption.
- Supports recovery from accidental state changes.

Use case:

- `blacktickets-dev-tfstate` is prepared for Terraform remote state.

## Messaging and Notifications

### SQS

SQS is a message queue service.

How it helps:

- Decouples booking creation from notification processing.
- Allows retries if notification processing fails.
- Prevents notification failure from breaking booking success.

Use case:

- Booking service sends `BOOKING_CONFIRMED` messages to SQS.

### Lambda

Lambda runs code without managing servers.

How it helps:

- Processes SQS messages automatically.
- Scales with the number of messages.
- Avoids running a dedicated notification worker server.

Use case:

- The booking notification Lambda consumes SQS messages and publishes them to SNS.

### SNS

SNS is a publish/subscribe notification service.

How it helps:

- Sends messages to subscribers.
- Supports email notifications.
- Can later support SMS, HTTP endpoints, or fanout to multiple systems.

Use case:

- SNS sends booking confirmation notifications to an email subscriber.

## Security

### IAM

IAM controls permissions for AWS resources and services.

How it helps:

- Grants EC2 permission to pull ECR images and read secrets.
- Grants Lambda permission to read SQS and publish to SNS.
- Grants CloudTrail permission to write logs.

Use case:

- BlackTickets uses IAM roles and policies for EC2 app instances, Lambda, and CloudTrail.

### Security Groups

Security groups act like virtual firewalls.

How they help:

- Control which resources can talk to each other.
- Restrict public access to only the ALB.
- Keep RDS private.

Use case:

- Public ALB accepts internet traffic.
- EC2 app instances accept traffic from ALBs.
- RDS accepts PostgreSQL traffic only from app instances.

### Secrets Manager

Secrets Manager stores sensitive runtime values.

How it helps:

- Avoids hardcoding secrets in application containers.
- Centralizes DB passwords, JWT secrets, internal tokens, and seed credentials.

Use case:

- The EC2 user data reads runtime app configuration from Secrets Manager.

### WAF

AWS WAF protects web applications from common malicious requests.

How it helps:

- Blocks common exploit patterns.
- Blocks SQL injection attempts.
- Rate-limits abusive IPs.

Use case:

- The Web ACL is attached to the public ALB.
- It uses AWS managed common rules, SQLi rules, and a rate limit rule.
- `SizeRestrictions_BODY` is tuned to count instead of block, because it was blocking valid app requests.

## Monitoring and Operations

### CloudWatch Dashboard

A CloudWatch dashboard shows operational metrics in one view.

How it helps:

- Gives quick visibility into app health.
- Helps during demos, debugging, and operations.

Use case:

- `BlackTickets-Operations` shows ALB, ASG, EC2, RDS, Lambda, SQS, and CloudFront metrics.

### CloudWatch Alarms

CloudWatch alarms notify when metrics cross thresholds.

How they help:

- Detect issues early.
- Notify operators through SNS.
- Track failures, queue backlog, high CPU, and low database storage.

Use case:

- BlackTickets has alarms for ALB 5XX errors, EC2 CPU, RDS CPU, RDS storage, Lambda errors, and SQS queue depth.

### CloudWatch Logs

CloudWatch Logs stores logs from AWS services and applications.

How it helps:

- Enables log search and troubleshooting.
- Stores CloudTrail events for investigation.
- Stores Lambda logs.

Use case:

- CloudTrail sends events to `/aws/cloudtrail/blacktickets-dev`.
- Lambda writes execution logs to its Lambda log group.

## Auditing

### CloudTrail

CloudTrail records AWS API activity.

How it helps:

- Shows who changed what and when.
- Supports IAM auditing.
- Supports incident investigation.
- Captures S3 object-level events for the poster bucket.

Use case:

- BlackTickets records management read/write events.
- It captures S3 read/write data events for event posters.
- It writes logs to S3 and CloudWatch Logs.

## Terraform Operations

### Remote State

Remote state stores Terraform state in S3 instead of only on a local machine.

How it helps:

- Allows safe team collaboration.
- Protects state with versioning and encryption.
- Makes infrastructure reproducible across machines.

Use case:

- BlackTickets has an S3 bucket prepared for remote state.
- The backend block points Terraform state to S3.

### DynamoDB State Locking

DynamoDB locking prevents multiple Terraform operations from running at the same time.

How it helps:

- Prevents state corruption.
- Makes team workflows safer.

Use case:

- `blacktickets-dev-terraform-locks` provides Terraform state locking.

## Service Flow in BlackTickets

### User Traffic Flow

1. User opens the BlackTickets app.
2. Traffic reaches the public ALB.
3. WAF inspects incoming requests.
4. Public ALB forwards frontend traffic to the app instance.
5. Frontend proxies API traffic to the private ALB.
6. Private ALB routes requests to identity, event, booking, or chatbot services.
7. Backend services connect to RDS PostgreSQL.

### Booking Notification Flow

1. User books tickets.
2. Booking service creates a booking.
3. Booking service sends a message to SQS.
4. Lambda consumes the SQS message.
5. Lambda publishes to SNS.
6. SNS sends an email notification.

### Poster Upload Flow

1. Admin creates an event with a poster.
2. Event service uploads poster image to S3.
3. CloudFront serves the poster image to users.
4. CloudTrail audits S3 object activity.

### Monitoring Flow

1. AWS services emit metrics to CloudWatch.
2. Dashboard displays operational metrics.
3. Alarms watch for failure thresholds.
4. Alarm notifications go to SNS.
5. Operators receive email alerts.

## Current and Planned Services

Already implemented or prepared in Terraform:

- VPC, subnets, route tables, NAT, Internet Gateway
- VPC endpoints
- Public and private ALBs
- EC2 launch template
- Auto Scaling Group
- ECR
- RDS PostgreSQL
- S3 poster bucket
- CloudFront poster distribution
- SQS booking queue
- Lambda booking notification consumer
- SNS email notifications
- CloudWatch dashboard
- CloudWatch alarms
- AWS WAF
- CloudTrail
- Terraform remote state S3 bucket
- DynamoDB Terraform lock table

Mentioned as future roadmap:

- EventBridge
- Route 53 and ACM
- GitHub Actions CI/CD
- Blue/green deployment

## Why This Architecture Helps BlackTickets

This Terraform architecture helps BlackTickets become more production-ready by improving:

- Security: private networking, WAF, IAM, Secrets Manager, CloudTrail.
- Reliability: ALB health checks, ASG instance replacement, RDS, SQS retries.
- Observability: CloudWatch dashboard, alarms, logs, CloudTrail.
- Scalability: ALB, ASG, SQS, Lambda, CloudFront.
- Maintainability: infrastructure as code, remote state, reusable configuration.
- Auditability: CloudTrail management and S3 data events.

The result is a project that is easier to deploy, explain, monitor, troubleshoot, and extend.
