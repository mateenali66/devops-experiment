# DevOps Experiment - Production-Grade AWS EKS Platform

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-623CE4?logo=terraform)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28+-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![AWS](https://img.shields.io/badge/AWS-EKS-FF9900?logo=amazon-aws)](https://aws.amazon.com/eks/)
[![GPU](https://img.shields.io/badge/GPU-Ready-76B900?logo=nvidia)](https://developer.nvidia.com/)

A comprehensive, production-ready DevOps platform demonstrating Infrastructure as Code, GitOps, and modern cloud-native practices.

**Last Updated:** December 2024

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              AWS Cloud                                       │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                           VPC (10.0.0.0/16)                           │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐       │  │
│  │  │  Public Subnet  │  │  Public Subnet  │  │  Public Subnet  │       │  │
│  │  │    AZ-1a        │  │    AZ-1b        │  │    AZ-1c        │       │  │
│  │  │  NAT Gateway    │  │                 │  │                 │       │  │
│  │  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘       │  │
│  │           │                    │                    │                │  │
│  │  ┌────────┴────────┐  ┌────────┴────────┐  ┌────────┴────────┐       │  │
│  │  │ Private Subnet  │  │ Private Subnet  │  │ Private Subnet  │       │  │
│  │  │     AZ-1a       │  │     AZ-1b       │  │     AZ-1c       │       │  │
│  │  │                 │  │                 │  │                 │       │  │
│  │  │  ┌───────────┐  │  │  ┌───────────┐  │  │  ┌───────────┐  │       │  │
│  │  │  │EKS Workers│  │  │  │EKS Workers│  │  │  │EKS Workers│  │       │  │
│  │  │  │(CPU/GPU)  │  │  │  │(CPU/GPU)  │  │  │  │(CPU/GPU)  │  │       │  │
│  │  │  └───────────┘  │  │  └───────────┘  │  │  └───────────┘  │       │  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘       │  │
│  │                                                                       │  │
│  │  ┌─────────────────────────────────────────────────────────────────┐ │  │
│  │  │                      EKS Control Plane                          │ │  │
│  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │ │  │
│  │  │  │    Flux     │  │ Prometheus  │  │   Grafana   │             │ │  │
│  │  │  │   GitOps    │  │             │  │             │             │ │  │
│  │  │  └─────────────┘  └─────────────┘  └─────────────┘             │ │  │
│  │  └─────────────────────────────────────────────────────────────────┘ │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                           GitHub Actions CI/CD                              │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐                   │
│  │ TF Validate   │  │ TF Plan       │  │ TF Apply      │                   │
│  │ & Lint        │→ │ (PR Preview)  │→ │ (Main Branch) │                   │
│  └───────────────┘  └───────────────┘  └───────────────┘                   │
│  ┌───────────────┐  ┌───────────────┐                                      │
│  │ Container     │  │ Security      │                                      │
│  │ Build & Push  │  │ Scanning      │                                      │
│  └───────────────┘  └───────────────┘                                      │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
.
├── terraform/                    # Terraform modules
│   ├── modules/
│   │   ├── vpc/                 # VPC, subnets, NAT, IGW
│   │   ├── eks/                 # EKS cluster + node groups
│   │   ├── eks-addons/          # EKS add-ons (CSI, CNI, etc.)
│   │   └── irsa/                # IAM Roles for Service Accounts
│   └── providers.tf
│
├── terragrunt/                   # Terragrunt environment configs
│   ├── terragrunt.hcl           # Root configuration
│   ├── dev/
│   │   ├── env.hcl
│   │   ├── vpc/
│   │   ├── eks/
│   │   └── eks-addons/
│   ├── staging/
│   └── prod/
│
├── kubernetes/                   # Kubernetes manifests
│   ├── flux-system/             # Flux bootstrap configuration
│   ├── infrastructure/          # Cluster-wide infrastructure
│   │   ├── sources/             # Helm repositories
│   │   ├── monitoring/          # Prometheus, Grafana
│   │   ├── nvidia/              # NVIDIA device plugin
│   │   └── ingress/             # Ingress controller
│   └── apps/                    # Application deployments
│       └── sample-gpu-app/
│
├── .github/
│   └── workflows/
│       ├── terraform-ci.yaml    # TF validate, plan, apply
│       ├── container-build.yaml # Build & push containers
│       └── flux-diff.yaml       # Preview Flux changes
│
├── docker/                       # Dockerfiles
│   └── sample-gpu-app/
│
└── docs/                         # Additional documentation
    ├── SETUP.md
    ├── GPU-WORKLOADS.md
    └── TROUBLESHOOTING.md
```

## 🚀 Features

### Infrastructure as Code
- **Terraform Modules**: Reusable, versioned modules for VPC and EKS
- **Terragrunt**: DRY configuration management across environments
- **State Management**: Remote state with S3 + DynamoDB locking
- **GPU Support**: Pre-configured node groups for NVIDIA GPU instances

### GitOps with Flux
- **Automated Deployments**: Git as single source of truth
- **Helm Controller**: Declarative Helm release management
- **Kustomize Integration**: Environment-specific overlays
- **Image Automation**: Automatic image updates (optional)

### Monitoring & Observability
- **Prometheus**: Metrics collection with GPU metrics support
- **Grafana**: Pre-configured dashboards for K8s and GPU monitoring
- **Alertmanager**: Alert routing and notification

### CI/CD with GitHub Actions
- **Infrastructure Pipeline**: Validate → Plan → Apply workflow
- **Container Pipeline**: Build, scan, and push to ECR
- **Security Scanning**: Trivy for container vulnerability scanning
- **Cost Estimation**: Infracost integration for PR cost preview

## 🛠️ Prerequisites

- AWS CLI v2 configured with appropriate credentials
- Terraform >= 1.5.0
- Terragrunt >= 0.50.0
- kubectl >= 1.28
- Flux CLI >= 2.0
- Docker (for building containers)

## 🏁 Quick Start

### 1. Clone and Configure

```bash
git clone https://github.com/mateenali66/devops-experiment.git
cd devops-experiment

# Set your AWS profile
export AWS_PROFILE=personal
```

### 2. Initialize Backend (First Time Only)

```bash
cd terragrunt/dev
terragrunt run-all init
```

### 3. Deploy Infrastructure

```bash
# Review the plan
terragrunt run-all plan

# Apply infrastructure
terragrunt run-all apply
```

### 4. Bootstrap Flux

```bash
# Configure kubectl
aws eks update-kubeconfig --name eks-dev-cluster --region us-west-2

# Bootstrap Flux
flux bootstrap github \
  --owner=mateenali66 \
  --repository=devops-experiment \
  --branch=main \
  --path=kubernetes/clusters/dev \
  --personal
```

### 5. Access Grafana

```bash
# Port forward Grafana
kubectl port-forward svc/kube-prometheus-stack-grafana -n monitoring 3000:80

# Default credentials: admin / prom-operator
```

## 🎮 GPU Workloads

This platform supports NVIDIA GPU workloads out of the box:

```yaml
# Example GPU pod request
resources:
  limits:
    nvidia.com/gpu: 1
```

See [docs/GPU-WORKLOADS.md](docs/GPU-WORKLOADS.md) for detailed GPU configuration.

## 📊 Monitoring Dashboards

Pre-configured Grafana dashboards:
- Kubernetes Cluster Overview
- Node Exporter / Node Metrics
- NVIDIA GPU Metrics (DCGM)
- Flux GitOps Status
- Container Resource Usage

## 🔐 Security Considerations

- Private EKS endpoint (configurable)
- IRSA for pod-level AWS permissions
- Network policies for pod isolation
- Secrets management via External Secrets Operator
- Container image scanning in CI/CD

## 💰 Cost Optimization

- Spot instances for non-GPU workloads
- Cluster autoscaler for dynamic scaling
- Karpenter support (optional)
- Right-sizing recommendations via Grafana

## 📚 Documentation

- [Setup Guide](docs/SETUP.md)
- [GPU Workloads Guide](docs/GPU-WORKLOADS.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## 📜 License

MIT License - see [LICENSE](LICENSE)
