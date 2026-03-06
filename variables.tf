variable "aws_region" {
  description = "Região AWS de deploy"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "ID da VPC alvo para o ECS Service"
  type        = string
}

variable "private_subnets" {
  description = "Lista de IDs das subnets privadas para o deploy do serviço"
  type        = list(string)
}

variable "environment" {
  description = "Environment to define Java profile in SPRING_PROFILES_ACTIVE"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "uat", "hml", "prd"], var.environment)
    error_message = "Valid values for environment are: dev, uat, hml, prd."
  }
}

variable "cluster_ssm_path" {
  description = "SSM Parameter to config ECS cluster"
  type        = string
  default     = "/ecs/cluster/name"
}

variable "image" {
  description = "Docker image repository-url/image:tag"
  type        = string
  default     = "444301769287.dkr.ecr.us-east-1.amazonaws.com/teste"
}

variable "task_cpu" {
  description = "How much CPU to give the ECS task, in CPU units or vCPUs"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "How much memory to give the ECS task in megabytes"
  type        = number
  default     = 512
}

variable "service_name" {
  description = "The name of the ECS service"
  type        = string
  default     = "MyService"
  validation {
    condition     = length(var.service_name) <= 25
    error_message = "ServiceName must be 25 characters or less."
  }
}

variable "container_port" {
  description = "Porta do Container"
  type        = number
  default     = 8080
}

# Toggles (Conditions from CFN)
variable "enable_s3_bucket_uploads" {
  description = "Habilitar roles de acesso ao S3 uploads"
  type        = bool
  default     = false
}

variable "enable_cognito_integration" {
  description = "Habilitar integrações com Cognito"
  type        = bool
  default     = false
}

variable "enable_messaging_pubsub" {
  description = "Habilitar acesso a filas SQS e topicos SNS"
  type        = bool
  default     = false
}

variable "enable_aurora_db_connection" {
  description = "Habilitar conexão com Aurora DB e SGs de Ingress associados"
  type        = bool
  default     = false
}

variable "enable_historico_integration" {
  description = "Habilitar acesso a recursos de historico (Dynamo, SQS, SNS)"
  type        = bool
  default     = false
}

# Variáveis Específicas
variable "s3_bucket_uploads" {
  description = "Nome do bucket S3 onde serão feitos uploads"
  type        = string
  default     = "llz-uploads"
}

variable "operation_sg_id" {
  description = "Security Group ID associated with Operation microservices"
  type        = string
}

variable "aot_config_parameter" {
  description = "SSM Parameter to config AWS Open Telemetry to monitoring service"
  type        = string
  default     = "/aot/config"
}

variable "secret_btg" {
  description = "Secret parameter to access BTG services"
  type        = string
  default     = "/config/secret_btg"
}

variable "aurora_db_sg_id" {
  description = "Security Group ID associated with Aurora database"
  type        = string
  default     = ""
}

variable "secret_database_user" {
  description = "SSM Secret parameter format of database user"
  type        = string
  default     = "/operation/db/user"
}

variable "secret_database_password" {
  description = "SSM Secret parameter format of database password"
  type        = string
  default     = "/operation/db/password"
}

variable "secret_database_endpoint" {
  description = "SSM Secret parameter format of database endpoint"
  type        = string
  default     = "/operation/db/endpoint"
}

variable "secret_database_write_endpoint" {
  description = "SSM Secret parameter format of database write endpoint"
  type        = string
  default     = "/operation/db/write-endpoint"
}

variable "secret_database_read_endpoint" {
  description = "SSM Secret parameter format of database read endpoint"
  type        = string
  default     = "/operation/db/read-endpoint"
}

# ALB Variables
variable "health_check_path" {
  description = "Health Check Path para o ALB"
  type        = string
  default     = "/healthcheck"
}

variable "shared_load_balancer_sg" {
  description = "Security Group ID of the shared Load Balancer"
  type        = string
  default     = "sg-0465721464b077e4b"
}

variable "listener_alb_arn" {
  description = "ARN of the existing HTTP Listener on the shared Load Balancer"
  type        = string
  default     = "arn:aws:elasticloadbalancing:us-east-1:756241603306:listener/app/alb-prd/b470f2ec411e724e/8a8bc3aa4c0330e3"
}

variable "path_pattern" {
  description = "Path pattern to match in listener rule"
  type        = string
  default     = "/api/{pluralServiceName}"
}

variable "rule_priority" {
  description = "Priority for the Listener Rule"
  type        = number
  default     = 1
}

# AutoScaling
variable "min_capacity" {
  description = "AutoScaling Min Capacity"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "AutoScaling Max Capacity"
  type        = number
  default     = 2
}

variable "autoscaling_cpu_target_value" {
  description = "AutoScaling CPU Target Value %"
  type        = number
  default     = 75
}

# Capacity Providers
variable "primary_capacity_provider" {
  description = "Primary ECS Capacity Provider"
  type        = string
  default     = "FARGATE_SPOT"
}

variable "primary_capacity_provider_weight" {
  type    = number
  default = 1
}

variable "primary_capacity_provider_base" {
  type    = number
  default = 1
}

variable "include_secondary_capacity_provider" {
  type    = bool
  default = true
}

variable "secondary_capacity_provider" {
  type    = string
  default = "FARGATE"
}

variable "secondary_capacity_provider_weight" {
  type    = number
  default = 0
}

variable "secondary_capacity_provider_base" {
  type    = number
  default = 0
}

variable "per_request_timeout_seconds" {
  description = "Timeout by request in Service Connect clients"
  type        = number
  default     = 30
}
