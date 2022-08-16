variable "vpc_id" {
  description = "ID of the VPC the NAT instance will be created in"
  type        = string
}

variable "nat_sg_id" {
  description = "Security group ID used by NAT instance"
  type        = string
}