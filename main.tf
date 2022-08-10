resource "aws_ecr_repository" "package-automator-repo" {
  name = "arm-package-generator-container"

  force_delete = true

  tags = {
    Project = "python-arm-package-generator"
    Environment = var.environment
  }
}