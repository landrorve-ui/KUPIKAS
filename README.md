# Zupikas

NestJS monorepo with three services — **backend** (port 3333), **queue-job** (port 3334), **trigger-job** (port 3335) — deployed to AWS EKS via GitHub Actions.

---

## Architecture overview

```
GitHub Actions
      │
      ├── Build Docker images ──► ECR (4 repos)
      │
      ├── Run DB migration ──────► EKS Job ──► AuroraDB (outside cluster)
      │
      └── Deploy services ───────► EKS (private subnets)
                                        │
                                   ┌────┴────────────────────┐
                                   │  ALB (internet-facing)  │
                                   └────┬────────────────────┘
                                        │
                          ┌─────────────┼──────────────┐
                          ▼             ▼              ▼
                      backend       queue-job     trigger-job
                    (HPA 2-10)     (HPA 2-10)    (HPA 2-10)
```

**Infrastructure (Terraform):**
- VPC with public + private subnets across 2 AZs
- EKS cluster — nodes run in private subnets only
- NAT Gateways for outbound internet from private subnets
- ECR repositories for each image
- AWS Load Balancer Controller + External Secrets Operator installed via Helm

---

## Prerequisites

| Tool | Version |
|------|---------|
| AWS CLI | v2 |
| Terraform | >= 1.5 |
| kubectl | >= 1.28 |
| Helm | >= 3 |
| Docker | >= 24 |
| Node.js | 22 |

AWS account requirements:
- IAM role with OIDC trust for GitHub Actions (`AWS_ROLE_TO_ASSUME_DEV` secret)
- S3 bucket `zupikas-terraform-state` + DynamoDB table `zupikas-terraform-locks` for Terraform state

---

## First-time infrastructure setup

Steps 2–5 are fully automated via the **Infrastructure Bootstrap** workflow
(`.github/workflows/infra-bootstrap.yml`). Only step 1 (creating the GitHub
secrets/variables themselves) must be done manually — it is the bootstrapping
prerequisite that unlocks everything else.

### Step 1 — Configure GitHub repository (manual, one-time)

In your GitHub repo → **Settings → Secrets and variables**:

| Secret | Value |
|--------|-------|
| `AWS_ROLE_TO_ASSUME_DEV` | ARN of the IAM role GitHub Actions assumes via OIDC |

| Variable | Default | Notes |
|----------|---------|-------|
| `AWS_REGION` | `us-west-1` | AWS region |
| `EKS_CLUSTER` | `zupikas-cluster` | EKS cluster name |

Also add these secrets for the bootstrap workflow to populate AWS Secrets Manager:

| Secret | Value |
|--------|-------|
| `BACKEND_KEY` | Backend service API key |
| `QUEUE_JOB_KEY` | Queue-job service API key |
| `TRIGGER_JOB_KEY` | Trigger-job service API key |

### Step 2 — Run the bootstrap workflow (automated)

Go to **Actions → Infrastructure Bootstrap → Run workflow** and enable all steps:

| Step | What it does |
|------|-------------|
| Create S3 + DynamoDB Terraform state backend | Idempotent — safe to re-run |
| Terraform apply | Provisions VPC, ECR repos, EKS cluster, ALB controller, External Secrets Operator |
| Upsert AWS Secrets Manager secret | Creates/updates `LUPIKAS/secrets` from the GitHub secrets above |
| Apply Kubernetes manifests | Applies namespace, ExternalSecret, Deployments, Services, HPA, Ingress |

The workflow runs steps in order and each step is independently toggle-able, so you can re-run any subset safely.

---

## Deploying code changes

### Via GitHub Actions (recommended)

Go to **Actions → Build and Deploy to Kubernetes (Dev) → Run workflow**.

Select which components to build and deploy:

| Input | Default | Description |
|-------|---------|-------------|
| `run_migration` | `true` | Build migration image and run `prisma migrate deploy` |
| `deploy_backend` | `true` | Build and deploy backend |
| `deploy_queue_job` | `true` | Build and deploy queue-job |
| `deploy_trigger_job` | `true` | Build and deploy trigger-job |

**Pipeline execution order:**

```
Build backend ──┐
Build queue-job ┤ (parallel)
Build trigger-job┤
Build migration ─┘
                 │
                 ▼
            Migrate DB (k8s Job, waits for completion)
                 │
      ┌──────────┼──────────┐
      ▼          ▼          ▼
  Deploy      Deploy     Deploy
  backend    queue-job  trigger-job
  (rollout)  (rollout)  (rollout)
```

Each deploy step uses `kubectl rollout status` and will fail the workflow if pods don't become healthy within 5 minutes.

### Manually (without CI)

```bash
# 1. Authenticate to ECR
aws ecr get-login-password --region us-west-1 | \
  docker login --username AWS --password-stdin \
  431546822103.dkr.ecr.us-west-1.amazonaws.com

# 2. Build and push an image
docker build -f docker/Dockerfile.backend -t \
  431546822103.dkr.ecr.us-west-1.amazonaws.com/tc-backend-dev:my-tag .

docker push 431546822103.dkr.ecr.us-west-1.amazonaws.com/tc-backend-dev:my-tag

# 3. Run migration
kubectl create job migration-manual \
  --image=431546822103.dkr.ecr.us-west-1.amazonaws.com/tc-migration-dev:my-tag \
  --namespace=zupikas

kubectl wait job/migration-manual --namespace=zupikas \
  --for=condition=complete --timeout=120s

kubectl delete job migration-manual --namespace=zupikas

# 4. Deploy
kubectl set image deployment/backend \
  backend=431546822103.dkr.ecr.us-west-1.amazonaws.com/tc-backend-dev:my-tag \
  --namespace=zupikas

kubectl rollout status deployment/backend --namespace=zupikas
```

---

## Scaling

Each service has an HPA that scales between 2 and 10 replicas:

- Scale out at **70% CPU** or **80% memory**
- Requires the [Kubernetes Metrics Server](https://github.com/kubernetes-sigs/metrics-server) installed in the cluster

Check current HPA state:

```bash
kubectl get hpa -n zupikas
```

Manually override replicas:

```bash
kubectl scale deployment/backend --replicas=5 -n zupikas
```

---

## Local development

```bash
npm install

# Run backend
npm run dev:backend

# Database migrations (local Postgres)
npm run migrate:dev

# Generate Prisma client
npm run generate
```

---

## Project structure

```
.
├── apps/
│   ├── backend/        # HTTP API — port 3333
│   ├── queue-job/      # Queue worker — port 3334
│   └── trigger-job/    # Trigger worker — port 3335
├── libs/
│   └── sharedb/        # Shared Prisma client + DB schema
├── docker/
│   ├── Dockerfile.backend
│   ├── Dockerfile.queuejob
│   ├── Dockerfile.triggerjob
│   └── Dockerfile.migration
├── k8s/                # Kubernetes manifests
├── terraform/          # AWS infrastructure (VPC, EKS, ECR)
│   ├── envs/dev/
│   └── modules/
│       ├── vpc/
│       ├── eks/
│       └── ecr/
└── .github/
    ├── actions/build/docker/aws/   # Reusable ECR build action
    └── workflows/deploy-dev.yml    # Main CI/CD pipeline
```

---

## Rollback

```bash
# View rollout history
kubectl rollout history deployment/backend -n zupikas

# Roll back to the previous version
kubectl rollout undo deployment/backend -n zupikas

# Roll back to a specific revision
kubectl rollout undo deployment/backend --to-revision=2 -n zupikas
```
