################################################################################
# Root Terragrunt Configuration
# DRY configuration for all environments
################################################################################

locals {
  # Parse the file path to get environment information
  parsed      = regex(".*/terragrunt/(?P<env>[^/]+)/.*", get_terragrunt_dir())
  environment = local.parsed.env

  # Load environment-specific variables
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # Common variables
  project_name = "devops-experiment"
  aws_region   = local.env_vars.locals.aws_region
  account_id   = local.env_vars.locals.account_id
}

# Generate provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "${local.aws_region}"

  default_tags {
    tags = {
      Environment = "${local.environment}"
      Project     = "${local.project_name}"
      ManagedBy   = "Terragrunt"
      Repository  = "devops-experiment"
    }
  }
}
EOF
}

# Remote state configuration
remote_state {
  backend = "s3"
  config = {
    encrypt        = true
    bucket         = "${local.project_name}-terraform-state-${local.account_id}"
    key            = "${local.environment}/${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    dynamodb_table = "${local.project_name}-terraform-locks"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Default inputs for all modules
inputs = {
  environment  = local.environment
  project_name = local.project_name
  aws_region   = local.aws_region

  tags = {
    Environment = local.environment
    Project     = local.project_name
    ManagedBy   = "Terragrunt"
  }
}
