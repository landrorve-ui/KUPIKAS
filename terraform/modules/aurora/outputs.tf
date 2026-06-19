output "cluster_endpoint" { value = aws_rds_cluster.main.endpoint }
output "reader_endpoint" { value = aws_rds_cluster.main.reader_endpoint }
output "port" { value = aws_rds_cluster.main.port }
output "db_name" { value = aws_rds_cluster.main.database_name }
output "secret_arn" { value = aws_secretsmanager_secret.db_credentials.arn }
output "security_group_id" { value = aws_security_group.aurora.id }
