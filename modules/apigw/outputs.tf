output "rest_api_id" {
  description = "Rest API ID"
  value       = aws_api_gateway_rest_api.this.id
}

output "root_resource_id" {
  description = "Root resource ID"
  value       = aws_api_gateway_rest_api.this.root_resource_id
}

output "api_gw_execution_arn" {
  description = "Execution ARN"
  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  value = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.this.id}/*/${aws_api_gateway_method.this.http_method}${aws_api_gateway_resource.this.path}"
}

output "aws_api_gateway_invoke_url" {
  description = "Invoke URL"
  value = aws_api_gateway_stage.this.invoke_url
}

output "api_gateway_api_key" {
  description = "API GW key value"
  value = aws_api_gateway_api_key.this.value
}
