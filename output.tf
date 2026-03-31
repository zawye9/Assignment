output "rds_endpoint" {
  description = "The connection endpoint for the RDS MySQL instance"
  value       = aws_db_instance.mysql.address
}

output "rds_port" {
  description = "The port the database is listening on"
  value       = aws_db_instance.mysql.port
}
output "eks_cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "eks_cluster_name" {
  value = aws_eks_cluster.main.name
}