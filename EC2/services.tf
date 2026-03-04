# 서비스들을 위한 private lb
resource "aws_lb" "internal_lbs" {
  count = length(var.service_names)

  name               = "${var.service_names[count.index]}-internal-lb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.private_lb_sg.id]
  subnets            = [for subnet in aws_subnet.private_subnets : subnet.id]

  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}

# internal lb들에 대한 listener
resource "aws_lb_listener" "front_end" {
  count = length(var.service_names)

  load_balancer_arn = aws_lb.internal_lbs[count.index].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal_lb_target_groups[count.index].arn
  }
}

# 서비스들에 대한 lb target group 목록
resource "aws_lb_target_group" "internal_lb_target_groups" {
  count = length(var.service_names)

  name     = "${var.service_names[count.index]}-lb-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.msa_vpc.id

  health_check {
    interval            = 30      # 헬스체크 주기 (초)
    timeout             = 5       # 헬스체크 타임아웃 (초)
    healthy_threshold   = 3       # 정상 판정 횟수
    unhealthy_threshold = 2       # 비정상 판정 횟수
    path                = "/${var.service_names[count.index]}/healthz"     # 헬스체크 요청 경로
    matcher             = "200-299" # 정상 응답 범위
    protocol            = "HTTP"
  }
}

# 모든 서비스들에 대한 오토스케일링 그룹
resource "aws_autoscaling_group" "service_asgs" {
  count = length(var.service_names)

  name                      = "${var.service_names[count.index]}-asg"
  max_size                  = 1
  min_size                  = 1
  health_check_grace_period = 30
  health_check_type         = "ELB"
  desired_capacity          = 1
  force_delete              = true
  vpc_zone_identifier       = [for subnet in aws_subnet.private_subnets: subnet.id]
  target_group_arns         = [aws_lb_target_group.internal_lb_target_groups[count.index].arn]

  instance_maintenance_policy {
    min_healthy_percentage = 80
    max_healthy_percentage = 120
  }

  tag {
    key                 = "Name"
    value               = var.service_names[count.index]
    propagate_at_launch = true
  }

  launch_template {
    id      = aws_launch_template.server_lt.id
    version = "$Latest"
  }
}

data "aws_ami" "server_ami" {
  owners = ["self"]

  filter {
    name   = "name"
    values = ["server-base"]
  }
}

# Auto Scaling 그룹 설정 (예제)
resource "aws_launch_template" "server_lt" {
  name_prefix   = "app-lt-"
  image_id      = data.aws_ami.server_ami.image_id
  instance_type = "t3.small"

  iam_instance_profile {
    name = aws_iam_instance_profile.codedeploy_profile.name
  }

  key_name = var.key_name

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.web_sg.id]
  }
}

# EC2 인스턴스 프로필 생성
resource "aws_iam_instance_profile" "codedeploy_profile" {
  name = "codedeploy-ec2-profile"
  role = aws_iam_role.ec2_codedeploy_role.name
}

resource "aws_iam_role" "ec2_codedeploy_role" {
  name               = "ec2-codedeploy-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

# EC2가 SecretManager에 접근할 수 있는 권한
resource "aws_iam_role_policy_attachment" "ec2_secrets_manager_role" {
  role       = aws_iam_role.ec2_codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_role_policy_attachment" "ec2_policy_attachment" {
  role       = aws_iam_role.ec2_codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# EC2가 S3 버킷에서 아티팩트를 가져올 수 있는 권한
resource "aws_iam_role_policy" "s3_artifact_access" {
  name   = "s3-artifact-access"
  role   = aws_iam_role.ec2_codedeploy_role.id
  policy = data.aws_iam_policy_document.s3_artifact_access.json
}

data "aws_iam_policy_document" "s3_artifact_access" {
  statement {
    effect = "Allow"
    actions = ["s3:GetObject", "s3:ListBucket"]
    resources = [
      data.aws_s3_bucket.cicd.arn,
      "${data.aws_s3_bucket.cicd.arn}/*",
    ]
  }
}

resource "aws_instance" "bastion" {
  ami                         = "ami-05a7f3469a7653972"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_subnets[0].id
  key_name                    = "mykey-h"
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "bastion"
  }

  user_data = <<-EOF
          #!/bin/bash
          apt-get update
          EOF
}