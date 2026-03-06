# Backend config para UAT
# Uso: terraform init -backend-config="envs/backend-uat.hcl"
bucket         = "llz-terraform-state"
key            = "moradores/uat/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "terraform-state-lock"
