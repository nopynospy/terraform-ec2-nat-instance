module "lambda_function" {
  source         = "../lambda"
  lambda_name    = var.lambda_name
  lambda_ecr_uri = var.lambda_ecr_uri
  sns_arn        = aws_sns_topic.nat_asg_scale_sns.arn
}

module "nat_security_group" {
  source                                        = "../../../modules/nat_security_group"
  nat_instance_name                             = "${var.nat_instance_name}_security_group"
  nat_instance_security_group_ingress_cidr_ipv4 = var.nat_instance_security_group_ingress_cidr_ipv4
  vpc_id                                        = var.vpc_id
}

module "aws_linux_2_data" {
  source = "../../../modules/aws_linux_2_data"
}

module "aws_linux_2_patch" {
  source              = "../../../modules/aws_linux_2_patch"
  patch_baseline_name = "aws_linux_2_patch_baseline"
  patch_group_name    = "aws_linux_2_patch_group_name"
}

resource "aws_launch_template" "this" {
  name_prefix = var.nat_instance_name
  image_id    = module.aws_linux_2_data.aws_linux_2_id
  #   key_name    = var.key_name

  iam_instance_profile {
    arn = module.ssm_iam.ssm_iam_profile_arn
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [module.nat_security_group.nat_sg_id]
    delete_on_termination       = true
  }

  tag_specifications {
    resource_type = "instance"
    tags          = local.common_tags
  }

  user_data = base64encode(<<EOT
#!/bin/bash
sudo /usr/bin/apt update
sysctl -w net.ipv4.ip_forward=1
/sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
EOT
  )

  description = "Launch template for NAT instance ${var.nat_instance_name}"
  tags        = local.common_tags
}

resource "aws_autoscaling_group" "this" {
  depends_on = [
    module.lambda_function
  ]
  name_prefix = var.nat_instance_name
  # desired_capacity    = 1
  min_size            = 1
  max_size            = 2
  vpc_zone_identifier = [var.nat_public_subnet_id]

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 2
      on_demand_percentage_above_base_capacity = 100
    }
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.this.id
        version            = "$Latest"
      }
      dynamic "override" {
        for_each = var.instance_types
        content {
          instance_type = override.value
        }
      }
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_notification" "this" {
  group_names = [
    aws_autoscaling_group.this.name
  ]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = aws_sns_topic.nat_asg_scale_sns.arn
}

module "scale_alarm_policy_up" {
  source              = "../scale_alarm_policy"
  alarm_description   = "One of the metrics has exceed 90%"
  asg_group_name      = aws_autoscaling_group.this.name
  asg_policy_name     = "nat-scale-up-policy"
  asg_adjustment      = 1
  threshold           = 90
  expression          = "m1>=90||m2>=90||m3>=90||m4>=90||m5>=90"
  comparison_operator = "GreaterThanOrEqualToThreshold"
}

module "scale_alarm_policy_down" {
  source              = "../scale_alarm_policy"
  alarm_description   = "All of the metrics are below 60%"
  asg_group_name      = aws_autoscaling_group.this.name
  asg_policy_name     = "nat-scale-down-policy"
  asg_adjustment      = -1
  threshold           = 60
  expression          = "m1<=60&&m2<=60&&m3<=60&&m4<=60&&m5<=60"
  comparison_operator = "LessThanOrEqualToThreshold"
}

resource "aws_sns_topic" "nat_asg_scale_sns" {
  name_prefix = "nat_asg_scale_"
}

resource "aws_sns_topic_subscription" "topic_lambda" {
  topic_arn = aws_sns_topic.nat_asg_scale_sns.arn
  protocol  = "lambda"
  endpoint  = module.lambda_function.lambda_arn
}

# enable SSM access
module "ssm_iam" {
  source = "../../../modules/ssm_iam_attachment"
}