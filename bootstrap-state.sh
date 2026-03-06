#!/usr/bin/env bash
# ============================================================
# bootstrap-state.sh
# Cria o bucket S3 e a tabela DynamoDB necessários para o
# backend remoto do Terraform (execute UMA vez por conta AWS)
# ============================================================
set -euo pipefail

BUCKET_NAME="llz-terraform-state"
REGION="us-east-1"
DYNAMO_TABLE="terraform-state-lock"

echo "🪣  Criando bucket S3: $BUCKET_NAME"
aws s3api create-bucket \
  --bucket "$BUCKET_NAME" \
  --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION" 2>/dev/null || true

echo "🔒  Habilitando versionamento no bucket"
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled

echo "🔐  Habilitando criptografia SSE-S3"
aws s3api put-bucket-encryption \
  --bucket "$BUCKET_NAME" \
  --server-side-encryption-configuration '{
    "Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]
  }'

echo "🚫  Bloqueando acesso público ao bucket"
aws s3api put-public-access-block \
  --bucket "$BUCKET_NAME" \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo "🗄️   Criando tabela DynamoDB para state lock: $DYNAMO_TABLE"
aws dynamodb create-table \
  --table-name "$DYNAMO_TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION" 2>/dev/null || true

echo ""
echo "✅  Bootstrap concluído!"
echo "   Bucket  : s3://$BUCKET_NAME"
echo "   DynamoDB: $DYNAMO_TABLE"
echo ""
echo "Próximo passo: configure os Secrets no GitHub (Settings > Environments)"
echo "  AWS_ROLE_ARN = arn:aws:iam::ACCOUNT_ID:role/github-actions-terraform-role"
