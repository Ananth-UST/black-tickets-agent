resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = aws_subnet.private_db[*].id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-db-subnet-group"
  })
}

resource "aws_db_instance" "postgres" {
  identifier             = "${local.name_prefix}-postgres"
  engine                 = "postgres"
  engine_version         = "16"
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  port                   = var.rds_port
  multi_az               = false
  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = true
  deletion_protection    = false

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-postgres"
  })
}

resource "aws_secretsmanager_secret" "app_config" {
  name        = "${local.name_prefix}/app-config"
  description = "Runtime configuration for BlackTickets application services."

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-app-config-secret"
  })
}

resource "aws_secretsmanager_secret_version" "app_config" {
  secret_id = aws_secretsmanager_secret.app_config.id

  secret_string = jsonencode({
    DB_HOST                        = aws_db_instance.postgres.address
    DB_PORT                        = tostring(var.rds_port)
    DB_USER                        = var.db_username
    DB_PASSWORD                    = var.db_password
    JWT_SECRET                     = var.jwt_secret
    INTERNAL_SERVICE_TOKEN         = var.internal_service_token
    BOOKING_NOTIFICATION_QUEUE_URL = aws_sqs_queue.booking_notifications.url
    ADMIN_EMAIL                    = var.admin_email
    ADMIN_PASSWORD                 = var.admin_password
    USER_EMAIL                     = var.user_email
    USER_PASSWORD                  = var.user_password
  })
}
