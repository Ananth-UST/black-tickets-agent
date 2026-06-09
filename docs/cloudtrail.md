# CloudTrail

## What CloudTrail Records

CloudTrail records AWS API activity for the BlackTickets account. This includes who made a request, when it happened, which source IP was used, what service was called, and whether the request succeeded or failed.

The BlackTickets trail is multi-region and includes global service events, so IAM and other global-service activity is captured alongside regional AWS activity.

## Management Events

Management events record control-plane API calls, such as creating, updating, or deleting AWS resources.

Examples:

- Creating or modifying IAM roles and policies.
- Updating security groups.
- Changing load balancer, RDS, Lambda, or SQS configuration.
- Creating or deleting S3 buckets.

Both read and write management events are enabled.

## Data Events

Data events record data-plane activity for selected resources. BlackTickets enables S3 object data events for the existing poster bucket.

This captures read and write activity on objects in:

```text
aws_s3_bucket.posters
```

Examples:

- `GetObject` for poster reads.
- `PutObject` for poster uploads.
- Object-level access attempts that are denied.

## S3 Auditing

CloudTrail logs are delivered to:

```text
blacktickets-dev-cloudtrail-logs
```

The log bucket is private, blocks public access, uses server-side encryption, has versioning enabled, transitions logs to Standard-IA after 30 days, and expires logs after 365 days.

Poster bucket object activity is audited through S3 data events. Use this to investigate unexpected object reads, writes, or access denied events.

## IAM Auditing

Because global service events are enabled, IAM activity is captured.

Use CloudTrail to review:

- Role creation or deletion.
- Policy updates.
- Access key changes.
- Permission changes on the EC2 app role, Lambda role, or CloudTrail role.
- Suspicious `AssumeRole` activity.

## How To Search Events

In the AWS Console:

1. Open **CloudTrail**.
2. Go to **Event history**.
3. Filter by event name, username, resource name, access key, or source IP.
4. Open an event to inspect request parameters, response elements, and error codes.

In CloudWatch Logs:

1. Open **CloudWatch Logs**.
2. Open log group:

```text
/aws/cloudtrail/blacktickets-dev
```

3. Search for event names such as `PutObject`, `DeleteObject`, `AuthorizeSecurityGroupIngress`, `CreateRole`, or `PutRolePolicy`.

Example CloudWatch Logs Insights query:

```sql
fields @timestamp, eventSource, eventName, userIdentity.arn, sourceIPAddress, errorCode
| sort @timestamp desc
| limit 50
```

## How To Investigate Incidents

Start with the time window of the incident, then:

1. Search for failed or unusual API calls.
2. Filter by `sourceIPAddress` to identify suspicious origins.
3. Filter by `userIdentity.arn` to identify the IAM principal involved.
4. Check IAM events for permission changes before the incident.
5. Check S3 data events for unexpected poster object reads or writes.
6. Check security group and load balancer changes for accidental exposure.
7. Export relevant CloudTrail events and preserve them with the incident notes.

For access-related incidents, pay close attention to `AccessDenied`, `AssumeRole`, `PutRolePolicy`, `AttachRolePolicy`, `CreateAccessKey`, `PutObject`, and `DeleteObject` events.
