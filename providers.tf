terraform {
  required_version = ">= 1.0.0"

  # O backend é configurado dinamicamente via arquivo HCL externo:
  #   terraform init -backend-config="envs/backend-<env>.hcl"
  # Isso permite um state isolado por ambiente sem alterar código.
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Service     = var.service_name
      ManagedBy   = "Terraform"
    }
  }
}

