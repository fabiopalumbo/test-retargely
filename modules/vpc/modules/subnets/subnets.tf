##################
# subnet
##################
resource "aws_subnet" "this" {
  count = length(var.subnets)

  vpc_id               = var.vpc_id
  cidr_block           = var.subnets[count.index]
  availability_zone    = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null
  # assign_ipv6_address_on_creation = var.subnet_assign_ipv6_address_on_creation == null ? var.assign_ipv6_address_on_creation : var.subnet_assign_ipv6_address_on_creation

  # ipv6_cidr_block = var.enable_ipv6 && length(var.subnet_ipv6_prefixes) > 0 ? cidrsubnet(aws_vpc.this[0].ipv6_cidr_block, 8, var.subnet_ipv6_prefixes[count.index]) : null

  tags = merge(
    {
      "Name" = format(
        "%s-${var.subnet_suffix}-%s",
        var.name,
        split("-", element(var.azs, count.index))[2]
      )
    },
    var.tags,
    var.subnet_tags,
  )
}

#################
# Routes
#################
resource "aws_route_table" "this" {
  count = var.create_subnet_route_table ? length(var.subnets) : 0

  vpc_id = var.vpc_id

  tags = merge(
    {
      "Name" = format("${var.name}-${var.subnet_suffix}-%s", split("-", element(var.azs, count.index))[2])
    },
    var.tags,
    var.route_table_tags,
  )
}

resource "aws_route" "internet_gateway" {
  count = var.create_subnet_route_table && var.create_internet_gateway_route ? 1 : 0

  route_table_id         = aws_route_table.this[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.internet_gateway_id

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "internet_gateway_ipv6" {
  count = var.create_subnet_route_table && var.enable_ipv6 ? 1 : 0

  route_table_id              = aws_route_table.this[0].id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = var.internet_gateway_id
}

resource "aws_route" "nat_gateway" {
  count = var.create_subnet_route_table && var.create_nat_gateway_route ? length(var.nat_gateway_ids) : 0

  route_table_id         = element(aws_route_table.this.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(var.nat_gateway_ids, count.index)

  timeouts {
    create = "5m"
  }
}

# resource "aws_route" "private_ipv6_egress" {
#   count = var.create_vpc && var.create_egress_only_igw && var.enable_ipv6 ? length(var.private_subnets) : 0

#   route_table_id              = element(aws_route_table.private.*.id, count.index)
#   destination_ipv6_cidr_block = "::/0"
#   egress_only_gateway_id      = element(aws_egress_only_internet_gateway.this.*.id, 0)
# }

resource "aws_route_table_association" "this" {
  count = length(var.subnets)

  subnet_id      = element(aws_subnet.this.*.id, count.index)
  route_table_id = element(aws_route_table.this.*.id, count.index)
}

########################
# Network ACLs
########################
resource "aws_network_acl" "this" {
  count = var.dedicated_network_acl ? 1 : 0

  vpc_id     = var.vpc_id
  subnet_ids = aws_subnet.this.*.id

  tags = merge(
    {
      "Name" = format("%s-${var.subnet_suffix}", var.name)
    },
    var.tags,
    var.acl_tags,
  )
}

resource "aws_network_acl_rule" "inbound" {
  count = var.dedicated_network_acl ? length(var.inbound_acl_rules) : 0

  network_acl_id = aws_network_acl.this[0].id

  egress          = false
  rule_number     = var.inbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.inbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.inbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.inbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.inbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.inbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.inbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.inbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.inbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

resource "aws_network_acl_rule" "outbound" {
  count = var.dedicated_network_acl ? length(var.outbound_acl_rules) : 0

  network_acl_id = aws_network_acl.this[0].id

  egress          = true
  rule_number     = var.outbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.outbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.outbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.outbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.outbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.outbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.outbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.outbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.outbound_acl_rules[count.index], "ipv6_cidr_block", null)
}