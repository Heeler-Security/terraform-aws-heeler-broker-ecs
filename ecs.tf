resource "aws_ecs_cluster" "broker_ecs_cluster" {
 name = "broker-ecs-cluster"
}

resource "aws_ecs_service" "ecs_service_broker" {
  name            = "heeler-service-broker"
  cluster         = aws_ecs_cluster.broker_ecs_cluster.id
  task_definition = aws_ecs_task_definition.task_definition_broker.arn
  launch_type     = "FARGATE"
  desired_count   = 1
  enable_execute_command = true

  network_configuration {
    subnets = var.private_subnet_ids
    security_groups = [aws_security_group.broker_sg.id]
  }
}

resource "aws_ecs_task_definition" "task_definition_broker" {
  family                   = "heeler-broker"
  network_mode             = "awsvpc"
  memory                   = 4096  
  cpu                      = 2048 
  task_role_arn            = aws_iam_role.broker_role.arn
  execution_role_arn       = aws_iam_role.broker_cluster_task_execution_role.arn
  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([{
    name  = "broker"
    image = var.broker_image
    portMappings = [
      {containerPort = 8080}
    ]

    "command" = ["/app/broker", "broker"]

    "linuxParameters" = {
       "initProcessEnabled": true
    }

    secrets = [
        {
            name = "BROKER_SECRET_KEY",
            valueFrom = aws_secretsmanager_secret.heeler_broker_secret_key.arn
        },
        {
            name = "BROKER_KEY_ID",
            valueFrom = aws_secretsmanager_secret.heeler_broker_key_id.arn
        }
    ]
    environment = [
        {
            name = "BROKER_HEELER_URL",
            value = "https://app.heeler.com/api/internal/broker"
        },
        {
            name = "SCA_COMMAND",
            value = "heeler-sca"
        },
        {
            name = "SAST_COMMAND",
            value = "semgrep"
        }
    ]
    logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"   = "/ecs/broker-ecs-task"
          "awslogs-region"  = var.region
          "awslogs-stream-prefix" = "heelerai"
          "awslogs-create-group": "true"
        }
    }
    healthcheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8080/_health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
    }
  }])
}
