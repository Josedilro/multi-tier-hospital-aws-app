# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-db-subnet-group"
      Environment = var.environment
    }
  )
}

# RDS Parameter Group for PostgreSQL
resource "aws_db_parameter_group" "postgres" {
  name   = "${var.project_name}-${var.environment}-postgres-params"
  family = "postgres14"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_duration"
    value = "1"
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-postgres-params"
      Environment = var.environment
    }
  )
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "postgres" {
  identifier        = "${var.project_name}-${var.environment}-db"
  engine            = "postgres"
  engine_version    = var.db_engine_version
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # Network & Security
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible    = false

  # High Availability (disabled for Phase 1 cost optimization)
  multi_az = false

  # Backup & Maintenance
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "mon:04:00-mon:05:00"
  
  # Enable automated backups
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.project_name}-${var.environment}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  
  # Performance Insights
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  
  # Parameter Group
  parameter_group_name = aws_db_parameter_group.postgres.name

  # Deletion Protection (disable for dev, enable for prod)
  deletion_protection = false

  # Auto minor version upgrade
  auto_minor_version_upgrade = true

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-postgres-db"
      Environment = var.environment
    }
  )

  lifecycle {
    ignore_changes = [
      final_snapshot_identifier
    ]
  }
}