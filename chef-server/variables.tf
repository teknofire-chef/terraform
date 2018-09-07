variable "default_tags" {
  description = "A list of default tags that will be applied to resources"
  default = {
  }
}

variable "vpc_state_path" {
  description = "Relative path to the location of the vpc terraform.tfstate file"
  default = "../vpc/terraform.tfstate"
}

variable "namespace" {
}

variable "aws_profile" {
  description = "AWS Profile to use for credentials"
}

variable "aws_region" {
  default = "us-west-2"
}

variable "aws_key_name" {
  description = "AWS Key name to use for authentication to ec2 instances"
}

#variable "spot_price" {
#  description = "Max price for spot instance request"
#  type = "map"
#}

variable "instance_type" {
  default = "m3.large"
  description = "AWS Instance Type, this should match with spot price"
}

variable "chef_config_path" {
  description = "Local path to where pem files and the knife.rb files live"
  default = "../../.chef"
}

variable "chef_server_version" {
  default = "latest"
}

variable "admin_email" {
  description = "Email for chef admin user"
}

variable "chef_password" {
  description = "Password for chef_user"
}
