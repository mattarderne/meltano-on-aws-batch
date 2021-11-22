# Docs here https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apprunner_service

resource "aws_iam_service_linked_role" "role_apprunner" {
  # TODO: this doesn't work if there is already a service linked role, in which case you need to specify it in the apprunner config
  aws_service_name = "apprunner.amazonaws.com"
}

resource "aws_apprunner_service" "meltano-apprunner" {
  service_name = "example"

  source_configuration {
      authentication_configuration {
      # TODO: replace this line with the hard coded arn
      # access_role_arn = aws_iam_service_linked_role.role_apprunner.arn
    }
    image_repository {
      image_configuration {
        port = "5000"
        start_command = "ui"
      }
      image_identifier      = var.docker_image
      image_repository_type = "ECR"

    }
  }

  tags = {
    Terraform = "true"
    Project = "${var.prefix}-meltano"
  }
}