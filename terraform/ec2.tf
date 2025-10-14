# Get the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 Instance for Web/Application Tier
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  key_name      = var.key_name

  # Network Configuration
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true

  # Root Volume
  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  # User Data Script - Installs and configures the application
  user_data = templatefile("${path.module}/user_data.sh", {
    db_host      = aws_db_instance.postgres.address
    db_port      = aws_db_instance.postgres.port
    db_name      = var.db_name
    db_username  = var.db_username
    db_password  = var.db_password
    requirements = file("${path.module}/../application/requirements.txt")
  })

  # Enable detailed monitoring
  monitoring = true

  # Metadata options for IMDSv2
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-web-server"
      Environment = var.environment
      Tier        = "Web"
      Role        = "Application Server"
    }
  )

  depends_on = [
    aws_db_instance.postgres,
    aws_nat_gateway.main
  ]

  lifecycle {
    create_before_destroy = false
    ignore_changes        = []
  }
}

# Elastic IP for Web Server (provides static IP address)
resource "aws_eip" "web" {
  instance = aws_instance.web.id
  domain   = "vpc"

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-web-eip"
      Environment = var.environment
      Purpose     = "Static IP for application server"
    }
  )

  depends_on = [aws_internet_gateway.main]
}