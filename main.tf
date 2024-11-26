provider "aws" {
  region = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

resource "aws_ecr_repository" "app_repo" {
  name = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecs_cluster" "app_cluster" {
  name = var.ecs_cluster_name
}

resource "aws_ecs_task_definition" "app_task" {
  family                = var.ecs_task_family
  container_definitions = <<DEFINITION
    [
        {
            "name": "dev-smartlib-users-container",
            "image": "${aws_ecr_repository.app_repo.repository_url}:latest",
            "essential": true,
            "memory": 512,
            "cpu": 256 ,
            "portMappings": [
                {
                    "containerPort": 80,
                    "hostPort": 80,
                    "protocol": "tcp",
                    "appProtocol": "http"
                }
            ]
        }
    ]
    DEFINITION
  requires_compatibilities = [ "FARGATE" ]
  network_mode = "awsvpc"
  memory = "512"
  cpu = "256"
  execution_role_arn = "arn:aws:iam::774305596814:role/ecsTaskExecutionRole"
}


# Query the default VPC
data "aws_vpc" "default" {
  default = true
}

# Query subnets in the specified VPC
data "aws_subnets" "vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Output the list of subnet IDs
output "subnet_ids" {
  value = data.aws_subnets.vpc_subnets.ids
}


resource "aws_ecs_service" "app_service" {
  name = var.ecs_service_name
  cluster = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  launch_type = "FARGATE"
  network_configuration {
#     default vpc subnet need to be queried
    subnets = data.aws_subnets.vpc_subnets.ids
    assign_public_ip = true
  }

  desired_count = 1

}


resource "aws_iam_role" "ecs_task_execution" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_attachment" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
