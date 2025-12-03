################################################################################
# IRSA Module Variables
################################################################################

variable "role_name" {
  description = "Name of the IAM role"
  type        = string
}

variable "role_description" {
  description = "Description of the IAM role"
  type        = string
  default     = "IRSA role for Kubernetes service account"
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the OIDC provider"
  type        = string
}

variable "service_accounts" {
  description = "List of service accounts to associate with this role"
  type = list(object({
    namespace = string
    name      = string
  }))
}

variable "policy_arns" {
  description = "List of IAM policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}

variable "inline_policy" {
  description = "Inline policy JSON to attach to the role"
  type        = string
  default     = ""
}

variable "assume_role_condition_test" {
  description = "Condition test for the assume role policy (StringEquals or StringLike)"
  type        = string
  default     = "StringEquals"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
