# These values are read by the next folder (03-app), which needs to tell the
# app where its database is and which secrets to read.

output "db_endpoint" {
  description = "The address the app connects to"
  value       = aws_db_instance.main.address
}

output "db_port" {
  description = "The port PostgreSQL is listening on"
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "The name of the database holding your class's reviews"
  value       = aws_db_instance.main.db_name
}

output "db_security_group_id" {
  description = "The database's firewall. 03-app adds a rule to this."
  value       = aws_security_group.db.id
}

output "db_secret_arn" {
  description = "Where AWS stored the database username and password"
  value       = aws_db_instance.main.master_user_secret[0].secret_arn
}

output "yelp_secret_arn" {
  description = "The (initially empty) secret that holds your Yelp API key"
  value       = aws_secretsmanager_secret.yelp.arn
}

output "yelp_secret_name" {
  description = "The name scripts/set-yelp-key.sh writes to"
  value       = aws_secretsmanager_secret.yelp.name
}
