# ============================================================
# Variáveis de ambiente: UAT
# ============================================================

aws_region   = "us-east-1"
environment  = "uat"
service_name = "moradores"

# --- Rede ----------------------------------------------------
vpc_id          = "vpc-CHANGE_ME_UAT"
private_subnets = ["subnet-CHANGE_ME_UAT_A", "subnet-CHANGE_ME_UAT_B"]

# --- Imagem --------------------------------------------------
image = "444301769287.dkr.ecr.us-east-1.amazonaws.com/moradores:latest"

# --- Task resources ------------------------------------------
task_cpu    = 256
task_memory = 512

# --- Capacity Providers --------------------------------------
primary_capacity_provider        = "FARGATE"
primary_capacity_provider_weight = 0
primary_capacity_provider_base   = 1

include_secondary_capacity_provider = true
secondary_capacity_provider        = "FARGATE_SPOT"
secondary_capacity_provider_weight = 1
secondary_capacity_provider_base   = 0

# --- Banco de Dados ------------------------------------------
enable_aurora_db_connection    = true
aurora_db_sg_id                = "sg-CHANGE_ME_UAT_DB"

secret_database_user           = "/operation/db/user"
secret_database_password       = "/operation/db/password"
secret_database_endpoint       = "/operation/db/endpoint"
secret_database_write_endpoint = "/operation/db/write-endpoint"
secret_database_read_endpoint  = "/operation/db/read-endpoint"

# --- Integrações opcionais -----------------------------------
enable_s3_bucket_uploads     = false
enable_cognito_integration   = false
enable_messaging_pubsub      = false
enable_historico_integration = true

# --- ALB / Listener -----------------------------------------
health_check_path       = "/healthcheck"
shared_load_balancer_sg = "sg-CHANGE_ME_UAT_ALB"
listener_alb_arn        = "arn:aws:elasticloadbalancing:us-east-1:ACCOUNT:listener/app/alb-uat/CHANGE_ME"
path_pattern            = "/api/moradores"
rule_priority           = 10
container_port          = 8080

# --- AutoScaling ---------------------------------------------
min_capacity                 = 1
max_capacity                 = 2
autoscaling_cpu_target_value = 75

# --- SSM / Observabilidade -----------------------------------
cluster_ssm_path      = "/ecs/cluster/name"
aot_config_parameter  = "/aot/config"
secret_btg            = "/config/secret_btg"

per_request_timeout_seconds = 30
