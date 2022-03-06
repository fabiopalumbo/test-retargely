resource "random_string" "this" {
  length  = 4
  special = false
  upper   = false
}

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

module "apigw" {
  source = "./modules/apigw"
  s3_arn = module.s3_bucket.arn

  tags = local.tags
}

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

  # Application subnets
  private_subnets               = local.private_cidrs
  private_subnet_suffix         = "private"
  private_dedicated_network_acl = true

  tags = local.tags 
}