resource "aws_sns_topic" "booking_notifications" {
  name = "blacktickets-dev-booking-notifications"

  tags = merge(local.common_tags, {
    Name = "blacktickets-dev-booking-notifications"
  })
}

resource "aws_sns_topic_subscription" "booking_notifications_email" {
  topic_arn = aws_sns_topic.booking_notifications.arn
  protocol  = "email"
  endpoint  = var.notification_email
}
