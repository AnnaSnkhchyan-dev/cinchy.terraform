# Output the ID of the RDS instance
output "rds_instance_id" {
  value = "${aws_db_instance.main_rds_instance.id}"
}

# Output the address (aka hostname) of the RDS instance
output "rds_instance_address" {
  value = "${aws_db_instance.main_rds_instance.address}"
}

# Output endpoint (hostname:port) of the RDS instance
output "rds_instance_endpoint" {
  value = "${aws_db_instance.main_rds_instance.endpoint}"
}

# password
output "rds_random_password" {
  value = "${random_password.password.result}"
}