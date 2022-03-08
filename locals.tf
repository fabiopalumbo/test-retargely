
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

    # cidrs           = chunklist(cidrsubnets(var.vpc_cidr, [for i in range(var.azs_count * 3) : var.vpc_offset]...), var.azs_count)
    public_cidrs      = ["10.0.1.0/24", "10.0.2.0/24"]
    private_cidrs     = ["10.0.11.0/24", "10.0.12.0/24"]
}
