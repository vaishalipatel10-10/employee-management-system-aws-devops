# Infrastructure

This folder is intended for operational and deployment scaffolding that supports the project handover.

Use this area for:

- deployment manifests and placeholders
- environment-specific scaffolding
- operational documentation for future implementation
- future student work related to ECS, ECR, CloudWatch, S3, and CI/CD readiness

## VPC Resources Created (Task 6)

| Resource | Name | ID |
|---|---|---|
| VPC | ems-vpc | vpc-07b8ac004dad34612 |
| Public Subnet 1a | ems-public-subnet-1a | subnet-0eb340d94c2e02ccb |
| Public Subnet 1b | ems-public-subnet-1b | subnet-0a743d23d219b9c03 |
| Private Subnet 1a | ems-private-subnet-1a | subnet-058ff797110c56559 |
| Private Subnet 1b | ems-private-subnet-1b | subnet-059e63d0bccbc670a |
| Internet Gateway | ems-igw | igw-01ce60881a038ffc5 |
| NAT Gateway | ems-nat-gw | nat-0e115ac7053fff09b |
| ALB Security Group | ems-alb-sg | sg-05000db1ca593bd08 |
| ECS Security Group | ems-ecs-sg | sg-0afafb07ce1de7805 |
## ECS/ALB Resources Created (Task 8)

| Resource | ID/Name |
|---|---|
| ECS Cluster | ems-cluster |
| ECS Service | ems-service |
| Task Definition | ems-task:1 |
| Application Load Balancer | ems-alb |
| ALB DNS | ems-alb-428908553.ap-south-1.elb.amazonaws.com |
| Target Group | ems-tg |
| **Live URL** | http://ems-alb-428908553.ap-south-1.elb.amazonaws.com/hello/ |