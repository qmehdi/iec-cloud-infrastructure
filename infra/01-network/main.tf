# -----------------------------------------------------------------------------
# The network: your own private slice of AWS, called a VPC (Virtual Private
# Cloud). Everything we build in later weeks lives inside it.
#
# This file sets up Terraform itself. The network is in the other .tf files:
#   vpc.tf      the VPC
#   public.tf   public subnets and the internet gateway
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Store this folder's state in the bucket from 00-bootstrap.
  # The bucket name comes from infra/backend.hcl:
  #   terraform init -backend-config=../backend.hcl
  backend "s3" {
    key = "01-network/terraform.tfstate"
  }
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project   = "cloud-devops-course"
      Stack     = "01-network"
      ManagedBy = "terraform"
    }
  }
}

# Every AWS region is split into separate data centers called availability
# zones (AZs). We spread the network across two of them, so one data center
# having a bad day can't take everything down.
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}
