# convertFromAmba.ps1
# Converts alerts from AMBA to the metrics.json schema.

param (
    [Parameter(Mandatory = $false)]
    [string]$inputUrl="https://raw.githubusercontent.com/Azure/azure-monitor-baseline-alerts/main/services/Synapse/workspaces/alerts.yaml"
)

$yamlObject = Invoke-WebRequest $inputUrl | `
                ConvertFrom-Yaml | `
                Where-Object { $_.type -eq "Metric"}

$filteredObjects = @()

# mapping between the operators used
$operatorMap = @{
    "GreaterThanOrEqual" = "GreaterOrEquals"
    "LessThanOrEqual" = "LowerOrEquals"
    "LessThan" = "LowerThan"
}

foreach ($item in $yamlObject) {

    # translate the operator if needed
    if ($operatorMap.ContainsKey($($item.properties.operator))) {
        $operator = $operatorMap[$($item.properties.operator)]
    } else {
        $operator = $($item.properties.operator)
    }

    # if verified and visibile are both true, then the metric is recommended
    if ($item.properties.verified && $item.properties.visible) {
        $recommended = "true"
    } else {
        $recommended = "false"
    }

    $filteredObject = [PSCustomObject]@{
        metricName = $item.name
        aggregationType = $item.properties.timeAggregation
        timeGrain = $item.properties.evaluationFrequency
        degradedThreshold = "$($item.properties.threshold)"
        degradedOperator = $operator
        unhealthyThreshold = "$($item.properties.threshold)"
        unhealthyOperator = $operator
        recommended = $recommended
        metricNamespace = $item.properties.metricNamespace.toLower()
    }

    $filteredObjects += $filteredObject
}

$groupedData = $filteredObjects | Group-Object -Property metricNamespace

foreach ($group in $groupedData) {
    $namespace = $group.Name
    $data = $group.Group | Select-Object metricName, aggregationType, timeGrain, degradedThreshold, degradedOperator, unhealthyThreshold, unhealthyOperator, recommended
    Write-Host "Processing $namespace"

    # check if file already exists
    if (Test-Path "./templates/$namespace/metrics.json") {
        Write-Host "File already exists, merging"
        $existingData = Get-Content "./templates/$namespace/metrics.json" | ConvertFrom-Json
        $mergedJson = @{}
        $existingData + $data | ForEach-Object {
            $metricName = $_.metricName
            if (-not $mergedJson.ContainsKey($metricName)) {
                $mergedJson[$metricName] = $_
            }
        }
        $data = $mergedJson.Values

    } else {
        New-Item -Path "./templates/$namespace" -ItemType Directory
    }
    $data | ConvertTo-Json | Out-File -FilePath "./templates/$namespace/metrics.json"

    
}
