# -----------------------------------------------------------------------------
# The app: Neighborhood Eats, live on the internet.
#
# Three pieces, and the order matters:
#
#   alb.tf      a load balancer in the PUBLIC subnets. The only part of your
#               network the internet can reach.
#   server.tf   one EC2 server in a PRIVATE subnet. It has no public address.
#               Visitors never talk to it directly.
#   iam.tf      the permissions that let the server read its own secrets and
#               let you log in without any SSH keys.
#
# Together they're the standard shape of a web application on AWS.
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "s3" {
    key = "03-app/terraform.tfstate"
  }
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project   = "cloud-devops-course"
      Stack     = "03-app"
      ManagedBy = "terraform"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  state_bucket = "tfstate-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}"
}

# This folder needs both of the earlier stacks: the network for its subnets,
# and the database for its address and its secrets.
data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket  = local.state_bucket
    key     = "01-network/terraform.tfstate"
    region  = var.region
    profile = var.aws_profile
  }
}

data "terraform_remote_state" "database" {
  backend = "s3"

  config = {
    bucket  = local.state_bucket
    key     = "02-database/terraform.tfstate"
    region  = var.region
    profile = var.aws_profile
  }
}

locals {
  vpc_id             = data.terraform_remote_state.network.outputs.vpc_id
  public_subnet_ids  = data.terraform_remote_state.network.outputs.public_subnet_ids
  private_subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids

  db_endpoint      = data.terraform_remote_state.database.outputs.db_endpoint
  db_port          = data.terraform_remote_state.database.outputs.db_port
  db_name          = data.terraform_remote_state.database.outputs.db_name
  db_secret_arn    = data.terraform_remote_state.database.outputs.db_secret_arn
  db_sg_id         = data.terraform_remote_state.database.outputs.db_security_group_id
  yelp_secret_arn  = data.terraform_remote_state.database.outputs.yelp_secret_arn
  yelp_secret_name = data.terraform_remote_state.database.outputs.yelp_secret_name
}
