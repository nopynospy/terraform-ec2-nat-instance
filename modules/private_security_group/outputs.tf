output "private_sg_id" {
    description = "Security group ID for private subnet"
    value = aws_security_group.this.id
}