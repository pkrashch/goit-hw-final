resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-db"
  subnet_ids = aws_subnet.db[*].id
}

resource "aws_db_instance" "main" {
  identifier     = "${var.project}-pg"
  engine         = "postgres"
  engine_version = "16"
  instance_class = var.db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 50
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  # RDS generates the password and stores it in Secrets Manager.
  # It never appears in Terraform code or variables.
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false
  multi_az               = var.db_multi_az

  backup_retention_period      = 1
  performance_insights_enabled = false
  skip_final_snapshot          = true
  deletion_protection          = false
  apply_immediately            = true
}
