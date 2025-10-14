# ---------------------------------------------
# Script: create_project_structure.ps1
# Purpose: Creates project folder structure
# ---------------------------------------------

# Define project root folder
$project = "multi-tier-hospital-aws-app"

# Create project directory if it doesn’t exist
if (-Not (Test-Path -Path $project)) {
    New-Item -ItemType Directory -Path $project -Force | Out-Null
    Write-Host "Created project directory: $project"
} else {
    Write-Host "Project directory already exists: $project"
}

# Move into the project directory
Set-Location $project

# Define subfolder structure
$folders = @(
    "terraform",
    "application",
    "application\templates",
    "application\static",
    "application\static\css",
    "application\static\js",
    "application\database",
    "scripts",
    "docs"
)

# Create each folder
foreach ($folder in $folders) {
    if (-Not (Test-Path -Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
        Write-Host "Created folder: $folder"
    } else {
        Write-Host "Folder already exists: $folder"
    }
}

Write-Host "`n? Project structure created successfully!"
