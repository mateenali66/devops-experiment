################################################################################
# EKS Module Variables
################################################################################

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.29"
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the cluster"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the cluster"
  type        = list(string)
}

################################################################################
# Cluster Configuration
################################################################################

variable "cluster_endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to access the public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_enabled_log_types" {
  description = "List of control plane logging types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cluster_log_retention_days" {
  description = "Retention period for cluster logs"
  type        = number
  default     = 30
}

variable "cluster_encryption_key_arn" {
  description = "ARN of KMS key for secrets encryption (creates new if empty)"
  type        = string
  default     = ""
}

variable "cluster_admin_arns" {
  description = "List of IAM ARNs to grant cluster admin access"
  type        = list(string)
  default     = []
}

################################################################################
# Default Node Group Configuration
################################################################################

variable "default_node_group_instance_types" {
  description = "Instance types for the default node group"
  type        = list(string)
  default     = ["m6i.large", "m6i.xlarge"]
}

variable "default_node_group_capacity_type" {
  description = "Capacity type for the default node group (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
}

variable "default_node_group_disk_size" {
  description = "Disk size in GB for the default node group"
  type        = number
  default     = 50
}

variable "default_node_group_desired_size" {
  description = "Desired number of nodes in the default node group"
  type        = number
  default     = 2
}

variable "default_node_group_min_size" {
  description = "Minimum number of nodes in the default node group"
  type        = number
  default     = 1
}

variable "default_node_group_max_size" {
  description = "Maximum number of nodes in the default node group"
  type        = number
  default     = 5
}

variable "default_node_group_labels" {
  description = "Labels to apply to the default node group"
  type        = map(string)
  default     = {}
}

################################################################################
# GPU Node Group Configuration
################################################################################

variable "enable_gpu_node_group" {
  description = "Enable GPU node group"
  type        = bool
  default     = false
}

variable "gpu_node_group_instance_types" {
  description = "Instance types for the GPU node group"
  type        = list(string)
  default     = ["g4dn.xlarge", "g4dn.2xlarge"]
}

variable "gpu_node_group_capacity_type" {
  description = "Capacity type for the GPU node group (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
}

variable "gpu_node_group_disk_size" {
  description = "Disk size in GB for the GPU node group"
  type        = number
  default     = 100
}

variable "gpu_node_group_desired_size" {
  description = "Desired number of nodes in the GPU node group"
  type        = number
  default     = 0
}

variable "gpu_node_group_min_size" {
  description = "Minimum number of nodes in the GPU node group"
  type        = number
  default     = 0
}

variable "gpu_node_group_max_size" {
  description = "Maximum number of nodes in the GPU node group"
  type        = number
  default     = 3
}

variable "gpu_node_group_labels" {
  description = "Labels to apply to the GPU node group"
  type        = map(string)
  default     = {}
}

################################################################################
# Tags
################################################################################

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
