resource "random_password" "db" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "django" {
  length           = 64
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_id" "secret_name" {
  byte_length = 3
}

resource "aws_secretsmanager_secret" "app" {
  name = "${local.name_prefix}-app-secrets-${random_id.secret_name.hex}"

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id = aws_secretsmanager_secret.app.id
  secret_string = jsonencode({
    mysql_password    = random_password.db.result
    django_secret_key = random_password.django.result
  })
}
