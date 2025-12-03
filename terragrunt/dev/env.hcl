################################################################################
# Dev Environment Variables
################################################################################

locals {
  environment = "dev"
  aws_region  = "us-west-2"
  account_id  = "YOUR_AWS_ACCOUNT_ID"  # Replace with your AWS account ID

  # VPC Configuration
  vpc_cidr       = "10.0.0.0/16"
  az_count       = 3
  single_nat     = true  # Cost savings for dev

  # EKS Configuration
  cluster_name    = "eks-dev-cluster"
  cluster_version = "1.29"

  # Node Group Configuration
  default_node_instance_types = ["t3.medium", "t3.large"]
  default_node_desired_size   = 2
  default_node_min_size       = 1
  default_node_max_size       = 5

  # GPU Node Group (disabled by default for cost)
  enable_gpu_nodes         = false
  gpu_node_instance_types  = ["g4dn.xlarge"]
  gpu_node_desired_size    = 0
  gpu_node_min_size        = 0
  gpu_node_max_size        = 2
}
