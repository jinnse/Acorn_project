resource "helm_release" "karpenter" {
  name       = "karpenter"
  repository = "https://charts.karpenter.sh"
  chart      = "karpenter"
  version    = "0.16.3"

  namespace        = "karpenter"
  create_namespace = true

  set {
    name  = "serviceAccount.name"
    value = "karpenter"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.karpenter_controller.arn
  }

  set {
    name  = "settings.aws.defaultInstanceProfile"
    value = aws_iam_instance_profile.karpenter_node.name
  }


  set {
    name  = "controller.env[0].name"
    value = "CLUSTER_NAME"
  }
  set {
    name  = "controller.env[0].value"
    value = var.cluster_name
  }
  set {
    name  = "controller.env[1].name"
    value = "CLUSTER_ENDPOINT"
  }
  set {
    name  = "controller.env[1].value"
    value = var.cluster_endpoint
  }
}
