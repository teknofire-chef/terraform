output "minecraft_public_dns" {
  value = "${module.minecraft-server.public_dns}"
}
output "minecraft_eip_public_ip" {
  value = "${aws_eip.lb.public_ip}"
}
output "instance_type" {
  value = "${var.instance_type}"
}
