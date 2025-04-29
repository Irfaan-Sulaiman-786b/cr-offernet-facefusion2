param (
    [string]$Environment = "Dev"  # Default to "Dev" if no parameter is provided
)

# Activate the virtual environment (.venv)
.venv/Scripts/Activate.ps1

# Uninstall the package (if it's already installed)
pip uninstall -y offernet_common_routines

# Delete the tar.gz file locally (if it exists)
if (Test-Path -Path offernet_common_routines-0.1.0.tar.gz) {
    Remove-Item -Path offernet_common_routines-0.1.0.tar.gz -Force
}

# Based on the environment, modify the GCS path
if ($Environment -eq "Dev") {
    Write-Host "Deploying to Dev Environment"
    # Copy the tar.gz file from GCS to the current directory
    gsutil cp gs://gcs-shared-code-dev/offernet_common_routines-0.1.0.tar.gz .
}
elseif ($Environment -eq "Live") {
    Write-Host "Deploying to Live Environment"
    # Copy the tar.gz file from GCS to the current directory
    gsutil cp gs://gcs-shared-code-live/offernet_common_routines-0.1.0.tar.gz .
}
else {
    Write-Host "Invalid environment specified. Please specify either 'Dev' or 'Live'."
}

# Install the package from the local tar.gz file
pip install offernet_common_routines-0.1.0.tar.gz

# Deactivate the virtual environment (optional, but recommended)
deactivate