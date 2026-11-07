# GoIT Final Project: Web App on AWS (ECS Fargate + RDS PostgreSQL)

Documentation index:

1. [Environment description and technology justification](architecture.md)
2. [Architecture diagram](architecture.md#architecture-diagram)
3. [Deployment and configuration guide](deployment.md)
4. [Monitoring, scaling, load testing and cost control](operations.md)
5. [Acceptance criteria checklist](#acceptance-criteria-mapping)

## Repository layout

| Path | Purpose |
|------|---------|
| `app/` | Flask demo app (visit counter in PostgreSQL), Dockerfile |
| `terraform/` | All AWS infrastructure as code |
| `scripts/deploy.sh` | Two-phase deploy (ECR, image push, full apply) |
| `scripts/load_test.sh` | Load generator for Auto Scaling demo |
| `docs/` | This documentation |

## Acceptance criteria mapping

| Criterion | Where it is satisfied |
|-----------|-----------------------|
| AWS environment with justified architecture | `terraform/*.tf`, [architecture.md](architecture.md) |
| Security via VPC, IAM, Security Groups | `network.tf`, `security.tf`, `iam.tf` |
| Database per requirements | `rds.tf` (RDS PostgreSQL, password in Secrets Manager) |
| App reachable at public URL | ALB DNS, Terraform output `app_url` |
| CloudWatch monitoring and alerts | `monitoring.tf` (alarms, dashboard, SNS topic) |
| Auto Scaling and load balancing | `alb.tf`, `ecs.tf` (target tracking policies) |
| Cost optimization (Cost Explorer / Budgets) | `cost.tf`, [operations.md](operations.md#cost-optimization) |
| Description of architecture and technology choices | [architecture.md](architecture.md) |

> The submission file `ФП_ПІБ.txt` should be assembled from `architecture.md` and `deployment.md`
> (sections: environment, justification, diagram, deployment instructions) plus the public URL
> and screenshots described in [operations.md](operations.md#evidence-to-attach).
