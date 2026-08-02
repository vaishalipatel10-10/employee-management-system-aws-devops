# Deployment Guide

This document lists every AWS resource created for this project, in the order they were provisioned, along with their purpose. Region used throughout: **ap-south-1 (Mumbai)**.

---

## 1. Networking (VPC)

| Resource | Name | ID |
|---|---|---|
| VPC | ems-vpc | vpc-07b8ac004dad34612 |
| Public Subnet 1a | ems-public-subnet-1a | subnet-0eb340d94c2e02ccb |
| Public Subnet 1b | ems-public-subnet-1b | subnet-0a743d23d219b9c03 |
| Private Subnet 1a | ems-private-subnet-1a | subnet-058ff797110c56559 |
| Private Subnet 1b | ems-private-subnet-1b | subnet-059e63d0bccbc670a |
| Internet Gateway | ems-igw | igw-01ce60881a038ffc5 |
| NAT Gateway | ems-nat-gw | nat-0e115ac7053fff09b |
| Public Route Table | ems-public-rt | rtb-033f48e42ca1265f9 |
| Private Route Table | ems-private-rt | rtb-0267fa27f0b13bce5 |

**Design:** Public subnets host the ALB and route out via the Internet Gateway. Private subnets host the ECS tasks and route outbound traffic (for pulling images, etc.) via the NAT Gateway, with no inbound internet access.

---

## 2. Security Groups

| Security Group | Name | Allows |
|---|---|---|
| ALB SG | ems-alb-sg | Inbound 80 from `0.0.0.0/0` |
| ECS SG | ems-ecs-sg | Inbound 8000 from ALB SG only |
| RDS SG (default VPC) | ems-rds-sg | Inbound 3306 from ECS private subnet CIDRs (via VPC peering) |

This enforces a strict layered access model: only the ALB is internet-facing; the application and database tiers are only reachable from the layer directly above them.

---

## 3. Database (Amazon RDS)

- **Engine:** MySQL 8.0.46
- **Instance:** `ems-mysql-db`, `db.t3.micro`, Free Tier
- **Location:** Default VPC (`vpc-0cb1723e566a22a75`), connected to the custom VPC via **VPC Peering** (`pcx-0c485f87379266e55`)
- **Credentials:** Stored in AWS Secrets Manager (`ems/db-credentials`), referenced by the ECS task definition — never hardcoded
- Migrations applied via Django (`python manage.py migrate`) from a local machine connected through the RDS security group

---

## 4. Container Registry (Amazon ECR)

- Repository: `ems-app`
- Image scanning on push: enabled
- Images tagged both `latest` and with the Git commit SHA on every CI/CD run

---

## 5. Compute (Amazon ECS Fargate)

- **Cluster:** `ems-cluster`
- **Service:** `ems-service` (desired count: 1, Fargate launch type, private subnets, no public IP)
- **Task Definition:** `ems-task` — 512 CPU units, 1024 MB memory, container port 8000
- **IAM Role:** `ems-ecs-task-execution-role` with `AmazonECSTaskExecutionRolePolicy` and `SecretsManagerReadWrite` attached
- **Logging:** CloudWatch Logs group `/ecs/ems-task`

---

## 6. Load Balancing

- **Application Load Balancer:** `ems-alb`, internet-facing, spans both public subnets
- **Target Group:** `ems-tg`, target type `ip`, health check path `/hello/`
- **Listener:** port 80 → forwards to `ems-tg`
- **Live URL:** http://ems-alb-428908553.ap-south-1.elb.amazonaws.com/hello/

---

## 7. CI/CD (GitHub Actions)

Workflow file: `.github/workflows/ci.yml`

Triggered on push to `main` or `feature/devops-setup`. Steps:
1. Checkout → Setup Python → Install dependencies
2. Configure AWS credentials (via repository secrets `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`)
3. Login to ECR → Build Docker image → Push to ECR
4. Render new ECS task definition with the freshly pushed image
5. Deploy to ECS
6. Wait for the service to stabilize (via `aws ecs wait services-stable`, run as a separate step for reliability)

A dedicated IAM user (`github-actions-ems`) with a least-privilege inline policy (ECR push, ECS deploy, and `iam:PassRole` scoped to the task execution role only) is used for the pipeline — not a personal admin account.

---

## 8. Monitoring

- **CloudWatch Dashboard:** `ems-dashboard` — ECS CPU and memory utilization widgets
- **CloudWatch Alarm:** `ems-high-cpu` — triggers when average CPU > 75% over two 5-minute periods
- **SNS Topic:** `ems-alerts` — email subscription confirmed, alarm notifications routed here

---

## 9. Secrets & Security

- **AWS Secrets Manager secret:** `ems/db-credentials` — contains `DB_USER` and `DB_PASSWORD`
- Task definition references these via the `secrets` block, not the `environment` block
- `.env`, `db-secret.json`, and other credential files are excluded from version control via `.gitignore`