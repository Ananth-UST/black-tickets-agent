terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "blacktickets-dev-tfstate"
    key            = "blacktickets/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "blacktickets-dev-terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
