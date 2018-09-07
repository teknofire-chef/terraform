resource "aws_spot_instance_request" "chef_server" {
  # spot instance info
  instance_type = "${var.instance_type}"
  #spot_price = "${lookup(var.spot_price, var.instance_type)}"
  wait_for_fulfillment = true
  instance_interruption_behaviour = "stop"

  # aws_instance info
  ami           = "${data.aws_ami.ubuntu.id}"
  key_name      = "${var.aws_key_name}"
  subnet_id     = "${data.terraform_remote_state.vpc.public_subnets[1]}"
  vpc_security_group_ids = ["${data.terraform_remote_state.vpc.default_sg_id}","${data.terraform_remote_state.vpc.http_sg_id}"]
  lifecycle {
    ignore_changes = "ami"
  }
  iam_instance_profile = "${data.terraform_remote_state.vpc.base_instance_profile_id}"

  tags = "${merge(var.default_tags, map("Name", format("%s", "${var.namespace}-chef-server")))}"
}

resource "null_resource" "chef_server" {
  connection {
    user = "ubuntu"
    host = "${aws_spot_instance_request.chef_server.public_dns}"
    agent = true
  }

  provisioner "file" {
    source = "../scripts/set_tags.sh"
    destination = "/tmp/set_tags.sh"
  }

  provisioner "file" {
    source = "../scripts/install_chef_server.sh"
    destination = "/tmp/install_chef_server.sh"
  }

  # this will copy the tags from the spot instance request to the created instance
  provisioner "remote-exec" {
    inline = [
      "bash /tmp/set_tags.sh ${var.aws_region} ${aws_spot_instance_request.chef_server.id} ${aws_spot_instance_request.chef_server.spot_instance_id}",
      "chmod +x /tmp/install_chef_server.sh",
      "sudo /tmp/install_chef_server.sh ${var.chef_password} ${var.chef_server_version}",
      "rm /tmp/set_tags.sh /tmp/install_chef_server.sh"
    ]
  }

  # scp the user pem file to local
  provisioner "local-exec" {
    command = <<EOF
mkdir -p ${var.chef_config_path}
echo ${aws_spot_instance_request.chef_server.public_dns} > ${var.chef_config_path}/chef_server_dns.txt
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@${aws_spot_instance_request.chef_server.public_dns}:/drop/teknofire.pem ${var.chef_config_path}/teknofire.pem
EOF
  }
}
