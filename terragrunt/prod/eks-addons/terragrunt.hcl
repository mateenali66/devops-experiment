################################################################################
# EKS Add-ons Module - Dev Environment
################################################################################

include "root" {
  path = find_in_parent_folders()
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../../terraform/modules/eks-addons"
}

dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    cluster_name      = "mock-cluster"
    cluster_version   = "1.29"
    oidc_provider_arn = "arn:aws:iam::000000000000:oidc-provider/oidc.eks.us-west-2.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E"
    oidc_provider_url = "https://oidc.eks.us-west-2.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  cluster_name    = dependency.eks.outputs.cluster_name
  cluster_version = dependency.eks.outputs.cluster_version

  oidc_provider_arn = dependency.eks.outputs.oidc_provider_arn
  oidc_provider_url = dependency.eks.outputs.oidc_provider_url

  enable_ebs_csi_driver = true

  tags = {
    Environment = local.env_vars.locals.environment
    Component   = "eks-addons"
  }
}
