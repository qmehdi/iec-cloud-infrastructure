# -----------------------------------------------------------------------------
# The database: a PostgreSQL server that AWS runs for you.
#
# This is the first "managed service" in the course. You don't install
# PostgreSQL, you don't patch it, and you never see its password. You describe
# the database you want and AWS operates it.
#
# This file sets up Terraform and finds last week's network. The database
# itself is in the other .tf files:
#   security.tf   who is allowed to connect
#   rds.tf        the database
#   secrets.tf    a safe place for the Yelp API key
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project   = "cloud-devops-course"
      Stack     = "02-database"
      ManagedBy = "terraform"
    }
  }
}

# -----------------------------------------------------------------------------
# Reading last week's work.
#
# The network lives in its own folder, with its own state file. Rather than
# repeat the subnet IDs here (and get them wrong), we read them straight out
# of 01-network's state. This is how real projects join stacks together.
#
# That path is relative to this folder, so it only works if you ran
# `terraform apply` in infra/01-network first. If Terraform says it can't find
# the file, that's the step you missed.
# -----------------------------------------------------------------------------
data "terraform_remote_state" "network" {
  backend = "local"

  config = {
    path = "../01-network/terraform.tfstate"
  }
}

locals {
  vpc_id             = data.terraform_remote_state.network.outputs.vpc_id
  private_subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids
}
