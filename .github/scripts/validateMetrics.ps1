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
    recommended        = [string]
}

# Define allowed values for specific properties
$allowedValues = @{
    aggregationType = @("Average")
    degradedOperator = @("GreaterThan")
    unhealthyOperator = @("GreaterThan")
    recommended = @("true", "false")
}

# Validate each object against the schema
$isSchemaValid = $true

foreach ($object in $objects) {
    foreach ($property in $schema.Keys) {
        # Check if the property exists
        if ($object.$property -isnot $schema[$property]) {
            Write-Host "::warning file=$metricsFile::Invalid schema detected for '$property'."
            $isSchemaValid = $false
            break
        }

        # Check if the property value is in the allowed values array
        if ($allowedValues.ContainsKey($property) -and $object.$property -notin $allowedValues[$property]) {
            Write-Host "::warning file=$metricsFile::Invalid value detected for '$property'. Set to $($object.$property). Allowed values are $($allowedValues[$property])."
            $isSchemaValid = $false
            break
        }
    }
}

Write-Host "isSchemaValid=$isSchemaValid" >> $env:GITHUB_ENV

if ($isSchemaValid) {
    Write-Host "Schema validation successful."
}