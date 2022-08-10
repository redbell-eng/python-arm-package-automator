variable "environment" {
  type = string
  description = "The environment to deploy into. dev, test, or prod"
  default = "dev"

  validation {
    condition = can(regex("dev|test|prod", var.environment))
    error_message = "Please use dev, test, or prod for environment."
  }
}

variable "aws_profile" {
  type = string
  description = "The name of the AWS profile to use when authenticating during Packer and Terraform builds."
}