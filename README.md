# terraform-ec2-nat-instance

This repo is a fork from [Ken Helbert's terraform-ec2-nat-instance](https://github.com/kenhalbert/terraform-ec2-nat-instance)

I decided to fork from his repo because of the brevity. Nevertheless, some infrastructure designs took inspirations from [int128's terraform-aws-nat-instance](https://github.com/int128/terraform-aws-nat-instance)

For production, please use NAT Gateway.

# Changes made
1. Add more variables and reduce hard-coded values.
    - region_id
2. Rename variables to be more specific
    - name -> nat_instance_name
    - ami_id -> nat_instance_ami_id
    - security_group_ingress_cidr_ipv4 -> nat_instance_security_group_ingress_cidr_ipv4
    - ssh_key_name -> nat_instance_ssh_key_name
    - public_subnet_id -> nat_public_subnet_id
3. Features added
    - SSM for NAT instance (Better security, no need to open port 22 and rely on SSH key)
4. Replace user_data for nat_instance
    - Tested original code in US-East-1 region, but private instance could not ping google.com
    - Now use [these two lines from this blog post](https://www.kabisa.nl/tech/cost-saving-with-nat-instances/#the-ec2-instance) instead