variable "env"                   { type = string }
variable "project_name"          { type = string }
variable "vpc_id"                { type = string }
variable "azs"                   { type = list(string) }
variable "compute_subnet_cidrs"  { type = list(string) }
variable "endpoint_subnet_cidrs" { type = list(string) }
variable "tags"                  { type = map(string) }
