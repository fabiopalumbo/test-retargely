#  ############ Subnets ############

variable "subnets" {
  description = "A list of subnets"
  type        = list(string)

  validation {
    condition = (
      length(var.subnets) > 1
    )
    error_message = "You must specify at least one subnet."
  }
}
variable "subnet_suffix" {
  description = "Suffix to append to subnets name"
  type        = string
  default     = ""
}
variable "subnet_tags" {
  description = "Additional tags for the subnets"
  type        = map(string)
  default     = {}
}

#  ############# Routes ############

variable "create_subnet_route_table" {
  description = "Controls if separate route table for should be created"
  type        = bool
  default     = false
}
variable "create_internet_gateway_route" {
  description = "Controls if an internet gateway route for public access should be created"
  type        = bool
  default     = false
}
variable "create_nat_gateway_route" {
  description = "Controls if a nat gateway route should be created to give internet access to the subnets"
  type        = bool
  default     = false
}
variable "route_table_tags" {
  description = "Additional tags for the route tables"
  type        = map(string)
  default     = {}
}

#  ############## IPv6 #############

variable "subnet_ipv6_prefixes" {
  description = "Assigns IPv6 subnet id based on the Amazon provided /56 prefix base 10 integer (0-256). Must be of equal length to the corresponding IPv4 subnet list"
  type        = list
  default     = []
}
variable "subnet_assign_ipv6_address_on_creation" {
  description = "Assign IPv6 address on subnet, must be disabled to change IPv6 CIDRs. This is the IPv6 equivalent of map_public_ip_on_launch"
  type        = bool
  default     = null
}

#  ############## ACLs #############

variable "acl_tags" {
  description = "Additional tags for the subnets network ACL"
  type        = map(string)
  default     = {}
}
variable "dedicated_network_acl" {
  description = "Whether to use dedicated network ACL (not default) and custom rules for subnets"
  type        = bool
  default     = false
}
variable "inbound_acl_rules" {
  description = "subnets inbound network ACL rules"
  type        = list(map(string))

  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
}

variable "outbound_acl_rules" {
  description = "subnets outbound network ACL rules"
  type        = list(map(string))

  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
}

#  ########## Passthrough ##########

variable "vpc_id" {
  description = "Id of the VPC"
  type        = string
}

variable "name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
  default     = ""
}

variable "azs" {
  description = "A list of availability zones names or ids in the region"
  type        = list(string)
  default     = []
}

# variable "nat_gateway_count" {
#   description = "Number of NAT Gateways in the VPC"
#   type        = number
# }

variable "enable_ipv6" {
  description = "Requests an Amazon-provided IPv6 CIDR block with a /56 prefix length for the VPC. You cannot specify the range of IP addresses, or the size of the CIDR block."
  type        = bool
  default     = false
}

variable "internet_gateway_id" {
  description = "Id of the VPC internet gateway"
  type        = string
}

variable "nat_gateway_ids" {
  description = "A list of nat gateways"
  type        = list(string)
}

variable "private_route_table_ids" {
  description = "A list of private route tables"
  type        = list(string)
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}