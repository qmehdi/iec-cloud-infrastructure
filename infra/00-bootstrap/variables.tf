variable "alert_email" {
  description = "The email address that budget alerts go to. Terraform will ask you for this."
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.alert_email))
    error_message = "That doesn't look like an email address. Try again, for example: you@example.com"
  }
}

variable "budget_limit" {
  description = "Your monthly budget in US dollars. You get emails as spending approaches it."
  type        = string
  default     = "10"
}

variable "region" {
  description = "The AWS region the course uses."
  type        = string
  default     = "us-west-2"
}

variable "aws_profile" {
  description = "The AWS CLI profile Terraform signs in with. scripts/check-setup.sh creates it."
  type        = string
  default     = "course"
}
