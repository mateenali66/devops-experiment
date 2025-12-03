################################################################################
# EKS Add-ons Module Outputs
################################################################################

output "vpc_cni_addon_version" {
  description = "Version of the VPC CNI add-on"
  value       = aws_eks_addon.vpc_cni.addon_version
}

output "coredns_addon_version" {
  description = "Version of the CoreDNS add-on"
  value       = aws_eks_addon.coredns.addon_version
}

output "kube_proxy_addon_version" {
  description = "Version of the Kube Proxy add-on"
  value       = aws_eks_addon.kube_proxy.addon_version
}

output "ebs_csi_addon_version" {
  description = "Version of the EBS CSI Driver add-on"
  value       = var.enable_ebs_csi_driver ? aws_eks_addon.ebs_csi[0].addon_version : null
}

output "ebs_csi_role_arn" {
  description = "IAM role ARN for the EBS CSI Driver"
  value       = var.enable_ebs_csi_driver && var.ebs_csi_role_arn == "" ? aws_iam_role.ebs_csi[0].arn : var.ebs_csi_role_arn
}

output "vpc_cni_role_arn" {
  description = "IAM role ARN for the VPC CNI"
  value       = var.vpc_cni_role_arn == "" ? aws_iam_role.vpc_cni[0].arn : var.vpc_cni_role_arn
}
