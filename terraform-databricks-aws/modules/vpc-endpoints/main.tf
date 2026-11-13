locals {
  name_prefix = "${var.project_name}-${var.env}"
}

# ── S3 Gateway Endpoint ───────────────────────────────────────────────────────
# Route table associations are managed in the route-tables module.
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowDatabricksAndWorkspaceS3"
      Effect    = "Allow"
      Principal = "*"
      Action    = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket", "s3:GetBucketLocation"]
      Resource  = "*"
    }]
  })

  tags = merge(var.tags, { Name = "${local.name_prefix}-s3-gw-endpoint" })
}

# ── STS Interface Endpoint ────────────────────────────────────────────────────
# Note: The original diagram referenced "AWS STB endpoint" – confirmed as STS
# per Databricks documentation (AWS Security Token Service).
resource "aws_vpc_endpoint" "sts" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.sts"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.endpoint_subnet_ids
  security_group_ids  = [var.endpoint_sg_id]
  private_dns_enabled = true

  tags = merge(var.tags, { Name = "${local.name_prefix}-sts-endpoint" })
}

# ── Kinesis Interface Endpoint ────────────────────────────────────────────────
resource "aws_vpc_endpoint" "kinesis" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.kinesis-streams"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.endpoint_subnet_ids
  security_group_ids  = [var.endpoint_sg_id]
  private_dns_enabled = true

  tags = merge(var.tags, { Name = "${local.name_prefix}-kinesis-endpoint" })
}
