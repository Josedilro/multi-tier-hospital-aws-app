# SKS Hospital - Application Deployment Script for Windows
# This script deploys the full application to the EC2 instance

param(
    [Parameter(Mandatory=$true)]
    [string]$EC2_IP,
    
    [Parameter(Mandatory=$true)]
    [string]$KEY_PATH
)

Write-Host "=== SKS Medical Center - Application Deployment ===" -ForegroundColor Cyan
Write-Host ""

# Check if key file exists
if (-not (Test-Path $KEY_PATH)) {
    Write-Host "Error: Key file not found at $KEY_PATH" -ForegroundColor Red
    exit 1
}

# Check if application directory exists
if (-not (Test-Path "..\application")) {
    Write-Host "Error: Application directory not found" -ForegroundColor Red
    exit 1
}

Write-Host "Step 1: Creating temporary deployment package..." -ForegroundColor Green

# Create a temporary directory for deployment
$tempDir = Join-Path $env:TEMP "hospital-app-deploy"
if (Test-Path $tempDir) {
    Remove-Item -Recurse -Force $tempDir
}
New-Item -ItemType Directory -Path $tempDir | Out-Null

# Copy application files
Copy-Item -Recurse "..\application\*" $tempDir

Write-Host "Step 2: Uploading application files to EC2..." -ForegroundColor Green

# Use SCP to upload files
scp -i $KEY_PATH -r "$tempDir\*" "ec2-user@${EC2_IP}:/home/ec2-user/hospital-app/"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to upload files" -ForegroundColor Red
    exit 1
}

Write-Host "Step 3: Restarting application service..." -ForegroundColor Green

# SSH and restart the application
$sshCommand = @"
cd /home/ec2-user/hospital-app
sudo systemctl restart hospital-app
sudo systemctl status hospital-app
"@

ssh -i $KEY_PATH "ec2-user@${EC2_IP}" $sshCommand

Write-Host ""
Write-Host "=== Deployment Complete! ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Application URL: http://${EC2_IP}:5000" -ForegroundColor Yellow
Write-Host ""
Write-Host "Login Credentials:" -ForegroundColor Yellow
Write-Host "  Username: kaashvi | Password: kaashvi123" -ForegroundColor White
Write-Host "  Username: yuvaan  | Password: yuvaan123" -ForegroundColor White
Write-Host "  Username: karthik | Password: karthik123" -ForegroundColor White
Write-Host "  Username: omkar   | Password: omkar123" -ForegroundColor White
Write-Host ""

# Clean up
Remove-Item -Recurse -Force $tempDir