# GPU Workloads Guide

This guide covers running GPU-accelerated workloads on the EKS cluster.

## Overview

The platform supports NVIDIA GPU workloads through:
- **EKS GPU Node Groups**: Pre-configured with NVIDIA GPU AMIs
- **NVIDIA Device Plugin**: Exposes GPUs as schedulable resources
- **DCGM Exporter**: Exports GPU metrics to Prometheus

## Supported GPU Instance Types

| Instance Type | GPUs | GPU Memory | Use Case |
|---------------|------|------------|----------|
| g4dn.xlarge | 1x T4 | 16 GB | Inference, light training |
| g4dn.2xlarge | 1x T4 | 16 GB | Inference with more CPU/RAM |
| g4dn.12xlarge | 4x T4 | 64 GB | Multi-GPU inference |
| p3.2xlarge | 1x V100 | 16 GB | Training workloads |
| p3.8xlarge | 4x V100 | 64 GB | Large-scale training |
| p4d.24xlarge | 8x A100 | 320 GB | High-performance training |

## Enabling GPU Support

### 1. Update Terragrunt Configuration

Edit `terragrunt/dev/env.hcl`:

```hcl
locals {
  enable_gpu_nodes         = true
  gpu_node_instance_types  = ["g4dn.xlarge", "g4dn.2xlarge"]
  gpu_node_desired_size    = 1
  gpu_node_min_size        = 0
  gpu_node_max_size        = 3
}
```

### 2. Apply Changes

```bash
cd terragrunt/dev/eks
terragrunt apply
```

### 3. Verify GPU Nodes

```bash
# Check nodes with GPU label
kubectl get nodes -l nvidia.com/gpu.present=true

# Check allocatable GPUs
kubectl describe nodes | grep -A10 "Allocatable:" | grep nvidia

# Verify NVIDIA device plugin
kubectl get pods -n nvidia-device-plugin
```

## Scheduling GPU Workloads

### Basic GPU Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: gpu-test
spec:
  containers:
    - name: cuda-test
      image: nvidia/cuda:12.2.0-base-ubuntu22.04
      command: ["nvidia-smi"]
      resources:
        limits:
          nvidia.com/gpu: 1
  # Required to schedule on GPU nodes
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  nodeSelector:
    nvidia.com/gpu.present: "true"
```

### GPU Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ml-inference
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ml-inference
  template:
    metadata:
      labels:
        app: ml-inference
    spec:
      containers:
        - name: inference
          image: your-ml-image:latest
          resources:
            requests:
              memory: "4Gi"
              cpu: "2"
              nvidia.com/gpu: 1
            limits:
              memory: "8Gi"
              cpu: "4"
              nvidia.com/gpu: 1
          env:
            - name: NVIDIA_VISIBLE_DEVICES
              value: "all"
            - name: NVIDIA_DRIVER_CAPABILITIES
              value: "compute,utility"
      tolerations:
        - key: nvidia.com/gpu
          operator: Exists
          effect: NoSchedule
      nodeSelector:
        nvidia.com/gpu.present: "true"
```

## GPU Sharing (Time-Slicing)

For better GPU utilization, enable time-slicing:

### Configure Device Plugin

Edit `kubernetes/infrastructure/nvidia/device-plugin.yaml`:

```yaml
config:
  map:
    default: |-
      version: v1
      sharing:
        timeSlicing:
          renameByDefault: true
          failRequestsGreaterThanOne: false
          resources:
            - name: nvidia.com/gpu
              replicas: 4  # Split each GPU into 4 virtual GPUs
```

### Use Shared GPUs

```yaml
resources:
  limits:
    nvidia.com/gpu: 1  # Now uses 1/4 of a physical GPU
```

## GPU Metrics & Monitoring

### Available Metrics

The DCGM Exporter provides these metrics:

| Metric | Description |
|--------|-------------|
| `DCGM_FI_DEV_GPU_UTIL` | GPU utilization (%) |
| `DCGM_FI_DEV_MEM_COPY_UTIL` | Memory utilization (%) |
| `DCGM_FI_DEV_GPU_TEMP` | GPU temperature (°C) |
| `DCGM_FI_DEV_POWER_USAGE` | Power usage (W) |
| `DCGM_FI_DEV_FB_FREE` | Free framebuffer memory (MB) |
| `DCGM_FI_DEV_FB_USED` | Used framebuffer memory (MB) |

### Prometheus Queries

```promql
# GPU utilization by pod
DCGM_FI_DEV_GPU_UTIL{namespace="gpu-workloads"}

# Memory usage percentage
DCGM_FI_DEV_FB_USED / (DCGM_FI_DEV_FB_USED + DCGM_FI_DEV_FB_FREE) * 100

# High temperature alert
DCGM_FI_DEV_GPU_TEMP > 80
```

### Grafana Dashboard

Access the pre-configured GPU dashboard:
1. Open Grafana (port-forward to 3000)
2. Navigate to Dashboards → GPU Monitoring
3. Select namespace and pod filters

## Best Practices

### 1. Resource Requests
Always specify GPU requests/limits:
```yaml
resources:
  requests:
    nvidia.com/gpu: 1
  limits:
    nvidia.com/gpu: 1
```

### 2. Node Affinity
Use node selectors for GPU workloads:
```yaml
nodeSelector:
  nvidia.com/gpu.present: "true"
```

### 3. Tolerations
Always include GPU taints:
```yaml
tolerations:
  - key: nvidia.com/gpu
    operator: Exists
    effect: NoSchedule
```

### 4. Memory Management
- Monitor GPU memory usage
- Use appropriate batch sizes
- Implement graceful memory cleanup

### 5. Cost Optimization
- Use Spot instances for fault-tolerant workloads
- Scale down GPU nodes during off-hours
- Right-size instance types based on actual usage

## Troubleshooting

### GPU Not Detected

```bash
# Check device plugin logs
kubectl logs -n nvidia-device-plugin -l app.kubernetes.io/name=nvidia-device-plugin

# Verify node labels
kubectl get nodes --show-labels | grep nvidia

# Check kubelet logs on the node
kubectl debug node/<node-name> -it --image=busybox
```

### Pod Stuck in Pending

```bash
# Check events
kubectl describe pod <pod-name>

# Common causes:
# - No GPU nodes available
# - Insufficient GPU resources
# - Missing tolerations
```

### CUDA Errors

```bash
# Verify CUDA installation
kubectl exec -it <pod-name> -- nvidia-smi

# Check driver version compatibility
kubectl exec -it <pod-name> -- cat /proc/driver/nvidia/version
```

## Example Workloads

### PyTorch Training Job

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: pytorch-training
spec:
  template:
    spec:
      containers:
        - name: pytorch
          image: pytorch/pytorch:2.0.1-cuda11.7-cudnn8-runtime
          command: ["python", "-c", "import torch; print(torch.cuda.is_available())"]
          resources:
            limits:
              nvidia.com/gpu: 1
      tolerations:
        - key: nvidia.com/gpu
          operator: Exists
          effect: NoSchedule
      nodeSelector:
        nvidia.com/gpu.present: "true"
      restartPolicy: Never
```

### TensorFlow Serving

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tf-serving
spec:
  replicas: 2
  selector:
    matchLabels:
      app: tf-serving
  template:
    metadata:
      labels:
        app: tf-serving
    spec:
      containers:
        - name: tf-serving
          image: tensorflow/serving:latest-gpu
          ports:
            - containerPort: 8501
          resources:
            limits:
              nvidia.com/gpu: 1
          volumeMounts:
            - name: model
              mountPath: /models
      tolerations:
        - key: nvidia.com/gpu
          operator: Exists
          effect: NoSchedule
      nodeSelector:
        nvidia.com/gpu.present: "true"
      volumes:
        - name: model
          emptyDir: {}
```
