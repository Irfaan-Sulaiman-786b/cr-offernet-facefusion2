param (
    [string]$env
)

# Validate environment input
if ($env -ne "dev" -and $env -ne "live") {
    Write-Host "ERROR: Invalid environment! Use 'dev' or 'live'."
    exit 1
}

# Set variables based on environment
$projectId = "omnibase-master"  # Change this to your Google Cloud project ID
$region = "europe-west4"
$repoName = "cr-offernet-facefusion-$env"  # Unique repository for each environment
$imageName = "cr-offernet-facefusion"  # Add environment suffix to the image name

# Full image path in Google Artifact Registry
$imagePath = "$region-docker.pkg.dev/$projectId/$repoName/$imageName"

Write-Host "Deploying image for environment: $env"

# Check if Artifact Registry exists
Write-Host "Checking if Artifact Registry exists..."
$repoCheck = gcloud artifacts repositories list --filter="name:$repoName" --format="value(name)"

Write-Host "RepoCheck Length: $($repoCheck.Length)"

if ($repoCheck.Length -eq 0) {
    Write-Host "Repository '$repoName' not found. Creating it..."
    gcloud artifacts repositories create $repoName `
        --repository-format=docker `
        --location=$region `
        --description="Docker repository for unified bots ($env)"
} else {
    Write-Host "Repository '$repoName' already exists. Skipping creation."
}

Write-Host "Enabling Artifact Registry API (if not already enabled)..."
gcloud services enable artifactregistry.googleapis.com

Write-Host "Authenticating Docker with Google Cloud..."
gcloud auth configure-docker "$region-docker.pkg.dev"

Write-Host "Building Docker image with --no-cache to avoid reusing layers..."
docker build --no-cache -t "$imageName" .

Write-Host "Tagging Docker image for Google Artifact Registry..."
docker tag "$imageName" "$imagePath"

Write-Host "Pushing Docker image to Artifact Registry..."
docker push "$imagePath"

Write-Host "Deployment complete! Image is now available at:"
Write-Host "   $imagePath"

Write-Host "Listing images in the repository..."
gcloud artifacts docker images list "$region-docker.pkg.dev/$projectId/$repoName"