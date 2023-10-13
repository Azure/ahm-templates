# convertFromAmba.ps1
# Converts alerts from AMBA to the metrics.json schema.

param (
    [Parameter(Mandatory = $true)]
    [string]$inputUrl="https://raw.githubusercontent.com/Azure/azure-monitor-baseline-alerts/main/services/Compute/virtualMachineScaleSets/alerts.yaml"
)

$yamlObject = Invoke-WebRequest $inputUrl | `
                ConvertFrom-Yaml | `
                Where-Object { $_.type -eq "Metric"}

$filteredObjects = @()

# mapping between the operators used
$operatorMap = @{
    "GreaterThanOrEqual" = "GreaterOrEquals"
    "LessThanOrEqual" = "LowerOrEquals"
}

foreach ($item in $yamlObject) {

    # translate the operator if needed
    if ($operatorMap.ContainsKey($($item.properties.operator))) {
        $operator = $operatorMap[$($item.properties.operator)]
    } else {
        $operator = $($item.properties.operator)
    }

    $filteredObject = [PSCustomObject]@{
        metricName = $item.name
        aggregationType = $item.properties.timeAggregation
        timeGrain = $item.properties.evaluationFrequency
        degradedThreshold = "$($item.properties.threshold)"
        degradedOperator = $operator
        unhealthyThreshold = "$($item.properties.threshold)"
        unhealthyOperator = $operator
        recommended = "false"
    }

    $filteredObjects += $filteredObject
}

$jsonOutput = $filteredObjects | ConvertTo-Json

Write-Host $jsonOutput