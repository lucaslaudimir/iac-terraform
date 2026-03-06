# Backend config para HML
# Uso: terraform init -backend-config="envs/backend-hml.hcl"
bucket         = "llz-terraform-state"
key            = "moradores/hml/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "terraform-state-lock"
