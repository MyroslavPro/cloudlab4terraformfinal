# As i use def VPC, i check for it and received identifier
data "aws_vpc" "vpc_default" {
  default = true
}
# 
data "aws_subnets" "get_aws_subnets_info" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc_default.id]
  }
}

data "aws_subnet" "subnets_ids_list" {
  for_each = toset(data.aws_subnets.get_aws_subnets_info.ids)
  id       = each.value
}

output "subnet_ids" {
  value = [for s in data.aws_subnet.subnets_ids_list : s.id]
}

output "vpc_id_default" {
  value = data.aws_vpc.vpc_default.id
}
