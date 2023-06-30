# validateMetrics.ps1
# Validates the schema of the metrics.json file.
# This script is used by the GitHub Actions workflow.

param (
    [Parameter(Mandatory = $true)]
    [string]$metricsFile
)

# Test if metrics.json exists
if (-not (Test-Path $metricsFile)) {
    Write-Host "Metrics file not found at '$metricsFile'."
    exit 1
}

# Convert JSON to PowerShell objects
$objects = Get-Content $metricsFile | ConvertFrom-Json

# Define the expected schema
$schema = @{
    metricName         = [string]
    aggregationType    = [string]
    timeGrain          = [string]
    degradedThreshold  = [string]
    degradedOperator   = [string]
    unhealthyThreshold = [string]
    unhealthyOperator  = [string]
    recommended        = [bool]
}

# Validate each object against the schema
$isSchemaValid = $true

foreach ($object in $objects) {
    foreach ($property in $schema.Keys) {
        if ($object.$property -isnot $schema[$property]) {
            Write-Host "::notice file=$metricsFile::Invalid schema detected for '$property' in object:"
            # Write-Host $object | ConvertTo-Json -Depth 4
            $isSchemaValid = $false
            break
        }
    }
}

if ($isSchemaValid) {
    Write-Host "Schema validation successful."
}