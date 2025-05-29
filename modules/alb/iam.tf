# ALB 설치할 때 필요한 IAM 정책 정의
data "http" "alb_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.1/docs/install/iam_policy.json"
}

# ALB 컨트롤러 전용 IAM 정책 생성 (공식 정책)
resource "aws_iam_policy" "alb_controller" {
  name   = "AWSLoadBalancerControllerIAMPolicy-v2"
  policy = data.http.alb_policy.response_body
}

# EC2 리소스 접근 허용 (서브넷, SG 등)
resource "aws_iam_policy" "alb_controller_ec2_describe" {
  name   = "ALBControllerEC2DescribePolicy-v2"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:Describe*",
          "ec2:CreateSecurityGroup",
          "ec2:CreateTags",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DeleteSecurityGroup"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "alb_sa_attach_ec2_describe" {
  role       = aws_iam_role.alb_sa_role.name
  policy_arn = aws_iam_policy.alb_controller_ec2_describe.arn
}
