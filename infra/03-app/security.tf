# -----------------------------------------------------------------------------
# Three firewalls in a chain. This is the most important file of the week.
#
#   internet  --80-->  load balancer  --80-->  app server  --5432-->  database
#
# Each step only accepts traffic from the step before it. The database will
# not accept a connection from the load balancer; the app server will not
# accept one from the internet. If you can only remember one thing about
# security groups, remember that they reference each other, not IP addresses.
# -----------------------------------------------------------------------------

# --- 1. The load balancer: open to the world ---------------------------------
resource "aws_security_group" "alb" {
  name        = "course-alb-sg"
  description = "The load balancer. Open to the internet on port 80."
  vpc_id      = local.vpc_id

  tags = {
    Name = "course-alb-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_from_internet" {
  security_group_id = aws_security_group.alb.id
  description       = "Anyone, anywhere, on port 80"

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80
}

resource "aws_vpc_security_group_egress_rule" "alb_to_anywhere" {
  security_group_id = aws_security_group.alb.id
  description       = "Let the load balancer reach the app server"

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

# --- 2. The app server: only from the load balancer --------------------------
resource "aws_security_group" "app" {
  name        = "course-app-sg"
  description = "The app server. Reachable only from the load balancer."
  vpc_id      = local.vpc_id

  tags = {
    Name = "course-app-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Note what this rule does NOT contain: an IP address. It names the load
# balancer's security group instead. Whatever the load balancer's addresses
# turn out to be, and however many it has, this rule follows it.
resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id = aws_security_group.app.id
  description       = "Web traffic, but only from the load balancer"

  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
}

# The server needs to reach OUT: to install software, to read its secrets from
# AWS, and to call Yelp. That traffic goes through the NAT gateway. Nothing on
# the internet can start a connection back the other way.
resource "aws_vpc_security_group_egress_rule" "app_to_anywhere" {
  security_group_id = aws_security_group.app.id
  description       = "Outbound, through the NAT gateway"

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

# --- 3. The database: only from the app server -------------------------------
# This rule is attached to the DATABASE's security group, which was created in
# 02-database. We add it here, because the app is the reason it exists.
resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id = local.db_sg_id
  description       = "PostgreSQL, but only from the app server"

  referenced_security_group_id = aws_security_group.app.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432

  tags = {
    Name = "course-db-from-app"
  }
}
