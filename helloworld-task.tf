locals {
  helloworld_fargate_container_definitions = [
    {
      name      = "helloworld-cloud"
      image     = "pauljflo/demo-app:latest"

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.helloworld_fargate.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "helloworld-fargate"
        }
      }

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name: "APP_ENV"
          value: "dev"
        }
      ]

      volumesFrom = []
    },
  ]
}

resource "aws_ecs_task_definition" "helloworld" {
  family                   = "helloworld-fargate"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_fargate.arn
  network_mode             = "awsvpc"
  task_role_arn            = aws_iam_role.helloworld.arn
  cpu                      = 256
  memory                   = 512

  # Nasty regex to workaround https://github.com/hashicorp/terraform/issues/17033
  container_definitions = replace(replace(jsonencode(local.helloworld_fargate_container_definitions), "/\"([0-9]+\\.?[0-9]*|true|false)\"/", "$1"), "/\"value\":([0-9]+\\.?[0-9]*|true|false)/", "\"value\":\"$1\"")

  volume {
    name      = "tmp_storage"
  }
}

resource "aws_ecs_service" "helloworld_fargate" {
  lifecycle {
    create_before_destroy = false
    ignore_changes = ["desired_count"]
  }

  depends_on                         = [aws_lb_listener.app]
  name                               = "helloworld-fargate"
  cluster                            = aws_ecs_cluster.ecs.id
  launch_type                        = "FARGATE"
  task_definition                    = aws_ecs_task_definition.helloworld.arn
  desired_count                      = 1
  deployment_minimum_healthy_percent = 100

  network_configuration {
    security_groups = [aws_security_group.ecs.id, aws_security_group.unfiltered_egress.id]
    subnets         = module.vpc.private_subnets
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.helloworld.arn
    container_name   = "helloworld-cloud"
    container_port   = 80
  }
}

resource "aws_cloudwatch_log_group" "helloworld_fargate" {
  name = "helloworld-fargate"
}

resource "aws_cloudwatch_log_stream" "helloworld_fargate" {
  name           = "helloworld-fargate"
  log_group_name = aws_cloudwatch_log_group.helloworld_fargate.name
}

resource "aws_lb_target_group" "helloworld" {
  depends_on           = [aws_lb.app]
  name                 = "helloworld"
  port                 = 80
  protocol             = "HTTP"
  target_type          = "ip"
  deregistration_delay = 120
  vpc_id               = module.vpc.vpc_id
}
