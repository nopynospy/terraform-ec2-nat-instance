output "nat_sg_id" {
  description = "Security group ID for NAT instance"
  value       = module.nat_security_group.nat_sg_id
}

output "ssm_iam_profile_name" {
  description = "IAM SSM instance profile name (for reusing to add SSM to other instances)"
  value       = module.ssm_iam.ssm_iam_profile_name
}

output "patch_group_id" {
  description = "EC2 patch group ID, to be used in EC2 tag key, 'Patch Group'"
  value       = module.aws_linux_2_patch.patch_group_id
}