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

variable "vpc_cidr" {
  description = "The range of private IP addresses the VPC can use. 10.0.0.0/16 = 65,536 addresses."
  type        = string
  default     = "10.0.0.0/16"
}
