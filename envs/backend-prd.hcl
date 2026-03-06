# Backend config para PRD
# Uso: terraform init -backend-config="envs/backend-prd.hcl"
bucket         = "llz-terraform-state"
key            = "moradores/prd/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "terraform-state-lock"
