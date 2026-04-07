resource "aws_db_subnet_group" "mysql" {
  name       = "${local.name_prefix}-db-subnets"
  subnet_ids = aws_subnet.private[*].id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-db-subnets"
  })
}

resource "aws_db_instance" "mysql" {
  identifier                 = "${local.name_prefix}-mysql"
  engine                     = "mysql"
  instance_class             = var.db_instance_class
  allocated_storage          = var.db_allocated_storage
  storage_type               = var.db_storage_type
  db_name                    = var.db_name
  username                   = var.db_username
  password                   = random_password.db.result
  publicly_accessible        = false
  multi_az                   = var.db_multi_az
  storage_encrypted          = true
  skip_final_snapshot        = var.db_skip_final_snapshot
  deletion_protection        = var.db_deletion_protection
  backup_retention_period    = var.db_backup_retention_period
  apply_immediately          = true
  db_subnet_group_name       = aws_db_subnet_group.mysql.name
  vpc_security_group_ids     = [aws_security_group.rds.id]
  auto_minor_version_upgrade = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-mysql"
  })
}
