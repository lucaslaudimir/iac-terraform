data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Coletar dinamicamente o nome do cluster referenciado no environment via SSM
data "aws_ssm_parameter" "cluster_name" {
  name = "/${var.environment}${var.cluster_ssm_path}"
}

# Recuperar a VPC enviada como target para o SG
data "aws_vpc" "target" {
  id = var.vpc_id
}
