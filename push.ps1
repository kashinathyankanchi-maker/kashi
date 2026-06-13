# Flutter Project Push Helper Script
Clear-Host

Write-Host "=== Sentinel Forensic Flutter GitHub Push Helper ===" -ForegroundColor Cyan
Write-Host "This script will commit and push the Flutter codebase to your GitHub repository." -ForegroundColor Gray
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
git commit -m "Updates: Sentinel Forensic Flutter App Codebase" 2>$null

Write-Host "3. Setting branch to 'flutter-version'..." -ForegroundColor Blue
git branch -M flutter-version

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
git push -u origin flutter-version

Write-Host ""
Write-Host "=== Process Completed! ===" -ForegroundColor Green
Write-Host "Please review your branch at: https://github.com/kashinathyankanchi-maker/kashi/tree/flutter-version" -ForegroundColor Green
Write-Host ""
Read-Host "Press Enter to exit"
