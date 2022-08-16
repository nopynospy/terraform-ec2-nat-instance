variable "nat_instance_name" {
  description = "A unique name for the NAT instance"
  type        = string
}

variable "nat_instance_security_group_ingress_cidr_ipv4" {
  description = "Security group ingress (IPV4) for NAT instance"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC the NAT instance will be created in"
  type        = string
}