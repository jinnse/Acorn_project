terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      configuration_aliases = [aws, aws.use1]
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      configuration_aliases = [kubernetes]
    }
    helm = {
      source = "hashicorp/helm"
      configuration_aliases = [helm]
    }
  }
}
