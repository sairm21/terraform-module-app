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
