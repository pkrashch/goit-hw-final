# Deployment and Configuration Guide

## Prerequisites
- AWS account and credentials configured (`aws configure` or SSO), with permissions to create VPC, ECS, ECR, RDS, ELB, IAM, CloudWatch, SNS, Budgets, Cost Explorer resources.
- Tools: Terraform >= 1.5, AWS CLI v2, Docker (buildx, able to build `linux/amd64`).
- One-time console step: enable **Cost Explorer** (Billing and Cost Management -> Cost Explorer -> Launch). It can take up to 24 h before data appears.

## Step 1: Configure variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# edit alert_email (required) and, optionally, monthly_budget_usd, region, etc.
```

Main variables:

| Variable | Default | Meaning |
|----------|---------|---------|
| `region` | `eu-central-1` | AWS region |
| `alert_email` | (required) | Receives SNS alarms and budget alerts |
| `monthly_budget_usd` | `50` | Monthly cost budget |
| `min_capacity` / `max_capacity` | `2` / `6` | Auto Scaling bounds |
| `cpu_target` | `50` | Target average CPU % |
| `db_instance_class` | `db.t4g.micro` | RDS size |
| `single_nat_gateway` | `true` | Cheaper single NAT vs one per AZ |
| `db_multi_az` | `false` | RDS Multi-AZ |

## Step 2: Deploy (automated)

```bash
./scripts/deploy.sh
```

The script runs in three phases, because the ECS service needs an image to exist in ECR first:
1. `terraform apply -target=aws_ecr_repository.app` creates the registry.
2. Builds the Docker image and pushes it to ECR.
3. `terraform apply` creates everything else (VPC, RDS, ALB, ECS, alarms, budgets). RDS creation takes ~5-10 minutes.

## Step 2 (alternative): Deploy manually

```bash
cd terraform
terraform init
terraform apply -target=aws_ecr_repository.app

REPO=$(terraform output -raw ecr_repository_url)
aws ecr get-login-password --region eu-central-1 \
  | docker login --username AWS --password-stdin "${REPO%%/*}"
docker build --platform linux/amd64 -t "$REPO:latest" ../app
docker push "$REPO:latest"

terraform apply
```

## Step 3: Confirm the SNS subscription
AWS sends a "Subscription Confirmation" e-mail to `alert_email`. **Click the confirm link**, otherwise no alarm e-mails are delivered. Budget e-mails do not need confirmation.

## Step 4: Verify

```bash
URL=$(terraform output -raw app_url)
curl "$URL/health"     # {"status":"ok"}
curl "$URL/"           # {"host":"...","message":"Hello from ECS Fargate","visits":1}
curl "$URL/"           # visits increments -> database works
```

Wait 1-2 minutes after apply for targets to become healthy (ALB -> Target Groups in the console).

## Updating the application

```bash
docker build --platform linux/amd64 -t "$REPO:latest" app && docker push "$REPO:latest"
aws ecs update-service --cluster goit-final-cluster --service goit-final-svc \
  --force-new-deployment --region eu-central-1
```
The deployment circuit breaker rolls back automatically if new tasks fail health checks.

## Cleanup (important to stop charges)

```bash
cd terraform
terraform destroy
```
The NAT Gateway (~$33/month), ALB (~$18/month) and RDS are the main fixed costs, so destroy the stack after the demo.

## Troubleshooting

| Symptom | Likely cause / fix |
|---------|--------------------|
| 503 from ALB | Tasks not healthy yet; check ECS service events and `/ecs/goit-final` log group |
| Task stops with `CannotPullContainerError` | Image not pushed, or wrong architecture (build with `--platform linux/amd64`) |
| Task fails reading secret | Check the execution role policy and NAT connectivity |
| `terraform apply` fails on Budgets/CE | Billing permissions missing for the IAM user, or Cost Explorer not enabled |
