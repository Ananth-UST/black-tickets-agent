resource "aws_sqs_queue" "booking_notifications" {
  name                       = "blacktickets-dev-booking-notifications"
  receive_wait_time_seconds  = 20
  visibility_timeout_seconds = 30
  message_retention_seconds  = 345600

  tags = merge(local.common_tags, {
    Name = "blacktickets-dev-booking-notifications"
  })
}
