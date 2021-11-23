# data "aws_secretsmanager_secret" "secrets" {
#   arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:my_secrety_name-123456"
# }

# data "aws_secretsmanager_secret_version" "current" {
#   secret_id = data.aws_secretsmanager_secret.secrets.id
# }



# variable "secret_map" {
#   description = "A Key/Value map of secrets that will be added to AWS Secrets"
#   type        = map(string)
# }

# variable "secret_retention_days" {
#   default     = 0
#   description = "Number of days before secret is actually deleted. Increasing this above 0 will result in Terraform errors if you redeploy to the same workspace."
# }

# resource "aws_secretsmanager_secret" "map_secret" {
#   for_each = var.secret_map

#   name  = "/${terraform.workspace}/${each.key}"
#   recovery_window_in_days = var.secret_retention_days

#   tags = merge(var.default_tags, {
#     Name = "${var.base_name}–${each.key}"
#   })
# }

# resource "aws_secretsmanager_secret_version" "map_secret" {
#   for_each = aws_secretsmanager_secret.map_secret

#   secret_id     = aws_secretsmanager_secret.map_secret[each.key].id
#   secret_string = var.secret_map[each.key]
# }

# output "secret_arns" {
#   value = zipmap(keys(aws_secretsmanager_secret_version.map_secret), values(aws_secretsmanager_secret_version.map_secret)[*].arn)
# }

# module "secrets" {
#   source       = "./secrets"
#   base_name    = var.prefix

#   secret_map = {
#     "shared/bastion/ssh/public_pem"         = tls_private_key.bastion.public_key_openssh
#     "shared/bastion/ssh/private_pem"        = tls_private_key.bastion.private_key_pem
#     "shared/bastion/ssh/username"           = random_pet.bastion_username.id
#   }
# }