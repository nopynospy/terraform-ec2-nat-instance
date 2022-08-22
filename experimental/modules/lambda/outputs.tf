output "lambda_arn" {
  description = "ARN of lambda function"
  value       = aws_lambda_function.this.arn
}