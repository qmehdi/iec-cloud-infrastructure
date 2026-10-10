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

variable "instance_type" {
  description = "How big the app server is. t3.micro is the smallest useful size."
  type        = string
  default     = "t3.micro"
}

variable "app_repo_url" {
  description = "The git repository the server installs the app from."
  type        = string
  default     = "https://github.com/qmehdi/neighborhood-eats.git"
}

variable "app_version" {
  description = "Which tagged release of the app to install. Pinned, so every server runs the same code."
  type        = string
  default     = "v1.0.0"
}
