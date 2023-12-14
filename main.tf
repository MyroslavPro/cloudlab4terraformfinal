# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 5.0"
#     }
#   }
# }

# # Configure the AWS Provider
# provider "aws" {
#   region = "eu-west-1"
# }

resource "aws_launch_template" "ecs_lt" {
  name_prefix   = "ecs-template"
  image_id      = "ami-0ff103cb56a347a33" #  -- EC2 ECS compatible image
  instance_type = "t2.micro"

  monitoring {
    enabled = true
  }

  key_name = "ec2ecsglog"

  vpc_security_group_ids = [aws_security_group.allow_all_ports.id]
  iam_instance_profile {
    #name = "ecsInstanceRole"
    arn = aws_iam_instance_profile.ecs_node.arn
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "EC2 Terraform ecs instance"
      Description = "My AWS EC2 instance launched for task on cluster from terraform"
    }
  }

  # Without this the ECS service will not be able to deploy and run containers on our EC2 instance.!!
  user_data = base64encode(
    <<-EOF
#!/bin/bash
echo ECS_CLUSTER=${aws_ecs_cluster.ecs_cluster_terraform_lab.name} >> /etc/ecs/ecs.config;
EOF
  )

}

# Here I create asg for ec2 instances
resource "aws_autoscaling_group" "ecs_asg" {
  desired_capacity = var.desired_count_instances
  max_size         = var.max_num_ec2_instances
  min_size         = var.min_num_ec2_instances
  #   availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  vpc_zone_identifier = [for s in data.aws_subnet.subnets_ids_list : s.id]


  launch_template {
    id      = aws_launch_template.ecs_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
}


# My EC2 instances cluster
resource "aws_ecs_cluster" "ecs_cluster_terraform_lab" {
  name = "my_ecs_cluster_terraform_lab"
}


resource "aws_ecs_capacity_provider" "ecs_capacity_provider" {
  name = "capacity_provider_terraform"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs_asg.arn

    managed_scaling {
      maximum_scaling_step_size = 10
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
      # target_capacity           = 3
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "capasity_provier_strategy_service_lab" {
  cluster_name = aws_ecs_cluster.ecs_cluster_terraform_lab.name

  capacity_providers = [aws_ecs_capacity_provider.ecs_capacity_provider.name]

  default_capacity_provider_strategy {
    base   = 1
    weight = 100
    # base              = 0
    # weight            = 1
    capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
  }
}


resource "aws_security_group" "allow_all_ports" {
  name        = "allow_all_ports_terraform_lab4"
  description = "Allow all inbound and outbound traffic"

  ingress {
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "All tcp ports(for containers to anable Loud Balancer to redirect traffic for conainers on EC2 instances)"
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "allow_all_ports"
    Description = "For lab purposes i open the ports for dynamic reagasting the mapping of containers to hosts"
  }
}

# ECR repository 
# data "aws_ecr_image" "task_image" {
#   repository_name = "ecr_lab_cloud_repo"
#   #repository_name = "my/ecr_lab_cloud_repo"
#   most_recent = true
# }

output "aws_security_group_all_allowd" {
  value = aws_security_group.allow_all_ports.id
}


data "aws_ecr_repository" "task_repo" {
  name = "ecr_lab_cloud_repo"
}

output "task_repo_image__url" {
  value = data.aws_ecr_repository.task_repo.repository_url
}

data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}


# My task for the service, which will be scaled
resource "aws_ecs_task_definition" "ecs_task_terraform_lab" {
  family             = "projectLabCloud4Terraform"
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  container_definitions = jsonencode([
    {
      name      = "projectLabCloud4Terraform"
      image     = "${data.aws_ecr_repository.task_repo.repository_url}:latest"
      cpu       = 256
      memory    = 450
      essential = true
      portMappings = [
        {
          containerPort = 8080
          "protocol" : "tcp",
          "appProtocol" : "http"
        }
      ]
    }
  ])

}

variable "container_memory" {
  type    = number
  default = 450
}

variable "container_cpu" {
  type    = number
  default = 256
}

resource "aws_ecs_service" "ecs_service" {
  name            = "my-ecs-service-terraform-lab"
  cluster         = aws_ecs_cluster.ecs_cluster_terraform_lab.id
  task_definition = aws_ecs_task_definition.ecs_task_terraform_lab.arn
  desired_count   = var.desired_count_tasks

  # addiing load balancer
  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    #container_name   = var.service_name
    container_name = "projectLabCloud4Terraform"
    container_port = 8080
  }

  force_new_deployment = true

  ordered_placement_strategy {
    type  = "binpack"
    field = "memory"
  }
  # Bin Pack on memory, should fill them one by one
  # placement_constraints {
  #   type = "memberOf"
  #   expression = "attribute:memory <= ${var.container_memory}"  
  # }


  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
    # weight            = 1
    weight = 100
  }

  depends_on = [aws_autoscaling_group.ecs_asg]

  tags = {
    Description = "Ecs service created with terraform for cloud lab"
  }
}
