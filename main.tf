# The ECR image repo for the Docker image that the package automator will use
resource "aws_ecr_repository" "package-automator-repo" {
  name = "arm-package-generator-container"

  force_delete = true
}

# The S3 bucket that the package automator tasks will upload the finalized Python ARM packages to
resource "aws_s3_bucket" "package-output-bucket" {
  bucket = "python-arm-package-automator-${data.aws_caller_identity.current-account.account_id}-${var.environment}"
}

resource "aws_s3_bucket_acl" "package-output-bucket-acl" {
  bucket = aws_s3_bucket.package-output-bucket.id
  acl = "private"
}

# IAM Setup for the ECS tasks to access the relevant S3 bucket (above)
data "aws_iam_policy_document" "package-cluster-policy-doc" {
  statement {
    sid = "s3readandwrite"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObjectAcl",
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.package-output-bucket.arn,
      "${aws_s3_bucket.package-output-bucket.arn}/*"
    ]
  }
}

module "package-s3-access-policy" {
  source = "registry.terraform.io/terraform-aws-modules/iam/aws//modules/iam-policy"

  name = "arm-package-generator-${var.environment}-cluster-policy"
  path = "/"
  description = "Allow retrieving and putting objects into the python-arm-package-automator S3 bucket"

  policy = data.aws_iam_policy_document.package-cluster-policy-doc.json
}

module "package-s3-access-role" {
  source = "registry.terraform.io/terraform-aws-modules/iam/aws//modules/iam-assumable-role"

  trusted_role_services = [
    "ecs-tasks.amazonaws.com"
  ]

  create_role = true
  role_requires_mfa = false

  role_name = "arm-package-generator-${var.environment}-cluster-role"
  custom_role_policy_arns = [
    module.package-s3-access-policy.arn
  ]
}

# AWS ECS Cluster Setup
resource "aws_ecs_cluster" "package-cluster" {
  name = "python-arm-package-generator-${var.environment}-cluster"
}

resource "aws_ecs_task_definition" "package-service-definition" {
  family                = "python-arm-packager"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu = 256
  memory = 1024

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture = "ARM64"
  }

  container_definitions = <<TASK_DEF
[
  {
    "name": "python-arm-packager-service",
    "image": "${aws_ecr_repository.package-automator-repo.repository_url}",
    "cpu": 256,
    "memory": 1024,
    "essential": true
  }
]
TASK_DEF
}