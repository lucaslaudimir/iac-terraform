resource "aws_security_group" "container_sg" {
  name        = "${var.service_name}-${var.environment}-sg"
  description = "${var.service_name}-${var.environment}-ContainerSecurityGroup"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = var.container_port
    to_port         = var.container_port
    security_groups = [var.shared_load_balancer_sg]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "database_sg_ingress" {
  count                    = local.enable_db_connection ? 1 : 0
  description              = "Allow service ${var.service_name} inbound traffic"
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.container_sg.id
  security_group_id        = var.aurora_db_sg_id
}

resource "aws_lb_target_group" "target_group" {
  name                 = "${var.service_name}-tg-${var.environment}"
  port                 = var.container_port
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 60

  health_check {
    interval            = 60
    path                = var.health_check_path
    timeout             = 30
    unhealthy_threshold = 5
    healthy_threshold   = 3
    matcher             = "200,302"
  }
}

resource "aws_lb_listener_rule" "listener_rule" {
  listener_arn = var.listener_alb_arn
  priority     = var.rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }

  condition {
    path_pattern {
      values = ["${local.actual_path_pattern}*"]
    }
  }
}
