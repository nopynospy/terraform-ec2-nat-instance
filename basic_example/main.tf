provider "aws" {
  region     = var.region_id
  access_key = var.access_key
  secret_key = var.secret_key
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name                 = "example"
  cidr                 = var.vpc_cidr
  azs                  = ["${var.region_id}a"]
  private_subnets      = [var.private_subnet_cidr]
  public_subnets       = [var.public_subnet_cidr]
  enable_dns_hostnames = true
}

module "nat" {
  source                                        = "../"
  region_id                                     = var.region_id
  nat_instance_name                             = "NAT-instance"
  nat_instance_security_group_ingress_cidr_ipv4 = module.vpc.private_subnets_cidr_blocks[0]
  nat_public_subnet_id    = module.vpc.public_subnets[0]
  vpc_id                  = module.vpc.vpc_id
  private_route_table_ids = module.vpc.private_route_table_ids
}

module "private_security_group" {
  source = "../modules/private_security_group"
  vpc_id = module.vpc.vpc_id
  nat_sg_id = module.nat.nat_sg_id
}

module "aws_linux_2_data" {
  source = "../modules/aws_linux_2_data"
}

resource "aws_instance" "private" {
  depends_on = [
    module.nat
  ]
  ami = module.aws_linux_2_data.aws_linux_2_id
  instance_type = "t3.nano"
  subnet_id            = module.vpc.private_subnets[0]
  iam_instance_profile = module.nat.ssm_iam_profile_name

  vpc_security_group_ids = [module.private_security_group.private_sg_id]
  tags = {
    Name = "private_instance"
    Role = "private"
    "Patch Group" = module.nat.patch_group_id
  }
}

module "cloudwatch" {
  source = "../modules/cloudwatch"
  dashboard_name = "NAT-instance-dashboard"
  nat_instance_id = module.nat.nat_instance_id
  region_id = var.region_id
}