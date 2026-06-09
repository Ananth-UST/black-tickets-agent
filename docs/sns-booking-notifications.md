# SNS Booking Notifications

## Architecture

Booking Service -> SQS -> Lambda -> SNS -> Email

When a booking is successfully created, `booking-service` publishes a `BOOKING_CONFIRMED` message to SQS. The Lambda consumer reads messages from the existing SQS queue and publishes valid booking notification payloads to an SNS topic. SNS then sends the notification to the configured email subscriber.

## Terraform Resources

- `aws_sqs_queue.booking_notifications`
  - Existing queue; not recreated by this change.
- `aws_lambda_function.booking_notification_consumer`
  - Runtime: `nodejs20.x`
  - Environment variable: `SNS_TOPIC_ARN`
- `aws_lambda_event_source_mapping.booking_notification_consumer`
  - Connects the existing SQS queue to the Lambda consumer.
- `aws_sns_topic.booking_notifications`
  - Topic name: `blacktickets-dev-booking-notifications`
- `aws_sns_topic_subscription.booking_notifications_email`
  - Email endpoint from `var.notification_email`.
- `aws_iam_role_policy.booking_notification_consumer`
  - Allows SQS reads only from the booking notifications queue.
  - Allows `sns:Publish` only to the booking notifications SNS topic.
  - Allows CloudWatch log writes for the Lambda log group.

Terraform output:

```text
booking_notifications_sns_topic_arn
```

## Email Subscription Confirmation

After `terraform apply`, AWS SNS sends a confirmation email to `notification_email`.

Open that email and click **Confirm subscription**. Email delivery will not start until the subscription is confirmed.

If the email does not arrive, check spam/junk folders and verify that `notification_email` is correct.

## Testing Steps

1. Set `notification_email` in Terraform input variables.
2. Run `terraform apply`.
3. Confirm the SNS email subscription from the email inbox.
4. Create a booking through the BlackTickets application.
5. Confirm `booking-service` logs show the SQS publish.
6. Confirm Lambda logs show `Published booking notification to SNS.`
7. Confirm the email arrives with:
   - `eventType`
   - `bookingId`
   - `userId`
   - `eventId`
   - `timestamp`

## Troubleshooting

- No confirmation email: verify `notification_email`, check spam, and inspect the SNS subscription status.
- Booking succeeds but Lambda does not run: verify the Lambda event source mapping is enabled and the SQS queue has messages.
- Lambda fails with SNS authorization errors: verify its IAM policy allows `sns:Publish` to `booking_notifications_sns_topic_arn`.
- Lambda fails with missing topic ARN: verify `SNS_TOPIC_ARN` is present in the Lambda environment.
- Email not received after Lambda success: confirm the SNS subscription status is `Confirmed`.
- Repeated Lambda failures: inspect CloudWatch Logs; failed batches remain in SQS and are retried according to SQS/Lambda retry behavior.
