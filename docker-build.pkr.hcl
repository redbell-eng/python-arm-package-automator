variable "ecr-repo" {
  type = string
  description = "The URL of the ECR repository to push the ARM Docker image to."
  default = ""
}

source "docker" "arm-container" {
  image = "arm64v8/python:3.10.0b5-alpine3.16"

  post-processors {
    post-processor "docker-tag" {
      repository = var.ecr-repo
      tags = ["latest"]
    }

    post-processor "docker-push" {
      ecr_login = true
      aws_profile = ""
      login_server = "https://${var.ecr-repo}/"
    }
  }

}