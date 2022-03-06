data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "random_string" "this" {
  length  = 4
  special = false
  upper   = false
}

# API Gateway
resource "aws_api_gateway_rest_api" "this" {
  name        = "${var.identifier}-stream"
  description = "${var.identifier} Endpoint"
  api_key_source  = "HEADER"
  
  endpoint_configuration {
    types = [ "EDGE" ]
  }

  tags = merge(
      {
        "Name" = "stream-api-${var.identifier}"
      },
      var.tags
    )  
}

resource "aws_api_gateway_resource" "this" {
  path_part   = "stream"
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.this.id
}

resource "aws_api_gateway_method" "this" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.this.id
  http_method   = "PUT"
  authorization = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "this" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.this.id
  http_method             = aws_api_gateway_method.this.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.this.invoke_arn
}

resource "aws_api_gateway_method_response" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.this.id
  http_method = aws_api_gateway_method.this.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.this.id
  http_method = aws_api_gateway_method.this.http_method
  status_code = aws_api_gateway_method_response.this.status_code

  depends_on = [
    aws_api_gateway_integration.this
  ]
}

resource "aws_api_gateway_deployment" "this" {

  rest_api_id = aws_api_gateway_rest_api.this.id

  lifecycle {
    create_before_destroy = true
  }  

  depends_on = [
    aws_api_gateway_method.this,
    aws_api_gateway_integration.this
  ]
}

resource "aws_api_gateway_stage" "this" {
  stage_name    = "stream"
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id

  lifecycle {
    create_before_destroy = false
  }  

}

resource "aws_api_gateway_usage_plan" "this" {
  name = "${var.identifier}-stream"

  api_stages {
    api_id = aws_api_gateway_rest_api.this.id
    stage  = aws_api_gateway_stage.this.stage_name
  }
}

resource "aws_api_gateway_api_key" "this" {
  name = "${var.identifier}-stream"
}

resource "aws_api_gateway_usage_plan_key" "this" {
  key_id        = aws_api_gateway_api_key.this.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.this.id
}
