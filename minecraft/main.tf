provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

data "terraform_remote_state" "vpc" {
  backend = "local"

  config {
    path = "${path.module}/${var.vpc_state_path}"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

module "minecraft-server" {
  source = "../modules/tagged_spot_instance"

  name                    = "minecraft-server"
  namespace               = "${var.namespace}"

  ami                     = "${data.aws_ami.ubuntu.id}"
  username                = "ubuntu"

  aws_region              = "${var.aws_region}"
  instance_type           = "${var.my_instance_type}"
  key_name                = "${var.aws_key_name}"
  subnet_id               = "${data.terraform_remote_state.vpc.public_subnets[0]}"
  vpc_security_group_ids  = ["${data.terraform_remote_state.vpc.default_sg_id}","${data.terraform_remote_state.vpc.http_sg_id}", "${aws_security_group.mineos.id}"]
  iam_instance_profile    = "${data.terraform_remote_state.vpc.base_instance_profile_id}"
  role                    = "${data.terraform_remote_state.vpc.base_role_id}"
  instance_tags           = "${var.default_tags}"
  instance_root_volume_size = 20
}

resource "aws_eip" "lb" {
  instance = "${module.minecraft-server.instance_id}"
  vpc      = true
}

resource "aws_security_group" "mineos" {
  name        = "default_mineos"
  description = "Allow just mineos"
  vpc_id      = "${data.terraform_remote_state.vpc.vpc_id}"

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.allowed_cidrs}", "${data.terraform_remote_state.vpc.cidr}"]
  }

  ingress {
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
