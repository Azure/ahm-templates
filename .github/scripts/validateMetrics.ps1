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
    aggregationType = @("Average","Maximum","Minimum")
    degradedOperator = @("GreaterThan","GreaterOrEquals","Equals","LowerThan","LowerOrEquals","Contains")
    unhealthyOperator = @("GreaterThan","GreaterOrEquals","Equals","LowerThan","LowerOrEquals","Contains")
    recommended = @("true", "false")
}

# Validate each object against the schema
$isSchemaValid = $true

$errorCount = 0

# Check if metricName is unqiue per metrics.json
$objects | Group-Object -Property metricName | Where-Object { $_.Count -gt 1 } | ForEach-Object {
    Write-Host "::error file=$metricsFile::Duplicate metricName detected for '$($_.Name)'."
    $isSchemaValid = $false
}

foreach ($object in $objects) {
    foreach ($property in $schema.Keys) {
        # Check if the property exists
        if ($object.$property -isnot $schema[$property]) {
            Write-Host "::error file=$metricsFile::Invalid schema detected for '$property'."
            $isSchemaValid = $false
            break
        }

        # Check if the property value is in the allowed values array
        if ($allowedValues.ContainsKey($property) -and $object.$property -notin $allowedValues[$property]) {
            Write-Host "::error file=$metricsFile::Invalid value detected for '$property'. Set to $($object.$property). Allowed values are $($allowedValues[$property])."
            $isSchemaValid = $false
            break
        }

    }
}

if ($isSchemaValid) {
    Write-Host "Schema validation successful for $metricsFile."
} else {
    Write-Host "Schema validation failed for $metricsFile."
    exit 1
}