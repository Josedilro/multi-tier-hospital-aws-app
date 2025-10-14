# ---------------------------------------------
# Script: cleanup_project_structure.ps1
# Purpose: Deletes the project folder structure
# ---------------------------------------------

# Define project root folder
$project = "multi-tier-hospital-aws-app"

# Confirm before deletion
if (Test-Path -Path $project) {
    Write-Host "Are you sure you want to delete the project directory '$project'? (Y/N)"
    $confirmation = Read-Host

    if ($confirmation -eq 'Y' -or $confirmation -eq 'y') {
        Remove-Item -Path $project -Recurse -Force
        Write-Host "?? Project directory '$project' deleted successfully."
    } else {
        Write-Host "? Deletion cancelled."
    }
} else {
    Write-Host "?? Project directory '$project' does not exist."
}
