param (
    [Parameter(Mandatory)]
    [string] $jsonfile,
    [string] $schemafile = "./templates/metrics.schema.json"

)

if (!(Test-Path $schemafile)) {
    Write-Error "Schemafile $schemafile not found."
    exit
}

if (!(Test-Path $jsonfile)) {
    Write-Error "File $jsonfile not found."
    exit
} else {
    $json = Get-Content -Path $jsonfile -Raw | convertfrom-json | convertto-json
}

$json

if (!(Test-Json -Json $json -schemafile $schemafile)) {
    Write-Error "File $jsonfile does not contain valid JSON."
} else {
    Write-Host "$jsonfile validated against $schemafile"
}

