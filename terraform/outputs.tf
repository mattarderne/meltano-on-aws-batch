output "ecr_repository" {
  value = aws_ecr_repository.meltano-job-repo.repository_url
}
