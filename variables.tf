variable "region_id" {
  description = "Region to launch the NAT instance"
  type = string
}

variable "nat_instance_name" {
  description = "A unique name for the NAT instance"
  type = string
}

variable "nat_instance_ami_id" {
  description = "ID of the AMI to use"
  type = string
}

variable "nat_instance_security_group_ingress_cidr_ipv4" {
  description = "Security group ingress (IPV4) for NAT instance"
  type = string
}

variable "nat_instance_ssh_key_name" {
  description = "Name of the SSH key for the NAT instance"
  type = string
}

variable "nat_public_subnet_id" {
  description = "ID of the subnet the instance will be created in"
  type = string
}

variable "vpc_id" {
  description = "ID of the VPC the NAT instance will be created in"
  type = string
}

 variable "nat_instance_type" {
  type = string
  description = "Instance type for NAT"
  default = "t3.nano"
 }

 variable "private_route_table_ids" {
  description = "List of ID of the route tables for the private subnets."
  type        = list(string)
  default     = []
}