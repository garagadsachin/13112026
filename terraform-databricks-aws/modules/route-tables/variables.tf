variable "env"                    { type = string }
variable "project_name"           { type = string }
variable "vpc_id"                 { type = string }
variable "compute_subnet_ids"     { type = list(string) }
variable "endpoint_subnet_ids"    { type = list(string) }
variable "s3_gateway_endpoint_id" { type = string }
variable "tgw_id" {
  type    = string
  default = null
}
variable "tgw_routes" {
  type    = list(string)
  default = []
}
variable "tags"                   { type = map(string) }
