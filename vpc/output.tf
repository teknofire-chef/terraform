output "vpc_id" {
  value = "${module.vpc.vpc_id}"
}

output "vpc_region" {
  value = "${var.aws_region}"
}

output "cidr" {
  value = "${var.vpc_cidr}"
}

output "public_subnets" {
  value = "${module.vpc.public_subnets}"
}

output "default_sg_id" {
  value = "${aws_security_group.default.id}"
}

output "http_sg_id" {
  value = "${aws_security_group.http.id}"
}

output "windows_sg_id" {
  value = "${aws_security_group.windows_default.id}"
}

output "allowed_cidrs" {
  value = "${var.allowed_cidrs}"
}

output "base_role_id" {
  value = "${aws_iam_role.base_role.id}"
}

output "base_instance_profile_id" {
  value = "${aws_iam_instance_profile.base_profile.id}"
}
