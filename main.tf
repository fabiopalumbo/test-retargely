resource "random_string" "this" {
  length  = 4
  special = false
  upper   = false
}

#######
# VPC #
#######

module "vpc" {
  source = "./modules/vpc"

  name = "${local.identifier}-vpc"
  cidr = var.vpc_cidr
  azs  = slice(data.aws_availability_zones.available.names, 0, var.azs_count)

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true
  enable_dns_hostnames   = true
  enable_dhcp_options    = true

  # Endpoints
  enable_s3_endpoint = true

  enable_apigw_endpoint              = true
  apigw_endpoint_private_dns_enabled = true
  apigw_endpoint_security_group_ids  = [aws_security_group.endpoint_securitygroup.id]
  apigw_endpoint_subnet_ids          = module.vpc.private_subnets

  # Public subnets
  public_subnets               = local.public_cidrs
  public_dedicated_network_acl = true

  # Private subnets
  private_subnets               = local.private_cidrs
  private_subnet_suffix         = "private"
  private_dedicated_network_acl = true

  tags = local.tags 
}


##################
# S3 Bucket      #
##################

module "s3_bucket" {
  source = "./modules/s3_bucket"

  bucket = "${local.identifier}-${data.aws_region.current.name}-${data.aws_caller_identity.current.account_id}-${random_string.this.id}"
  acl    = "private"

  force_destroy = true

  versioning = {
    enabled = false
  }

  tags = local.tags
}

##################
# API Gateway    #
##################

module "apigw" {
  source = "./modules/apigw"
  s3_arn        = module.s3_bucket.s3_bucket_arn
  lambda_arn    = module.text_loader.0.lambda_function_invoke_arn

  tags = local.tags

  depends_on = [
    module.text_loader,
    module.s3_bucket
  ]

}

##########
# Lambda #
##########

module "text_loader" {
  count = var.lambda_enabled ? 1 : 0

  source = "./modules/lambda"

  function_name = "${local.identifier}-text-loader"
  description   = "Lambda function to asynchronous retrieve file from s3 bucket"
  handler       = var.lambda.text_loader.handler
  runtime       = var.lambda.text_loader.runtime
  timeout       = 30

  #source_path   = var.lambda.text_loader.source_path
  local_existing_package = data.null_data_source.downloaded_package.outputs["filename"]

  create_package      = false

  attach_policies = true
  number_of_policies = 3
  policies        = [
    aws_iam_policy.text_lambda_loader[0].arn,
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
    "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess",
  ]

  publish = true

  environment_variables = {
    DEBUG = "true"
    LOG_LEVEL = "info"
  }

  tags = local.tags
}

locals {
  package_url = "https://raw.githubusercontent.com/terraform-aws-modules/terraform-aws-lambda/master/examples/fixtures/python3.8-zip/existing_package.zip"
  downloaded  = "downloaded_package_${md5(local.package_url)}.zip"
}

resource "null_resource" "download_package" {
  triggers = {
    downloaded = local.downloaded
  }

  provisioner "local-exec" {
    command = "curl -L -o ${local.downloaded} ${local.package_url}"
  }
}

data "null_data_source" "downloaded_package" {
  inputs = {
    id       = null_resource.download_package.id
    filename = local.downloaded
  }
}



###############################
# VPC Endpoint Security Group #
###############################

resource "aws_security_group" "endpoint_securitygroup" {

  name        = "${local.identifier}-vpc-endpoint-${random_string.this.id}"
  description = "Allow VPC traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "Allow from VPC"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [var.vpc_cidr]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = local.tags
}

#####################
# Lambda IAM Policy #
#####################

resource "aws_iam_policy" "text_lambda_loader" {
  count = var.lambda_enabled ? 1 : 0

  name        = "${local.identifier}-lambda-loader-${random_string.this.id}"
  path        = "/"
  description = "Text loader lambda policy"
  policy = data.aws_iam_policy_document.text_lambda_loader[0].json
}

data "aws_iam_policy_document" "text_lambda_loader" {
  count = var.lambda_enabled ? 1 : 0
  statement {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:GetObjectAcl"
      ]
      resources = [
        "arn:aws:s3:::{var.bucket}",
        "arn:aws:s3:::{var.bucket}/*",
      ]
  }
  statement {        
      effect = "Allow"
      actions = [
        "s3:ListAllMyBuckets"
      ]
      resources = ["*"]
      }
  statement {        
      effect = "Allow"
      actions = [
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ]
      resources = [
        "arn:aws:s3:::{var.bucket}"
      ]
      }
}

################
# Cloudwatch   #
################

module "all_lambdas_errors_alarm" {
  source = "./modules/cloudwatch/metric-alarm"

  alarm_name          = "${local.identifier}-all-lambdas-errors-${random_string.this.id}"
  alarm_description   = "Lambdas with errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 0
  period              = 60
  unit                = "Count"

  namespace   = "AWS/Lambda"
  metric_name = "Errors"
  statistic   = "Maximum"

  # alarm_actions = [module.aws_sns_topic.sns_topic_arn]
}

module "alarm" {
  source = "./modules/cloudwatch/metric-alarm"

  alarm_name          = "${local.identifier}-lambda-duration-${random_string.this.id}"
  alarm_description   = "Lambda duration is too high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 10
  period              = 60
  unit                = "Milliseconds"

  namespace   = "AWS/Lambda"
  metric_name = "Duration"
  statistic   = "Maximum"

  dimensions = {
    FunctionName = "${local.identifier}-text-loader"
  }

  # alarm_actions = [module.aws_sns_topic.sns_topic_arn]
}

module "dashboard" {
  source = "./modules/cloudwatch/dashboard"
  dashboard_name = var.identifier

}

resource "aws_api_gateway_account" "this" {
  cloudwatch_role_arn = aws_iam_role.cloudwatch.arn
}

resource "aws_iam_role" "cloudwatch" {
  name = "api_gateway_cloudwatch_global"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cloudwatch" {
  name = "default"
  role = aws_iam_role.cloudwatch.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}
