variable "env"          { type = string }
variable "project_name" { type = string }
variable "vpc_cidr"     { type = string }
variable "azs"          { type = list(string) }
variable "enable_flow_logs"       { type = bool }
variable "flow_logs_iam_role_arn" { type = string }
variable "flow_logs_log_group"    { type = string }
variable "tags"         { type = map(string) }
