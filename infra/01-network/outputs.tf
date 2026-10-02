# Outputs are values Terraform prints after it runs. Later weeks also read
# them, so the database and servers know which network to join.

output "vpc_id" {
  description = "The ID of your VPC"
  value       = aws_vpc.main.id
}

output "availability_zones" {
  description = "The two data centers your network spans"
  value       = local.azs
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = aws_subnet.public[*].id
}
