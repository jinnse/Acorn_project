# vpc 전체 IP 주소 범위
variable "vpc_cidr" {
  description = "CIDR"
  type        = string
  default     = "10.10.10.0/24"
}

# vpc 이름
variable "vpc_name" {
  description = "Name"
  type        = string
  default     = "msa-vpc"
}

# 사용할 가용 영역 리스트트
variable "azs" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]
}

# 퍼블릿 서브넷에 할당할 CIDR 리스트
variable "public_subnet_cidrs" {
  description = "List of CIDRs for public subnets"
  type        = list(string)
  default     = ["10.10.10.0/27", "10.10.10.32/27", "10.10.10.64/27"]
}

# 프라이빗 서브넷에 할당할 CIDR 리스트
variable "private_subnet_cidrs" {
  description = "List of CIDRs for private subnets"
  type        = list(string)
  default     = ["10.10.10.96/27", "10.10.10.128/27", "10.10.10.160/27"]
}

variable "service_names" {
  description = "List of autoscaling group name"
  type        = list(string)
  default     = ["center", "notice", "reg"]
}

variable "key_name" {
  description = "SSH key name"
  type        = string
  default = "mykey-h"
}

#
variable "codeconnection_arn" {
  description   = "code connection arn"
  type          = string
  default       = "arn:aws:codeconnections:ap-northeast-2:387721658341:connection/65722506-54ae-4787-95f2-5bd1bd1fab55"
}

variable "s3_cicd" {
  type = string
  default = "cicd-20250523"
}