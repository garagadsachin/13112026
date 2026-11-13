output "s3_endpoint_id"      { value = aws_vpc_endpoint.s3.id }
output "sts_endpoint_id"     { value = aws_vpc_endpoint.sts.id }
output "kinesis_endpoint_id" { value = aws_vpc_endpoint.kinesis.id }
