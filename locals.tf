
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

locals {
    identifier = "${var.identifier}-retargely"

    tags = {
      Identifier  = var.identifier
      Terraform   = true
      Workspace   = terraform.workspace
      Environment = var.environment
    }

    cidrs             = chunklist(cidrsubnets(var.vpc_cidr, [for i in range(var.azs_count * 3) : var.vpc_offset]...), var.azs_count)
    public_cidrs      = local.cidrs[0]
    private_cidrs     = local.cidrs[1]
}
