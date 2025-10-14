# SKS Medical Center - Phase 1 Deployment

## Deployment Date
October 14, 2025

## Infrastructure Details
- **Region:** ap-south-1 (Mumbai)
- **VPC CIDR:** 10.0.0.0/16
- **EC2 Instance:** t3.micro (Amazon Linux 2)
- **RDS Instance:** db.t3.micro (PostgreSQL 14)
- **Estimated Monthly Cost:** ~$50 USD

## Application Details
- **URL:** http://YOUR_EC2_IP:5000
- **Python Version:** 3.8.20
- **Flask Version:** 3.0.0
- **Database:** PostgreSQL 14

## Doctor Accounts
- kaashvi / kaashvi123 (General Medicine)
- yuvaan / yuvaan123 (Pediatrics)
- karthik / karthik123 (Cardiology)
- omkar / omkar123 (Orthopedics)

## Deployment Steps Completed
1. ✅ Created complete Terraform configuration
2. ✅ Deployed VPC and networking
3. ✅ Deployed RDS PostgreSQL database
4. ✅ Deployed EC2 with automated setup
5. ✅ Configured systemd service
6. ✅ Initialized database with doctors
7. ✅ Deployed full application templates
8. ✅ Tested all features

## Known Issues & Resolutions
- Fixed: Python 3.7 → 3.8 compatibility
- Fixed: scrypt → pbkdf2:sha256 for password hashing
- Fixed: Terraform template syntax conflicts

## Next Steps - Phase 2
- Medicine prescription module
- Pharmacy database with geolocation
- Pharmacy finder (nearest 2-3 locations)
- Redis caching
- Enhanced UI with maps