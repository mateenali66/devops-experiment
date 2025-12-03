# Portfolio: Real-World DevOps Experience

This section showcases production infrastructure challenges I've solved, architectures I've built, and performance issues I've diagnosed.

## Case Studies

| Project | Domain | Key Technologies |
|---------|--------|------------------|
| [Kubernetes Platform Rebuild](01-kubernetes-platform-rebuild.md) | Platform Engineering | EKS, Terraform, GitOps |
| [GPU/ML Inference Pipeline](02-gpu-ml-inference-pipeline.md) | ML Infrastructure | GPU, Kubernetes, Model Serving |
| [Infrastructure Automation](03-infrastructure-automation.md) | DevOps | IaC, CI/CD, Self-Service |
| [Performance Debugging](04-performance-debugging.md) | SRE | SNAT, Connection Pooling, Cold Starts |

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           Production Infrastructure                                  │
│                                                                                     │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐                 │
│  │   Development   │    │    Staging      │    │   Production    │                 │
│  │   Environment   │───▶│   Environment   │───▶│   Environment   │                 │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘                 │
│          │                      │                      │                           │
│          └──────────────────────┼──────────────────────┘                           │
│                                 │                                                   │
│                    ┌────────────▼────────────┐                                     │
│                    │    GitOps Pipeline      │                                     │
│                    │  (Flux CD / ArgoCD)     │                                     │
│                    └────────────┬────────────┘                                     │
│                                 │                                                   │
│  ┌──────────────────────────────┼──────────────────────────────┐                   │
│  │                    Kubernetes Platform                       │                   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │                   │
│  │  │   Ingress   │  │  Service    │  │    GPU      │          │                   │
│  │  │  Controller │  │    Mesh     │  │  Workloads  │          │                   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘          │                   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │                   │
│  │  │ Monitoring  │  │   Logging   │  │   Secrets   │          │                   │
│  │  │ Prometheus  │  │   Loki      │  │  Management │          │                   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘          │                   │
│  └──────────────────────────────────────────────────────────────┘                   │
│                                                                                     │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## Skills Demonstrated

- **Infrastructure as Code**: Terraform, Terragrunt, CloudFormation, Pulumi
- **Container Orchestration**: Kubernetes, EKS, GKE, Docker
- **GitOps**: Flux CD, ArgoCD, Helm, Kustomize
- **Observability**: Prometheus, Grafana, Datadog, CloudWatch
- **CI/CD**: GitHub Actions, GitLab CI, Jenkins, CircleCI
- **Cloud Platforms**: AWS, GCP, Azure
- **GPU/ML Infrastructure**: NVIDIA GPU scheduling, Model serving, Inference optimization
