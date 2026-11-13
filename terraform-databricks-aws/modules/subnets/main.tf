locals {
  name_prefix = "${var.project_name}-${var.env}"
}

# Private compute subnets – one per AZ, no public IP assignment.
resource "aws_subnet" "compute" {
  count                   = length(var.compute_subnet_cidrs)
  vpc_id                  = var.vpc_id
  cidr_block              = var.compute_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-compute-${var.azs[count.index]}"
    SubnetType  = "compute"
    Environment = var.env
  })
}

# Private endpoint subnets – dedicated /26 per AZ for VPC interface endpoints.
resource "aws_subnet" "endpoint" {
  count                   = length(var.endpoint_subnet_cidrs)
  vpc_id                  = var.vpc_id
  cidr_block              = var.endpoint_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-endpoint-${var.azs[count.index]}"
    SubnetType  = "endpoint"
    Environment = var.env
  })
}
