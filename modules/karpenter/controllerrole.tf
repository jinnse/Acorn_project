# 1. AssumeRole Policy (OIDC/ServiceAccount 연결)
data "aws_iam_policy_document" "karpenter_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.eks.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:karpenter:karpenter"]
    }
  }
}

# 2. Controller용 Role 생성
resource "aws_iam_role" "karpenter_controller" {
  name = "karpenter-controller"
  assume_role_policy = data.aws_iam_policy_document.karpenter_assume_role.json
}

# 3. Karpenter Controller Policy (공식 권장 최소 권한)
data "aws_iam_policy_document" "karpenter_controller_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:Describe*",
      "ec2:TerminateInstances",
      "ec2:RunInstances",
      "ec2:CreateFleet",
      "ec2:CreateLaunchTemplate",
      "ec2:CreateTags",
      "ec2:DeleteLaunchTemplate",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeInstances",
      "ec2:DescribeImages",
      "ec2:DescribeSecurityGroups",
      "iam:PassRole",
      "ssm:GetParameter",
      "eks:DescribeCluster",
      "pricing:GetProducts",
      "ec2:DescribeSpotPriceHistory",  
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeInstanceTypeOfferings",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeSubnets",
      "ec2:DescribePlacementGroups",
      "ec2:GetLaunchTemplateData",
      "ec2:CreateLaunchTemplateVersion",
      "ec2:ModifyInstanceAttribute",
      "ec2:DescribeVolumes",
      "ec2:AttachVolume",
      "elasticloadbalancing:*"
      # 필요에 따라 공식문서에서 추가 권한 더 삽입
    ]
    resources = ["*"]
  }

}

# 4. 위 Policy를 실제 AWS에 생성
resource "aws_iam_policy" "karpenter_controller" {
  name   = "KarpenterControllerPolicy"
  policy = data.aws_iam_policy_document.karpenter_controller_policy.json
  
  lifecycle {
    create_before_destroy = true
  }
}

# 5. Policy를 Role에 Attach
resource "aws_iam_role_policy_attachment" "karpenter_controller" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_controller.arn
}
