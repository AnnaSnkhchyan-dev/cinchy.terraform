resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "aws_db_instance" "main_rds_instance" {
  identifier             = "${var.rds_instance_identifier}"
  name                   = "${var.database_name}"
  allocated_storage      = "${var.allocated_storage}"
  engine                 = "${var.database_engine}"
  engine_version         = "${var.engine_version}"
  instance_class         = "${var.rds_instance_type}"
  username               = "${var.username}"
  password               = "${var.password}"#random_password.password.result
  vpc_security_group_ids = [
    "${var.vpnsecuritygroup}"
    ]
  multi_az               = "${var.rds_is_multi_az}"
  storage_type           = "${var.rds_storage_type}"
  tags = {
    terraformed = true
  }
  
  skip_final_snapshot = true
  # snapshot_identifier = "${var.rds_instance_identifier}-final-${timestamp()}"
  # apply_immediately = true
  # #auto_minor_version_upgrade=true
}

resource "aws_db_parameter_group" "main_rds_instance" {
  count = "${var.use_external_parameter_group ? 0 : 1}"

  name   = "${var.rds_instance_identifier}-${replace(var.db_parameter_group, ".", "")}-custom-params"
  family = "${var.db_parameter_group}"
  tags = {
    terraformed = true
  }
  # Example for MySQL
  # parameter {
  #   name = "character_set_server"
  #   value = "utf8"
  # }


  # parameter {
  #   name = "character_set_client"
  #   value = "utf8"
  # }

}

# Security groups
resource "aws_security_group" "main_db_access" {
  name        = "${var.rds_instance_identifier}-access"
  description = "Allow access to the database"
  vpc_id      = "${var.rds_vpc_id}"
  tags = {
    terraformed = true
  }

}

resource "aws_security_group_rule" "allow_db_access" {
  type = "ingress"

  from_port   = "${var.database_port}"
  to_port     = "${var.database_port}"
  protocol    = "tcp"
  cidr_blocks = "${var.private_cidr}"

  security_group_id = "${aws_security_group.main_db_access.id}"
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type = "egress"

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.main_db_access.id}"
}