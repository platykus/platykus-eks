terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.22.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.12.1"
    }
  }

  required_version = ">= 1.2"
}

locals {
  platform      = "platykus"
  identity      = "${var.system}-${var.environment}"
  identity_tags = {
    "${local.platform}/system"      = var.system
    "${local.platform}/environment" = var.environment
  }
  tags = merge(var.tags, local.identity_tags)
}

provider "aws" {
  region = var.aws_region
}

resource "aws_resourcegroups_group" "this" {
  name = local.identity
  tags = local.tags

  resource_query {
    query = <<JSON
{
  "ResourceTypeFilters": [
    "AWS::EC2::Instance"
  ],
  "TagFilters": [
    {
      "Key": "${local.platform}/system",
      "Values": ["${var.system}"]
    },
    {
      "Key": "${local.platform}/environment",
      "Values": ["${var.environment}"]
    }
  ]
}
JSON
  }
}

