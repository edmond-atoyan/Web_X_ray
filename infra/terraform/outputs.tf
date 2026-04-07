output "app_url" {
  description = "Public URL for the Django app."
  value       = var.app_hostname != "" ? "http://${var.app_hostname}" : "http://${aws_eip.k3s.public_ip}"
}

output "k3s_public_ip" {
  description = "Elastic IP attached to the K3s node."
  value       = aws_eip.k3s.public_ip
}

output "k3s_instance_id" {
  description = "EC2 instance ID for the K3s node."
  value       = aws_instance.k3s.id
}

output "ec2_key_pair_name" {
  description = "AWS key pair name created for the EC2 instance when an SSH public key is configured."
  value       = length(aws_key_pair.deployer) > 0 ? aws_key_pair.deployer[0].key_name : null
}

output "ssh_command" {
  description = "SSH command to connect to the EC2 K3s node once port 22 is allowed and an SSH key pair is configured."
  value       = length(aws_key_pair.deployer) > 0 ? "ssh -i ${var.ssh_private_key_path} ubuntu@${aws_eip.k3s.public_ip}" : null
}

output "k3s_api_endpoint" {
  description = "Kubernetes API endpoint if you open port 6443 to your admin CIDR."
  value       = "https://${aws_eip.k3s.public_ip}:6443"
}

output "rds_endpoint" {
  description = "MySQL endpoint for the application."
  value       = aws_db_instance.mysql.address
}

output "rds_port" {
  description = "MySQL port."
  value       = aws_db_instance.mysql.port
}

output "model_bucket_name" {
  description = "Bucket storing model.pkl."
  value       = aws_s3_bucket.model.bucket
}

output "model_object_key" {
  description = "S3 key for model.pkl."
  value       = aws_s3_object.model.key
}

output "app_secret_arn" {
  description = "Secrets Manager ARN holding the Django secret key and DB password."
  value       = aws_secretsmanager_secret.app.arn
  sensitive   = true
}

output "github_actions_deploy_role_arn" {
  description = "IAM role ARN for the GitHub Actions deploy workflow."
  value       = aws_iam_role.github_actions_deploy.arn
}

output "github_actions_oidc_provider_arn" {
  description = "GitHub Actions OIDC provider ARN used by the deploy role."
  value       = local.github_actions_oidc_provider_arn
}
