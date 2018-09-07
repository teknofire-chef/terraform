variable "default_tags" {
  description = "A list of default tags that will be applied to resources, do not change this here instead modify the values in terraform.tfvars"
  type = "map"
  default = {
  }
}

variable "aws_profile" {
  description = "AWS Credentials profile to use"
  default = "default"
}

variable "namespace" {
  description = "Namespace to attach to created resources"
}

variable "allowed_cidrs" {
  default = ["0.0.0.0/0"]
}

variable "vpc_public_subnets" {
  default = ["10.30.30.0/24", "10.30.40.0/24"]
}

variable "aws_region" {
  default = "us-west-2"
}

variable "vpc_cidr" {
  default = "10.30.0.0/16"
}
