# Manual Deployment Guide (Without GitHub Actions)

This guide explains how to deploy the infrastructure directly from your local machine using aws-vault and Docker.

## Prerequisites

- Docker and Docker Compose installed
- aws-vault configured with your AWS profile
- Git repository cloned locally

## Required Environment Variables

Replace placeholders with your actual values:
```bash
export TF_VAR_db_password="YourSecurePassword123"
export TF_VAR_django_secret_key="django-insecure-your-long-secret-key-here"
export GITHUB_SHA=$(git rev-parse HEAD)
export TF_WORKSPACE=staging
export AWS_ACCOUNT_ID="YOUR_AWS_ACCOUNT_ID"  # 12-digit AWS account number
export PROJECT_PREFIX="your-project-name"    # Used in resource naming
```

## Step 1: Setup Infrastructure (Run Once)

Creates IAM user, ECR repositories, and necessary policies.
```bash
cd infra/

# Initialize and apply setup
aws-vault exec YOUR_PROFILE -- docker compose run --rm terraform -chdir=setup init
aws-vault exec YOUR_PROFILE -- docker compose run --rm terraform -chdir=setup apply

# Get credentials (save these for later)
aws-vault exec YOUR_PROFILE -- docker compose run --rm terraform -chdir=setup output
```

## Step 2: Build and Push Docker Images
```bash
# Return to project root
cd ~/path/to/your/project

# Login to ECR
aws-vault exec YOUR_PROFILE -- aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com

# Build and push app image
docker build --compress -t ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/${PROJECT_PREFIX}-api-app:$GITHUB_SHA .
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/${PROJECT_PREFIX}-api-app:$GITHUB_SHA

# Build and push proxy image
docker build --compress -t ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/${PROJECT_PREFIX}-api-proxy:$GITHUB_SHA proxy/
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/${PROJECT_PREFIX}-api-proxy:$GITHUB_SHA
```

## Step 3: Deploy Application Infrastructure
```bash
# Export image variables
export TF_VAR_ecr_app_image="${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/${PROJECT_PREFIX}-api-app:$GITHUB_SHA"
export TF_VAR_ecr_proxy_image="${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/${PROJECT_PREFIX}-api-proxy:$GITHUB_SHA"

cd infra/

# Initialize deploy
docker compose run --rm terraform -chdir=deploy/ init

# Apply infrastructure
docker compose run --rm terraform -chdir=deploy/ apply
```

Wait 5-10 minutes for RDS and ECS to fully provision.

## Step 4: Create Django Superuser
```bash
# List ECS tasks (cluster name format: ${PROJECT_PREFIX}-${TF_WORKSPACE}-cluster)
aws ecs list-tasks --cluster ${PROJECT_PREFIX}-staging-cluster --region us-east-1

# Connect to container (replace TASK_ARN with actual ARN)
aws ecs execute-command \
  --cluster ${PROJECT_PREFIX}-staging-cluster \
  --task TASK_ARN \
  --container api \
  --command "/bin/sh" \
  --interactive \
  --region us-east-1

# Inside container:
python manage.py migrate
python manage.py createsuperuser
exit
```

## Step 5: Access Application

Get Load Balancer DNS:
```bash
# Load balancer name format: ${PROJECT_PREFIX}-${TF_WORKSPACE}-lb
aws elbv2 describe-load-balancers \
  --names ${PROJECT_PREFIX}-staging-lb \
  --query 'LoadBalancers[0].DNSName' \
  --output text
```

Access at: `http://<LB_DNS>/admin`

## Destroy Infrastructure (Save Costs)
```bash
cd infra/

# Destroy application infrastructure
docker compose run --rm terraform -chdir=deploy/ destroy

# Destroy setup (if needed)
docker compose run --rm terraform -chdir=setup/ destroy
```

## Estimated Monthly Costs

- RDS (db.t4g.micro): ~$15-20
- Application Load Balancer: ~$16
- ECS Fargate: ~$5-10
- **Total: ~$35-45/month**

Always destroy resources when not in use to avoid charges.

## Troubleshooting

**Issue:** `No valid credential sources found`
**Solution:** Make sure you're logged in with aws-vault: `aws-vault exec YOUR_PROFILE`

**Issue:** `The security token included in the request is invalid`
**Solution:** Refresh aws-vault session: `aws-vault remove YOUR_PROFILE` then login again

**Issue:** Docker permission denied
**Solution:** Add user to docker group: `sudo usermod -aG docker $USER` (logout/login required)
