variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix for created resources."
  type        = string
  default     = "web-xray"
}

variable "environment" {
  description = "Environment label used for tagging and naming."
  type        = string
  default     = "dev"
}

variable "github_actions_oidc_provider_arn" {
  description = "Existing GitHub Actions OIDC provider ARN. Leave empty to let Terraform create it."
  type        = string
  default     = ""
}

variable "github_actions_allowed_subjects" {
  description = "Allowed GitHub OIDC subject claims for assuming the deploy role."
  type        = list(string)
  default     = ["repo:edmond-atoyan/web_code:ref:refs/heads/main"]
}

variable "container_image" {
  description = "Container image URI that K3s should deploy. Use a publicly pullable image or provide an image pull secret."
  type        = string
}

variable "image_pull_secret_name" {
  description = "Optional Kubernetes image pull secret name for private registries."
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "EC2 instance type for the single-node K3s server."
  type        = string
  default     = "t3.medium"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB for the K3s instance."
  type        = number
  default     = 30
}

variable "admin_cidrs" {
  description = "CIDR blocks allowed to reach K3s API and optional SSH."
  type        = list(string)
  default     = []
}

variable "ssh_public_key_path" {
  description = "Path to the local public key that Terraform should register as the EC2 key pair."
  type        = string
  default     = "/home/edmond/.ssh/web_xray_ec2.pub"
}

variable "ssh_private_key_path" {
  description = "Path to the local private key used for SSHing into the EC2 instance."
  type        = string
  default     = "/home/edmond/.ssh/web_xray_ec2"
}

variable "allowed_app_cidrs" {
  description = "CIDR blocks allowed to reach the web app."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "app_hostname" {
  description = "Optional DNS hostname for the ingress. Leave empty to route by IP."
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "CIDR for the VPC."
  type        = string
  default     = "10.42.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR for the public subnet hosting the K3s node."
  type        = string
  default     = "10.42.0.0/24"
}

variable "k3s_cluster_cidr" {
  description = "Pod network CIDR for K3s. Must not overlap the VPC CIDR."
  type        = string
  default     = "10.52.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "Two private subnet CIDRs for the RDS subnet group."
  type        = list(string)
  default     = ["10.42.10.0/24", "10.42.11.0/24"]
}

variable "db_name" {
  description = "RDS database name."
  type        = string
  default     = "webxraydb"
}

variable "db_username" {
  description = "Master username for RDS MySQL."
  type        = string
  default     = "webxray"
}

variable "db_instance_class" {
  description = "RDS instance size."
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage for the RDS instance in GiB."
  type        = number
  default     = 20
}

variable "db_storage_type" {
  description = "RDS storage type."
  type        = string
  default     = "gp3"
}

variable "db_backup_retention_period" {
  description = "Backup retention for the RDS instance."
  type        = number
  default     = 7
}

variable "db_multi_az" {
  description = "Whether to enable Multi-AZ for the RDS instance."
  type        = bool
  default     = false
}

variable "db_deletion_protection" {
  description = "Whether to enable deletion protection on RDS."
  type        = bool
  default     = false
}

variable "db_skip_final_snapshot" {
  description = "Whether destroy should skip the final snapshot."
  type        = bool
  default     = true
}

variable "kubernetes_namespace" {
  description = "Namespace used for the application deployment."
  type        = string
  default     = "web-xray"
}
