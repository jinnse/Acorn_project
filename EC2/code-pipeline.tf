# 각 서비스별로 CodePipeline 생성
resource "aws_codepipeline" "service_pipeline" {
  count    = length(var.service_names)
  name     = "${var.service_names[count.index]}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  pipeline_type = "V2"

  artifact_store {
    location = data.aws_s3_bucket.cicd.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = var.codeconnection_arn
        FullRepositoryId = "seminchoi/sample-codes"
        BranchName       = "aws-${var.service_names[count.index]}"
      }
    }
  }

  # Git Trigger 추가
  trigger {
    provider_type = "CodeStarSourceConnection"

    git_configuration {
      source_action_name = "Source"

      push {
        branches {
          includes = ["aws-${var.service_names[count.index]}"]
        }
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.codebuild_projects[count.index].name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ApplicationName     = aws_codedeploy_app.service_apps[count.index].name
        DeploymentGroupName = aws_codedeploy_deployment_group.service_deploy_groups[count.index].deployment_group_name
      }
    }
  }
}

# CodePipeline IAM 역할
data "aws_iam_policy_document" "pipeline_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name               = "codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.pipeline_assume_role.json
}

resource "aws_iam_role_policy_attachment" "codepipeline_policy_attachment" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "codepipeline-policy"
  role   = aws_iam_role.codepipeline_role.id
  policy = data.aws_iam_policy_document.codepipeline_policy.json
}

data "aws_iam_policy_document" "codepipeline_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObject"
    ]
    resources = [
      data.aws_s3_bucket.cicd.arn,
      "${data.aws_s3_bucket.cicd.arn}/*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetApplication",
      "codedeploy:GetApplicationRevision",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:RegisterApplicationRevision"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "codeconnections:UseConnection"
    ]
    resources = [
      var.codeconnection_arn
    ]
  }
}

