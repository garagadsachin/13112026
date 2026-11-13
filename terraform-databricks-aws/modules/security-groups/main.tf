locals {
  name_prefix = "${var.project_name}-${var.env}"
}

# ── Workspace / cluster security group ───────────────────────────────────────
# Databricks SRA: intra-SG TCP+UDP for cluster communication; outbound to
# control plane via PrivateLink endpoints.
resource "aws_security_group" "workspace" {
  name        = "${local.name_prefix}-workspace-sg"
  description = "Databricks workspace cluster nodes – ${var.env}"
  vpc_id      = var.vpc_id

  # Intra-SG: cluster node ↔ cluster node (TCP + UDP)
  ingress {
    description = "Intra-SG TCP"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Intra-SG UDP"
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    self        = true
  }

  # Outbound: HTTPS to VPC endpoints (443)
  egress {
    description = "HTTPS to VPC endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restricted by endpoint policies; no IGW present
  }

  # Outbound: SCC relay (6666)
  egress {
    description = "SCC relay"
    from_port   = 6666
    to_port     = 6666
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound: Databricks internal services (8443–8451)
  egress {
    description = "Databricks internal services"
    from_port   = 8443
    to_port     = 8451
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound: intra-SG TCP (cluster ↔ cluster)
  egress {
    description = "Intra-SG TCP"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  # Outbound: intra-SG UDP
  egress {
    description = "Intra-SG UDP"
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    self        = true
  }

  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-workspace-sg"
    Environment = var.env
  })
}

# ── PrivateLink endpoint security group ──────────────────────────────────────
resource "aws_security_group" "endpoint" {
  name        = "${local.name_prefix}-endpoint-sg"
  description = "VPC interface endpoints – ${var.env}"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTPS from workspace nodes"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.workspace.id]
  }

  ingress {
    description     = "SCC relay from workspace nodes"
    from_port       = 6666
    to_port         = 6666
    protocol        = "tcp"
    security_groups = [aws_security_group.workspace.id]
  }

  ingress {
    description     = "Databricks internal services from workspace nodes"
    from_port       = 8443
    to_port         = 8451
    protocol        = "tcp"
    security_groups = [aws_security_group.workspace.id]
  }

  # No explicit egress rules needed – AWS connection tracking handles return traffic.

  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-endpoint-sg"
    Environment = var.env
  })
}
