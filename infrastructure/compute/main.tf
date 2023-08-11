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

data "tfe_outputs" "workspaces" {
  organization = var.tfc_org
  # for_each     = var.upstream_workspaces
  for_each  = toset(local.workspaces)
  workspace = each.key
}


locals {
  workspaces = [
    "clumsy-bird-label-${var.environment}",
    "clumsy-bird-network-${var.environment}",
    "clumsy-bird-compute-${var.environment}",
  ]
  workspaces_names = {
    "deploy"  = "clumsy-bird-deploy-${var.environment}"
    "label"   = "clumsy-bird-label-${var.environment}"
    "network" = "clumsy-bird-network-${var.environment}"
    "compute" = "clumsy-bird-compute-${var.environment}"
  }
}

data "tfe_workspace" "workspaces" {
  organization = var.tfc_org
  for_each     = toset(local.workspaces)
  name         = each.key
}

locals {
  id   = data.tfe_outputs.workspaces["clumsy-bird-label-${var.environment}"].values.id
  # tags = data.tfe_outputs.workspaces["clumsy-bird-label-${var.environment}"].values.tags
  tags = {
    Environment = "dev"
  }
}

resource "aws_security_group" "clumsy_bird" {
  description = "Clumsy Bird Security Group Access"
  name        = "${local.id}-security-group"

  vpc_id = data.tfe_outputs.workspaces["clumsy-bird-network-${var.environment}"].values.vpc-id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8001
    to_port     = 8001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_eip" "clumsy_bird" {
  instance = aws_instance.clumsy_bird.id
  domain   = "vpc"
  tags     = data.tfe_outputs.workspaces["clumsy-bird-label-${var.environment}"].values.tags
}

resource "aws_eip_association" "clumsy_bird" {
  instance_id   = aws_instance.clumsy_bird.id
  allocation_id = aws_eip.clumsy_bird.id
}

resource "aws_instance" "clumsy_bird" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  associate_public_ip_address = true
  subnet_id                   = element(data.tfe_outputs.workspaces["clumsy-bird-network-${var.environment}"].values.public_subnets, 0)
  vpc_security_group_ids      = [aws_security_group.clumsy_bird.id]

  user_data = templatefile("${path.module}/application-files/deploy_app.sh", {})

  tags = local.tags
}

module "s3_bucket" {
  source        = "terraform-aws-modules/s3-bucket/aws"
  version       = "~>3.14"
  bucket_prefix = local.id
  acl           = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  versioning = {
    enabled = true
  }

  tags = local.tags
}