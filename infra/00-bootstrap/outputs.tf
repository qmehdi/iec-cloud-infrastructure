output "budget_alerts_go_to" {
  description = "Who gets the budget emails"
  value       = var.alert_email
}

output "budget_limit" {
  description = "Your monthly budget"
  value       = format("$%s per month", var.budget_limit)
}
