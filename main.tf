terraform {
  backend "s3" {
    bucket = "estubbs-terraformstate"
    region = "us-east-1"
    key    = "unifi-route53-ddns"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.76.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.6.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = var.common_tags
  }
}
