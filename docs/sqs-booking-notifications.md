# SQS Booking Notifications

## Architecture

Booking Service -> SQS

When a booking is successfully created, `booking-service` publishes a `BOOKING_CONFIRMED` message to the booking notifications SQS queue. The booking API still returns success if SQS publishing fails.

## Terraform Resources

- `aws_sqs_queue.booking_notifications`
  - Queue name: `blacktickets-dev-booking-notifications`
  - Long polling: `receive_wait_time_seconds = 20`
  - Visibility timeout: `30`
  - Message retention: `345600`
- `aws_iam_role_policy.ec2_booking_notifications_sqs`
  - Allows the EC2 app IAM role to call:
    - `sqs:SendMessage`
    - `sqs:GetQueueUrl`
    - `sqs:GetQueueAttributes`
  - Resource is limited to the booking notifications queue ARN.

## Environment Variable

`BOOKING_NOTIFICATION_QUEUE_URL` is stored in Secrets Manager and passed to the `booking-service` container by launch template user-data.

## Message Format

```json
{
  "eventType": "BOOKING_CONFIRMED",
  "bookingId": "<booking-id>",
  "userId": "<user-id>",
  "eventId": "<event-id>",
  "timestamp": "<iso8601>"
}
```

## Testing Steps

1. Apply Terraform and confirm `booking_notifications_queue_url` is output.
2. Create a booking through the application.
3. Check `booking-service` logs for `Published booking notification to SQS.`
4. In AWS SQS, poll the `blacktickets-dev-booking-notifications` queue.
5. Confirm the message body matches the expected JSON format.

## Troubleshooting

- If booking succeeds but no SQS message appears, check `BOOKING_NOTIFICATION_QUEUE_URL` inside the `booking-service` container.
- If logs show an SQS authorization error, verify the EC2 instance profile has the inline SQS policy.
- If logs show a region error, verify `AWS_REGION` is passed to `booking-service`.
- If the API fails before booking creation, troubleshoot the existing booking flow first: JWT, event reservation, and database connectivity.
