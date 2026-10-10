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

variable "db_name" {
  description = "The name of the database the app stores reviews in."
  type        = string
  default     = "neighborhood_eats"
}

variable "db_username" {
  description = "The database's administrator account. AWS generates its password."
  type        = string
  default     = "courseadmin"
}

variable "db_instance_class" {
  description = "How big the database server is. db.t4g.micro is the smallest and cheapest."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_engine_version" {
  description = "Which major version of PostgreSQL to run."
  type        = string
  default     = "17"
}

variable "db_storage_gb" {
  description = "How much disk the database gets, in gigabytes."
  type        = number
  default     = 20
}
