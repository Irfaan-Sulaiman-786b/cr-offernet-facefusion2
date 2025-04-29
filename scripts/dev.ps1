$env:ENVIRONMENT = "local"

$env:GOOGLE_PROJECT_ID = "omnibase-master"
$env:GOOGLE_SERVICE_ACCOUNT_KEY = Get-Content .general-service-account-key.json -Raw
$env:GOOGLE_OFFERNET_PIXEL_TOPIC_ID = "ps-offernet-pixel-dev"
$env:GOOGLE_OFFERNET_PIXEL_DATASET = "offernet_pixel_dev"
$env:GOOGLE_OFFERNET_PIXEL_TABLE = "u_pixel_traffic"
$env:GOOGLE_LOGGING_FLAG = 1

$env:GOOGLE_SERVICE_ACCOUNT_KEY = Get-Content .general-service-account-key.json -Raw

$env:EXPECTED_API_KEY = "f439480c-715f-461d-bafd-9006fd44a432"

Write-Output $env:ENVIRONMENT

Write-Output $env:GOOGLE_PROJECT_ID
Write-Output $env:GOOGLE_OFFERNET_PIXEL_TOPIC_ID
Write-Output $env:GOOGLE_OFFERNET_PIXEL_DATASET
Write-Output $env:GOOGLE_OFFERNET_PIXEL_TABLE
Write-Output $env:GOOGLE_LOGGING_FLAG