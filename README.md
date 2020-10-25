This Terraform repository will create a simple ECS Fargate cluster and deploy a demo app to it from Dockerhub. 
It will also configure CodePipeline to deploy to this ECS service from a Github repository. 

This has been designed as a minimum viable product for experimentation and should not be deployed as a production platform. 
IAM and Security Group rules are very lax and AZs are limited to 2. 

You will need to update, S3 bucket name for artifacts, and set the git repository and personal access token in inputs.tfvars
By default the following repo is built: https://github.com/pauljflo/node-hello