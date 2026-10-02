# -----------------------------------------------------------------------------
# Bootstrap: the two things every other part of the course depends on.
#
#   1. An S3 bucket where Terraform keeps its "state": its record of what it
#      has built. Every later folder stores its state here.
#   2. A budget alarm that emails you if your AWS spending heads toward $10.
#
# This folder is special: it keeps its own state on your laptop, because the
# bucket that will hold everyone else's state doesn't exist until it runs.
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile

  # Every resource gets these labels, so you can always tell what belongs to the course.
  default_tags {
    tags = {
      Project   = "cloud-devops-course"
      Stack     = "00-bootstrap"
      ManagedBy = "terraform"
    }
  }
}

# Look up which AWS account and region we're in.
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id   = data.aws_caller_identity.current.account_id
  state_bucket = "tfstate-${local.account_id}-${data.aws_region.current.region}"
}

# --- 1. The state bucket -----------------------------------------------------

resource "aws_s3_bucket" "state" {
  bucket = local.state_bucket

  # Lets the final teardown in Week 6 delete the bucket even though it has files in it.
  force_destroy = true
}

# Keep every old version of the state file, so a mistake can be undone.
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encrypt everything stored in the bucket.
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Make sure nothing in this bucket can ever be made public.
resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- 2. The budget alarm -----------------------------------------------------

resource "aws_budgets_budget" "monthly" {
  name         = "cloud-devops-course-monthly"
  budget_type  = "COST"
  limit_amount = var.budget_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  # Email when you've actually spent half your budget...
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 50
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  # ...when you've spent all of it...
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  # ...and when AWS predicts you'll go over by the end of the month.
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }
}

# --- 3. A settings file for every other folder -------------------------------
# Every later folder needs to know the bucket's name to store its state there.
# The name includes your account ID, so instead of making you type it, we write
# it into infra/backend.hcl for you.

resource "local_file" "backend_config" {
  filename        = "${path.module}/../backend.hcl"
  file_permission = "0644"
  content         = <<-EOT
    # Written by infra/00-bootstrap. Every other folder uses this with:
    #   terraform init -backend-config=../backend.hcl
    bucket       = "${aws_s3_bucket.state.bucket}"
    region       = "${data.aws_region.current.region}"
    profile      = "${var.aws_profile}"
    encrypt      = true
    use_lockfile = true
  EOT
}
