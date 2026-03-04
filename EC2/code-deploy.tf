# CodeDeploy용 IAM 역할
data "aws_iam_policy_document" "codedeploy_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codedeploy_role" {
  name               = "codedeploy-role"
  assume_role_policy = data.aws_iam_policy_document.codedeploy_assume_role.json
}

# CodeDeploy 기본 정책 연결
resource "aws_iam_role_policy_attachment" "codedeploy_policy_attachment" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

resource "aws_iam_role_policy_attachment" "codedeploy_policy_attachment_admin" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# # CodeDeploy에서 Auto Scaling 그룹에 액세스할 수 있는 정책
# resource "aws_iam_role_policy_attachment" "codedeploy_autoscaling_attachment" {
#   role       = aws_iam_role.codedeploy_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
# }
#

# 각 서비스별로 CodeDeploy 애플리케이션 생성
resource "aws_codedeploy_app" "service_apps" {
  count         = length(var.service_names)
  name          = "${var.service_names[count.index]}-service"
  compute_platform = "Server"
}

# 각 서비스별로 CodeDeploy 배포 그룹 생성
resource "aws_codedeploy_deployment_group" "service_deploy_groups" {
  count                  = length(var.service_names)
  app_name               = aws_codedeploy_app.service_apps[count.index].name
  deployment_group_name  = "${var.service_names[count.index]}-deploy-group"
  service_role_arn       = aws_iam_role.codedeploy_role.arn
  deployment_config_name = "CodeDeployDefault.OneAtATime"

  autoscaling_groups = [aws_autoscaling_group.service_asgs[count.index].id]

  deployment_style {
    deployment_type   = "IN_PLACE"
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
  }

  # load_balancer_info {
  #   elb_info {
  #     name = aws_lb.internal_lbs[count.index].name
  #   }
  #   target_group_info {
  #     name = aws_lb_target_group.internal_lb_target_groups[count.index].name
  #   }
  # }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}



# EC2 인스턴스 프로필용 IAM 역할
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
