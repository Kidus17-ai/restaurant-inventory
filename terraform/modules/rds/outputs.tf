output "db_endpoint" {
  description = "RDS endpoint address"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}

output "rds_security_group_id" {
  description = "Security group ID of RDS"
  value       = aws_security_group.rds.id
}