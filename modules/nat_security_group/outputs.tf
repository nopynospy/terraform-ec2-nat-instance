output "nat_sg_id" {
    description = "Security group ID for NAT instance"
    value = aws_security_group.this.id
}