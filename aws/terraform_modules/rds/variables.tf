# RDS variables
variable "database_name" {
  type = string
}
variable "allocated_storage" {
  type = number
}
variable "database_engine" {
  type = string
}
variable "engine_version" {
  type = number
}
variable "rds_instance_type" {
  type = string
}
variable "username" {
  type = string
}
variable "db_parameter_group" {
  description = "Parameter group, depends on DB engine used"
  # default = "mysql5.6"
  # default = "postgres13"
}
variable "vpnsecuritygroup" {
  type = string
}
variable "rds_is_multi_az" {
  description = "Set to true on production"
  default     = false
}
variable "rds_storage_type" {
  description = "One of 'standard' (magnetic), 'gp2' (general purpose SSD), or 'io1' (provisioned IOPS SSD)."
  default     = "standard"
}
variable "rds_instance_identifier" {
  description = "Custom name of the instance"
}

variable "use_external_parameter_group" {
  description = "Use parameter group specified by `parameter_group_name` instead of built-in one"
  default = false
}
variable "tags" {
  description = "A map of tags to add to all resources"
  default     = {}
}

variable "rds_vpc_id" {
  description = "VPC to connect to, used for a security group"
  type        = string
}
variable "database_port" {}
variable "private_cidr" {
  description = "VPC private addressing, used for a security group"
  type        = list
}
variable "password" {
  description = "Password for the master DB user. Note that this may show up in logs, and it will be stored in the state file"
  type        = string
  default     = null
}