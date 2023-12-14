resource "aws_lb" "ecs_alb" {
  name               = "ecs-alb-terraform"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_all_ports.id]
  subnets            = [for s in data.aws_subnet.subnets_ids_list : s.id]

  tags = {
    Name = "ecs-alb"
  }
}

resource "aws_lb_listener" "ecs_alb_listener" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = var.lb_listener_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg.arn
  }
}

resource "aws_lb_target_group" "ecs_tg" {
  name        = "ecsTargetGroupTerraformLab4"
  port        = var.ec2_target_port
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = data.aws_vpc.vpc_default.id

  health_check {
    #path = "${var.health_check_endpoint}"
    path = "/"
  }
}

# variable "health_check_endpoint" {
#   type = string
#   default = "/swagger-ui.html#/"
# }

variable "lb_listener_port" {
  type    = number
  default = 80
}

variable "ec2_target_port" {
  type    = number
  default = 80
}

output "application_lb_dns" {
  value = aws_lb.ecs_alb.dns_name
}