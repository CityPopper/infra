terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = "~> 1.0.0"

  backend "s3" {
    bucket = "Replace using backend-config option"
    key    = "Replace using backend-config option"
  }
}

provider "aws" {
  profile = "default"
  region  = var.region

  default_tags {
    tags = { terraform : "true" }
  }
}
