################################################################################
# VPC Module - Dev Environment
################################################################################

include "root" {
  path = find_in_parent_folders()
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../../terraform/modules/vpc"
}

inputs = {
  name               = "${local.env_vars.locals.environment}-${local.env_vars.locals.cluster_name}"
  vpc_cidr           = local.env_vars.locals.vpc_cidr
  az_count           = local.env_vars.locals.az_count
  cluster_name       = local.env_vars.locals.cluster_name
  enable_nat_gateway = true
  single_nat_gateway = local.env_vars.locals.single_nat
  enable_flow_logs   = false

  tags = {
    Environment = local.env_vars.locals.environment
    Component   = "networking"
  }
}
