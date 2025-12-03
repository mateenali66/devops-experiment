################################################################################
# Production Environment Variables
################################################################################

locals {
  environment = "prod"
  aws_region  = "us-west-2"
  account_id  = "YOUR_AWS_ACCOUNT_ID"  # Replace with your AWS account ID

  # VPC Configuration
  vpc_cidr       = "10.1.0.0/16"
  az_count       = 3
  single_nat     = false  # High availability for production

  # EKS Configuration
  cluster_name    = "eks-prod-cluster"
  cluster_version = "1.29"

  # Node Group Configuration
  default_node_instance_types = ["m6i.large", "m6i.xlarge"]
  default_node_desired_size   = 3
  default_node_min_size       = 2
  default_node_max_size       = 10

  # GPU Node Group
  enable_gpu_nodes         = true
  gpu_node_instance_types  = ["g4dn.xlarge", "g4dn.2xlarge", "p3.2xlarge"]
  gpu_node_desired_size    = 1
  gpu_node_min_size        = 0
  gpu_node_max_size        = 5
}
