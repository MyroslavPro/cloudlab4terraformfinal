
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = var.max_num_tasks
  min_capacity       = var.min_num_tasks
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster_terraform_lab.name}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

## Policy for CPU tracking
resource "aws_appautoscaling_policy" "ecs_cpu_policy" {
  name               = "EC2Instances_CPUTargetTrackingScaling_of_tasks"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = var.target_tracking_desired_value
    scale_in_cooldown  = var.timespace_between_scaling
    scale_out_cooldown = var.timespace_between_scaling

    predefined_metric_specification {
      predefined_metric_type = var.metric_type_CPU
    }
  }
}

# variable "min_number_of_tasks" {
#   type = number
#   default = 1
# }
# variable "max_number_of_tasks" {
#   type = number
#   default = 6
# }

variable "target_tracking_desired_value" {
  type    = number
  default = 50
}

variable "timespace_between_scaling" {
  type    = number
  default = 240 #  4 minutes
}
variable "metric_type_CPU" {
  type    = string
  default = "ECSServiceAverageCPUUtilization"
}
variable "metric_type_Memory" {
  type    = string
  default = "ECSServiceAverageMemoryUtilization"
}