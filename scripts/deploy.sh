#!/usr/bin/env bash
# Two-phase deploy: ECR first, push image, then everything else.
set -euo pipefail
cd "$(dirname "$0")/../terraform"

terraform init
terraform apply -target=aws_ecr_repository.app -auto-approve

REPO=$(terraform output -raw ecr_repository_url)
REGION=$(terraform output -raw ecr_repository_url | cut -d. -f4)
docker logout "${REPO%%/*}" >/dev/null 2>&1 || true  # drop stale cached creds (cause of 403)
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "${REPO%%/*}"
docker build --platform linux/amd64 -t "$REPO:latest" ../app
docker push "$REPO:latest"

terraform apply -auto-approve
echo "App URL: $(terraform output -raw app_url)"
