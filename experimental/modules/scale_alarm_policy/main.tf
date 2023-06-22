resource "aws_autoscaling_policy" "this" {
  name                   = var.asg_policy_name
  scaling_adjustment     = var.asg_adjustment
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = var.asg_group_name
}

resource "aws_cloudwatch_metric_alarm" "this" {
  alarm_name                = "nat-instance-exceed-${var.threshold}"
  comparison_operator       = var.comparison_operator
  evaluation_periods        = "2"
  threshold                 = var.threshold
  alarm_description         = var.alarm_description
  alarm_actions             = [aws_autoscaling_policy.this.arn]
  insufficient_data_actions = []

  metric_query {
    id          = "e1"
    expression  = var.expression
    label       = "Any metric above ${var.threshold}"
    return_data = "true"
  }

  metric_query {
    id = "m1"
    metric {
      metric_name = "CPUUtilization"
      namespace   = "AWS/EC2"
      period      = "120"
      stat        = "Average"
      dimensions = {
        AutoScalingGroupName = var.asg_group_name
      }
    }
  }
  metric_query {
    id = "m2"
    metric {
      metric_name = "NetworkIn"
      namespace   = "AWS/EC2"
      period      = "120"
      stat        = "Average"
      dimensions = {
        AutoScalingGroupName = var.asg_group_name
      }
    }
  }
  metric_query {
    id = "m3"
    metric {
      metric_name = "NetworkOut"
      namespace   = "AWS/EC2"
      period      = "120"
      stat        = "Average"
      dimensions = {
        AutoScalingGroupName = var.asg_group_name
      }
    }
  }
  metric_query {
    id = "m4"
    metric {
      metric_name = "NetworkPacketsIn"
      namespace   = "AWS/EC2"
      period      = "120"
      stat        = "Average"
      dimensions = {
        AutoScalingGroupName = var.asg_group_name
      }
    }
  }
  metric_query {
    id = "m5"
    metric {
      metric_name = "NetworkPacketsOut"
      namespace   = "AWS/EC2"
      period      = "120"
      stat        = "Average"
      dimensions = {
        AutoScalingGroupName = var.asg_group_name
      }
    }
  }
}
