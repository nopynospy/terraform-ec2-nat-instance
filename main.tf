terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = var.region_id
}

module "nat_security_group" {
  source = "./modules/nat_security_group"
  nat_instance_name = var.nat_instance_name
  nat_instance_security_group_ingress_cidr_ipv4 = var.nat_instance_security_group_ingress_cidr_ipv4
  vpc_id = var.vpc_id
}

module "aws_linux_2_data" {
  source = "./modules/aws_linux_2_data"
}

module "aws_linux_2_patch" {
  source = "./modules/aws_linux_2_patch"
  patch_baseline_name = "aws_linux_2_patch_baseline"
  patch_group_name = "aws_linux_2_patch_group_name"
}

resource "aws_instance" "this" {
  instance_type = var.nat_instance_type
  count         = 1
  monitoring    = true
  ami = module.aws_linux_2_data.aws_linux_2_id
  # For better security, just use SSM
  # key_name = var.nat_instance_ssh_key_name
  iam_instance_profile = module.ssm_iam.ssm_iam_profile_name
  network_interface {
    network_interface_id = aws_network_interface.this.id
    device_index         = 0
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
    "Patch Group" = module.aws_linux_2_patch.patch_group_id
  }
}

# use this network interface for the private subnet route table route
resource "aws_network_interface" "this" {
  subnet_id         = var.nat_public_subnet_id
  source_dest_check = false
  security_groups   = [module.nat_security_group.nat_sg_id]

  tags = {
    Name = "${var.nat_instance_name}_network_interface"
  }
}

resource "aws_eip" "this" {
  instance = aws_instance.this[0].id
  vpc      = true
}

resource "aws_route" "this" {
  count                  = length(var.private_route_table_ids)
  route_table_id         = var.private_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.this.id
}

module "ssm_iam" {
  source = "./modules/ssm_iam_attachment"
}