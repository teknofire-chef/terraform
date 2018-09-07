output "chef_server_request_id" {
  value = "${aws_spot_instance_request.chef_server.id}"
}

output "chef_server_public_dns" {
  value = "${aws_spot_instance_request.chef_server.public_dns}"
}
