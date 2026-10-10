output "app_url" {
  description = "Open this in your browser. It's your app, on your server."
  value       = "http://${aws_lb.main.dns_name}"
}

output "instance_id" {
  description = "The app server's ID. You'll need it to log in with Session Manager."
  value       = aws_instance.app.id
}

output "log_in_to_the_server" {
  description = "Copy and paste this to get a shell on the server"
  value       = "aws ssm start-session --target ${aws_instance.app.id} --profile ${var.aws_profile} --region ${var.region}"
}

output "yelp_secret_name" {
  description = "Where the Yelp key goes. scripts/set-yelp-key.sh writes to this."
  value       = local.yelp_secret_name
}
