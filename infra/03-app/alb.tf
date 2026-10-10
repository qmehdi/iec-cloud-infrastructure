# -----------------------------------------------------------------------------
# The Application Load Balancer (ALB).
#
# It has a public address and sits in the public subnets. Visitors connect to
# it, and it passes each request on to a healthy server behind it.
#
# Today there's only one server, so a load balancer looks like overkill. Two
# things make it worth it right now:
#   - it's the reason the app server can stay in a private subnet, and
#   - it checks the server's health every few seconds, which is what makes
#     next week's self-healing possible.
# -----------------------------------------------------------------------------
resource "aws_lb" "main" {
  name               = "course-alb"
  load_balancer_type = "application"

  # internal = false means "give it a public address".
  internal        = false
  subnets         = local.public_subnet_ids
  security_groups = [aws_security_group.alb.id]

  # Both availability zones, so the load balancer survives one data centre
  # having a bad day.
  enable_deletion_protection = false

  tags = {
    Name = "course-alb"
  }
}

# A target group is the list of servers the load balancer sends traffic to,
# plus the health check it uses to decide which ones are working.
resource "aws_lb_target_group" "app" {
  name        = "course-app-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "instance"

  health_check {
    enabled = true

    # The app answers this with a small piece of JSON. Look at /health in your
    # browser once the site is up.
    path     = "/health"
    protocol = "HTTP"
    matcher  = "200"

    # Ask every 15 seconds. Two good answers in a row means healthy; three bad
    # ones means take it out of service.
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  # When a server is removed, wait this long for its current requests to
  # finish before cutting it off. 30 seconds is plenty for this app.
  deregistration_delay = 30

  tags = {
    Name = "course-app-tg"
  }
}

# Put our one server in the group. In Week 4, Auto Scaling takes over this job
# and this resource goes away.
resource "aws_lb_target_group_attachment" "app" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app.id
  port             = 80
}

# A listener is "what to do with traffic arriving on a port".
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
