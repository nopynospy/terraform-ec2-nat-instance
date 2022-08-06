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
  key_name = var.ssh_key_name
  network_interface {
    network_interface_id = aws_network_interface.network_interface.id
    device_index = 0
  }
  user_data = <<EOT
#!/bin/bash
sudo /usr/bin/apt update
sudo /usr/bin/apt install ifupdown
/bin/echo '#!/bin/bash
if [[ $(sudo /usr/sbin/iptables -t nat -L) != *"MASQUERADE"* ]]; then
  /bin/echo 1 > /proc/sys/net/ipv4/ip_forward
  /usr/sbin/iptables -t nat -A POSTROUTING -s ${var.security_group_ingress_cidr_ipv4} -j MASQUERADE
fi
' | sudo /usr/bin/tee /etc/network/if-pre-up.d/nat-setup
sudo chmod +x /etc/network/if-pre-up.d/nat-setup
sudo /etc/network/if-pre-up.d/nat-setup 
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