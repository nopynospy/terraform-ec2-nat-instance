variable "asg_group_name" {
  type        = string
  description = "Auto scaling group name"
}

variable "asg_policy_name" {
    type = string
    description = "Name of ASG policy"
}

variable "asg_adjustment" {
    type = number
    description = "Instance amount to add or subtract"
}

variable "threshold" {
    type = number
    description = "Threshold of when to scale"
}

variable "expression" {
    type = string
    description = "Alarm trigger expression"
}

variable "comparison_operator" {
    type = string
    description = "Alarm trigger comparison operator"
}

variable "alarm_description" {
    type = string
    description = "Description for alarm"
}