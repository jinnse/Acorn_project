# eks 클러스터 설정
resource "aws_eks_cluster" "univ_eks" {
  name     = var.cluster_name
  version  = var.cluster_version

  access_config {
    authentication_mode = "API"
  }

  role_arn = aws_iam_role.univ_eks_role.arn

  vpc_config {
    subnet_ids = var.private_subnet_ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.univ_eks_role_attachment
  ]
}

resource "aws_iam_role" "univ_eks_role" {
  name = "univ_eks_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "univ_eks_role_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.univ_eks_role.name
}

# eks node group 설정
resource "aws_eks_node_group" "univ_ng" {
  cluster_name    = aws_eks_cluster.univ_eks.name
  node_group_name = "univ_ng"
  node_role_arn   = aws_iam_role.univ_nodegroup_role.arn
  subnet_ids      = var.private_subnet_ids
  instance_types = ["m7g.xlarge"]
  ami_type       = "AL2_ARM_64"
  #instance_types = ["m5.xlarge"]
  scaling_config {
    desired_size = 3
    max_size     = 4
    min_size     = 3
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.univ-ng-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.univ-ng-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.univ-ng-AmazonEC2ContainerRegistryReadOnly
  ]
}

resource "aws_iam_role" "univ_nodegroup_role" {
  name = "univ_nodegroup_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "univ-ng-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.univ_nodegroup_role.name
}

resource "aws_iam_role_policy_attachment" "univ-ng-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.univ_nodegroup_role.name
}

resource "aws_iam_role_policy_attachment" "univ-ng-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.univ_nodegroup_role.name
}

resource "aws_iam_role_policy_attachment" "ebs_csi_policy" {
  role       = aws_iam_role.univ_nodegroup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# 현재 AWS 계정 ID를 가져오기 위한 데이터 소스
data "aws_caller_identity" "current" {}

resource "aws_eks_access_entry" "sso_admin" {
  cluster_name  = aws_eks_cluster.univ_eks.name
  principal_arn = "arn:aws:iam::886723286293:role/aws-reserved/sso.amazonaws.com/ap-northeast-2/AWSReservedSSO_AdministratorAccess_be811d95ad9f0f4a"
}

resource "aws_eks_access_policy_association" "sso_admin_policy" {
  cluster_name  = aws_eks_cluster.univ_eks.name
  principal_arn = aws_eks_access_entry.sso_admin.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

resource "aws_iam_openid_connect_provider" "oidc" {
  url = aws_eks_cluster.univ_eks.identity[0].oidc[0].issuer
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da0ecd2e0f4"]
}