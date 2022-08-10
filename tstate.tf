terraform {
  cloud {
    organization = "redbell-eng"

    workspaces {
      name = "python-arm-package-automator"
    }
  }
}