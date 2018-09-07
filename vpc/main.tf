provider "aws" {
  version = "~> 1.28"
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  # source = "github.com/terraform-community-modules/tf_aws_vpc"

  name = "${var.namespace}"

  cidr = "${var.vpc_cidr}"
  public_subnets  = "${var.vpc_public_subnets}"
  enable_dns_hostnames = true
  enable_dns_support = true
  enable_s3_endpoint = false
  map_public_ip_on_launch = true
  enable_nat_gateway = false

  azs      = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]

  tags = "${var.default_tags}"
}

resource "aws_security_group" "default" {
  name        = "${var.namespace}_default_allows"
  description = "Allow just ssh in"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.allowed_cidrs}", "${var.vpc_cidr}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "http" {
  name        = "${var.namespace}_http"
  description = "Allow just http/s in"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.allowed_cidrs}", "${var.vpc_cidr}"]
    security_groups = ["${aws_security_group.default.id}"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${var.allowed_cidrs}", "${var.vpc_cidr}"]
    security_groups = ["${aws_security_group.default.id}"]
  }
}

resource "aws_security_group" "windows_default" {
  name        = "${var.namespace}_default_windows"
  description = "Allow just ssh in"
  vpc_id      = "${module.vpc.vpc_id}"

  # WINRM HTTP/HTTPS
  ingress {
    from_port   = 5985
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = ["${var.allowed_cidrs}", "${var.vpc_cidr}"]
    security_groups = ["${aws_security_group.default.id}"]
  }
  # RDP
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["${var.allowed_cidrs}", "${var.vpc_cidr}"]
    security_groups = ["${aws_security_group.default.id}"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "base_role" {
  name = "${var.namespace}_base_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service":[
          "ec2.amazonaws.com",
          "es.amazonaws.com"
        ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "base_profile" {
  name = "${var.namespace}_base_profile"
  role = "${aws_iam_role.base_role.name}"
}
