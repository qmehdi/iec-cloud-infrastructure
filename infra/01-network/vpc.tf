# The VPC: a private network that belongs only to your account.
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  # Give things inside the VPC friendly DNS names (like ip-10-0-1-25...),
  # which later weeks rely on.
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "course-vpc"
  }
}
