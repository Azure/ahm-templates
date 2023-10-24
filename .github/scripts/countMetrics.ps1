# countMetrics.ps1

param (
    [Parameter(Mandatory = $false)]
    [string]$inputDir = "./templates"
)

$metricsFiles = Get-ChildItem metrics.json -Recurse -Path $inputDir
$mergedData = @()

foreach ($file in $metricsFiles) {

    # parse metricNamespace from filename
    $indexOfLastTemplates = $file.FullName.LastIndexOf("templates")
    if ($indexOfLastTemplates -ge 0) {
        $result = $file.FullName.Substring($indexOfLastTemplates + ("templates".Length+1))
        if ($result -like "*metrics.json") {
            $metricNamespace = $result.Substring(0, $result.Length - ("metrics.json".Length+1))
        } else {
            $metricNamespace = $result
        }
    }

    # load individual metrics.json file
    $jsonContent = Get-Content $file | ConvertFrom-Json

    # add the metricNamespace to each entry
    foreach ($item in $jsonContent) {
        # Add the "metricNamespace" property to the object
        $item | Add-Member -MemberType NoteProperty -Name "metricNamespace" -Value $metricNamespace
    }

    $mergedData += $jsonContent
}

$totalMetrics = $mergedData.Count
$totalMetricNamespaces = ($mergedData | Group-Object -Property metricNamespace).Count

Write-Output "totalMetrics=$($totalMetrics)" >> $Env:GITHUB_OUTPUT
Write-Output "totalMetricNamespaces=$($totalMetricNamespaces)" >> $Env:GITHUB_OUTPUT

Write-Host "Total number of metrics defined: $totalMetrics"
Write-Host "Total number of metric namespaces defined: $($totalMetricNamespaces)"