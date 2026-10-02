# -----------------------------------------------------------------------------
# Private subnets: the part of the VPC the internet can't reach.
# Your database and app servers will live here in later weeks.
#
# Things in a private subnet still sometimes need to reach OUT to the
# internet: to download software updates, or (in Week 4) to call the Yelp API.
# The NAT gateway is a one-way door for that: traffic can go out and the reply
# comes back, but nobody on the internet can start a connection in.
#
# COST: a NAT gateway costs money for every hour it exists (a few cents an
# hour). That's why we tear it down at the end of every class.
# -----------------------------------------------------------------------------

variable "enable_nat" {
  description = "Create the NAT gateway. In Week 4 we turn this off on purpose to see what breaks."
  type        = bool
  default     = true
}

# One private subnet in each availability zone:
#   course-private-a  10.0.10.0/24
#   course-private-b  10.0.11.0/24
resource "aws_subnet" "private" {
  count = length(local.azs)

  vpc_id            = aws_vpc.main.id
  availability_zone = local.azs[count.index]
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)

  tags = {
    Name = "course-private-${substr(local.azs[count.index], -1, 1)}"
    Tier = "private"
  }
}

# A fixed public IP address for the NAT gateway. When your servers call out
# to the internet, this is the address the other side sees.
resource "aws_eip" "nat" {
  count  = var.enable_nat ? 1 : 0
  domain = "vpc"

  tags = {
    Name = "course-nat-ip"
  }
}

# The NAT gateway itself. It sits in a PUBLIC subnet (it needs the internet
# gateway) and serves the PRIVATE subnets. To save money we use one NAT
# gateway for both zones. A real production system would use one per zone.
resource "aws_nat_gateway" "main" {
  count = var.enable_nat ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "course-nat"
  }

  # The internet gateway must exist first, or the NAT gateway has no way out.
  depends_on = [aws_internet_gateway.main]
}

# Directions for the private subnets. Notice there's no route to the
# internet gateway here: that's what makes them private.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "course-private-routes"
  }
}

# "Anything headed for the internet, go through the NAT gateway."
# Only exists while the NAT gateway does.
resource "aws_route" "private_to_nat" {
  count = var.enable_nat ? 1 : 0

  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[0].id
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "nat_public_ip" {
  description = "The public IP address your private servers use when they reach the internet"
  value       = var.enable_nat ? aws_eip.nat[0].public_ip : "NAT gateway is turned off"
}
