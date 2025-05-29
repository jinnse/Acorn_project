# EKS 클러스터 정보
data "aws_eks_cluster" "eks" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "eks" {
  name = var.cluster_name
}

# EKS OIDC Provider 정보
# OIDC Provider 등록
# resource "aws_iam_openid_connect_provider" "oidc" {
#   url = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer

#   client_id_list = ["sts.amazonaws.com"]
#   thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da0afd10df6"]  # AWS OIDC Thumbprint
#   depends_on = [data.aws_eks_cluster.eks]
# }

data "aws_iam_openid_connect_provider" "eks" {
  arn = var.oidc_provider_arn
}

# ALB용 IAM Role 생성
resource "aws_iam_role" "alb_sa_role" {
  name = "eks-alb-controller-role-v2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(data.aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })
}

# ALB 정책 연결 (GitHub에서 다운받은 공식 정책)
resource "aws_iam_role_policy_attachment" "alb_sa_attach" {
  role       = aws_iam_role.alb_sa_role.name
  policy_arn = aws_iam_policy.alb_controller.arn
}

# ELB FullAccess 정책 연결 (보조)
resource "aws_iam_role_policy_attachment" "alb_sa_elb_full_access" {
  role       = aws_iam_role.alb_sa_role.name
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
}


# Kubernetes ServiceAccount 생성 (IAM Role과 연결)

resource "kubernetes_service_account" "alb_sa" {
  provider = kubernetes.eks   
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.alb_sa_role.arn
    }
  }
    depends_on = [ 
    aws_iam_role.alb_sa_role,
    aws_iam_role_policy_attachment.alb_sa_attach,
    data.aws_iam_openid_connect_provider.eks
  ]
}

#aws-auth ConfigMap에 SSO 관리 권한 등록
# resource "kubernetes_config_map" "aws_auth" {
#   provider = kubernetes.eks  
#   metadata {
#     name      = "aws-auth"
#     namespace = "kube-system"
#   }

#   data = {
#     mapRoles = yamlencode([
#       {
#         rolearn  = "arn:aws:sts::886723286293:assumed-role/AWSReservedSSO_AdministratorAccess_be811d95ad9f0f4a/alex941@naver.com",
#         username = "admin",
#         groups   = ["system:masters"]
#       },
#       {
#         rolearn  = var.node_group_role_arn,
#         username = "system:node:{{EC2PrivateDNSName}}",
#         groups   = ["system:bootstrappers", "system:nodes"]
#       }
#     ])
#   }

#   depends_on = [
#     var.cluster_name,
#     var.node_group_role_arn
#   ]
# }
