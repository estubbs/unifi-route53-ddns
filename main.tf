terraform {
  backend "s3" {
    bucket = "estubbs-terraformstate"
    region = "us-east-1"
    key    = "k8scluster"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.76.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = var.common_tags
  }
}
