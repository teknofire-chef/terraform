provider "aws" {
  version = "~> 1.28"
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

resource "aws_iam_role_policy" "tag_instance_policy" {
  name        = "${var.namespace}-tag-instance-policy"
  role        = "${data.terraform_remote_state.vpc.base_role_id}"

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
        "arn:aws:ec2:*:*:instance/${aws_spot_instance_request.chef_server.spot_instance_id}"
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

resource "aws_s3_bucket" "backups" {
  bucket = "${var.namespace}-fire-backups"
  acl    = "private"
}

resource "aws_iam_role_policy" "backup_instance_policy" {
  name        = "${var.namespace}-backup-instance-policy"
  role        = "${data.terraform_remote_state.vpc.base_role_id}"

  policy = <<EOF
{
  "Statement": [
    {
      "Action": [
        "s3:CreateBucket",
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:ListBucketMultipartUploads",
        "s3:ListBucketVersions"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${var.namespace}-fire-backups"
      ]
    },
    {
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:AbortMultipartUpload",
        "s3:ListMultipartUploadParts",
        "iam:PassRole"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${var.namespace}-fire-backups/*"
      ]
    }
  ],
  "Version": "2012-10-17"
}
EOF
}
