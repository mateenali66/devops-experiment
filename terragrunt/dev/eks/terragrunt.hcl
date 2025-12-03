################################################################################
# EKS Module - Dev Environment
################################################################################

include "root" {
  path = find_in_parent_folders()
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../../terraform/modules/eks"
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id             = "vpc-00000000000000000"
    private_subnet_ids = ["subnet-00000000000000001", "subnet-00000000000000002", "subnet-00000000000000003"]
    public_subnet_ids  = ["subnet-00000000000000004", "subnet-00000000000000005", "subnet-00000000000000006"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  cluster_name    = local.env_vars.locals.cluster_name
  cluster_version = local.env_vars.locals.cluster_version

  vpc_id             = dependency.vpc.outputs.vpc_id
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids
  public_subnet_ids  = dependency.vpc.outputs.public_subnet_ids

  # Cluster access configuration
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]  # Restrict in production

  # Default node group
  default_node_group_instance_types = local.env_vars.locals.default_node_instance_types
  default_node_group_capacity_type  = "ON_DEMAND"
  default_node_group_desired_size   = local.env_vars.locals.default_node_desired_size
  default_node_group_min_size       = local.env_vars.locals.default_node_min_size
  default_node_group_max_size       = local.env_vars.locals.default_node_max_size
  default_node_group_disk_size      = 50

  # GPU node group
  enable_gpu_node_group          = local.env_vars.locals.enable_gpu_nodes
  gpu_node_group_instance_types  = local.env_vars.locals.gpu_node_instance_types
  gpu_node_group_capacity_type   = "ON_DEMAND"
  gpu_node_group_desired_size    = local.env_vars.locals.gpu_node_desired_size
  gpu_node_group_min_size        = local.env_vars.locals.gpu_node_min_size
  gpu_node_group_max_size        = local.env_vars.locals.gpu_node_max_size
  gpu_node_group_disk_size       = 100

  # Cluster admin access - add your IAM ARN here
  cluster_admin_arns = [
    # "arn:aws:iam::${local.env_vars.locals.account_id}:user/your-username",
    # "arn:aws:iam::${local.env_vars.locals.account_id}:role/your-role",
  ]

  tags = {
    Environment = local.env_vars.locals.environment
    Component   = "kubernetes"
  }
}
