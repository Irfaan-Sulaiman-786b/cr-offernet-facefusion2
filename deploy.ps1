<#
.SYNOPSIS
    Deploys to Cloud Run with robust Docker configuration output.
#>

param (
    [Parameter(Mandatory=$false)]
    [ValidateSet("main", "dev")]
    [string]$Environment = "main"
)

# Configuration
$ProjectId = "omnibase-master"
$Region = "europe-west4"
$RepositoryName = (Split-Path -Leaf -Path (Get-Location))
$ServiceAccountKeyPath = ".\.general-service-account-key.json"
$Registry = "europe-west4-docker.pkg.dev"

# Deployment settings
$Suffix = if ($Environment -eq "main") { "live" } else { "dev" }
$ServiceName = "$RepositoryName-$Suffix"
$ImageUri = "$Registry/$ProjectId/$RepositoryName-$Suffix/$RepositoryName-image"

Write-Host "`n=== Deployment Settings ==="
Write-Host ("{0,-20}: {1}" -f "Environment", $Environment)
Write-Host ("{0,-20}: {1}" -f "Project ID", $ProjectId)
Write-Host ("{0,-20}: {1}" -f "Region", $Region)
Write-Host ("{0,-20}: {1}" -f "Service Name", $ServiceName)
Write-Host ("{0,-20}: {1}" -f "Image URI", $ImageUri)

# Authenticate
Write-Host "`n=== Authenticating ==="
gcloud auth activate-service-account --key-file=$ServiceAccountKeyPath 2>&1 | Write-Host
gcloud config set project $ProjectId 2>&1 | Write-Host

# Docker Configuration (Improved)
Write-Host "`n=== Docker Configuration ==="
try {
    # Manual configuration approach
    $dockerConfigPath = "$env:USERPROFILE\.docker\config.json"
    
    # Create or update Docker config
    if (Test-Path $dockerConfigPath) {
        $config = Get-Content $dockerConfigPath -Raw | ConvertFrom-Json -Depth 10
    } else {
        $config = New-Object PSObject
    }
    
    if (-not $config.PSObject.Properties['credHelpers']) {
        $config | Add-Member -NotePropertyName "credHelpers" -NotePropertyValue @{} -Force
    }
    
    $config.credHelpers[$Registry] = "gcloud"
    $config | ConvertTo-Json -Depth 10 | Set-Content $dockerConfigPath
    
    Write-Host "Successfully configured Docker for GCR"
    Write-Host "Verifying configuration..."
    gcloud auth configure-docker $Registry --verbosity=debug 2>&1 | Write-Host
}
catch {
    Write-Host "ERROR configuring Docker: $_"
    Write-Host "Attempting fallback method..."
    # Directly run the command without JSON manipulation
    gcloud auth configure-docker $Registry --verbosity=debug 2>&1 | Write-Host
}

# Continue with deployment...
Write-Host "`n=== Building Image ==="
docker build -t $ImageUri . 2>&1 | Write-Host

Write-Host "`n=== Pushing Image ==="
docker push $ImageUri 2>&1 | Write-Host

Write-Host "`n=== Deploying to Cloud Run ==="
gcloud run deploy $ServiceName `
    --image $ImageUri `
    --region $Region `
    --platform managed `
    --allow-unauthenticated `
    --memory 1Gi `
    --timeout 30m `
    --project $ProjectId 2>&1 | Write-Host

Write-Host "`n=== Deployment Complete ==="