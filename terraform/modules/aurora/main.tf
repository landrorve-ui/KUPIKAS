resource "random_password" "db" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "zupikas/${var.environment}/aurora"
  description             = "Aurora PostgreSQL credentials"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username     = var.db_username
    password     = random_password.db.result
    host         = aws_rds_cluster.main.endpoint
    port         = aws_rds_cluster.main.port
    dbname       = var.db_name
    DATABASE_URL = "postgresql://${var.db_username}:${urlencode(random_password.db.result)}@${aws_rds_cluster.main.endpoint}:${aws_rds_cluster.main.port}/${var.db_name}"
  })
}

resource "aws_db_subnet_group" "main" {
  name       = "zupikas-${var.environment}-aurora"
  subnet_ids = var.private_subnet_ids
  tags       = { Name = "zupikas-${var.environment}-aurora-subnet-group" }
}

resource "aws_security_group" "aurora" {
  name        = "zupikas-${var.environment}-aurora-sg"
  description = "Allow PostgreSQL from EKS nodes only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from EKS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.eks_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "zupikas-${var.environment}-aurora-sg" }
}

resource "aws_rds_cluster_parameter_group" "main" {
  name        = "zupikas-${var.environment}-aurora-pg16"
  family      = "aurora-postgresql16"
  description = "Aurora PostgreSQL 16 parameter group"
}

resource "aws_rds_cluster" "main" {
  cluster_identifier        = "zupikas-${var.environment}"
  engine                    = "aurora-postgresql"
  engine_version            = "16.4"
  engine_mode               = "provisioned"
  database_name             = var.db_name
  master_username           = var.db_username
  master_password           = random_password.db.result
  db_subnet_group_name      = aws_db_subnet_group.main.name
  vpc_security_group_ids    = [aws_security_group.aurora.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main.name
  storage_encrypted         = true
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = !var.deletion_protection
  final_snapshot_identifier = var.deletion_protection ? "zupikas-${var.environment}-final" : null
  backup_retention_period   = 7
  preferred_backup_window   = "03:00-04:00"

  serverlessv2_scaling_configuration {
    min_capacity = var.serverless_min_acu
    max_capacity = var.serverless_max_acu
  }

  tags = { Environment = var.environment }
}

resource "aws_rds_cluster_instance" "main" {
  count                = var.instance_count
  identifier           = "zupikas-${var.environment}-${count.index + 1}"
  cluster_identifier   = aws_rds_cluster.main.id
  instance_class       = "db.serverless"
  engine               = aws_rds_cluster.main.engine
  engine_version       = aws_rds_cluster.main.engine_version
  db_subnet_group_name = aws_db_subnet_group.main.name
}
