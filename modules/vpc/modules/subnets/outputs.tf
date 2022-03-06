output "subnet_ids" {
  description = "List of IDs of the subnets"
  value       = aws_subnet.this[*].id
}

output "subnet_arns" {
  description = "List of ARNs of the subnets"
  value       = aws_subnet.this[*].arn
}

output "subnets_cidr_blocks" {
  description = "List of cidr_blocks of the subnets"
  value       = aws_subnet.this[*].cidr_block
}

output "subnets_ipv6_cidr_blocks" {
  description = "List of IPv6 cidr_blocks of the subnets in an IPv6 enabled VPC"
  value       = aws_subnet.this[*].ipv6_cidr_block
}

output "route_table_ids" {
  description = "List of IDs of the route tables"
  value       = aws_route_table.this[*].id
}