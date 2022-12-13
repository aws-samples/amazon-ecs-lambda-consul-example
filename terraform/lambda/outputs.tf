output "lambda_arn" {
  value       = aws_lambda_function.greeter.arn
  description = "ARN of Greeter Lambda Function"
}