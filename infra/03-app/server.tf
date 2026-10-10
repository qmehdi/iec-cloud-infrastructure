# -----------------------------------------------------------------------------
# The server.
#
# One small EC2 instance in a private subnet. It has no public IP address,
# which means nothing on the internet can reach it directly: not a browser,
# not an attacker, not even you. You get to it in two ways:
#
#   - through the load balancer, as a visitor
#   - through Session Manager, as an administrator
# -----------------------------------------------------------------------------

# Which operating system image to use. Rather than hard-code an AMI ID (they
# differ per region and change every few weeks), we ask AWS for the current
# Amazon Linux 2023 image.
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
}

# The key Flask uses to sign session cookies. Generated once, kept in
# Terraform's state, and the same for every server, which matters in Week 4
# when there's more than one.
resource "random_password" "flask_secret" {
  length  = 48
  special = false
}

resource "aws_instance" "app" {
  ami           = data.aws_ssm_parameter.al2023.value
  instance_type = var.instance_type

  # A PRIVATE subnet. This one line is the whole point of last week's work.
  subnet_id              = local.private_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.app.id]

  # The role from iam.tf: Session Manager, plus read access to its own secrets.
  iam_instance_profile = aws_iam_instance_profile.app.name

  # Require IMDSv2 for the instance metadata service. The older version could
  # be tricked into handing out the server's credentials; this one can't.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true

    tags = {
      Name = "course-app-root"
    }
  }

  # The setup script that runs on first boot. Open user-data.sh.tftpl: it's
  # just the commands you would have typed by hand.
  user_data = templatefile("${path.module}/user-data.sh.tftpl", {
    app_repo_url    = var.app_repo_url
    app_version     = var.app_version
    region          = var.region
    db_host         = local.db_endpoint
    db_port         = local.db_port
    db_name         = local.db_name
    db_secret_arn   = local.db_secret_arn
    yelp_secret_arn = local.yelp_secret_arn
    flask_secret    = random_password.flask_secret.result
  })

  # If the setup script changes, build a fresh server rather than trying to
  # patch the running one. Rebuilding from scratch is the whole idea.
  user_data_replace_on_change = true

  tags = {
    Name = "course-app"
  }
}
