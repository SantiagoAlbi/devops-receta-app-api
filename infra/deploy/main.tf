terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.23.0"
    }
  }

  backend "s3" {
    bucket               = "devops-2026-receta-praguensis"
    key                  = "tf-state-deploy"
    workspace_key_prefix = "tf-state-deploy-env"
    region               = "us-east-1"
    encrypt              = true
    dynamodb_table       = "devops-receta-app-api-tf-lock"
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Enviroment = terraform.workspace
      Project    = var.project
      contact    = var.contact
      ManageBy   = "Terraform/deploy"
    }
  }
}

locals {
  prefix = "${var.prefix}-${terraform.workspace}"
}

data "aws_region" "current" {}
