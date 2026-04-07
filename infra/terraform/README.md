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
- A dedicated SSH key pair exists at `/home/edmond/.ssh/web_xray_ec2` and `/home/edmond/.ssh/web_xray_ec2.pub`.

## Files

- `terraform.tfvars.example`: starter variable file
- `templates/bootstrap.sh.tftpl`: EC2 bootstrapping for K3s, S3 model sync, and manifest install
- `templates/web-xray-app.yaml.tftpl`: Kubernetes Deployment, Service, and Ingress

## Usage

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

3. Initialize and apply Terraform.

```bash
terraform init
terraform plan
terraform apply
```

4. Open the value from the `app_url` output in your browser.
5. Use the `ssh_command` output to connect to the EC2 instance.

## Notes

- `model.pkl` is uploaded from `core/main/model.pkl` to S3 during `terraform apply`.
- The EC2 instance downloads the model from S3 into `/opt/web-xray/model/model.pkl` during boot.
- K3s auto-deploys the Kubernetes manifests from `/var/lib/rancher/k3s/server/manifests`.
- RDS is private and only reachable from the EC2/K3s security group.
- If you want to use a private registry, provide `image_pull_secret_name` and create that secret in the cluster separately.
- Terraform creates an EC2 key pair from `/home/edmond/.ssh/web_xray_ec2.pub` and exposes a ready-to-run `ssh_command` output.

## Good Next Steps

- Put Terraform state in an S3 backend with locking enabled.
- Add Route53 and ACM if you want a real domain and TLS.
- Move from single-node K3s to multi-node if you need higher availability.
