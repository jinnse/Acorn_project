variable "region" {
  description = "Name"
  type = string
  default = "ap-northeast-2"
}
variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "univ-eks"
}
variable "vpc_id" {
  description = "Name"
  type        = string
  default     = "eks-vpc"
}
variable "node_group_role_arn" {
  description = "EKS Node Group IAM Role ARN"
  type        = string
}

variable "oidc_provider_arn" {
  description = "OIDC Provider ARN passed from root module"
  type        = string
}