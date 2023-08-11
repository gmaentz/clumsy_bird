terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

locals {
  workspaces = [
    "clumsy-bird-label-${var.environment}",
    "clumsy-bird-network-${var.environment}",
    "clumsy-bird-compute-${var.environment}",
  ]
}

data "tfe_outputs" "workspaces" {
  organization = var.tfc_org
  # for_each     = var.upstream_workspaces
  for_each     = toset(local.workspaces)
  workspace    = each.key
}

locals {
  id   = data.tfe_outputs.workspaces["clumsy-bird-label-${var.environment}"].values.id
  # tags = data.tfe_outputs.workspaces["clumsy-bird-label-${var.environment}"].values.tags
  tags = {
    gabe = "was here"
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~>5.1"

  name = "my-vpc-${local.id}"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1d"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = local.tags
}