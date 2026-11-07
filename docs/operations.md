# Operations: Monitoring, Scaling, Load Testing, Cost

## Monitoring (CloudWatch)

- **Logs**: container stdout goes to log group `/ecs/goit-final` (14-day retention).
- **Container Insights** is enabled on the ECS cluster.
- **Dashboard** `goit-final-overview` (URL in Terraform output `dashboard_url`): ECS CPU/memory, ALB requests and 5xx, running task count, RDS CPU/connections.

### Alarms (all notify the SNS topic `goit-final-alerts`)

| Alarm | Condition |
|-------|-----------|
| `ecs-cpu-high` | CPU > 80% for 3 min |
| `ecs-memory-high` | Memory > 85% for 3 min |
| `alb-5xx` | > 5 target 5xx per minute, 2 periods |
| `alb-unhealthy-hosts` | any unhealthy target for 2 min |
| `alb-latency` | avg response time > 1 s for 3 min |
| `rds-cpu-high` | CPU > 80% for 10 min |
| `rds-low-storage` | free storage < 2 GiB |
| `rds-connections-high` | > 60 connections |

To test alerting, run the load test below (triggers `ecs-cpu-high`) and check the e-mail.

## Load balancing and Auto Scaling

- ALB health check: `GET /health` every 15 s on port 8080.
- Two **target tracking** policies on the ECS service (min 2, max 6 tasks):
  - average CPU 50%,
  - ALB requests per target 500.
- Scale-out cooldown 60 s, scale-in cooldown 120 s.
- Tasks are spread over two AZs.

## Load testing

```bash
./scripts/load_test.sh "$(terraform -chdir=terraform output -raw app_url)" 300 30
# or with hey:  hey -z 300s -c 30 $URL/load
```

`/load` is a CPU-bound endpoint. While it runs:
1. Watch CloudWatch dashboard: CPU rises above 50%.
2. ECS -> Cluster -> Service -> "Tasks" tab: task count grows from 2 toward 6 (takes a few minutes).
3. `ecs-cpu-high` alarm may fire and send an e-mail.
4. After the test, tasks scale back to 2 (about 15 minutes due to scale-in cooldown).

Check history with:
```bash
aws application-autoscaling describe-scaling-activities \
  --service-namespace ecs --region eu-central-1
```

## Cost optimization

Implemented in `cost.tf`:
- **AWS Budget** `goit-final-monthly`: default $50/month, e-mail at 50% actual, 80% actual, 100% forecasted.
- **Cost Anomaly Detection**: monitor per AWS service, daily e-mail when an anomaly impact is >= $5.

Design choices that reduce cost: Fargate Spot-free minimal task size (0.25 vCPU/512 MiB), `db.t4g.micro` (Graviton), single NAT, single-AZ RDS, 14-day log retention, ECR lifecycle policy, `terraform destroy` after demo.

### Analysis with Cost Explorer (console)
1. Billing and Cost Management -> Cost Explorer -> enable (first time only).
2. Group by **Service**, granularity Daily, filter by tag `Project = goit-final` (activate the tag under Cost allocation tags; all resources are tagged by the provider `default_tags`).
3. Identify the top services. Typically: **NAT Gateway / EC2-Other**, **Elastic Load Balancing**, **RDS**, **Fargate**.
4. Use Savings Plans / Compute Savings Plan recommendations if it runs long-term, and consider Fargate Spot for non-critical workloads.

### Evidence to attach
- Screenshot: browser showing the public URL response.
- Screenshot: CloudWatch dashboard during load test.
- Screenshot: ECS service with scaled-out task count and scaling activity.
- Screenshot / e-mail: SNS alarm notification.
- Screenshot: AWS Budgets page and Cost Explorer grouped by service.
- Screenshot: VPC resource map, security groups, IAM roles.
