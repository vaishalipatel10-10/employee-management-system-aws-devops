# Troubleshooting Guide

Real issues encountered while building and deploying this project, and how each was resolved.

---

### 1. Docker build failed — `mysqlclient` couldn't find `pkg-config`

**Symptom:** `pip install mysqlclient` failed during the Docker build stage with `pkg-config: not found`.

**Cause:** The Dockerfile's builder stage installed `libpq-dev` (PostgreSQL headers) instead of MySQL development headers, since the base image was originally set up for Postgres.

**Fix:** Replaced `libpq-dev` with `build-essential`, `default-libmysqlclient-dev`, and `pkg-config` in the builder stage.

---

### 2. Container crashed at runtime — `libmariadb.so.3: cannot open shared object file`

**Symptom:** The app container built successfully but crashed immediately with this error in `docker compose logs`.

**Cause:** The production (runtime) stage of the Dockerfile only had the MySQL *client* installed, not the shared runtime library that the compiled `mysqlclient` Python package needs at runtime.

**Fix:** Added `libmariadb3` alongside `default-mysql-client` in the production stage's `apt-get install`.

---

### 3. RDS connection timeout (`OperationalError: (2002, "Can't connect to server...")`)

**Symptom:** `python manage.py migrate` against RDS failed with a connection timeout.

**Cause:** The local machine's public IP had changed (common on home/mobile networks), and the RDS security group only allowed the previous IP.

**Fix:** Re-checked the current IP (`curl https://checkip.amazonaws.com`) and added a fresh security group ingress rule for port 3306 from the new IP.

---

### 4. ECS task couldn't reach RDS after moving to a custom VPC

**Symptom:** After building the ECS Fargate service in a new custom VPC (Task 6), tasks couldn't reach RDS, which lived in the AWS account's default VPC.

**Cause:** RDS and ECS were in two separate, non-connected VPCs. Security groups alone can't bridge different VPCs.

**Fix:** Created a **VPC Peering connection** between the two VPCs, accepted it, added routes in both VPCs' route tables pointing to each other's CIDR ranges via the peering connection, and added RDS security group rules allowing the new VPC's private subnet CIDR blocks on port 3306.

---

### 5. GitHub Actions reported "failure" even though the ECS deployment actually succeeded

**Symptom:** The `Deploy to Amazon ECS` step in the CI/CD pipeline failed with: `Error: Deployment ecs-svc/... not found after stabilization. The deployment was likely rolled back by the deployment circuit breaker.` — but checking the AWS ECS console showed the deployment had a `Success` status.

**Cause:** A known reliability issue in `aws-actions/amazon-ecs-deploy-task-definition@v2`'s built-in `wait-for-service-stability` check — it can look up a deployment ID that has already rotated out by the time it checks, producing a false failure even when the actual deployment succeeded.

**Fix:** Set `wait-for-service-stability: false` on the deploy step, and added a separate step that runs `aws ecs wait services-stable` directly via the AWS CLI, which is a more reliable, native waiter.

---

### 6. GitHub push rejected with "repository not found"

**Symptom:** `git push` to a second remote failed with `remote: Repository not found.`

**Cause:** The target GitHub repository hadn't been created yet at the URL being pushed to.

**Fix:** Created the empty repository on GitHub first, then re-ran `git push --set-upstream origin <branch>`.

---

### 7. Work pushed to the wrong repository

**Symptom:** Commits weren't visible in the instructor's repository, even though `git push` succeeded.

**Cause:** All work had been pushed only to a personal fork/repo (`origin`), matching the assignment's original instruction to work in "your own GitHub repository" — but the instructor also expected visibility in the source repository.

**Fix:** Added the instructor's repository as a second remote (`upstream`) and pushed the same branch to both:
```bash
git remote add upstream <instructor-repo-url>
git push upstream feature/devops-setup
```
From that point on, every commit was pushed to both `origin` and `upstream`.