# Troubleshooting Guide

Common issues and their solutions for the DevOps Experiment platform.

## Terraform / Terragrunt Issues

### State Lock Errors

**Symptom:**
```
Error: Error acquiring the state lock
```

**Solution:**
```bash
# Find the lock ID from the error message
terragrunt force-unlock <LOCK_ID>

# Or check DynamoDB for stuck locks
aws dynamodb scan --table-name devops-experiment-terraform-locks
```

### Backend Initialization Failed

**Symptom:**
```
Error: Failed to get existing workspaces
```

**Solution:**
1. Verify S3 bucket exists
2. Check IAM permissions
3. Verify region configuration

```bash
# Check bucket
aws s3 ls s3://devops-experiment-terraform-state-<account-id>/

# Reinitialize
terragrunt init -reconfigure
```

### Dependency Errors

**Symptom:**
```
Error: Module not found
```

**Solution:**
```bash
# Clear cache
rm -rf .terragrunt-cache
rm -rf .terraform

# Reinitialize
terragrunt init
```

## EKS Issues

### Nodes Not Joining Cluster

**Symptom:** Node group shows "DEGRADED" status

**Debug Steps:**
```bash
# Check node group status
aws eks describe-nodegroup \
  --cluster-name eks-dev-cluster \
  --nodegroup-name <nodegroup-name>

# Check EC2 instances
aws ec2 describe-instances \
  --filters "Name=tag:eks:nodegroup-name,Values=<nodegroup-name>"

# Connect to node for logs
aws ssm start-session --target <instance-id>
journalctl -u kubelet
```

**Common Causes:**
- Security group blocking communication
- IAM role missing permissions
- VPC CNI issues

### kubectl Connection Failed

**Symptom:**
```
Unable to connect to the server
```

**Solution:**
```bash
# Update kubeconfig
aws eks update-kubeconfig --name eks-dev-cluster --region us-west-2

# Verify AWS identity
aws sts get-caller-identity

# Check cluster endpoint
kubectl cluster-info
```

### Cluster Autoscaler Not Scaling

**Debug:**
```bash
# Check autoscaler logs
kubectl logs -n kube-system -l app=cluster-autoscaler

# Check node group scaling limits
aws eks describe-nodegroup --cluster-name eks-dev-cluster \
  --nodegroup-name <nodegroup> | jq '.nodegroup.scalingConfig'
```

## Flux Issues

### Kustomization Failing

**Symptom:** Kustomization shows "False" ready status

**Debug:**
```bash
# Get detailed status
flux get kustomizations

# Check specific kustomization
kubectl describe kustomization <name> -n flux-system

# View Flux logs
flux logs --level=error
```

**Common Causes:**
- Invalid YAML syntax
- Missing dependencies
- Resource conflicts

### HelmRelease Not Installing

**Debug:**
```bash
# Check HelmRelease status
flux get helmreleases -A

# Describe for errors
kubectl describe helmrelease <name> -n <namespace>

# Check Helm history
helm history <release-name> -n <namespace>

# Force reconciliation
flux reconcile helmrelease <name> -n <namespace>
```

### Source Not Syncing

**Debug:**
```bash
# Check git repository status
flux get sources git

# Check for authentication issues
kubectl describe gitrepository flux-system -n flux-system

# Force sync
flux reconcile source git flux-system
```

## Monitoring Issues

### Prometheus Not Scraping Targets

**Debug:**
```bash
# Check targets in Prometheus UI
kubectl port-forward svc/kube-prometheus-stack-prometheus -n monitoring 9090:9090
# Open http://localhost:9090/targets

# Check ServiceMonitor
kubectl get servicemonitor -A

# Verify service selector matches
kubectl get svc -A --show-labels
```

### Grafana Dashboard Empty

**Debug:**
1. Verify Prometheus data source
2. Check time range
3. Verify metrics exist

```bash
# Test Prometheus query
kubectl exec -it prometheus-0 -n monitoring -- \
  wget -qO- 'http://localhost:9090/api/v1/query?query=up'
```

### Alertmanager Not Sending Alerts

**Debug:**
```bash
# Check Alertmanager config
kubectl get secret alertmanager-kube-prometheus-stack-alertmanager -n monitoring \
  -o jsonpath='{.data.alertmanager\.yaml}' | base64 -d

# Check firing alerts
kubectl port-forward svc/kube-prometheus-stack-alertmanager -n monitoring 9093:9093
# Open http://localhost:9093
```

## GPU Issues

### NVIDIA Device Plugin Not Running

**Debug:**
```bash
# Check pod status
kubectl get pods -n nvidia-device-plugin

# Check logs
kubectl logs -n nvidia-device-plugin -l app.kubernetes.io/name=nvidia-device-plugin

# Verify node has GPU
kubectl describe node <gpu-node> | grep nvidia
```

### GPU Not Visible to Pods

**Debug:**
```bash
# Test with simple pod
kubectl run gpu-test --rm -it --restart=Never \
  --image=nvidia/cuda:12.2.0-base-ubuntu22.04 \
  --overrides='{"spec":{"tolerations":[{"key":"nvidia.com/gpu","operator":"Exists","effect":"NoSchedule"}],"nodeSelector":{"nvidia.com/gpu.present":"true"}}}' \
  -- nvidia-smi

# Check allocatable resources
kubectl describe nodes | grep -A5 "Allocatable:"
```

### CUDA Version Mismatch

**Symptom:**
```
CUDA driver version is insufficient for CUDA runtime version
```

**Solution:**
- Use compatible CUDA container image
- Check node's NVIDIA driver version:
```bash
kubectl exec <pod> -- nvidia-smi | head -3
```

## Networking Issues

### Pods Cannot Reach External Services

**Debug:**
```bash
# Test DNS
kubectl run test --rm -it --restart=Never --image=busybox -- nslookup google.com

# Test connectivity
kubectl run test --rm -it --restart=Never --image=curlimages/curl -- curl -I https://google.com

# Check CoreDNS
kubectl logs -n kube-system -l k8s-app=kube-dns
```

### Service Not Accessible

**Debug:**
```bash
# Check service endpoints
kubectl get endpoints <service-name>

# Check pod labels match selector
kubectl get pods --show-labels

# Test from within cluster
kubectl run test --rm -it --restart=Never --image=busybox -- wget -qO- http://<service>.<namespace>.svc.cluster.local
```

### LoadBalancer Stuck in Pending

**Debug:**
```bash
# Check service events
kubectl describe svc <service-name>

# Check AWS Load Balancer Controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

## CI/CD Issues

### GitHub Actions Failing

**Common Causes:**
1. **AWS credentials**: Verify OIDC role trust policy
2. **Secrets not set**: Check repository secrets
3. **Timeout**: Increase timeout values

**Debug OIDC:**
```bash
# Verify role trust policy allows GitHub Actions
aws iam get-role --role-name <role-name> | jq '.Role.AssumeRolePolicyDocument'
```

### Container Build Failing

**Debug:**
```bash
# Build locally
cd docker/sample-gpu-app
docker build -t test .

# Check for missing files
docker build --no-cache -t test .
```

## Quick Fixes

### Restart All Pods in Namespace
```bash
kubectl rollout restart deployment -n <namespace>
```

### Clear Flux Cache
```bash
flux suspend kustomization --all
flux resume kustomization --all
```

### Reset EKS Add-on
```bash
aws eks update-addon --cluster-name <cluster> --addon-name <addon> --resolve-conflicts OVERWRITE
```

### Force Terraform State Refresh
```bash
terragrunt refresh
```

## Getting Help

1. **Check logs first** - Most issues have clear error messages
2. **Search existing issues** - GitHub issues often have solutions
3. **AWS Support** - For EKS-specific issues
4. **Community** - Kubernetes Slack, Stack Overflow
