variable "environment" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "eks_security_group_id" { type = string }

variable "db_name" {
  type    = string
  default = "zupikas"
}

variable "db_username" {
  type    = string
  default = "zupikas_admin"
}

variable "serverless_min_acu" {
  type    = number
  default = 0.5
}

variable "serverless_max_acu" {
  type    = number
  default = 8
}

variable "instance_count" {
  type    = number
  default = 1
}

variable "deletion_protection" {
  type    = bool
  default = false
}
