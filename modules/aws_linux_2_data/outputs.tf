output "aws_linux_2_id" {
    description = "AMI ID of the latest Amazon Linux 2"
    value = data.aws_ami.this.id
}