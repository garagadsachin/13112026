# terraform-databricks-aws

Terraform module for deploying a production-grade, security-hardened Databricks workspace on AWS. Designed around the Databricks Security Reference Architecture (SRA) with no public internet exposure by default.

---

## Architecture Overview

All traffic between Databricks cluster nodes and the control plane flows through AWS VPC interface endpoints (PrivateLink). No Internet Gateway is attached. S3 access uses a Gateway endpoint. Outbound internet and front-end PrivateLink are opt-in.

```
┌─────────────────────────────────────────────────────┐
│  AWS VPC (per environment)                          │
│                                                     │
│  ┌──────────────────┐   ┌────────────────────────┐  │
│  │  Compute Subnets │   │  Endpoint Subnets      │  │
│  │  (one per AZ)    │──▶│  (one per AZ)          │  │
│  │  workspace-sg    │   │  endpoint-sg           │  │
│  └──────────────────┘   └────────────────────────┘  │
│           │                        │                │
│           └──── Route Tables ──────┘                │
│                      │                              │
│         ┌────────────┼────────────┐                 │
│         ▼            ▼            ▼                 │
│    S3 Gateway    STS Interface  Kinesis Interface   │
│    Endpoint      Endpoint       Endpoint            │
└─────────────────────────────────────────────────────┘
```

Two deployment modes are planned:

| Mode | Description |
|---|---|
| `three_vpc` | DEV, TEST, PROD each get an isolated VPC (recommended) |
| `shared_nonprod` | DEV + TEST share one VPC; PROD is always isolated |

---

## Project Structure

```
terraform-databricks-aws/
├── modules/
│   ├── vpc/                  ✅ Complete
│   ├── subnets/              ✅ Complete
│   ├── security-groups/      ✅ Complete
│   ├── route-tables/         ✅ Complete
│   ├── vpc-endpoints/        ✅ Complete (S3, STS, Kinesis)
│   ├── cross-account-access/ 🔲 Pending
│   ├── databricks-workspace/ 🔲 Pending
│   ├── iam-roles/            🔲 Pending
│   ├── kms/                  🔲 Pending
│   ├── monitoring/           🔲 Pending
│   ├── outbound-connectivity/🔲 Pending
│   ├── privatelink/          🔲 Pending
│   ├── route53-dns/          🔲 Pending
│   ├── s3-storage/           🔲 Pending
│   └── unity-catalog/        🔲 Pending
├── environments/
│   ├── dev/                  ✅ Scaffolded (main.tf + terraform.tfvars)
│   ├── test/                 🔲 Pending
│   └── prod/                 🔲 Pending
├── examples/                 🔲 Pending (removed – to be re-added)
├── tests/                    🔲 Pending (removed – to be re-added)
├── main.tf                   🔲 Pending (after all modules done)
├── variables.tf              🔲 Pending
├── outputs.tf                🔲 Pending
├── providers.tf              🔲 Pending
├── terraform.tfvars.example  🔲 Pending
└── versions.tf               🔲 Pending
```

---

## What's Been Built

### Phase 1 – Networking Foundation (Complete)

#### `modules/vpc`
- Creates a VPC with DNS support and hostnames enabled.
- Optional VPC Flow Logs to CloudWatch (90-day retention).
- Outputs: `vpc_id`, `vpc_cidr`.

#### `modules/subnets`
- Private compute subnets (one per AZ, no public IP).
- Private endpoint subnets (dedicated /26 per AZ for VPC interface endpoints).
- Outputs: `compute_subnet_ids`, `endpoint_subnet_ids`.

#### `modules/security-groups`
- `workspace-sg`: Allows intra-SG TCP/UDP for cluster node communication. Egress restricted to HTTPS (443), SCC relay (6666), and Databricks internal services (8443–8451).
- `endpoint-sg`: Accepts traffic only from `workspace-sg` on ports 443, 6666, and 8443–8451.
- Outputs: `workspace_sg_id`, `endpoint_sg_id`.

#### `modules/route-tables`
- One compute route table per subnet for independent routing.
- Single shared endpoint route table.
- S3 Gateway endpoint route added to all route tables.
- Optional Transit Gateway routes on compute route tables.
- Outputs: `compute_route_table_ids`, `endpoint_route_table_id`.

#### `modules/vpc-endpoints`
- S3 Gateway endpoint with a scoped bucket policy.
- STS Interface endpoint (private DNS enabled).
- Kinesis Streams Interface endpoint (private DNS enabled).
- Outputs: `s3_endpoint_id`, `sts_endpoint_id`, `kinesis_endpoint_id`.

### Dev Environment Scaffold (Partial)
- `environments/dev/main.tf`: Wired to root module with S3 remote state backend (encrypted, DynamoDB lock), both `aws` and `databricks` providers configured.
- `environments/dev/terraform.tfvars`: Placeholder values ready to fill in.
- `environments/test/` and `environments/prod/`: Empty — not yet scaffolded.

---

## Next Steps

### Phase 2 – Storage & IAM

| Module | What it will do |
|---|---|
| `s3-storage` | Root S3 buckets per workspace (versioning, SSE-KMS, block public access, lifecycle rules) |
| `kms` | Customer-managed KMS keys for S3, EBS, and Databricks managed storage |
| `iam-roles` | EC2 instance profile for cluster nodes; S3 access policies |
| `cross-account-access` | Databricks cross-account IAM role and trust policy |

### Phase 3 – Databricks Workspace

| Module | What it will do |
|---|---|
| `databricks-workspace` | `databricks_mws_networks`, `databricks_mws_storage_configurations`, `databricks_mws_workspaces` resources |
| `unity-catalog` | Unity Catalog metastore, S3 bucket, IAM role, and metastore assignment |

### Phase 4 – Optional Features

| Module | What it will do |
|---|---|
| `privatelink` | Front-end PrivateLink (Databricks REST API via private endpoint) |
| `outbound-connectivity` | NAT Gateway or Transit Gateway for controlled internet egress |
| `route53-dns` | Private hosted zone for PrivateLink DNS resolution |

### Phase 5 – Monitoring & Observability

| Module | What it will do |
|---|---|
| `monitoring` | CloudTrail, GuardDuty, AWS Config, CloudWatch dashboards and alarms |

### Phase 6 – Root Module, Environments & Examples

- Wire all modules together in root `main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`, `versions.tf`, `terraform.tfvars.example`.
- Complete `environments/test/` and `environments/prod/` configs.
- Re-add `examples/three-vpc/` and `examples/shared-nonprod-vpc/` usage examples.
- Re-add `tests/validation.tftest.hcl` with CIDR non-overlap, minimum AZ, and no-internet-by-default assertions.

---

## Prerequisites

- Terraform >= 1.5.0
- AWS provider ~> 5.40
- Databricks provider ~> 1.40
- An S3 bucket and DynamoDB table for remote state
- A Databricks account (E2 / account-level)

---

## Quick Start (Dev Environment)

> Note: The root module is not yet complete. The dev environment scaffold references it but cannot be fully applied until Phase 2–5 modules are wired in.

```bash
cd environments/dev

# Fill in sensitive values
cp terraform.tfvars terraform.tfvars.local
# Edit terraform.tfvars.local with real account IDs and bucket names

terraform init
terraform plan -var-file="terraform.tfvars.local"
terraform apply -var-file="terraform.tfvars.local"
```

---

## Key Design Decisions

- No Internet Gateway attached to any VPC — all control-plane traffic via PrivateLink endpoints.
- Separate subnet tiers (compute vs. endpoint) for least-privilege security group scoping.
- One route table per compute subnet to allow independent routing (required for Transit Gateway scenarios).
- `deployment_mode` variable will drive whether DEV/TEST share a VPC or are isolated.
- Remote state encrypted at rest with KMS and locked via DynamoDB.
