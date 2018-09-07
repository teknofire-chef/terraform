variable "name" {}
variable "ami" {}
variable "username" {}
variable "aws_region" {}
variable "instance_type" {}
variable "key_name" {}
variable "subnet_id" {}
variable "vpc_security_group_ids" {
  type = "list"
}

variable "iam_instance_profile" {}
variable "role" {}
variable "instance_root_volume_size" { default = 8 }
variable "namespace" {}
variable "instance_tags" {
  type = "map"
}
