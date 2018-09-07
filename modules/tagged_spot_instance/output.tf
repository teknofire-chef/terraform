output "public_dns" {
  value = "${aws_spot_instance_request.main.public_dns}"
}
output "instance_id" {
  value = "${aws_spot_instance_request.main.spot_instance_id}"
}
