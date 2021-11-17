
output "rds_hostname" {
  description = "RDS instance hostname"
  value       = aws_db_instance.db_instance.address
  sensitive   = true
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.db_instance.port
}

output "rds_username" {
  description = "RDS instance root username"
  value       = aws_db_instance.db_instance.username
  sensitive   = true
}

output "db_connect_string" {
  description = "Posgresql database connection string"
  value       = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.db_instance.address}:${aws_db_instance.db_instance.port}/${var.db_name}"
  sensitive   = true
}

output "security_group_id" {
  description = "Security Group Name"
  value       = aws_security_group.security_group.id
}

# output "apprunner_url" {
#   description = "Apprunner application URL"
#   value       = aws_apprunner_service.meltano-apprunner.service_url
# }

output "ecr_repository" {
  value = "${aws_ecr_repository.meltano-job-repo.repository_url}"
}

output "image_bucket" {
  value = "${aws_s3_bucket.image-bucket.id}"
}