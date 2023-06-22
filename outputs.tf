output "nat_sg_id" {
  description = "Security group ID for NAT instance"
  value       = module.nat_security_group.nat_sg_id
}

output "patch_group_id" {
  description = "EC2 patch group ID, to be used in EC2 tag key, 'Patch Group'"
  value       = module.aws_linux_2_patch.patch_group_id
}

output "nat_instance_id" {
  description = "ID for NAT instance"
  value       = aws_instance.this[0].id
}