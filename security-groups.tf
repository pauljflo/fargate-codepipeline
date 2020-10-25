resource "aws_security_group" "ecs" {
  name   = "ecs"
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "ecs"
  }
}

resource "aws_security_group_rule" "app_alb_to_ecs" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs.id
  source_security_group_id = aws_security_group.app_alb.id
}

resource "aws_security_group" "app_alb" {
  name   = "app-alb"
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "app-alb"
  }
}

resource "aws_security_group_rule" "internet_to_app_alb" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.app_alb.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group" "unfiltered_egress" {
  name   = "unfiltered-egress"
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "unfiltered-egress"
  }
}

resource "aws_security_group_rule" "unfiltered_egress_to_internet" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  security_group_id = aws_security_group.unfiltered_egress.id
  cidr_blocks       = ["0.0.0.0/0"]
}