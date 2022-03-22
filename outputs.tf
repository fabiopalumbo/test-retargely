output "deployment_invoke_url" {
  description = "Deployment invoke url"
  value       = module.apigw.aws_api_gateway_invoke_url
}

output "s3_bucket_id" {
  description = "The name of the bucket."
  value       = module.s3_bucket.s3_bucket_id
}