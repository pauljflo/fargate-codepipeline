resource "aws_ecr_repository" "ecr" {
  name  = "steamhaus-lab/helloworld"
  image_scanning_configuration {
    scan_on_push = true
  }
}