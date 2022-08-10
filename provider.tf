provider "aws" {
  region = "us-east-2"

  default_tags {
    tags = {
      Project = "python-arm-package-generator"
      Environment = var.environment
    }
  }
}