provider "aws" {
  region = "us-east-2"

  default_tags {
    tags = {
      Project = "python-arm-package-generator"
      Environment = var.environment
    }
  }
}

# Need a separate AWS provider since ECR public repos can only be created in us-east-1 as of creating this code
provider "aws" {
  alias = "us-east-1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project = "python-arm-package-generator"
      Environment = var.environment
    }
  }
}