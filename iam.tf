data "aws_partition" "current" {}

data "aws_iam_policy_document" "ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# ------------------------------------------------------------------------
# Execution Role
# ------------------------------------------------------------------------
resource "aws_iam_role" "execution_role" {
  name               = local.execution_role
  assume_role_policy = data.aws_iam_policy_document.execution_role_assume.json
}

data "aws_iam_policy_document" "execution_role_assume" {
  statement {
    sid     = "ExecuteECSTasks"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
  statement {
    sid     = "CognitoLogs"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["cognito-idp.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "execution_role_ecs" {
  role       = aws_iam_role.execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "execution_role_cw" {
  role       = aws_iam_role.execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "execution_role_ssm" {
  role       = aws_iam_role.execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

# ------------------------------------------------------------------------
# Task Role
# ------------------------------------------------------------------------
resource "aws_iam_role" "task_role" {
  name               = local.task_role
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json
}

resource "aws_iam_role_policy" "aws_open_telemetry" {
  name   = "AWSOpenTelemetryPolicy"
  role   = aws_iam_role.task_role.id
  policy = data.aws_iam_policy_document.aws_open_telemetry.json
}

data "aws_iam_policy_document" "aws_open_telemetry" {
  statement {
    effect    = "Allow"
    actions   = [
      "logs:PutLogEvents",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets",
      "xray:GetSamplingStatisticSummaries",
      "ssm:GetParameters"
    ]
    resources = ["*"]
  }
}

# ------------------------------------------------------------------------
# Scalable Target Role (Auto Scaling)
# ------------------------------------------------------------------------
resource "aws_iam_role" "scalable_target_role" {
  name               = local.asg_role
  assume_role_policy = data.aws_iam_policy_document.autoscaling_assume.json
}

data "aws_iam_policy_document" "autoscaling_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["application-autoscaling.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "autoscaling_policy" {
  name   = "${var.service_name}-${var.environment}-AutoScalingPolicy"
  role   = aws_iam_role.scalable_target_role.id
  policy = data.aws_iam_policy_document.autoscaling_policy.json
}

data "aws_iam_policy_document" "autoscaling_policy" {
  statement {
    effect    = "Allow"
    actions   = [
      "application-autoscaling:*",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:PutMetricAlarm",
      "ecs:DescribeServices",
      "ecs:UpdateService"
    ]
    resources = ["*"]
  }
}

# ------------------------------------------------------------------------
# Conditional Roles: S3, Cognito, Historico, Messaging
# ------------------------------------------------------------------------
data "aws_iam_policy_document" "assume_task_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.task_role.arn]
    }
  }
}

resource "aws_iam_role" "s3_ecs_uploads" {
  count              = local.enable_s3_bucket_uploads ? 1 : 0
  name               = local.s3_role
  assume_role_policy = data.aws_iam_policy_document.assume_task_role.json
}

resource "aws_iam_role_policy" "s3_ecs_uploads_policy" {
  count  = local.enable_s3_bucket_uploads ? 1 : 0
  name   = "${var.service_name}-${var.environment}-S3ECSUploadsAccessPolicy"
  role   = aws_iam_role.s3_ecs_uploads[0].id
  policy = data.aws_iam_policy_document.s3_ecs_uploads[0].json
}

data "aws_iam_policy_document" "s3_ecs_uploads" {
  count = local.enable_s3_bucket_uploads ? 1 : 0
  statement {
    sid       = "ActionS3ECSUploadsObjects"
    effect    = "Allow"
    actions   = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListBucketVersions",
      "s3:GetObjectVersion",
      "s3:ListMultipartUploadParts"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::*",
      "arn:${data.aws_partition.current.partition}:s3:::${var.s3_bucket_uploads}"
    ]
  }
}

resource "aws_iam_role" "cognito_ecs" {
  count              = local.enable_cognito_integration ? 1 : 0
  name               = local.cognito_role
  assume_role_policy = data.aws_iam_policy_document.cognito_ecs_assume.json
}

data "aws_iam_policy_document" "cognito_ecs_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.task_role.arn]
    }
  }
  statement {
    sid     = "CognitoLogs"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["cognito-idp.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "cognito_ecs_policy" {
  count  = local.enable_cognito_integration ? 1 : 0
  name   = "${var.service_name}-${var.environment}-CognitoECSAccessPolicy"
  role   = aws_iam_role.cognito_ecs[0].id
  policy = data.aws_iam_policy_document.cognito_ecs[0].json
}

data "aws_iam_policy_document" "cognito_ecs" {
  count = local.enable_cognito_integration ? 1 : 0
  statement {
    sid       = "ActionCognitoIntegration"
    effect    = "Allow"
    actions   = [
      "cognito-identity:*",
      "cognito-idp:*",
      "iam:PassRole"
    ]
    resources = ["*"]
  }
  statement {
    sid       = "ActionCognitoLogs"
    effect    = "Allow"
    actions   = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "historico_ecs" {
  count              = local.enable_historico ? 1 : 0
  name               = local.historico_role
  assume_role_policy = data.aws_iam_policy_document.assume_task_role.json
}

resource "aws_iam_role_policy" "historico_ecs_policy" {
  count  = local.enable_historico ? 1 : 0
  name   = "${var.service_name}-${var.environment}-HistoricoAccessPolicy"
  role   = aws_iam_role.historico_ecs[0].id
  policy = data.aws_iam_policy_document.historico_ecs[0].json
}

data "aws_iam_policy_document" "historico_ecs" {
  count = local.enable_historico ? 1 : 0
  statement {
    sid       = "ActionHistoricoMessagingAccess"
    effect    = "Allow"
    actions   = [
      "ssm:GetParameters",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage",
      "sqs:SendMessage",
      "sqs:ChangeMessageVisibility",
      "sqs:DeleteMessage",
      "sns:Publish",
      "sns:Subscribe",
      "sns:CreateTopic"
    ]
    resources = ["*"]
  }
  statement {
    sid       = "ActionHistoricoDynamoDBAccess"
    effect    = "Allow"
    actions   = [
      "dynamodb:DescribeTable",
      "dynamodb:UpdateItem",
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:Query",
      "dynamodb:ListTables",
      "dynamodb:ListGlobalTables"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "messaging_policy" {
  count  = local.enable_pubsub ? 1 : 0
  name   = "${var.service_name}-${var.environment}-MessagingPolicy"
  role   = aws_iam_role.task_role.id
  policy = data.aws_iam_policy_document.messaging_policy[0].json
}

data "aws_iam_policy_document" "messaging_policy" {
  count = local.enable_pubsub ? 1 : 0
  statement {
    effect    = "Allow"
    actions   = [
      "ssm:GetParameters",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage",
      "sqs:SendMessage",
      "sqs:ChangeMessageVisibility",
      "sqs:DeleteMessage",
      "sns:Publish",
      "sns:Subscribe",
      "sns:CreateTopic"
    ]
    resources = ["*"]
  }
}
