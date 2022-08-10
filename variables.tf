variable "environment" {
  type = string
  description = "The environment to deploy into. dev, test, or prod"
  default = "dev"

  validation {
    condition = can(regex("dev|test|prod", var.environment))
    error_message = "Please use dev, test, or prod for environment."
  }
}