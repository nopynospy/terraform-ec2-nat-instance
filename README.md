# terraform-ec2-nat-instance

This repo is a fork from [Ken Helbert's terraform-ec2-nat-instance](https://github.com/kenhalbert/terraform-ec2-nat-instance)

I decided to fork from his repo because of the brevity.

For production, please use NAT Gateway.

# Original README
```
Shows how to create an EC2 NAT instance in AWS.  

A NAT instance can be a cheaper alternative to a NAT gateway.  See [my blog post on the topic](https://kenhalbert.com/posts/creating-an-ec2-nat-instance-in-aws) for a complete explanation of what a NAT instance is and why you might want to use one. 
```

# Changes made
1. Add more variables and reduce hard-coded values.
    - region_id
2. Rename variables to be more specific
    - name -> nat_instance_name
    - ami_id -> nat_instance_ami_id
    - security_group_ingress_cidr_ipv4 -> nat_instance_security_group_ingress_cidr_ipv4
    - ssh_key_name -> nat_instance_ssh_key_name
    - public_subnet_id -> nat_public_subnet_id