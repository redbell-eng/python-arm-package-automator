# Packer-related variable
# Store the actual values for these variables in a packer-vars.pkrvars.hcl file
# Don't commit it to remote (use a .gitignore file to avoid it)
variable "ecr_repo" {
  type = string
  description = "The URL of the ECR repository to push the ARM Docker image to."
}

variable "aws_profile" {
  type = string
  description = "The AWS profile that should be used when authenticating to AWS ECR"
}

# Pull an Alpine ARM-based container from Docker registry (prepackaged with Python)
source "docker" "arm-container" {
  image = "arm64v8/python:3-alpine"
  commit = true
}

# Build the container that will be used to package ARM-based Python packages
build {
  sources = ["source.docker.arm-container"]

  # Install awscli
  provisioner "shell" {
    inline = [
      "python -m pip install --upgrade pip",
      "python -m pip install --no-cache-dir awscli"
    ]
  }

  # Tag it and push it to ECR
  post-processors {
    post-processor "docker-tag" {
      repository = "${var.ecr_repo}"
      tags = ["latest"]
    }

    post-processor "docker-push" {
      ecr_login = true
      aws_profile = var.aws_profile
      login_server = "https://${var.ecr_repo}/"
    }
  }
}