# The ECR image repo for the Docker image that the package automator will use
resource "aws_ecrpublic_repository" "package-automator-repo" {
  provider = aws.us-east-1
  repository_name = "arm-package-generator-container"
}

# The S3 bucket that the package automator tasks will upload the finalized Python ARM packages to
resource "aws_s3_bucket" "package-output-bucket" {
  bucket = "python-arm-package-automator-${data.aws_caller_identity.current-account.account_id}-${var.environment}"
}

resource "aws_s3_bucket_acl" "package-output-bucket-acl" {
  bucket = aws_s3_bucket.package-output-bucket.id
  acl = "private"
}

resource "aws_s3_bucket_public_access_block" "package-output-bucket-block-public" {
  bucket = aws_s3_bucket.package-output-bucket.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
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

  role_name = "arm-package-generator-${var.environment}-ecs-task-role"
  custom_role_policy_arns = [
    module.package-s3-access-policy.arn,
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]
}

# AWS ECS Cluster Setup
resource "aws_ecs_cluster" "package-cluster" {
  name = "python-arm-package-generator-${var.environment}-cluster"
}

module "package-cluster-execution-role" {
  source = "registry.terraform.io/terraform-aws-modules/iam/aws//modules/iam-assumable-role"

  trusted_role_services = [
    "ecs-tasks.amazonaws.com"
  ]

  create_role = true
  role_requires_mfa = false

  role_name = "arm-package-generator-${var.environment}-ecs-cluster-role"
  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]
}

resource "aws_ecs_task_definition" "package-task-definition" {
  family                = "python-arm-packager"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu = 256
  memory = 1024

  execution_role_arn = module.package-cluster-execution-role.iam_role_arn
  task_role_arn = module.package-s3-access-role.iam_role_arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture = "ARM64"
  }

  container_definitions = <<TASK_DEF
[
  {
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/python-arm-packager-${var.environment}",
          "awslogs-region": "us-east-2",
          "awslogs-stream-prefix": "ecs"
        }
    },
    "environment": [
        {
          "name": "S3_BUCKET_URL",
          "value": "${aws_s3_bucket.package-output-bucket.id}"
        }
      ],
    "entryPoint": [
        "packager.sh"
      ],
    "name": "python-arm-packager-task",
    "workingDirectory": "/home/scripts",
    "image": "${aws_ecrpublic_repository.package-automator-repo.repository_uri}",
    "cpu": 256,
    "memory": 1024
  }
]
TASK_DEF
}

# CloudWatch log group for the above task
resource "aws_cloudwatch_log_group" "packager-log-group" {
  name = "/ecs/python-arm-packager-dev"
}