terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "restockiq-terraform-state"
    key            = "terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "restockiq-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}