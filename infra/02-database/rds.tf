# -----------------------------------------------------------------------------
# The PostgreSQL database.
# -----------------------------------------------------------------------------

# A "subnet group" tells AWS which parts of the network the database may live
# in. We give it both PRIVATE subnets: the database gets no route to the
# internet, and the internet gets no route to it.
#
# Why two, when we only run one database? AWS requires at least two
# availability zones, so that it could move the database to the other data
# centre if one had a failure.
resource "aws_db_subnet_group" "main" {
  name        = "course-db-subnets"
  description = "The private subnets the database may live in"
  subnet_ids  = local.private_subnet_ids

  tags = {
    Name = "course-db-subnets"
  }
}

resource "aws_db_instance" "main" {
  identifier = "course-db"

  # --- What to run ---------------------------------------------------------
  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  # --- Storage -------------------------------------------------------------
  allocated_storage = var.db_storage_gb
  storage_type      = "gp3"
  storage_encrypted = true

  # --- The database and its administrator ----------------------------------
  db_name  = var.db_name
  username = var.db_username

  # This is the good bit. Instead of us inventing a password, putting it in a
  # variable, and accidentally committing it to git, AWS generates one, stores
  # it in Secrets Manager, and rotates it on request. Nobody ever sees it.
  # The app reads it from Secrets Manager when it starts.
  manage_master_user_password = true

  # --- Where it lives ------------------------------------------------------
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]

  # No public address. There is no way to reach this database from the
  # internet, only from inside your VPC.
  publicly_accessible = false

  # One copy, in one availability zone. A production database would set this
  # to true and keep a standby copy in the other zone.
  multi_az = false

  # --- Course settings -----------------------------------------------------
  # These exist so that 'terraform destroy' is quick and never leaves
  # anything behind that costs money. A real database would do the opposite:
  # keep backups, refuse to be deleted by accident, and take a final snapshot.
  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false
  apply_immediately       = true

  auto_minor_version_upgrade   = true
  performance_insights_enabled = false

  tags = {
    Name = "course-db"
  }
}
