data "aws_region" "current" {}

# ECS Fargate

data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "ecs.amazonaws.com",
        "ecs-tasks.amazonaws.com",
        "logs.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "ecs_fargate" {
  name = "ecs-fargate"
  path = "/"

  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_policy" "ecs_fargate" {
  name = "ecs-fargate"
  path = "/"

  policy = data.aws_iam_policy_document.ecs_fargate.json
}

data "aws_iam_policy_document" "ecs_fargate" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "ecs_fargate" {
  role       = aws_iam_role.ecs_fargate.name
  policy_arn = aws_iam_policy.ecs_fargate.arn
}

# ECS Fargate permissions

resource "aws_iam_policy" "ecs_fargate_permissions" {
  name = "ecs-fargate-permissions"
  path = "/"

  policy = data.aws_iam_policy_document.ecs_fargate_permissions.json
}

data "aws_iam_policy_document" "ecs_fargate_permissions" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutLogEventsBatch",
    ]

    resources = [
      "*",
    ]
  }
}

# HELLOWORLD

resource "aws_iam_instance_profile" "helloworld" {
  name = "helloworld"
  role = aws_iam_role.helloworld.name
}

resource "aws_iam_role" "helloworld" {
  name               = "helloworld"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy_attachment" "helloworld_permissions" {
  role       = aws_iam_role.helloworld.name
  policy_arn = aws_iam_policy.ecs_fargate_permissions.arn
}