# Setup Guide

This guide walks through the complete setup of the DevOps Experiment platform.

## Prerequisites

### Required Tools

| Tool | Version | Installation |
|------|---------|--------------|
| AWS CLI | v2.x | [AWS CLI Install](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) |
| Terraform | >= 1.5.0 | [Terraform Install](https://developer.hashicorp.com/terraform/downloads) |
| Terragrunt | >= 0.50.0 | [Terragrunt Install](https://terragrunt.gruntwork.io/docs/getting-started/install/) |
| kubectl | >= 1.28 | [kubectl Install](https://kubernetes.io/docs/tasks/tools/) |
| Flux CLI | >= 2.0 | [Flux Install](https://fluxcd.io/flux/installation/) |
| Helm | >= 3.0 | [Helm Install](https://helm.sh/docs/intro/install/) |
| Docker | Latest | [Docker Install](https://docs.docker.com/get-docker/) |

### AWS Configuration

1. **Configure AWS CLI:**
```bash
aws configure
# Or use a profile
export AWS_PROFILE=personal
```

2. **Verify access:**
```bash
aws sts get-caller-identity
```

## Step 1: Prepare Backend Resources

Before running Terragrunt, create the S3 bucket and DynamoDB table for state management:

```bash
# Set variables
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="devops-experiment-terraform-state-${ACCOUNT_ID}"
REGION="us-west-2"

# Create S3 bucket
aws s3api create-bucket \
  --bucket $BUCKET_NAME \
  --region $REGION \
  --create-bucket-configuration LocationConstraint=$REGION

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket $BUCKET_NAME \
  --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket $BUCKET_NAME \
  --public-access-block-configuration '{
    "BlockPublicAcls": true,
    "IgnorePublicAcls": true,
    "BlockPublicPolicy": true,
    "RestrictPublicBuckets": true
  }'

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name devops-experiment-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region $REGION
```

## Step 2: Configure Environment Variables

Edit `terragrunt/dev/env.hcl` and update:

```hcl
locals {
  account_id = "YOUR_AWS_ACCOUNT_ID"  # Replace with actual account ID
}
```

## Step 3: Deploy Infrastructure

### Initialize and Plan

```bash
cd terragrunt/dev

# Initialize all modules
terragrunt run-all init

# Review the plan
terragrunt run-all plan
```

### Apply Infrastructure

```bash
# Deploy VPC first
cd vpc && terragrunt apply

# Deploy EKS
cd ../eks && terragrunt apply

# Deploy EKS add-ons
cd ../eks-addons && terragrunt apply
```

Or deploy all at once:
```bash
cd terragrunt/dev
terragrunt run-all apply
```

## Step 4: Configure kubectl

```bash
# Update kubeconfig
aws eks update-kubeconfig \
  --name eks-dev-cluster \
  --region us-west-2

# Verify connectivity
kubectl get nodes
kubectl cluster-info
```

## Step 5: Bootstrap Flux

```bash
# Export GitHub token
export GITHUB_TOKEN=<your-github-token>

# Bootstrap Flux
flux bootstrap github \
  --owner=mateenali66 \
  --repository=devops-experiment \
  --branch=main \
  --path=kubernetes/clusters/dev \
  --personal

# Verify Flux installation
flux check
flux get all
```

## Step 6: Verify Deployments

### Check Flux Resources
```bash
# Check Kustomizations
kubectl get kustomizations -n flux-system

# Check HelmReleases
kubectl get helmreleases -A

# Check pods in all namespaces
kubectl get pods -A
```

### Access Grafana
```bash
# Port forward
kubectl port-forward svc/kube-prometheus-stack-grafana -n monitoring 3000:80

# Open http://localhost:3000
# Default credentials: admin / prom-operator
```

## Step 7: Enable GPU Support (Optional)

To enable GPU nodes:

1. Edit `terragrunt/dev/env.hcl`:
```hcl
locals {
  enable_gpu_nodes        = true
  gpu_node_desired_size   = 1
}
```

2. Apply changes:
```bash
cd terragrunt/dev/eks
terragrunt apply
```

3. Verify GPU nodes:
```bash
kubectl get nodes -l nvidia.com/gpu.present=true
kubectl describe nodes | grep -A5 "Allocatable:"
```

## Troubleshooting

### Common Issues

**1. Terragrunt state lock error:**
```bash
# Force unlock (use with caution)
terragrunt force-unlock <LOCK_ID>
```

**2. EKS node group not joining:**
```bash
# Check node group status
aws eks describe-nodegroup \
  --cluster-name eks-dev-cluster \
  --nodegroup-name eks-dev-cluster-default

# Check node logs
kubectl logs -n kube-system -l app=aws-node
```

**3. Flux sync failing:**
```bash
# Check Flux logs
flux logs

# Force reconciliation
flux reconcile kustomization flux-system --with-source
```

## Cleanup

To destroy all resources:

```bash
# Uninstall Flux first
flux uninstall

# Destroy infrastructure in reverse order
cd terragrunt/dev
terragrunt run-all destroy
```

## Next Steps

- [GPU Workloads Guide](GPU-WORKLOADS.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)
