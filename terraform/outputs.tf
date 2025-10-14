# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

# EC2 Outputs
output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_eip.web.public_ip
}

output "ec2_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = aws_instance.web.private_ip
}

# RDS Outputs
output "rds_endpoint" {
  description = "Connection endpoint for the RDS instance"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_address" {
  description = "Address of the RDS instance"
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "Port of the RDS instance"
  value       = aws_db_instance.postgres.port
}

output "database_name" {
  description = "Name of the database"
  value       = aws_db_instance.postgres.db_name
}

# Application Access
output "application_url" {
  description = "URL to access the hospital application"
  value       = "http://${aws_eip.web.public_ip}:5000"
}

# Security Group IDs
output "web_security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web.id
}

output "db_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.database.id
}

# Connection Instructions
output "connection_instructions" {
  description = "Instructions to connect to the application"
  value = <<-EOT
    
    ╔════════════════════════════════════════════════════════════════╗
    ║          SKS HOSPITAL APPLICATION DEPLOYED SUCCESSFULLY!        ║
    ╚════════════════════════════════════════════════════════════════╝
    
    📍 Application URL: http://${aws_eip.web.public_ip}:5000
    
    🔐 Doctor Login Credentials:
    ┌─────────────────────────┬──────────┬──────────────┐
    │ Doctor Name             │ Username │ Password     │
    ├─────────────────────────┼──────────┼──────────────┤
    │ Dr. Kaashvi Srivastava  │ kaashvi  │ kaashvi123   │
    │ Dr. Yuvaan Srivastava   │ yuvaan   │ yuvaan123    │
    │ Dr. Karthik             │ karthik  │ karthik123   │
    │ Dr. Omkar               │ omkar    │ omkar123     │
    └─────────────────────────┴──────────┴──────────────┘
    
    🖥️  SSH Access:
    ssh -i "your-keypair.pem" ec2-user@${aws_eip.web.public_ip}
    
    📊 Database Connection:
    Host: ${aws_db_instance.postgres.address}
    Port: ${aws_db_instance.postgres.port}
    Database: ${aws_db_instance.postgres.db_name}
    
    ⚠️  Note: Wait 2-3 minutes after deployment for the application to fully initialize.
    
    EOT
}