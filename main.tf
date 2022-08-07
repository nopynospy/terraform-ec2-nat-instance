terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 2.7.0"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region = var.region_id
}

resource "aws_security_group" "security_group" {
  name = "${var.nat_instance_name}_security_group"
  description = "Security group for NAT instance ${var.nat_instance_name}"
  vpc_id = var.vpc_id

  ingress = [
    {
      description = "Ingress CIDR"
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = [var.nat_instance_security_group_ingress_cidr_ipv4]
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = true
    }
  ]

  egress = [
    {
      description = "Default egress"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = true
    }
  ]
}

resource "aws_instance" "nat_instance" {
  ami = var.nat_instance_ami_id
  instance_type = var.nat_instance_type
  count = 1
  # For better security, just use SSM
  # key_name = var.nat_instance_ssh_key_name
  iam_instance_profile   = aws_iam_instance_profile.nat_iam_instance_profile.name
  network_interface {
    network_interface_id = aws_network_interface.network_interface.id
    device_index = 0
  }
  user_data = <<EOT
#!/bin/bash
sudo /usr/bin/apt update
sysctl -w net.ipv4.ip_forward=1
/sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
  EOT

  tags = {
    Name = var.nat_instance_name
    Role = "nat"
  }
}

# use this network interface for the private subnet route table route
resource "aws_network_interface" "network_interface" {
  subnet_id = var.nat_public_subnet_id
  source_dest_check = false
  security_groups = [aws_security_group.security_group.id]

  tags = {
    Name = "${var.nat_instance_name}_network_interface"
  }
}

resource "aws_eip" "nat_public_ip" {
  instance = aws_instance.nat_instance[0].id
  vpc      = true
}

resource "aws_route" "this" {
  count                  = length(var.private_route_table_ids)
  route_table_id         = var.private_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.network_interface.id
}


# enable SSM access
resource "aws_iam_instance_profile" "nat_iam_instance_profile" {
  role = aws_iam_role.nat_iam_role.name
}

resource "aws_iam_role" "nat_iam_role" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "nat_ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.nat_iam_role.name
}