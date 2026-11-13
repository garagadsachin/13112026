output "compute_subnet_ids"  { value = aws_subnet.compute[*].id }
output "endpoint_subnet_ids" { value = aws_subnet.endpoint[*].id }
