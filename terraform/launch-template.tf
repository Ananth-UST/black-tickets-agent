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
  ecr_registry = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

resource "aws_launch_template" "app" {
  name_prefix   = "${local.name_prefix}-app-"
  image_id      = data.aws_ami.ubuntu_2404.id
  instance_type = var.ec2_instance_type
  key_name      = var.ec2_key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_app.name
  }

  vpc_security_group_ids = [aws_security_group.ec2_app.id]

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
    APP_CONFIG_SECRET_ARN="${aws_secretsmanager_secret.app_config.arn}"

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
      -e POSTER_CDN_DOMAIN="${aws_cloudfront_distribution.posters.domain_name}" \
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

  depends_on = [aws_secretsmanager_secret_version.app_config]

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
