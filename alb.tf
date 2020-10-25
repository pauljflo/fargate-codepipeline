resource "aws_lb" "app" {
  name            = "helloworld"
  internal        = false
  security_groups = [aws_security_group.app_alb.id, aws_security_group.unfiltered_egress.id]
  subnets         = module.vpc.public_subnets
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.helloworld.arn
    type             = "forward"
  }
}