locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  allowed_hosts = join(
    ",",
    compact(concat(
      ["127.0.0.1", "localhost", aws_eip.k3s.public_ip],
      var.app_hostname != "" ? [var.app_hostname] : []
    ))
  )

  app_manifest = templatefile("${path.module}/templates/web-xray-app.yaml.tftpl", {
    namespace              = var.kubernetes_namespace
    container_image        = var.container_image
    image_pull_secret_name = var.image_pull_secret_name
    db_host                = aws_db_instance.mysql.address
    db_name                = var.db_name
    db_user                = var.db_username
    db_port                = tostring(aws_db_instance.mysql.port)
    allowed_hosts          = local.allowed_hosts
    app_hostname           = var.app_hostname
  })
}
