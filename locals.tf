locals {
  # Avaliação de booleanos e ambiente equivalente a "Conditions" do CFN
  is_prd             = var.environment == "prd"
  log_retention_days = local.is_prd ? 365 : 7

  enable_db_connection       = var.enable_aurora_db_connection
  enable_s3_bucket_uploads   = var.enable_s3_bucket_uploads
  enable_cognito_integration = var.enable_cognito_integration
  enable_pubsub              = var.enable_messaging_pubsub
  enable_historico           = var.enable_historico_integration
  include_secondary          = var.include_secondary_capacity_provider

  # Formatação Padrão de Nomenclatura baseada no CFN !Join
  family_name    = "${var.service_name}-${var.environment}-TaskDefinition"
  execution_role = "${var.service_name}-${var.environment}-ExecutionRole"
  task_role      = "${var.service_name}-${var.environment}-TaskRole"
  s3_role        = "${var.service_name}-${var.environment}-S3ECSUploadsRole"
  cognito_role   = "${var.service_name}-${var.environment}-CognitoECSRole"
  historico_role = "${var.service_name}-${var.environment}-HistoricoECSRole"
  asg_role       = "${var.service_name}-${var.environment}-ScalableTargetRole"

  # Para ARNs dinâmicos do container definitions, compondo paths usando a infraestrutura do Terraform local
  # O formato no cloudformation era: !Sub /${Environment}${SecretDatabaseUser}
  secret_db_user_path       = "/${var.environment}${var.secret_database_user}"
  secret_db_password_path   = "/${var.environment}${var.secret_database_password}"
  secret_db_endpoint_path   = "/${var.environment}${var.secret_database_endpoint}"
  secret_db_write_url_path  = "/${var.environment}${var.secret_database_write_endpoint}"
  secret_db_read_url_path   = "/${var.environment}${var.secret_database_read_endpoint}"
  secret_aes_key            = "/${var.environment}/operation/secret/aes/key"
}
