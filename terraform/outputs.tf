output "ecr_repository" {
  value = aws_ecr_repository.meltano-job-repo.repository_url
}

output "job_queue" {
  value = aws_batch_job_queue.meltano.id
}
