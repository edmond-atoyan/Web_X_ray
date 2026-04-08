# AWS K3s Terraform

This Terraform stack provisions a practical baseline deployment for the Django X-ray app:

- 1 EC2 instance running single-node K3s
- 1 private RDS MySQL instance
- 1 private S3 bucket that stores `model.pkl`
- 1 Secrets Manager secret for the Django secret key and DB password

## What It Assumes

- You are okay starting with a single-node K3s cluster on EC2.
- Your application image is already published to a registry that the node can pull from.
- The current app runtime uses MySQL in AWS and mounts `model.pkl` from the node filesystem.
- SSH access is optional. If you do want SSH, provide a public key locally or through GitHub Actions.

## Files

- `terraform.tfvars.example`: starter variable file
- `templates/bootstrap.sh.tftpl`: EC2 bootstrapping for K3s, S3 model sync, and manifest install
- `templates/web-xray-app.yaml.tftpl`: Kubernetes Deployment, Service, and Ingress

## Usage

### GitHub Actions Auto-Apply

After the repository secrets are configured, pushes to `main` that change `infra/terraform/**` or `core/main/model.pkl` will run `terraform apply` automatically through `.github/workflows/terraform.yml`.

Required GitHub secret:

- `AWS_TERRAFORM_ROLE_ARN`, which should be set to the `github_actions_terraform_role_arn` Terraform output after the bootstrap apply

Optional GitHub secret:

- `SSH_PUBLIC_KEY` if you want Terraform to register an EC2 key pair for SSH access

Optional GitHub repository variables:

- `TF_STATE_BUCKET`
- `TF_STATE_LOCK_TABLE`
- `TF_STATE_KEY`
- `TERRAFORM_CONTAINER_IMAGE`

If those repository variables are omitted, the workflow derives sane defaults and bootstraps the S3 state bucket and DynamoDB lock table automatically.

### Local Usage

1. Build and publish the app image.

Example with Docker Hub:

```bash
cd /home/edmond/Desktop/Web_X_ray/web_code/core
docker build -t your-user/tb-detection-ai:latest .
docker push your-user/tb-detection-ai:latest
```

2. Copy the example variables file and set at least `container_image`.

```bash
cd /home/edmond/Desktop/Web_X_ray/web_code/infra/terraform
cp terraform.tfvars.example terraform.tfvars
```

Set `admin_cidrs` to your current public IP in CIDR form if you want SSH and direct K3s API access.

3. Initialize against the same remote backend used by CI and apply Terraform.

```bash
terraform init \
  -backend-config="bucket=web-xray-tfstate-<account-id>-us-east-1" \
  -backend-config="key=web-xray/dev/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="dynamodb_table=web-xray-terraform-locks"
terraform plan
terraform apply
```

4. Open the value from the `app_url` output in your browser.
5. If you configured an SSH public key, use the `ssh_command` output to connect to the EC2 instance.

## Notes

- `model.pkl` is uploaded from `core/main/model.pkl` to S3 during `terraform apply`.
- The EC2 instance downloads the model from S3 into `/opt/web-xray/model/model.pkl` during boot.
- K3s auto-deploys the Kubernetes manifests from `/var/lib/rancher/k3s/server/manifests`.
- RDS is private and only reachable from the EC2/K3s security group.
- If you want to use a private registry, provide `image_pull_secret_name` and create that secret in the cluster separately.
- Terraform creates an EC2 key pair only when you provide a public key, and exposes `ssh_command` only in that case.
- GitHub Actions auto-apply uses an S3 backend with DynamoDB locking instead of local `terraform.tfstate`.

## Good Next Steps

- Split the Terraform workflow into separate plan and apply jobs if you want PR previews before merge.
- Add Route53 and ACM if you want a real domain and TLS.
- Move from single-node K3s to multi-node if you need higher availability.
