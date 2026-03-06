# ============================================================
# Variáveis de ambiente: PRD
# Diferenças chave: FARGATE puro (sem SPOT), mais capacidade,
# retention de logs maior (já controlado pelo locals.tf is_prd)
# ============================================================

aws_region   = "us-east-1"
environment  = "prd"
service_name = "moradores"

# --- Rede ----------------------------------------------------
vpc_id          = "vpc-CHANGE_ME_PRD"
private_subnets = ["subnet-CHANGE_ME_PRD_A", "subnet-CHANGE_ME_PRD_B"]

# --- Imagem --------------------------------------------------
image = "444301769287.dkr.ecr.us-east-1.amazonaws.com/moradores:latest"

# --- Task resources ------------------------------------------
task_cpu    = 512
task_memory = 1024

# --- Capacity Providers: PRD usa FARGATE puro ----------------
primary_capacity_provider        = "FARGATE"
primary_capacity_provider_weight = 1
primary_capacity_provider_base   = 1

include_secondary_capacity_provider = false
secondary_capacity_provider        = "FARGATE"
secondary_capacity_provider_weight = 0
secondary_capacity_provider_base   = 0

# --- Banco de Dados ------------------------------------------
enable_aurora_db_connection    = true
aurora_db_sg_id                = "sg-CHANGE_ME_PRD_DB"

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
shared_load_balancer_sg = "sg-0f439a9e0ffab6b6"
listener_alb_arn        = "arn:aws:elasticloadbalancing:us-east-1:756241603306:listener/app/alb-prd/b470f2ec411e724e/8a8bc3aa4c0330e3"
path_pattern            = "/api/moradores"
rule_priority           = 10
container_port          = 8080

# --- AutoScaling: PRD tem capacidade maior -------------------
min_capacity                 = 2
max_capacity                 = 10
autoscaling_cpu_target_value = 75

# --- SSM / Observabilidade -----------------------------------
cluster_ssm_path      = "/ecs/cluster/name"
aot_config_parameter  = "/aot/config"
secret_btg            = "/config/secret_btg"

per_request_timeout_seconds = 30
