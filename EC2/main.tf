module "eks_cicd" {
  source        = "./eks-cicd"  # 모듈 경로 또는 원격 주소
  vpc_id        = aws_vpc.msa_vpc.id
  public_subnet_ids = [ for subnet in aws_subnet.public_subnets: subnet.id ]
  private_subnet_ids = [ for subnet in aws_subnet.private_subnets: subnet.id ]
  service_names = var.service_names
  codeconnection_arn = var.codeconnection_arn
  s3_cicd = var.s3_cicd
  codebuild_role_name = aws_iam_role.code_build_role.name
  codebuild_role_arn = aws_iam_role.code_build_role.arn
  codepipeline_role_name = aws_iam_role.codepipeline_role.name
  codepipeline_role_arn = aws_iam_role.codepipeline_role.arn
}