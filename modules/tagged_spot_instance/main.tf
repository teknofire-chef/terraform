resource "aws_spot_instance_request" "main" {
  # spot instance info
  instance_type = "${var.instance_type}"
  wait_for_fulfillment = true
  instance_interruption_behaviour = "terminate"

  # aws_instance info
  ami           = "${var.ami}"
  key_name      = "${var.key_name}"
  subnet_id     = "${var.subnet_id}"
  vpc_security_group_ids = ["${var.vpc_security_group_ids}"]
  iam_instance_profile = "${var.iam_instance_profile}"

  lifecycle {
    ignore_changes = "ami"
  }

  root_block_device {
    volume_type = "gp2"
    volume_size = "${var.instance_root_volume_size}"
  }

  tags = "${merge(var.instance_tags, map("Name", format("%s", "${var.namespace}-${var.name}")))}"
}

resource "null_resource" "main" {
  connection {
    user = "${var.username}"
    host = "${aws_spot_instance_request.main.public_dns}"
    agent = true
  }

  provisioner "file" {
    source = "${path.module}/scripts/set_tags.sh"
    destination = "/tmp/set_tags.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "echo $(curl -s http://169.254.169.254/latest/meta-data/public-hostname) | xargs sudo hostnamectl set-hostname",
      "bash /tmp/set_tags.sh ${var.aws_region} ${aws_spot_instance_request.main.id} ${aws_spot_instance_request.main.spot_instance_id}"
    ]
  }
}

resource "aws_iam_role_policy" "tag_policy" {
  name        = "${var.namespace}_${var.name}_tag_policy"
  role        = "${var.role}"

  policy = <<EOF
{
  "Statement": [
    {
      "Action": [
        "ec2:DeleteTags",
        "ec2:CreateTags",
        "ec2:DescribeTags"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:ec2:*:*:instance/${aws_spot_instance_request.main.spot_instance_id}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeSpotInstanceRequests"
      ],
      "Resource": "*"
    }
  ],
  "Version": "2012-10-17"
}
EOF
}
