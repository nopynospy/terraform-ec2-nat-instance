# output "network_interface_id" {
#   description = "ID of the NAT instance's network interface"
#   value = aws_network_interface.network_interface.id
# }

# output "instance_id" {
#   description = "ID of the instance"
#   value = aws_instance.nat_instance[0].id
# }

output "nat_sg_id" {
  value = aws_security_group.security_group.id
}