variable "max_num_ec2_instances" {
  type    = number
  default = 6
}
variable "min_num_ec2_instances" {
  type    = number
  default = 1
}


variable "max_num_tasks" {
  type    = number
  default = 12 # var.max_num_ec2_instances * 2
}

variable "min_num_tasks" {
  type    = number
  default = 1
}


variable "desired_count_instances" {
  type    = number
  default = 2
}

variable "desired_count_tasks" {
  type    = number
  default = 3
}