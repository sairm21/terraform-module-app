variable "env" {}
variable "component" {}
variable "tags" {
  default = {}
}
variable "subnets" {}
variable "vpc_id" {}
variable "app_port" {}
variable "sg_subnets_cidr" {}
variable "instance_type" {}
variable "kms_key_id" {}
variable "min_size" {}
variable "max_size" {}
variable "desired_capacity" {}
variable "bastion_host" {}
variable "lb_dns_name" {}
variable "listener_arn" {}
variable "lb_rule_priority" {}
