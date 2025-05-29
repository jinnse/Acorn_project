variable "cluster_name" {
  description = "EKS 클러스터 이름"
  type        = string
  default     = "univ-eks"
}

variable "region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "eks_cluster_endpoint" {
  description = "EKS 클러스터 API 서버 endpoint"
  type        = string
  default     = "https://dummy"
}

variable "eks_cluster_ca" {
  description = "EKS 클러스터 인증서 (base64 encoded)"
  type        = string
  default     = "ZHVtbXk="  # base64로 'dummy'
}

variable "eks_cluster_name" {
  description = "EKS 클러스터 이름 (Helm/K8s provider 용)"
  type        = string
  default     = "univ-eks"
}

