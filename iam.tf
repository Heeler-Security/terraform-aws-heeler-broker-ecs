data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "broker_cluster_compute_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com", "ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "broker_cluster_task_execution_role_policy" {
  statement {
    effect = "Allow"
    actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
        "logs:DescribeLogGroups",
        "logs:PutRetentionPolicy"
    ]
    resources = [
        "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/broker-ecs-task*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "broker-cluster-task-execution-role-policy" {
  name        = "broker-cluster-${var.region}-task-execution-role-policy"
  policy      = data.aws_iam_policy_document.broker_cluster_task_execution_role_policy.json
}

resource "aws_iam_role" "broker_cluster_task_execution_role" {
  name = "broker-cluster-${var.region}-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
  }
}

resource "aws_iam_policy_attachment" "ecs_task_execution_role_attachment2" {
  name       = "broker-cluster-${var.region}-ecs-task-execution-RolePolicyAttachment"
  policy_arn = aws_iam_policy.broker-cluster-task-execution-role-policy.arn
  roles      = [aws_iam_role.broker_cluster_task_execution_role.name]
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_attachment1" {
  role       = aws_iam_role.broker_cluster_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "broker_role" {
  name = "broker-${var.region}-role"
  assume_role_policy = data.aws_iam_policy_document.broker_cluster_compute_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "broker_role_attachment2" {
  role      = aws_iam_role.broker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "broker_secrets_policy_doc" {
   statement {
     effect = "Allow"
     actions = [
       "secretsmanager:GetSecretValue"
     ]
     resources = [
       aws_secretsmanager_secret.heeler_broker_secret_key.arn,
       aws_secretsmanager_secret.heeler_broker_key_id.arn
     ]     
   }
}

resource "aws_iam_policy" "broker_secrets_policy" {
   name = "broker-${var.region}-secrets-policy"
   policy = data.aws_iam_policy_document.broker_secrets_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "broker_role_attachment3" {
  role      = aws_iam_role.broker_cluster_task_execution_role.name
  policy_arn = aws_iam_policy.broker_secrets_policy.arn
}
