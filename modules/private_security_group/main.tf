resource "aws_security_group" "this" {
  name        = "example-terraform-aws-nat-instance"
  description = "expose http service"
  vpc_id      = var.vpc_id
  ingress {
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [var.nat_sg_id]
  }
  ingress {
    protocol        = "tcp"
    from_port       = 443
    to_port         = 443
    security_groups = [var.nat_sg_id]
  }
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}