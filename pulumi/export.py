import pulumi

pulumi.export("ecrRepository", aws_ecr_repository["meltano-job-repo"]["repository_url"])
pulumi.export("jobQueue", aws_batch_job_queue["meltano"]["id"])
