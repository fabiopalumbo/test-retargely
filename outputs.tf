output "deployment_invoke_url" {
  description = "Deployment invoke url"
  value       = module.apigw.aws_api_gateway_invoke_url
}

output "lambda_function_name" {
  description = "The name of the Lambda Function"
  value       = module.text_loader.lambda_function_name
}