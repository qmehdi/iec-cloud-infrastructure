# -----------------------------------------------------------------------------
# Bootstrap: the safety net you put in place before you build anything else.
#
# One thing lives here: a budget alarm that emails you if your AWS spending
# heads toward $10. You set it up once, in Week 2, and then leave it alone for
# the rest of the course.
#
# Terraform keeps a record of everything it builds, called its "state". In this
# course that record is a plain file on your laptop, terraform.tfstate, sitting
# in the same folder as the code that built it. It's listed in .gitignore,
# because it describes your AWS account rather than the course.
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

  # Every resource gets these labels, so you can always tell what belongs to the course.
  default_tags {
    tags = {
      Project   = "cloud-devops-course"
      Stack     = "00-bootstrap"
      ManagedBy = "terraform"
    }
  }
}

# --- The budget alarm --------------------------------------------------------

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
