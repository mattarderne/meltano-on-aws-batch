
# output "apprunner_url" {
#   description = "Apprunner application URL"
#   value       = aws_apprunner_service.meltano-apprunner.service_url
# }

output "ecr_repository" {
  value = aws_ecr_repository.meltano-job-repo.repository_url
}

output "image_bucket" {
  value = aws_s3_bucket.image-bucket.id
}