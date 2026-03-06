terraform {
  required_version = ">= 1.0.0"

  backend "s3" {
    # TO DO: Ajustar os valores com as informações reais da conta (Bucket, Lock Table, etc)
    bucket         = "meu-bucket-terraform-state"
    key            = "ecs-service/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }

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
