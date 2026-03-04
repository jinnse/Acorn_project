# CICD 에서 빌드 된 애플리케이션 파일을 저장하거나 필요한 캐시 파일을 저장하는 버킷
data "aws_s3_bucket" "cicd" {
  bucket = var.s3_cicd
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "code_build_role" {
  name               = "code-build-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "aws_code_build_role_attach" {
  role       = aws_iam_role.code_build_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess"
}

resource "aws_iam_role_policy_attachment" "secret_manager_attach" {
  role       = aws_iam_role.code_build_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_role_policy_attachment" "codebuild_admin_attach" {
  role       = aws_iam_role.code_build_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role_policy" "s3_access_policy" {
  role   = aws_iam_role.code_build_role.name
  policy = data.aws_iam_policy_document.s3_access.json
}

data "aws_iam_policy_document" "s3_access" {
  statement {
    effect = "Allow"
    actions = ["s3:*"]
    resources = [
      data.aws_s3_bucket.cicd.arn,
      "${data.aws_s3_bucket.cicd.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "ec2_network" {
  role   = aws_iam_role.code_build_role.name
  policy = data.aws_iam_policy_document.ec2-network.json
}

data "aws_iam_policy_document" "ec2-network" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:*",
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeVpcs",
      "ec2:AttachNetworkInterface",
      "ec2:ModifyNetworkInterfaceAttribute",
      "ec2:AssignPrivateIpAddresses",
      "ec2:UnassignPrivateIpAddresses",
      "ec2:CreateTags"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "cloudwatch_logs_inline_policy" {
  name   = "CloudWatchLogsInlinePolicy"
  role   = aws_iam_role.code_build_role.name
  policy = data.aws_iam_policy_document.cloudwatch_logs_policy.json
}

data "aws_iam_policy_document" "cloudwatch_logs_policy" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      # "arn:aws:logs:*:log-group:cicd-group:*"
      "*"
    ]
  }
}

data "aws_iam_policy_document" "codeconnections_policy" {
  statement {
    effect = "Allow"
    actions = [
      "codeconnections:*"
    ]
    resources = [
      "arn:aws:codeconnections:ap-northeast-2:118500955862:connection/4321c421-937d-4115-ac26-827d09a4cd73"
    ]
  }
}

resource "aws_iam_role_policy" "codeconnections_policy" {
  name   = "codeconnections-policy"
  role   = aws_iam_role.code_build_role.id
  policy = data.aws_iam_policy_document.codeconnections_policy.json
}

resource "aws_codebuild_project" "codebuild_projects" {
  count         = length(var.service_names)

  name          = "${var.service_names[count.index]}-service"
  description   = "${var.service_names[count.index]}-service"
  build_timeout = 5
  service_role  = aws_iam_role.code_build_role.arn

  artifacts {
    type     = "S3"
    location = data.aws_s3_bucket.cicd.bucket
    name     = "${var.service_names[count.index]}-service"
  }

  cache {
    type     = "S3"
    location = data.aws_s3_bucket.cicd.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "cicd-group"
      stream_name = "${var.service_names[count.index]}-service-stream"
    }
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/seminchoi/sample-codes.git"
    git_clone_depth = 1
  }

  source_version = "aws-${var.service_names[count.index]}"

  vpc_config {
    vpc_id = aws_vpc.msa_vpc.id

    subnets = [for subnet in aws_subnet.private_subnets : subnet.id]

    security_group_ids = [aws_security_group.codebuild_sg.id]
  }

  tags = {
    Environment = "build"
  }
}

resource "aws_security_group" "codebuild_sg" {
  name        = "codebuild-sg"
  description = "codebuild-sg"
  vpc_id      = aws_vpc.msa_vpc.id

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "codebuild_sg"
  }
}