#  SKS Medical Center - Multi-Tier Hospital Management System

[![AWS](https://img.shields.io/badge/AWS-Cloud-orange?logo=amazon-aws)](https://aws.amazon.com/)
[![Terraform](https://img.shields.io/badge/IaC-Terraform-purple?logo=terraform)](https://www.terraform.io/)
[![Python](https://img.shields.io/badge/Python-3.9-blue?logo=python)](https://www.python.org/)
[![Flask](https://img.shields.io/badge/Framework-Flask-lightgrey?logo=flask)](https://flask.palletsprojects.com/)

> A production-ready, cloud-native hospital management system built on AWS, demonstrating enterprise-grade architecture patterns and DevOps best practices.

##  Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Features](#features)
- [Technology Stack](#technology-stack)
- [Prerequisites](#prerequisites)
- [Phase 1 - Current Implementation](#phase-1---current-implementation)
- [Getting Started](#getting-started)
- [Deployment Guide](#deployment-guide)
- [Future Enhancements](#future-enhancements)
- [Contributing](#contributing)
- [License](#license)

##  Project Overview

SKS Medical Center is a comprehensive hospital management system designed to streamline patient care, medicine prescription, and pharmacy coordination. This project showcases production-ready AWS architecture with infrastructure-as-code, automated deployments, and scalable design patterns.

**Hospital Details:**
- **Name:** SKS Medical Center
- **Location:** Bengaluru, Karnataka, India
- **Medical Staff:** Dr. Kaashvi Srivastava, Dr. Yuvaan Srivastava, Dr. Karthik, Dr. Omkar
- **Specialties:** Multi-specialty care with integrated pharmacy network

##  Architecture

### Phase 1 Architecture (Current)

```
                                    ┌─────────────────┐
                                    │   Internet      │
                                    └────────┬────────┘
                                             │
                                    ┌────────▼────────┐
                                    │  AWS Region     │
                                    │  ap-south-1     │
                                    └────────┬────────┘
                                             │
                    ┌────────────────────────┴────────────────────────┐
                    │                    VPC                           │
                    │            CIDR: 10.0.0.0/16                     │
                    └───────────────────────┬──────────────────────────┘
                                            │
                    ┌───────────────────────┴──────────────────────────┐
                    │                                                   │
          ┌─────────▼─────────┐                         ┌──────────────▼──────────┐
          │  Public Subnet     │                         │  Private Subnet         │
          │  10.0.1.0/24       │                         │  10.0.3.0/24            │
          │  AZ: ap-south-1a   │                         │  AZ: ap-south-1a        │
          └─────────┬──────────┘                         └──────────────┬──────────┘
                    │                                                   │
          ┌─────────▼──────────┐                         ┌──────────────▼──────────┐
          │   EC2 Instance     │                         │    RDS PostgreSQL       │
          │   Flask App        │────────────────────────▶│    Multi-AZ: No (Phase1)│
          │   Security Group   │      DB Connection      │    Size: db.t3.micro    │
          └────────────────────┘                         └─────────────────────────┘
```

### AWS Resources (Phase 1)

| Resource | Configuration | Purpose |
|----------|---------------|---------|
| **VPC** | 10.0.0.0/16 | Network isolation |
| **Public Subnet** | 10.0.1.0/24, 10.0.2.0/24 | Web tier (EC2) |
| **Private Subnet** | 10.0.3.0/24, 10.0.4.0/24 | Database tier (RDS) |
| **Internet Gateway** | 1x IGW | Public internet access |
| **NAT Gateway** | 1x NAT | Private subnet outbound access |
| **EC2 Instance** | t3.micro, Amazon Linux 2 | Application server |
| **RDS PostgreSQL** | db.t3.micro, 20GB | Database |
| **Security Groups** | 3 groups | Network security |

## Features

### Phase 1 - Core Patient Management 

- **User Authentication**
  - Doctor login system with session management
  - Role-based access control
  - Secure password hashing

- **Patient Management**
  - Patient registration with comprehensive details
  - Patient search and filtering
  - View patient medical history
  - Edit and update patient information
  - Responsive dashboard with statistics

- **Medical Staff**
  - 4 pre-configured doctor accounts
  - Doctor profile management
  - Activity tracking

### Phase 2 - Medicine & Pharmacy (Planned)

- Medicine prescription module
- Pharmacy database with geolocation
- Nearest pharmacy finder (2-3 locations)
- Redis caching for pharmacy data
- Interactive maps

### Phase 3 - Production Architecture (Planned)

- Application Load Balancer
- Auto Scaling Groups
- ElastiCache Redis cluster
- CI/CD with GitHub Actions
- CloudWatch monitoring
- Payment gateway integration

## 🛠️ Technology Stack

### Cloud Infrastructure
- **Cloud Provider:** AWS (ap-south-1 region)
- **IaC Tool:** Terraform v1.5+
- **Compute:** EC2 (Amazon Linux 2)
- **Database:** RDS PostgreSQL 14
- **Networking:** VPC, Subnets, IGW, NAT Gateway

### Application
- **Backend:** Python 3.9+, Flask 2.3
- **ORM:** SQLAlchemy
- **Frontend:** Bootstrap 5, HTML5, CSS3, JavaScript
- **Database:** PostgreSQL 14

### DevOps & Monitoring
- **Version Control:** Git, GitHub
- **Configuration Management:** Python dotenv
- **Logging:** Flask logging, CloudWatch (Phase 3)

##  Prerequisites

Before you begin, ensure you have:

1. **AWS Account** with appropriate IAM permissions
2. **AWS CLI** configured with credentials
3. **Terraform** v1.5+ installed
4. **Python** 3.9+ installed
5. **Git** installed
6. **SSH Key Pair** in AWS (for EC2 access)

### Verify Installation (Windows)

```powershell
aws --version
terraform --version
python --version
git --version
```

##  Phase 1 - Current Implementation

### What's Included

-  Complete VPC setup with public/private subnets
-  RDS PostgreSQL database (Multi-AZ ready)
-  EC2 instance with Flask application
-  Security groups with least privilege access
-  100% Infrastructure as Code (Terraform)
-  Patient CRUD operations
-  Doctor authentication system
-  Responsive web interface

### Infrastructure Metrics

- **Deployment Time:** ~10 minutes
- **Terraform Resources:** 25+ AWS resources
- **Lines of Terraform Code:** ~600
- **Application Code:** ~800 lines
- **Estimated Monthly Cost:** ~$20-25 USD (t3.micro instances)

## 🎬 Getting Started

### Step 1: Clone the Repository

```bash
git clone https://github.com/KislayaSrivastava/multi-tier-hospital-aws-app.git
cd multi-tier-hospital-aws-app
```

### Step 2: Configure AWS Credentials

```powershell
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Default region: ap-south-1
# Default output format: json
```

### Step 3: Set Up Terraform Variables

Create `terraform/terraform.tfvars`:

```hcl
aws_region = "ap-south-1"
project_name = "sks-hospital"
environment = "dev"
db_username = "hospitaladmin"
db_password = "YourSecurePassword123!"  # Change this!
key_name = "your-ec2-keypair-name"      # Your AWS key pair name
```

### Step 4: Deploy Infrastructure

```powershell
cd terraform

# Initialize Terraform
terraform init

# Review the execution plan
terraform plan

# Deploy infrastructure (takes ~10 minutes)
terraform apply

# Note the outputs (EC2 public IP, RDS endpoint)
```

### Step 5: Deploy Application

After Terraform completes, it will output the EC2 public IP. SSH into the instance:

```powershell
# SSH from Windows (use PuTTY or Windows Terminal with SSH)
ssh -i "your-keypair.pem" ec2-user@<EC2_PUBLIC_IP>
```

On the EC2 instance:

```bash
# Application is already deployed by user_data script
# Check application status
sudo systemctl status hospital-app

# View logs
sudo journalctl -u hospital-app -f
```

### Step 6: Access the Application

Open your browser and navigate to:

```
http://<EC2_PUBLIC_IP>:5000
```

**Default Login Credentials:**

| Doctor Name | Username | Password |
|-------------|----------|----------|
| Dr. Kaashvi Srivastava | kaashvi | kaashvi123 |
| Dr. Yuvaan Srivastava | yuvaan | yuvaan123 |
| Dr. Karthik | karthik | karthik123 |
| Dr. Omkar | omkar | omkar123 |

## Deployment Guide

### Complete Deployment Steps

1. **Infrastructure Provisioning** (Terraform)
   - VPC and networking setup
   - RDS database creation
   - EC2 instance launch
   - Security group configuration

2. **Application Deployment** (Automated via user_data)
   - Python environment setup
   - Flask application installation
   - Database initialization
   - Systemd service configuration

3. **Database Initialization**
   - Schema creation
   - Doctor accounts setup
   - Sample data loading (optional)

### Manual Application Update

To update the application after infrastructure is deployed:

```bash
# SSH into EC2 instance
ssh -i "your-keypair.pem" ec2-user@<EC2_PUBLIC_IP>

# Navigate to application directory
cd /home/ec2-user/hospital-app

# Pull latest changes (if using git)
git pull origin main

# Restart application
sudo systemctl restart hospital-app
```

##  Testing

### Local Development

```powershell
# Navigate to application directory
cd application

# Create virtual environment
python -m venv venv
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set environment variables
$env:FLASK_APP="app.py"
$env:FLASK_ENV="development"
$env:DATABASE_URL="postgresql://user:pass@localhost:5432/hospital_db"

# Run application
python app.py
```

### Application Endpoints

- `GET /` - Login page
- `POST /login` - Authentication
- `GET /dashboard` - Main dashboard
- `GET /patients` - Patient list
- `GET /patients/new` - Add patient form
- `POST /patients` - Create patient
- `GET /patients/<id>` - Patient details
- `GET /patients/<id>/edit` - Edit patient
- `POST /patients/<id>/update` - Update patient

##  Cost Estimation

### Monthly AWS Costs (Phase 1)

| Service | Configuration | Estimated Cost |
|---------|---------------|----------------|
| EC2 (t3.micro) | 1 instance, 730 hrs/month | $7.50 |
| RDS (db.t3.micro) | 1 instance, 730 hrs/month | $12.00 |
| EBS Volumes | 20 GB gp3 | $2.00 |
| Data Transfer | 10 GB/month | $1.00 |
| NAT Gateway | 730 hrs/month | $32.00 |
| **Total** | | **~$54.50/month** |

**Cost Optimization Tips:**
- Use Savings Plans for EC2/RDS (save 30-40%)
- Remove NAT Gateway in dev (use VPC endpoints)
- Use RDS Reserved Instances
- Enable S3 lifecycle policies (Phase 3)

##  Security Best Practices

-  Database in private subnet (no internet access)
-  Security groups with least privilege
-  Password hashing with werkzeug
-  SQL injection prevention via SQLAlchemy ORM
-  Session management with Flask-Login
-  HTTPS with ACM (Phase 3)
-  WAF integration (Phase 3)
-  Secrets Manager for credentials (Phase 3)

##  Monitoring (Phase 3)

- CloudWatch metrics and alarms
- Application performance monitoring
- Database performance insights
- Custom dashboards
- Log aggregation

##  Future Enhancements

### Phase 2: Medicine & Pharmacy Integration
- Prescription management
- Pharmacy locator with geolocation
- Redis caching layer
- RESTful API development

### Phase 3: Production Architecture
- Application Load Balancer
- Auto Scaling Groups (min: 2, max: 4)
- Multi-AZ RDS deployment
- ElastiCache Redis cluster
- CI/CD pipeline with GitHub Actions
- Blue-green deployment
- Comprehensive monitoring

### Phase 4: Advanced Features
- Payment gateway (Razorpay/Stripe)
- SMS/Email notifications (SNS/SES)
- Medical report uploads (S3)
- Appointment scheduling
- Telemedicine integration

##  Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

##  License

This project is licensed under the MIT License - see the LICENSE file for details.

##  Author

**Kislaya Srivastava**
- LinkedIn: [linkedin.com/in/kislaya-srivastava](https://www.linkedin.com/in/kislaya-srivastava)
- GitHub: [github.com/KislayaSrivastava](https://github.com/KislayaSrivastava)
- Email: kislaya.srivastava@gmail.com

## 🙏 Acknowledgments

- AWS Documentation and Best Practices
- Flask Community
- Terraform AWS Provider Documentation

---

**Built with ❤️ using AWS, Terraform, and Python**