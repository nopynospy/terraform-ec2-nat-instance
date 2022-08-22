variable "lambda_name" {
  type        = string
  description = "Lambda function name"
}

variable "lambda_ecr_uri" {
  type        = string
  description = "URI for the ECR version for lambda code"
}

variable "sns_arn" {
  type        = string
  description = "ARN for SNS to serve as lambda trigger"
}