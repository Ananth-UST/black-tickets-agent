resource "aws_lb" "public" {
  name               = "${local.name_prefix}-public-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [module.security_groups.alb_security_group_id]
  subnets            = module.networking.public_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-alb"
  })
}

resource "aws_lb" "private" {
  name               = "${local.name_prefix}-private-alb"
  load_balancer_type = "application"
  internal           = true
  security_groups    = [module.security_groups.private_alb_security_group_id]
  subnets            = module.networking.private_app_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-alb"
  })
}

resource "aws_lb_target_group" "frontend" {
  name        = "${local.name_prefix}-frontend-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = module.networking.vpc_id

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
  vpc_id      = module.networking.vpc_id

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
  vpc_id      = module.networking.vpc_id

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
  vpc_id      = module.networking.vpc_id

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
  vpc_id      = module.networking.vpc_id

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
