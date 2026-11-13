output "compute_route_table_ids" { value = aws_route_table.compute[*].id }
output "endpoint_route_table_id" { value = aws_route_table.endpoint.id }
