# # provider "aws" {
# #   region = "ap-northeast-2"
# # }

# # # 가격 조회용
# # provider "aws" {
# #   alias = "use1"
# #   region = "us-east-1"
# # }

# # provider "kubernetes" {
# #   alias = "eks"
# #   host                   = var.eks_cluster_endpoint != "https://dummy" ? var.eks_cluster_endpoint : null
# #   cluster_ca_certificate = var.eks_cluster_ca != "ZHVtbXk=" ? base64decode(var.eks_cluster_ca) : null
# #   token                  = var.eks_cluster_ca != "ZHVtbXk=" ? data.aws_eks_cluster_auth.eks.token : null
# # }

# # provider "helm" {
# #   alias = "eks"
# #   kubernetes {
# #     host                   = var.eks_cluster_endpoint != "https://dummy" ? var.eks_cluster_endpoint : null
# #     cluster_ca_certificate = var.eks_cluster_ca != "ZHVtbXk=" ? base64decode(var.eks_cluster_ca) : null
# #     token                  = var.eks_cluster_ca != "ZHVtbXk=" ? data.aws_eks_cluster_auth.eks.token : null
# #   }
# # }
# # data "aws_eks_cluster_auth" "eks" {
# #   name = var.eks_cluster_name
# # }

# # data "aws_eks_cluster" "eks" {
# #   name = var.eks_cluster_name
# # }

# provider "aws" {
#   region = "ap-northeast-2"
# }

# # 가격 조회용 (미국 동부)
# provider "aws" {
#   alias  = "use1"
#   region = "us-east-1"
# }

# # Kubernetes Provider (EKS 연동)
# provider "kubernetes" {
#   alias = "eks"
#   host                   = var.eks_cluster_endpoint != "https://dummy" ? var.eks_cluster_endpoint : null
#   cluster_ca_certificate = var.eks_cluster_ca != "ZHVtbXk=" ? base64decode(var.eks_cluster_ca) : null

#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "aws"
#     args        = [
#       "eks",
#       "get-token",
#       "--cluster-name", var.eks_cluster_name,
#       "--region", "ap-northeast-2",
#       "--profile", "sso-admin"
#     ]
#   }
# }

# # Helm Provider (kubernetes 내부로 helm install 할 때 사용)
# provider "helm" {
#   alias = "eks"
#   kubernetes {
#     host                   = var.eks_cluster_endpoint != "https://dummy" ? var.eks_cluster_endpoint : null
#     cluster_ca_certificate = var.eks_cluster_ca != "ZHVtbXk=" ? base64decode(var.eks_cluster_ca) : null

#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       command     = "aws"
#       args        = [
#         "eks",
#         "get-token",
#         "--cluster-name", var.eks_cluster_name,
#         "--region", "ap-northeast-2",
#         "--profile", "sso-admin"
#       ]
#     }
#   }
# }

# # EKS 인증 정보
# data "aws_eks_cluster" "eks" {
#   name = var.eks_cluster_name
# }

# data "aws_eks_cluster_auth" "eks" {
#   name = var.eks_cluster_name
# }


provider "aws" {
  region  = "ap-northeast-2"
}

provider "aws" {
  alias   = "use1"
  region  = "us-east-1"
}

provider "kubernetes" {
  alias = "eks"
  host                   = var.eks_cluster_endpoint != "https://dummy" ? var.eks_cluster_endpoint : null
  cluster_ca_certificate = var.eks_cluster_ca != "ZHVtbXk=" ? base64decode(var.eks_cluster_ca) : null

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = [
      "eks",
      "get-token",
      "--cluster-name", var.eks_cluster_name,
      "--region", "ap-northeast-2"
    ]
  }
}

provider "helm" {
  alias = "eks"
  kubernetes {
    host                   = var.eks_cluster_endpoint != "https://dummy" ? var.eks_cluster_endpoint : null
    cluster_ca_certificate = var.eks_cluster_ca != "ZHVtbXk=" ? base64decode(var.eks_cluster_ca) : null

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = [
          "eks",
          "get-token",
          "--cluster-name", var.eks_cluster_name,
          "--region", "ap-northeast-2"
      ]
    }
  }
}

data "aws_eks_cluster" "eks" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "eks" {
  name = var.eks_cluster_name
}