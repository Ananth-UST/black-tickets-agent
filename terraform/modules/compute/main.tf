data "aws_caller_identity" "current" {}

data "aws_ami" "ubuntu_2404" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  name_prefix  = "${var.project_name}-${var.environment}"
  ecr_registry = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_lb" "public" {
  name               = "${local.name_prefix}-public-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-alb"
  })
}

resource "aws_lb" "private" {
  name               = "${local.name_prefix}-private-alb"
  load_balancer_type = "application"
  internal           = true
  security_groups    = [var.private_alb_security_group_id]
  subnets            = var.private_app_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-alb"
  })
}

resource "aws_lb_target_group" "frontend" {
  name        = "${local.name_prefix}-frontend-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-frontend-tg"
  })
}

resource "aws_lb_target_group" "identity" {
  name        = "${local.name_prefix}-identity-tg"
  port        = 4001
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-identity-tg"
  })
}

resource "aws_lb_target_group" "event" {
  name        = "${local.name_prefix}-event-tg"
  port        = 4002
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-event-tg"
  })
}

resource "aws_lb_target_group" "booking" {
  name        = "${local.name_prefix}-booking-tg"
  port        = 4003
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-booking-tg"
  })
}

resource "aws_lb_target_group" "chatbot" {
  name        = "${local.name_prefix}-chatbot-tg"
  port        = 4004
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-chatbot-tg"
  })
}

resource "aws_lb_listener" "public_http" {
  load_balancer_arn = aws_lb.public.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-http-listener"
  })
}

resource "aws_lb_listener" "private_http" {
  load_balancer_arn = aws_lb.private.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not found"
      status_code  = "404"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-http-listener"
  })
}

resource "aws_lb_listener_rule" "auth" {
  listener_arn = aws_lb_listener.private_http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.identity.arn
  }

  condition {
    path_pattern {
      values = ["/auth/*"]
    }
  }
}

resource "aws_lb_listener_rule" "users" {
  listener_arn = aws_lb_listener.private_http.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.identity.arn
  }

  condition {
    path_pattern {
      values = ["/users/*"]
    }
  }
}

resource "aws_lb_listener_rule" "events" {
  listener_arn = aws_lb_listener.private_http.arn
  priority     = 30

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.event.arn
  }

  condition {
    path_pattern {
      values = ["/events", "/events/*"]
    }
  }
}

resource "aws_lb_listener_rule" "bookings" {
  listener_arn = aws_lb_listener.private_http.arn
  priority     = 40

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.booking.arn
  }

  condition {
    path_pattern {
      values = ["/bookings", "/bookings/*"]
    }
  }
}

resource "aws_lb_listener_rule" "chatbot" {
  listener_arn = aws_lb_listener.private_http.arn
  priority     = 50

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.chatbot.arn
  }

  condition {
    path_pattern {
      values = ["/chatbot/*"]
    }
  }
}

resource "aws_launch_template" "app" {
  name_prefix   = "${local.name_prefix}-app-"
  image_id      = data.aws_ami.ubuntu_2404.id
  instance_type = var.ec2_instance_type
  key_name      = var.ec2_key_name

  iam_instance_profile {
    name = var.ec2_instance_profile_name
  }

  vpc_security_group_ids = [var.ec2_app_security_group_id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -euo pipefail
    exec > >(tee -a /var/log/blacktickets-user-data.log | logger -t blacktickets-user-data -s 2>/dev/console) 2>&1

    apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y docker.io python3 postgresql-client curl unzip
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
    unzip -q /tmp/awscliv2.zip -d /tmp
    /tmp/aws/install
    systemctl enable --now docker
    usermod -aG docker ubuntu

    AWS_REGION="${var.aws_region}"
    ECR_REGISTRY="${local.ecr_registry}"
    IMAGE_TAG="${var.ecr_image_tag}"
    APP_CONFIG_SECRET_ARN="${var.app_config_secret_arn}"

    SECRET_JSON="$(aws secretsmanager get-secret-value --region "$${AWS_REGION}" --secret-id "$${APP_CONFIG_SECRET_ARN}" --query SecretString --output text)"

    secret_value() {
      python3 -c 'import json, os, sys; print(json.loads(os.environ["SECRET_JSON"])[sys.argv[1]])' "$1"
    }

    export SECRET_JSON
    export DB_HOST="$(secret_value DB_HOST)"
    export DB_PORT="$(secret_value DB_PORT)"
    export DB_USER="$(secret_value DB_USER)"
    export DB_PASSWORD="$(secret_value DB_PASSWORD)"
    export JWT_SECRET="$(secret_value JWT_SECRET)"
    export INTERNAL_SERVICE_TOKEN="$(secret_value INTERNAL_SERVICE_TOKEN)"
    export BOOKING_NOTIFICATION_QUEUE_URL="$(secret_value BOOKING_NOTIFICATION_QUEUE_URL)"
    export ADMIN_EMAIL="$(secret_value ADMIN_EMAIL)"
    export ADMIN_PASSWORD="$(secret_value ADMIN_PASSWORD)"
    export USER_EMAIL="$(secret_value USER_EMAIL)"
    export USER_PASSWORD="$(secret_value USER_PASSWORD)"
    export PGPASSWORD="$${DB_PASSWORD}"

    until psql "host=$${DB_HOST} port=$${DB_PORT} user=$${DB_USER} dbname=postgres sslmode=require" -c "SELECT 1"; do
      sleep 10
    done

    for database in identity_db event_db booking_db; do
      if ! psql "host=$${DB_HOST} port=$${DB_PORT} user=$${DB_USER} dbname=postgres sslmode=require" -tAc "SELECT 1 FROM pg_database WHERE datname = '$${database}'" | grep -q 1; then
        psql "host=$${DB_HOST} port=$${DB_PORT} user=$${DB_USER} dbname=postgres sslmode=require" -c "CREATE DATABASE $${database}"
      fi
    done

    aws ecr get-login-password --region "$${AWS_REGION}" | docker login --username AWS --password-stdin "$${ECR_REGISTRY}"

    docker network create blacktickets || true

    docker pull "$${ECR_REGISTRY}/blacktickets-identity-service:$${IMAGE_TAG}"
    docker pull "$${ECR_REGISTRY}/blacktickets-event-service:$${IMAGE_TAG}"
    docker pull "$${ECR_REGISTRY}/blacktickets-booking-service:$${IMAGE_TAG}"
    docker pull "$${ECR_REGISTRY}/blacktickets-chatbot-service:$${IMAGE_TAG}"
    docker pull "$${ECR_REGISTRY}/blacktickets-frontend:$${IMAGE_TAG}"

    docker rm -f identity-service event-service booking-service chatbot-service blacktickets-frontend || true

    docker run -d --restart unless-stopped --name identity-service --network blacktickets -p 4001:4001 \
      -e DB_HOST="$${DB_HOST}" \
      -e DB_PORT="$${DB_PORT}" \
      -e DB_USER="$${DB_USER}" \
      -e DB_PASSWORD="$${DB_PASSWORD}" \
      -e DB_PASS="$${DB_PASSWORD}" \
      -e DB_NAME="identity_db" \
      -e DB_SSL="true" \
      -e JWT_SECRET="$${JWT_SECRET}" \
      -e INTERNAL_SERVICE_TOKEN="$${INTERNAL_SERVICE_TOKEN}" \
      -e ADMIN_EMAIL="$${ADMIN_EMAIL}" \
      -e ADMIN_PASSWORD="$${ADMIN_PASSWORD}" \
      -e USER_EMAIL="$${USER_EMAIL}" \
      -e USER_PASSWORD="$${USER_PASSWORD}" \
      "$${ECR_REGISTRY}/blacktickets-identity-service:$${IMAGE_TAG}"

    docker run -d --restart unless-stopped --name event-service --network blacktickets -p 4002:4002 \
      -e DB_HOST="$${DB_HOST}" \
      -e DB_PORT="$${DB_PORT}" \
      -e DB_USER="$${DB_USER}" \
      -e DB_PASSWORD="$${DB_PASSWORD}" \
      -e DB_PASS="$${DB_PASSWORD}" \
      -e DB_NAME="event_db" \
      -e DB_SSL="true" \
      -e JWT_SECRET="$${JWT_SECRET}" \
      -e INTERNAL_SERVICE_TOKEN="$${INTERNAL_SERVICE_TOKEN}" \
      -e AWS_REGION="$${AWS_REGION}" \
      -e POSTER_BUCKET_NAME="${var.poster_bucket_name}" \
      -e POSTER_CDN_DOMAIN="${var.poster_cdn_domain}" \
      "$${ECR_REGISTRY}/blacktickets-event-service:$${IMAGE_TAG}"

    docker run -d --restart unless-stopped --name booking-service --network blacktickets -p 4003:4003 \
      -e DB_HOST="$${DB_HOST}" \
      -e DB_PORT="$${DB_PORT}" \
      -e DB_USER="$${DB_USER}" \
      -e DB_PASSWORD="$${DB_PASSWORD}" \
      -e DB_PASS="$${DB_PASSWORD}" \
      -e DB_NAME="booking_db" \
      -e DB_SSL="true" \
      -e JWT_SECRET="$${JWT_SECRET}" \
      -e INTERNAL_SERVICE_TOKEN="$${INTERNAL_SERVICE_TOKEN}" \
      -e EVENT_SERVICE_URL="http://event-service:4002" \
      -e AWS_REGION="$${AWS_REGION}" \
      -e BOOKING_NOTIFICATION_QUEUE_URL="$${BOOKING_NOTIFICATION_QUEUE_URL}" \
      "$${ECR_REGISTRY}/blacktickets-booking-service:$${IMAGE_TAG}"

    docker run -d --restart unless-stopped --name chatbot-service --network blacktickets -p 4004:4004 \
      -e EVENT_SERVICE_URL="http://event-service:4002" \
      -e BOOKING_SERVICE_URL="http://booking-service:4003" \
      -e AWS_REGION="$${AWS_REGION}" \
      "$${ECR_REGISTRY}/blacktickets-chatbot-service:$${IMAGE_TAG}"

    docker run -d --restart unless-stopped --name blacktickets-frontend --network blacktickets -p 80:80 \
      -e PRIVATE_ALB_DNS="${aws_lb.private.dns_name}" \
      "$${ECR_REGISTRY}/blacktickets-frontend:$${IMAGE_TAG}"
  EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = merge(local.common_tags, {
      Name = "${local.name_prefix}-app"
    })
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(local.common_tags, {
      Name = "${local.name_prefix}-app-volume"
    })
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-app-lt"
  })
}

resource "aws_autoscaling_group" "app" {
  name                = "${local.name_prefix}-app-asg"
  min_size            = 1
  desired_capacity    = 1
  max_size            = 2
  vpc_zone_identifier = var.private_app_subnet_ids
  target_group_arns = [
    aws_lb_target_group.frontend.arn,
    aws_lb_target_group.identity.arn,
    aws_lb_target_group.event.arn,
    aws_lb_target_group.booking.arn,
    aws_lb_target_group.chatbot.arn
  ]
  health_check_type = "ELB"

  health_check_grace_period = 300
  enabled_metrics = [
    "GroupAndWarmPoolDesiredCapacity",
    "GroupAndWarmPoolTotalCapacity",
    "GroupDesiredCapacity",
    "GroupInServiceCapacity",
    "GroupInServiceInstances",
    "GroupMaxSize",
    "GroupMinSize",
    "GroupPendingCapacity",
    "GroupPendingInstances",
    "GroupStandbyCapacity",
    "GroupStandbyInstances",
    "GroupTerminatingCapacity",
    "GroupTerminatingInstances",
    "GroupTerminatingRetainedCapacity",
    "GroupTerminatingRetainedInstances",
    "GroupTotalCapacity",
    "GroupTotalInstances",
    "WarmPoolDesiredCapacity",
    "WarmPoolMinSize",
    "WarmPoolPendingCapacity",
    "WarmPoolPendingRetainedCapacity",
    "WarmPoolTerminatingCapacity",
    "WarmPoolTerminatingRetainedCapacity",
    "WarmPoolTotalCapacity",
    "WarmPoolWarmedCapacity"
  ]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-app-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = "terraform"
    propagate_at_launch = true
  }
}
