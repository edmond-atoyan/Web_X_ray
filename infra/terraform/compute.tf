data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "${local.name_prefix}-deployer"
  public_key = trimspace(file(var.ssh_public_key_path))

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-deployer"
  })
}

resource "aws_instance" "k3s" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.k3s.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  key_name                    = aws_key_pair.deployer.key_name
  associate_public_ip_address = false
  user_data_replace_on_change = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = templatefile("${path.module}/templates/bootstrap.sh.tftpl", {
    aws_region     = var.aws_region
    public_ip      = aws_eip.k3s.public_ip
    app_manifest   = local.app_manifest
    model_bucket   = aws_s3_bucket.model.bucket
    model_key      = aws_s3_object.model.key
    app_secret_arn = aws_secretsmanager_secret.app.arn
    namespace      = var.kubernetes_namespace
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-k3s"
  })
}

resource "aws_eip" "k3s" {
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-k3s-eip"
  })
}

resource "aws_eip_association" "k3s" {
  instance_id   = aws_instance.k3s.id
  allocation_id = aws_eip.k3s.id
}
