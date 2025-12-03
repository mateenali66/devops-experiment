################################################################################
# EKS Module Outputs
################################################################################

output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = aws_eks_cluster.main.id
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "The endpoint for the EKS cluster API server"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_version" {
  description = "The Kubernetes version of the cluster"
  value       = aws_eks_cluster.main.version
}

output "cluster_platform_version" {
  description = "The platform version of the cluster"
  value       = aws_eks_cluster.main.platform_version
}

output "cluster_status" {
  description = "The status of the EKS cluster"
  value       = aws_eks_cluster.main.status
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_security_group.cluster.id
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = aws_iam_role.cluster.arn
}

output "cluster_iam_role_name" {
  description = "IAM role name of the EKS cluster"
  value       = aws_iam_role.cluster.name
}

################################################################################
# Node Group Outputs
################################################################################

output "node_iam_role_arn" {
  description = "IAM role ARN for the node groups"
  value       = aws_iam_role.node.arn
}

output "node_iam_role_name" {
  description = "IAM role name for the node groups"
  value       = aws_iam_role.node.name
}

output "default_node_group_id" {
  description = "ID of the default node group"
  value       = aws_eks_node_group.default.id
}

output "gpu_node_group_id" {
  description = "ID of the GPU node group"
  value       = var.enable_gpu_node_group ? aws_eks_node_group.gpu[0].id : null
}

################################################################################
# OIDC Outputs
################################################################################

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for IRSA"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC Provider"
  value       = aws_iam_openid_connect_provider.eks.url
}

output "oidc_issuer" {
  description = "OIDC issuer URL for the cluster"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

################################################################################
# KMS Outputs
################################################################################

output "kms_key_arn" {
  description = "ARN of the KMS key used for secrets encryption"
  value       = var.cluster_encryption_key_arn != "" ? var.cluster_encryption_key_arn : aws_kms_key.eks[0].arn
}

output "kms_key_id" {
  description = "ID of the KMS key used for secrets encryption"
  value       = var.cluster_encryption_key_arn != "" ? null : aws_kms_key.eks[0].key_id
}

################################################################################
# Kubeconfig
################################################################################

output "kubeconfig_command" {
  description = "AWS CLI command to update kubeconfig"
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.main.name} --region ${data.aws_region.current.name}"
}

data "aws_region" "current" {}
