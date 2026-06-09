resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Allow public HTTP and HTTPS traffic to the public ALB."
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from allowed CIDRs"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.alb_ingress_cidrs
  }

  ingress {
    description = "HTTPS from allowed CIDRs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.alb_ingress_cidrs
  }

  egress {
    description = "Outbound to app targets"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb-sg"
  })
}

resource "aws_security_group" "private_alb" {
  name        = "${local.name_prefix}-private-alb-sg"
  description = "Allow HTTP from app instances to the private ALB."
  vpc_id      = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-alb-sg"
  })
}

resource "aws_security_group" "ec2_app" {
  name        = "${local.name_prefix}-ec2-app-sg"
  description = "Allow ALB traffic to EC2 application instances."
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "App traffic from ALB"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Outbound application traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ec2-app-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "private_alb_http_from_ec2_app" {
  security_group_id            = aws_security_group.private_alb.id
  referenced_security_group_id = aws_security_group.ec2_app.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  description                  = "HTTP from app instances"
}

resource "aws_vpc_security_group_egress_rule" "private_alb_backend_to_ec2_app" {
  security_group_id            = aws_security_group.private_alb.id
  referenced_security_group_id = aws_security_group.ec2_app.id
  ip_protocol                  = "tcp"
  from_port                    = 4001
  to_port                      = 4004
  description                  = "Backend service traffic to app instances"
}

resource "aws_vpc_security_group_ingress_rule" "ec2_app_backend_from_private_alb" {
  security_group_id            = aws_security_group.ec2_app.id
  referenced_security_group_id = aws_security_group.private_alb.id
  ip_protocol                  = "tcp"
  from_port                    = 4001
  to_port                      = 4004
  description                  = "Backend service traffic from private ALB"
}

resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-rds-sg"
  description = "Allow PostgreSQL traffic from EC2 application instances."
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from app instances"
    from_port       = var.rds_port
    to_port         = var.rds_port
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_app.id]
  }

  egress {
    description = "Outbound database traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-rds-sg"
  })
}
