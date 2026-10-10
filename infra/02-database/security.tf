# -----------------------------------------------------------------------------
# A security group is a firewall around one thing.
#
# This one wraps the database. Notice what's NOT in this file: any rule
# letting anything in. A security group with no inbound rules blocks
# everything, which is exactly what we want for now.
#
# Next step (03-app) adds a single rule to this group: "the app server, and
# only the app server, may connect on the PostgreSQL port." That rule lives
# with the app because the app is the reason it exists.
# -----------------------------------------------------------------------------
resource "aws_security_group" "db" {
  name        = "course-db-sg"
  description = "Postgres, reachable only from the app server"
  vpc_id      = local.vpc_id

  tags = {
    Name = "course-db-sg"
  }

  # If this group ever has to be replaced, make the new one before destroying
  # the old, so the database is never left without a firewall.
  lifecycle {
    create_before_destroy = true
  }
}
