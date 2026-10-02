output "state_bucket" {
  description = "Where Terraform will store the state for every other folder"
  value       = aws_s3_bucket.state.bucket
}

output "budget_alerts_go_to" {
  description = "Who gets the budget emails"
  value       = var.alert_email
}

output "budget_limit" {
  description = "Your monthly budget"
  value       = format("$%s per month", var.budget_limit)
}
