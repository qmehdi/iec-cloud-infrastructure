# -----------------------------------------------------------------------------
# Public subnets: the part of the VPC that can talk directly to the internet.
# Later, the load balancer that greets your users lives here.
# -----------------------------------------------------------------------------

# One public subnet in each availability zone:
#   course-public-a  10.0.0.0/24  (256 addresses)
#   course-public-b  10.0.1.0/24
resource "aws_subnet" "public" {
  count = length(local.azs)

  vpc_id            = aws_vpc.main.id
  availability_zone = local.azs[count.index]
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)

  # Anything started here automatically gets a public IP address.
  map_public_ip_on_launch = true

  tags = {
    Name = "course-public-${substr(local.azs[count.index], -1, 1)}"
    Tier = "public"
  }
}

# The internet gateway: the VPC's front door to the internet.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "course-igw"
  }
}

# A route table is a list of directions for network traffic.
# This one says: "anything headed for the internet (0.0.0.0/0), go through the
# internet gateway." That one rule is what makes a subnet "public".
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "course-public-routes"
  }
}

# Attach those directions to both public subnets.
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
