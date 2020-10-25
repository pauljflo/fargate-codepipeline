data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

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


//CODEPIPELNE ROLES

##Codebuild
resource "aws_iam_role" "codebuild_role" {
  name = "codebuild"
  path = "/"

  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume.json
}

data "aws_iam_policy_document" "codebuild_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ecr:GetAuthorizationToken",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecs:RunTask",
      "ssm:PutParameter",
      "ssm:GetParameter",
      "ssm:DeleteParameter",
      "iam:PassRole"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:List*",
      "s3:PutObject"
    ]

    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "codebuild_policy" {
  name   = "codebuild"
  path   = "/"
  policy = data.aws_iam_policy_document.codebuild_policy.json
}

resource "aws_iam_role_policy_attachment" "codebuild_attachment" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_policy.arn
}

### CodePipeline

data "aws_iam_policy_document" "codepipeline_assume" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "codebuild.amazonaws.com",
        "codepipeline.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline"
  path = "/"

  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume.json
}

data "aws_iam_policy_document" "codepipeline_policy" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:List*",
      "s3:PutObject"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "ecs:*",
      "events:DescribeRule",
      "events:DeleteRule",
      "events:ListRuleNamesByTarget",
      "events:ListTargetsByRule",
      "events:PutRule",
      "events:PutTargets",
      "events:RemoveTargets",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfiles",
      "iam:ListRoles",
      "logs:CreateLogGroup",
      "logs:DescribeLogGroups",
      "logs:FilterLogEvents"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "iam:PassRole"
    ]

    resources = [
      "*"
    ]

    condition {
      test     = "StringLike"
      variable = "iam:PassedToService"
      values = [
        "ecs-tasks.amazonaws.com"
      ]
    }
  }

  statement {
    actions = [
      "iam:PassRole"
    ]

    resources = [
      "arn:aws:iam::*:role/ecsInstanceRole*"
    ]

    condition {
      test     = "StringLike"
      variable = "iam:PassedToService"
      values = [
        "ec2.amazonaws.com",
        "ec2.amazonaws.com.cn"
      ]
    }
  }

  statement {
    actions = [
      "iam:PassRole"
    ]

    resources = [
      "arn:aws:iam::*:role/ecsAutoscaleRole*"
    ]

    condition {
      test     = "StringLike"
      variable = "iam:PassedToService"
      values = [
        "application-autoscaling.amazonaws.com",
        "application-autoscaling.amazonaws.com.cn"
      ]
    }
  }

  statement {
    actions = [
      "iam:CreateServiceLinkedRole"
    ]

    resources = [
      "*"
    ]

    condition {
      test     = "StringLike"
      variable = "iam:AWSServiceName"
      values = [
        "ecs.amazonaws.com",
        "spot.amazonaws.com",
        "spotfleet.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_policy" "codepipeline_policy" {
  name   = "codepipeline"
  path   = "/"
  policy = data.aws_iam_policy_document.codepipeline_policy.json
}

resource "aws_iam_role_policy_attachment" "codepipeline_attachment" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}