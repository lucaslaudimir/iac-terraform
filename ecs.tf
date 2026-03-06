resource "aws_cloudwatch_log_group" "task_definition" {
  name              = "/ecs/${var.service_name}-${var.environment}-TaskDefinition"
  retention_in_days = local.log_retention_days
}

resource "aws_cloudwatch_log_group" "service_connect" {
  name              = "/ecs/${var.service_name}-${var.environment}-ServiceConnect"
  retention_in_days = local.log_retention_days
}

resource "aws_cloudwatch_log_group" "aws_collector" {
  name              = "/ecs/${var.service_name}-${var.environment}-AWSCollector"
  retention_in_days = local.log_retention_days
}

resource "aws_ecs_task_definition" "task" {
  family                   = local.family_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.task_cpu)
  memory                   = tostring(var.task_memory)
  execution_role_arn       = aws_iam_role.execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name  = var.service_name
      image = var.image
      portMappings = [
        {
          containerPort = var.container_port
          name          = var.service_name
          protocol      = "tcp"
          appProtocol   = "http"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-create-group  = "true"
          awslogs-region        = data.aws_region.current.name
          awslogs-group         = aws_cloudwatch_log_group.task_definition.name
          awslogs-stream-prefix = "ecs"
        }
      }
      environment = [
        { name = "SPRING_PROFILES_ACTIVE", value = var.environment },
        { name = "ASSUME_ROLE_UPLOADS", value = local.enable_s3_bucket_uploads ? aws_iam_role.s3_ecs_uploads[0].arn : "" },
        { name = "ASSUME_ROLE_COGNITO", value = local.enable_cognito_integration ? aws_iam_role.cognito_ecs[0].arn : "" },
        { name = "ASSUME_ROLE_HISTORICO", value = local.enable_historico ? aws_iam_role.historico_ecs[0].arn : "" },
        { name = "OTEL_IMR_EXPORT_INTERVAL", value = "5000" },
        { name = "OTEL_RESOURCE_ATTRIBUTES", value = "service.name=${var.service_name},service.namespace=Operation,service.env=${var.environment}" },
        { name = "OTEL_EXPORTER_OTLP_ENDPOINT", value = "http://localhost:4317" }
      ]
      secrets = [
        { name = "DATABASE_USER", valueFrom = local.secret_db_user_path },
        { name = "DATABASE_PASSWORD", valueFrom = local.secret_db_password_path },
        { name = "DATABASE_ENDPOINT", valueFrom = local.secret_db_endpoint_path },
        { name = "DATABASE_WRITE_ENDPOINT", valueFrom = local.secret_db_write_url_path },
        { name = "DATABASE_READ_ENDPOINT", valueFrom = local.secret_db_read_url_path },
        { name = "SECRET_AES_KEY", valueFrom = local.secret_aes_key },
        { name = "SECRET_BTG", valueFrom = var.secret_btg },
        { name = "BTG_APOLICE_CLIENT_ID", valueFrom = "/config/btg/apolice/client_id" },
        { name = "BTG_APOLICE_CLIENT_SECRET", valueFrom = "/config/btg/apolice/client_secret" },
        { name = "BTG_APOLICE_X_API_KEY", valueFrom = "/config/btg/apolice/x_api_key" },
        { name = "SAP_USER", valueFrom = "/config/sap/user" },
        { name = "SAP_PASSWORD", valueFrom = "/config/sap/password" },
        { name = "SAP_CPI_USER", valueFrom = "/config/sap/cpi/user" },
        { name = "SAP_CPI_PASSWORD", valueFrom = "/config/sap/cpi/password" },
        { name = "SAP_STATUS_PAYMENT_USER", valueFrom = "/config/sap/status_payment/user" },
        { name = "SAP_STATUS_PAYMENT_PASSWORD", valueFrom = "/config/sap/status_payment/password" }
      ]
      dependsOn = [
        {
          condition     = "START"
          containerName = "ecs-cwagent"
        }
      ]
    },
    {
      name  = "ecs-cwagent"
      image = "public.ecr.aws/cloudwatch-agent/cloudwatch-agent:latest"
      portMappings = [
        { containerPort = 2000, protocol = "udp" },
        { containerPort = 4316, protocol = "tcp" },
        { containerPort = 4318, protocol = "tcp" }
      ]
      secrets = [
        { name = "CW_CONFIG_CONTENT", valueFrom = var.aot_config_parameter }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-create-group  = "true"
          awslogs-region        = data.aws_region.current.name
          awslogs-group         = aws_cloudwatch_log_group.aws_collector.name
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "service" {
  name                               = var.service_name
  cluster                            = data.aws_ssm_parameter.cluster_name.value
  task_definition                    = aws_ecs_task_definition.task.arn
  desired_count                      = var.min_capacity
  health_check_grace_period_seconds  = 30

  # Fargate strategy
  dynamic "capacity_provider_strategy" {
    for_each = [1]
    content {
      capacity_provider = var.primary_capacity_provider
      weight            = var.primary_capacity_provider_weight
      base              = var.primary_capacity_provider_base
    }
  }

  dynamic "capacity_provider_strategy" {
    for_each = local.include_secondary ? [1] : []
    content {
      capacity_provider = var.secondary_capacity_provider
      weight            = var.secondary_capacity_provider_weight
      base              = var.secondary_capacity_provider_base
    }
  }

  network_configuration {
    assign_public_ip = true
    subnets          = var.private_subnets
    security_groups  = [aws_security_group.container_sg.id, var.operation_sg_id]
  }

  service_connect_configuration {
    enabled = true
    service {
      port_name      = var.service_name
      discovery_name = var.service_name
      client_alias {
        dns_name = "${var.service_name}.internal"
        port     = var.container_port
      }
      timeout {
        per_request_timeout_seconds = var.per_request_timeout_seconds
      }
    }
    log_configuration {
      log_driver = "awslogs"
      options = {
        awslogs-create-group  = "true"
        awslogs-region        = data.aws_region.current.name
        awslogs-group         = aws_cloudwatch_log_group.service_connect.name
        awslogs-stream-prefix = "ecs"
      }
    }
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = var.service_name
    container_port   = var.container_port
  }

  # Necessário aguardar a listener rule antes de registrar os healthchecks
  depends_on = [
    aws_lb_listener_rule.listener_rule
  ]
}
