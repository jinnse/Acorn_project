# # # 헬름 차트를 이용한 alb-controller 설치치
resource "helm_release" "alb_controller" {
  provider   = helm.eks
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.7.1"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }
    depends_on = [
    aws_iam_role_policy_attachment.alb_sa_attach,
    aws_iam_role_policy_attachment.alb_sa_elb_full_access,
    aws_iam_role_policy_attachment.alb_sa_attach_ec2_describe,
    kubernetes_service_account.alb_sa
  ]

}

