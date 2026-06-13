# Sentinel Forensic Push Helper Script
Clear-Host

Write-Host "=== Sentinel Forensic GitHub Push Helper ===" -ForegroundColor Cyan
Write-Host "This script will commit and push the project files to your GitHub repository." -ForegroundColor Gray
Write-Host ""

# Check if git is installed locally
if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] Git was not found on your local system." -ForegroundColor Red
    Write-Host "Please install Git from https://git-scm.com/ and try again." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit
}

# Add files and commit
Write-Host "1. Adding files to staging..." -ForegroundColor Blue
git add .

Write-Host "2. Creating commit..." -ForegroundColor Blue
git commit -m "Updates: Sentinel Forensic CDR/TDR/SDR Data Analyzer" 2>$null

Write-Host "3. Setting branch to 'cdr-analyzer'..." -ForegroundColor Blue
git branch -M cdr-analyzer

# Check remote
$remoteUrl = "https://github.com/kashinathyankanchi-maker/kashi.git"
$existingRemote = git remote get-url origin 2>$null
if ($existingRemote -ne $remoteUrl) {
    if ($existingRemote) {
        git remote remove origin
    }
    git remote add origin $remoteUrl
}

Write-Host "4. Pushing to GitHub (https://github.com/kashinathyankanchi-maker/kashi)..." -ForegroundColor Blue
git push -u origin cdr-analyzer

Write-Host ""
Write-Host "=== Process Completed! ===" -ForegroundColor Green
Write-Host "Please review your repository at: https://github.com/kashinathyankanchi-maker/kashi/tree/cdr-analyzer" -ForegroundColor Green
Write-Host ""
Read-Host "Press Enter to exit"
