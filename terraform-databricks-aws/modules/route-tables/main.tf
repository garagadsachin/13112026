locals {
  name_prefix = "${var.project_name}-${var.env}"
}

# ── Compute route table (one per subnet for independent routing) ───────────────
resource "aws_route_table" "compute" {
  count  = length(var.compute_subnet_ids)
  vpc_id = var.vpc_id

  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-compute-rt-${count.index}"
    Environment = var.env
  })
}

resource "aws_route_table_association" "compute" {
  count          = length(var.compute_subnet_ids)
  subnet_id      = var.compute_subnet_ids[count.index]
  route_table_id = aws_route_table.compute[count.index].id
}

# S3 gateway endpoint route – added to every compute route table.
resource "aws_vpc_endpoint_route_table_association" "s3_compute" {
  count           = length(aws_route_table.compute)
  route_table_id  = aws_route_table.compute[count.index].id
  vpc_endpoint_id = var.s3_gateway_endpoint_id
}

# Optional Transit Gateway routes on compute route tables.
locals {
  tgw_rt_pairs = var.tgw_id != null ? [
    for pair in setproduct(range(length(aws_route_table.compute)), var.tgw_routes) : {
      rt_index = pair[0]
      cidr     = pair[1]
    }
  ] : []
}

resource "aws_route" "tgw_compute" {
  count                  = length(local.tgw_rt_pairs)
  route_table_id         = aws_route_table.compute[local.tgw_rt_pairs[count.index].rt_index].id
  destination_cidr_block = local.tgw_rt_pairs[count.index].cidr
  transit_gateway_id     = var.tgw_id
}

# ── Endpoint route table ──────────────────────────────────────────────────────
resource "aws_route_table" "endpoint" {
  vpc_id = var.vpc_id

  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-endpoint-rt"
    Environment = var.env
  })
}

resource "aws_route_table_association" "endpoint" {
  count          = length(var.endpoint_subnet_ids)
  subnet_id      = var.endpoint_subnet_ids[count.index]
  route_table_id = aws_route_table.endpoint.id
}

resource "aws_vpc_endpoint_route_table_association" "s3_endpoint" {
  route_table_id  = aws_route_table.endpoint.id
  vpc_endpoint_id = var.s3_gateway_endpoint_id
}
