resource "aws_security_group" "this" {
  name        = "${var.nat_instance_name}_security_group"
  description = "Security group for NAT instance ${var.nat_instance_name}"
  vpc_id      = var.vpc_id

  ingress = [
    {
      description      = "Ingress CIDR"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = [var.nat_instance_security_group_ingress_cidr_ipv4]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = true
    }
  ]

  egress = [
    {
      description      = "Default egress"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = true
    }
  ]
}