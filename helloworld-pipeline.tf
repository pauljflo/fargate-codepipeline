//CodeBuild
data "template_file" "buildspec" {
  template = file("${path.module}/buildspecs/docker.yml")

  vars = {
    application_name   = "helloworld"
    repository_url     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/steamhaus-lab/helloworld"
  }
}


resource "aws_codebuild_project" "app_build" {
  name          = "helloworld-codebuild"
  build_timeout = "10"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = data.template_file.buildspec.rendered
  }
}

//CodePipeline

#Artifacts storage in S3
resource "aws_s3_bucket" "steamhaus-labs-deploy" {
  bucket = var.artifacts_bucket
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_codepipeline" "helloworld_pipeline" {
  name     = "helloworld-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.steamhaus-labs-deploy.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["workspace"]

      configuration = {
        Owner                = var.github_owner
        Repo                 = var.github_repo
        Branch               = var.github_branch
        OAuthToken           = var.github_token
        PollForSourceChanges = "true"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["workspace"]
      output_artifacts = ["imagedefs"]

      configuration = {
        ProjectName = "helloworld-codebuild"
      }
    }
  }

    stage {
    name = "Approval"

    action {
      name             = "Approval"
      category         = "Approval"
      owner            = "AWS"
      provider         = "Manual"
      version          = "1"
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["imagedefs"]
      version         = "1"

      configuration = {
        ClusterName = aws_ecs_cluster.ecs.name
        ServiceName = aws_ecs_service.helloworld_fargate.name
        FileName    = "imagedefinitions.json"
      }
    }
  }
}