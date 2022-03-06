resource "random_string" "this" {
  length  = 4
  special = false
  upper   = false
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
  acl    = "private"
  s3_arn = module.s3_bucket.s3_bucket_arn

  tags = local.tags
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

##########
# Lambda #
##########

module "text_loader" {
  count = var.lambda_enabled ? 1 : 0

  source = "./modules/lambda"

  function_name = "${local.identifier}-text-loader-${random_string.this.id}"
  description   = "Lambda function to asynchronous retrieve file from s3 bucket"
  handler       = var.lambda.text_loader.handler
  runtime       = var.lambda.text_loader.runtime
  timeout       = 30

  source_path   = var.lambda.text_loader.source_path
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
        "arn:aws:s3:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:{var.bucket}",
        "arn:aws:s3:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:{var.bucket}/*",
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
        "arn:aws:s3:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:{var.bucket}"
      ]
      }
}