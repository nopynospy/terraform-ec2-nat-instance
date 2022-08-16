output "ssm_iam_profile_name" {
  value = aws_iam_instance_profile.this.name
}

output "ssm_iam_profile_arn" {
  value = aws_iam_instance_profile.this.arn
}