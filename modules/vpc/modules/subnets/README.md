# Subnets terraform submodule

Terraform submodule to create dynamic additional subnets

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| aws | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| acl\_tags | Additional tags for the subnets network ACL | `map(string)` | `{}` | no |
| azs | A list of availability zones names or ids in the region | `list(string)` | `[]` | no |
| create\_internet\_gateway\_route | Controls if an internet gateway route for public access should be created | `bool` | `false` | no |
| create\_nat\_gateway\_route | Controls if a nat gateway route should be created to give internet access to the subnets | `bool` | `false` | no |
| create\_subnet\_route\_table | Controls if separate route table for should be created | `bool` | `false` | no |
| dedicated\_network\_acl | Whether to use dedicated network ACL (not default) and custom rules for subnets | `bool` | `false` | no |
| enable\_ipv6 | Requests an Amazon-provided IPv6 CIDR block with a /56 prefix length for the VPC. You cannot specify the range of IP addresses, or the size of the CIDR block. | `bool` | `false` | no |
| inbound\_acl\_rules | subnets inbound network ACL rules | `list(map(string))` | <pre>[<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "from_port": 0,<br>    "protocol": "-1",<br>    "rule_action": "allow",<br>    "rule_number": 100,<br>    "to_port": 0<br>  }<br>]</pre> | no |
| internet\_gateway\_id | Id of the VPC internet gateway | `string` | n/a | yes |
| name | Name to be used on all the resources as identifier | `string` | `""` | no |
| nat\_gateway\_ids | A list of nat gateways | `list(string)` | n/a | yes |
| outbound\_acl\_rules | subnets outbound network ACL rules | `list(map(string))` | <pre>[<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "from_port": 0,<br>    "protocol": "-1",<br>    "rule_action": "allow",<br>    "rule_number": 100,<br>    "to_port": 0<br>  }<br>]</pre> | no |
| private\_route\_table\_ids | A list of private route tables | `list(string)` | n/a | yes |
| route\_table\_tags | Additional tags for the route tables | `map(string)` | `{}` | no |
| subnet\_assign\_ipv6\_address\_on\_creation | Assign IPv6 address on subnet, must be disabled to change IPv6 CIDRs. This is the IPv6 equivalent of map\_public\_ip\_on\_launch | `bool` | `null` | no |
| subnet\_ipv6\_prefixes | Assigns IPv6 subnet id based on the Amazon provided /56 prefix base 10 integer (0-256). Must be of equal length to the corresponding IPv4 subnet list | `list` | `[]` | no |
| subnet\_suffix | Suffix to append to subnets name | `string` | `""` | no |
| subnet\_tags | Additional tags for the subnets | `map(string)` | `{}` | no |
| subnets | A list of subnets | `list(string)` | n/a | yes |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |
| vpc\_id | Id of the VPC | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| route\_table\_ids | List of IDs of the route tables |
| subnet\_arns | List of ARNs of the subnets |
| subnet\_ids | List of IDs of the subnets |
| subnets\_cidr\_blocks | List of cidr\_blocks of the subnets |
| subnets\_ipv6\_cidr\_blocks | List of IPv6 cidr\_blocks of the subnets in an IPv6 enabled VPC |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
